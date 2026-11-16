bcf012 — upstream reference: C in-kernel reconcile auto-retry vs Rust port
==========================================================================

Source: github.com/koverstreet/bcachefs (kernel tree, master @ e41eb8a6f24,
2026-09-26 — final C state before archive; note: torvalds/linux master no
longer carries fs/bcachefs at all, so this tree IS the canonical C reference);
local tools/ = koverstreet/bcachefs-tools @ d48ba1a7a (2026-10-30, master).
Checkouts cached: ~/.cache/checkouts/github.com/koverstreet/bcachefs and
.../github.com/torvalds/linux (no reconcile there — kept for provenance).
-> refs/bcf012 -> refs/bcf025 -> refs/bcf030

Summary
=======

The C mechanism is not a timer: parked (pending) reconcile keys retry only
when the world's state changes. Every event that can un-park keys bumps a
persistent scan cookie (a KEY_TYPE_cookie in BTREE_ID_reconcile_scan, keyed
by RECONCILE_SCAN_COOKIE_pending) and/or kicks the kthread
(c->reconcile.kick++, RCU-dereference thread, wake_up_process). The scan
cookie btree is journaled, so pending-work requests survive remount. The Rust
port carries this whole event matrix — partially re-implemented in Rust
(data/reconcile/{work,scan}.rs, opts/change.rs, debug/sysfs.rs, vfs, fs/
inode_opts.rs, init/passes.rs), partially inherited via leftover kernel C
files (fs/init/{dev,recovery,fs}.c) that call Rust exports
(work.rs:1165 bch2_reconcile_wakeup, scan.rs:475/482 set_reconcile_needs_scan
/ set_fs_needs_reconcile). Verdict: **no material gap** — the port already
self-drains on the same events C does. Findings below are drifts/caveats,
not missing calls.

C mechanism (kernel tree, fs/bcachefs/data/reconcile/)
======================================================

API (work.h:67-81):

- bch2_reconcile_wakeup(c) — inline: c->reconcile.kick++; RCU-guarded
  wake_up_process(thread).
- bch2_reconcile_pending_wakeup(c) — inline: set_reconcile_needs_scan(
  c, {RECONCILE_SCAN_pending}, true) — i.e. bump the persistent pending
  cookie, then kick.
- bch2_set_reconcile_needs_scan_trans/_scan (work.c:132-166) — cookie += 1
  in BTREE_ID_reconcile_scan at position encode(scan); optional wakeup.
- bch2_set_reconcile_needs_scan_pre/_post (work.c:266-291) — bracket an opt
  change; _post always wakes (288). In-flight opt-change registration
  prevents the thread from deleting (completing) a cookie whose scan ran
  against a half-applied opt value.
- bch2_set_fs_needs_reconcile (work.c:294-298) — fs-wide cookie + wake.
- Thread gate (work.c:1755-1775): kthread_wait_freezable(pass_done >
  BCH_RECOVERY_PASS_check_snapshots || kthread_should_stop()) — data moves
  need bch2_snapshot_is_ancestor.
- Park: do_reconcile tail (work.c:1738-1748) — if nothing scanned, no kick
  since pass start, no stop: reconcile_wait() (io-clock wait / freezable
  schedule). Exits the park only on: kick, io-clock expiry, stop.

Event -> C call-site table
==========================

wakeup = bch2_reconcile_wakeup; pending = set_reconcile_needs_scan(pending).
"bracket" = pre(false)/post(true,wake) pair around the mutating operation.

