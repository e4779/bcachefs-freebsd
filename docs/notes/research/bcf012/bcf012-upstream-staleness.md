bcf012 upstream staleness check (bcachefs-tools)
================================================

Source: git fetch koverstreet/bcachefs-tools (origin/* refs only), gh CLI
Date: 2026-11-16; working tree untouched, no rebase, no builds
-> refs/bcf012 -> refs/bcf032 -> refs/reconcile-pending -> refs/io-clock

Summary
-------

Our clone base is d48ba1a7a (2026-10-30, "util/task: run, dispatch and wake
are TaskRef's"); merge-base with origin/master equals our HEAD — the overlay
carries everything, zero local commits on master. Upstream moved 1437 commits
in ~16 days to 8e1519c2d (2026-11-15). 1435 of 1437 are Kent Overstreet:
a solo Rust-ification sprint — os/ port layer (linux_kernel/linux_user),
C-file removal (dev.c, node_scan.c, rcu_pending.c, move.c, printbuf), enum
declarations, rustix migration. **No commit in the window references an issue
number; not a single PR was merged.** The three bcf012 mechanics are
byte-for-byte (modulo renames) unchanged: all post-base commits touching
reconcile/scan/plan are renames or restructures.

Base and upstream
-----------------

| Item             | Value                                        |
|------------------|----------------------------------------------|
| our base (HEAD)  | d48ba1a7a1d03afed5a20d1cce8189e9ae9a8486     |
| base date        | 2026-10-30 23:15 -0500                       |
| origin/master    | 8e1519c2dd41fc845fca608389dc7052e25e9d94     |
| upstream date    | 2026-11-15 05:05 -0500                       |
| merge-base       | d48ba1a7a (= HEAD; overlay model confirmed)  |
| commits behind   | 1437 (~90/day)                               |
| authors          | Kent Overstreet 1435, others 2               |

Relevant upstream commits after base
------------------------------------

Topic scan over fs/data/reconcile, fs/data/copygc, clock files, and message
grep (park/pending/wake/enospc/drain/capacity/scan):

| Commit    | Date       | What it changes                                       |
|-----------|------------|-------------------------------------------------------|
| 4e336b5c5 | 2026-11-14 | reconcile: scan is a Rust enum — pending-cookie machinery renamed only; run()/complete()/request_scan bodies identical |
| 503d14662 | 2026-11-06 | reconcile_scan tagged_union! enum; RECONCILE_SCAN_TYPES gone — rename |
| 659b08ce5 | 2026-11-11 | parked stripe's message out of line — cosmetic        |
| 4f2ece07a | 2026-11-10 | Btree phase's step is one attempt — pending-phase restructure, no semantics |
| e1fe6d66b | 2026-11-10 | EC stripe repair handed off — restructure             |
| 9c20d19fc | 2026-11-09 | alloc/capacity: disk_reservation_enospc tracepoint — observability only |
| 9c73bac97 | 2026-11-14 | util/refcount: stop() wakes no one when nothing out — adjacent util wake semantics, not our paths |
| df050176c | 2026-11-08 | vfs: evict_subvolume_inodes() lost-wakeup fix — unrelated to reconcile |
| fe1ad1afc | 2026-11-02 | linux/sched: wake_up_process() is a full barrier — generic port correctness |

fs/data/copygc: **zero commits** after base. The io-clock sleep logic
(cg.sleep(last + (capacity >> 6)) fallback, dev_list() wait) is identical.

GitHub issues/PRs (last 3 months)
---------------------------------

Issue #1234 — our bcf032 thread (FreeBSD: FUSE_DESTROY to one blocked reader,
daemon hangs on umount -f): **OPEN, 0 comments, updated 2026-11-15**. Kent has
not responded; no review-response commits from him in the window (all 1435 are
the rename/port sprint).

- #1124 [closed 2026-10-08] "reconcile: the pending scan cookie is deleted
  before the pending phases run" — the pending-scan-cookie bug. Fix predates
  our base: base scan.rs already keeps the pending cookie ("not a pending
  scan, which the pass completes after its pending phases").
- #920 [open, untouched since 2026-09-14] "`bcachefs reconcile wait` hangs on
  an idle filesystem with EC work queued" — the io-clock wait-gate area.
- #1184 [open, upd 2026-10-30] EC writes hang for good, no ENOSPC, nearly
  full fs + one member offline; #1201 [open] degraded multi-device hangs in
  folio_wait_bit; #960 [open] allocator wedges during reconcile; #947 [open]
  metadata devices filled with user data. None referenced by any post-base
  commit.
- PRs: none merged in the window. Open external PRs near our topics:
  #1215 bound opportunistic stripe reuse scans (0xFEEDC0DE64), #1228 copygc
  stripe cleanup under pressure (same), #1224 dev remove state_lock recheck
  (emorytaylor), #1195 copygc stripe evacuation full bucket (tom-doerr).

Verdict on bcf012 substance
---------------------------

(a) pending-scan cookie при freed-space — **fixed upstream, but before our
    base**: the cookie-deleted-before-pending-phases bug is #1124, closed
    2026-10-08, and our base d48ba1a already contains the corrected logic.
    Post-base: rename-only (4e336b5c5, 503d14662). The freed-space re-trigger
    angle remains unaddressed upstream — retry triggers are still device
    events only (online/resize/state/label; fs/init/dev.rs:1450 is a port of
    the same C logic we have). Nothing requests the pending scan on freed
    space in master.

(b) io-clock wait gate capacity>>6 — **still open**. work.rs iotime_end =
    now + (capacity >> 6) identical in master (base line 914 -> master 953);
    copygc.rs untouched post-base (capacity>>6 fallback intact at ~:804).
    Issue #920 open, no upstream movement.

(c) ENOSPC parks_on retry — **still open**. parks_on() (plan.rs:316) is
    identical in master, including the doc "nothing retries the pending list.
    check_reconcile_pending_err()" — that function still does not exist in
    the tree (dangling doc reference in both base and master). Only addition:
    ENOSPC diagnostic tracepoint 9c20d19fc. Open issues #1184/#1201/#947 sit
    on this path with zero commits referencing them.

Recommendation
--------------

bcf012 is not stale: none of (a-freed-space re-trigger), (b), (c) was solved
upstream after our base, and (a)'s cookie part was solved before our base (so
our overlay is already aligned). The real risk is churn, not staleness: 1437
commits of renames/removals mean our overlay patches (fs/sb/io.rs,
include/linux/wait.h, fs/btree/cache.c, ...) will collide hard at the next
rebase/merge — os/ port layer moves half the tree. Rebase sooner rather than
later; do not wait for the sprint to end.

SEE ALSO

[bcf012] — the plan this check validates; [bcf032] — issue #1234 still
unanswered; [maintainer-tone] — Kent solo-commits 99.9%, PRs unmerged,
issue-first coordination is the only channel.