| Event                                   | C file:line                       | What fires                      |
|-----------------------------------------|-----------------------------------|---------------------------------|
| Recovery fully done (lost+found, 1st jrnl) | init/recovery.c:1092            | wakeup                          |
| Recovery pass boundary (past check_snapshots) | init/passes.c:572-576       | wakeup (+copygc)                |
| Device online (attach -> sysfs online)  | init/dev.c:778                    | wakeup                          |
| Dev state change to rw/evacuating       | init/dev.c:817-899 (840 pre, 867 post) | pending bracket + stripes scan |
| Dev add (image update / multi-device)   | init/dev.c:1070-1080, 1180        | pending bracket                 |
| Dev remove/offline (SB write may have failed while offline) | init/dev.c:1250-1264 (1263) | pending + wake |
| Dev resize (grow)                       | init/dev.c:1313-1367 (1315 pre, 1365 post) | pending bracket |
| Dev group/label set (target change)     | alloc/disk_groups.c:467-485 (474/483; stale comment 476) | pending bracket |
| Opt change, data opts (targets/compression/checksum/replicas/ec/nocow) | opts.c:572-625 (596) | fs/inum scan bracket |
| Opt change, metadata opts               | opts.c:600-604                    | metadata scan bracket           |
| Opt durability increased                | opts.c:605-615 (612 pre)          | pending pre + device bracket    |
| Opt reconcile_enabled / read_only post  | opts.c:691-694 (693), 729-732 (731) | wakeup                        |
| Inode write changed per-inode reconcile opts | vfs/fs.c:144 (inum cookie in tx), 171 (wakeup) | inum scan + wake |
| Remount / reconfigure                   | vfs/fs.c:2440                     | wakeup                          |
| Power supply change (on/off battery)    | data/reconcile/work.c:1921-1930 (1928) | wakeup (CONFIG_POWER_SUPPLY)  |
| Sysfs debug                             | debug/sysfs.c:469-473 (attrs 167-168, list 644-645) | trigger_reconcile_wakeup / trigger_reconcile_pending_wakeup |
| Generic cookie bump with wakeup=true    | work.c:152-166 (158)              | any needs_scan caller           |

Rust side (tools/fs/) — same points, status
===========================================

Rust-native API: work.rs:954-956 reconcile_wakeup (thread.lock -> t.kick()),
work.rs:962-964 reconcile_pending_wakeup (= request_scan(pending, true)),
scan.rs:136-141 request_scan(scan, wakeup) (= set_reconcile_needs_scan),
scan.rs:225-235 opt_change_scan_pre, scan.rs:243-244 opt_change_scan_post
(always wakes), scan.rs:475/482 extern exports consumed by the leftover C.

| Event                                   | C kernel site          | Rust port site                          | Status |
|-----------------------------------------|------------------------|-----------------------------------------|--------|
| Recovery done                           | init/recovery.c:1092   | fs/init/recovery.c:1016-1017 (C leftover, calls Rust export) | present |
| Recovery pass boundary                  | init/passes.c:575      | fs/init/passes.rs:896-898 — but boundary pass is resume_logged_ops_early, not check_snapshots | present, drifted (see D1) |
| Device online                           | init/dev.c:778         | fs/init/dev.c:803 (C leftover)          | present |
| Dev state -> rw/evacuating              | init/dev.c:840/867     | fs/init/dev.c:857/870/893/897 (C leftover); entry = ioctl via chardev.rs:638 disk_set_state -> dev.rs:61 -> C bch2_dev_set_state | present |
| Dev add                                 | init/dev.c:1078/1180   | fs/init/dev.c:1206/1310 (C leftover; chardev.rs:566) | present |
| Dev remove/offline                      | init/dev.c:1263        | fs/init/dev.c:1424 (C leftover)         | present |
| Dev resize                              | init/dev.c:1315/1365   | fs/init/dev.c:1484-1487/1550-1551 (C leftover; chardev.rs:653) | present |
| Dev label/group set                     | alloc/disk_groups.c:474/483 | moved into opts path: fs/debug/sysfs.rs:478-484 (OptsDir) -> fs/opts/change.rs:70-80 (Opt_label: pending + device brackets) | present, relocated (see D2) |
| Opt change brackets (fs/inum/metadata/device/stripes) | opts.c:572-625 | fs/opts/change.rs:37-58 (bracket closure) | present |
| Opt durability increase                 | opts.c:612             | fs/opts/change.rs:57-61                 | present |
| Opt reconcile_enabled / read_only       | opts.c:693/731         | fs/opts/change.rs:159                   | present |
| Inode opts change                       | vfs/fs.c:144/171       | fs/fs/inode_opts.rs:644 (inum cookie), 675 (propagate finish), 759 (write_inode finish: reconcile_changed -> wakeup) | present |
| Remount/reconfigure                     | vfs/fs.c:2440          | fs/vfs/fs_type.rs:465                   | present |
| Power supply change                     | work.c:1928            | fs/data/reconcile/work.rs:1109-1140 (notifier + register), gated #[cfg(CONFIG_POWER_SUPPLY)] | present, cfg-risk (see D3) |
| Sysfs debug triggers                    | sysfs.c:469-473        | fs/debug/sysfs.rs:126-127 (both attrs)  | present |
| Thread recovery gate                    | work.c:1764-1765 (check_snapshots) | fs/data/reconcile/work.rs:932-936 (resume_logged_ops_early) | drifted (D1) |
| Park/wait + kick re-eval                | work.c:1738-1748       | fs/data/reconcile/work.rs:902-923 (wait), 808/829-833 (kick re-eval) | present |
| CLI evacuate kick                       | (n/a kernel: in-ioctl) | src/commands/device.rs:569 (sysfs trigger_reconcile_wakeup write, belt-and-braces on top of disk_set_state) | present |

Drifts and caveats (not missing calls)
======================================

D1 — Recovery-gate pass drifted: C gates the thread (and the pass-boundary
wake) on check_snapshots completion; Rust gates on resume_logged_ops_early
(local passes_format.rs: check_snapshots=19, resume_logged_ops_early=50, so
strictly later in the local sequence). Both sites carry a comment that this
is deliberate (work.rs:932-936: also waits until stripe-creation resume;
passes.rs:894 "the point it waits for"). Semantics: Rust reconcile starts
later during recovery than C. Fine for parity of the steady-state event
matrix; worth one sentence in bcf012's park map.

D2 — Label-set path relocated: kernel = sysfs dev label attr ->
bch2_dev_group_set (disk_groups.c, pending brackets); Rust = opts dir
(OptsDir, sysfs.rs:495-515) -> OptChange pre/post (change.rs:21-27, 233-237)
-> change.rs:70-80 (Opt_label: pending + device brackets). disk_groups.rs is
display-only by design. Coverage equivalent; entry point moved. Note kernel
disk_groups.c:476 still carries a stale comment ("bch2_reconcile_wakeup_pending
goes here") — cosmetic upstream nit, candidate for a drive-by fix PR.

D3 — POWER_SUPPLY cfg risk on FreeBSD: the battery-change wakeup
(work.rs:1109-1140) is #[cfg(CONFIG_POWER_SUPPLY)] and no POWER_SUPPLY knob
appears in Cargo.toml/build.rs/build_config.rs — likely compiled out of the
FUSE daemon build. Consequence for reconcile_on_ac_only (work.rs:96): 
on_battery is set once at start (work.rs:1140) and never updated -> if the
daemon mounts on battery, reconcile stays gated until manual
trigger_reconcile_wakeup; if mounted on AC, un-plugging doesn't pause it.
Relevant to bcf012/bcf025 ops notes; fix = wire an AC-state poll into the
daemon or drop the opt in the FreeBSD build docs.

Verdict for bcf012 (rewiring candidates)
========================================

1. Nothing to rewire for upstream parity: every C event has a live Rust-side
   counterpart (native or via C leftovers calling Rust exports), so the
   "self-drain" semantics already match. The bcf012 park backlog
   (ENOSPC-class parks in plan.rs:313-324/368, io-clock freeze in
   Copygc::sleep) is not caused by missing wakeups — upstream C parks the
   same way and also only retries on the events tabulated above.
2. If drainage automation beyond upstream is wanted (bcf025), the port
   already exposes the upstream-sanctioned entry point:
   sysfs internal/trigger_reconcile_pending_wakeup (sysfs.rs:127) — a cron
   write to it is exactly bch2_reconcile_pending_wakeup; no new call sites
   needed. SIGUSR1 -> that attr is the minimal upstreamable-free stopgap.
3. Genuinely upstreamable small items (koverstreet/bcachefs-tools door):
   (a) FreeBSD/non-Linux build: make the power-notifier absence explicit or
   poll AC state (D3); (b) drive-by: fix the stale disk_groups.c:476 comment
   upstream (it survives in our C leftovers); (c) upstream TODO already
   self-documented at dev.c:1255-1260: pending scans should note /which/
   targets have extents on the pending list to avoid full pending rescans on
   device flaps — that is the only "missing call" class upstream itself
   acknowledges, and both C and Rust lack it.

SEE ALSO

tasks/bcf012-background-threads-audit.md — park-condition map this feeds
tasks/bcf025-cron-usr1-decision.md — drainage automation decision (sysfs
trigger path, item 2 above)
tasks/bcf030-poolwatch-rwpend-alert.md — alert on the backlog these wakeups drain
docs/f3-runbook.org — ring/backtrace anchors for the io-clock freeze class
