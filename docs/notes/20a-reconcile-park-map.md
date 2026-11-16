# 20a — bcf012 final: reconcile park map (the sticky pending tail)

**Status: VERDICT CLOSED (2026-11-17).** The prod pool's rw_pend tail is the
entire btree replica set, parked permanently by a *configuration invariant*:
`metadata_replicas=2` with `metadata_target=none` on a 2-device pool. The
`none` fallback resolves btree `background_target` to the single-device
foreground target (nvme), so the hdd replica of every btree node is off-target
forever, and a rewrite can neither improve placement (1>1) nor durability
(2<2 is false) — `parks_on`, requeued forever. ENOSPC=0, EC=0. No trigger
fixes it in place; only a config change does. Card bcf012 closes with the map
below; fix choice belongs to the owner (§5).

Pool: `0ec475a1-a0c1-4877-9f6d-ae54986f43f8`, /mnt/pool, `/dev/nda0p3`
(NVMe 1.1T, dev0) + `/dev/ada1` (HDD 3.6T, dev1), format 1.39.

## 1. TL;DR verdict

- **Tail = whole btree.** `rw_pend` 12,467,712 sectors post-probe ==
  `dd_dev0_btree` == `dd_dev1_btree` == 24,351 nodes × 512 sectors — the
  complete btree replica set on both devices (§4). Not user data.
- **Park class = Replicas/target (placement invariant), not space.** Every
  btree node carries one nvme + one hdd replica; with the resolved target =
  nvme (1 device), the hdd replica is structurally off-target
  (`inode_opts.rs:214`), and `write_btree_feasible` returns
  improves_placement=false / improves_durability=false (2=2) → `parks_on` →
  pending, zero movement (§2, row P-A).
- **Nothing retries the pending list — upstream invariant.** Kent's own
  comment (`plan.rs:313-315`); the C kernel has no freed-space event either.
  Upstream moved 1437 commits past our base without touching this mechanics.
- **The "regrow 0 → 12.2M" scare was a measurement artifact** (§3): foreign
  test-uuid daemons + a used/total siginfo pair. Pool truth: sticky floor
  10.84M (11-07) → 12.46M (11-17), creeping +1.4M/9d ≈ 76 MB/day via the
  dev1 leaving-limbo drip, conserved across remounts.
- **USR1 kicks repark 1:1 to the floor** (ops 7aca4d1): the 206,848-sector
  tgt limbo swept into pend with zero sectors drained. Watermark/cron-drain
  fix class is dead for this tail (bcf025 consequence).
- **Per-key traces are unreachable on this line**: tracefs unavailable
  (tracepoint compiled out of the FUSE build), port sysfs fd = /dev/null
  stub, CLI `reconcile status` dies on "resolving sysfs fd". Classification
  stands on ring arithmetic + code reading (§2, §4).

## 2. Park-condition map

Status vocabulary: **invariant** = no in-place trigger can clear it, config
must change; **fixable** = patch/opt action can remove it; **gate** = modulates
drain timing, creates no backlog.

| Class | Code (file:line) | Status | Confirmation |
|---|---|---|---|
| P-A. Target-class park (btree placement invariant). `metadata_target=none` → btree `background_target` = `foreground_target` = nvme (single-device) → hdd replica of every 2-replica node off-target → need target (`needs_reconcile.rs:110-116`) → Move planned → `write_btree_feasible`: improves_placement (avail 1 > on-target 1)=false, improves_durability (2<2)=false (`update_feasible.rs:152-161`) → `data_update_fail_no_rw_devs` **by design** → `parks_on` (`plan.rs:316-337`) → `park()`. Code comment: a rewrite that can't improve placement "succeeds" off target and **requeues forever**. With metadata_replicas=2 on 2 devices *no target saturates* — invariant of the config, not of space. | `tools/fs/fs/inode_opts.rs:214`, `tools/fs/data/update_feasible.rs:128-161`, `tools/fs/data/reconcile/plan.rs:316-337` | **invariant** (fix = §5) | show-super: metadata_replicas=2, metadata_target=none, fg=nvme, bg=hdd, Durability 1+1 (§3, 11-16/17); USR1 probe repark 1:1; pend == btree total exactly |
| P-B. Replicas-class park (`Plan::Park(Replicas)`): need data_replicas + hipri (`needs_reconcile.rs:158-164`), kills empty (devices healthy) → `only(data_replicas)` → `Park(Replicas)` ("can't match data_replicas=N") | `tools/fs/data/reconcile/plan.rs:186-189`, `plan.rs:296-306` | dormant branch — does NOT fire here (all nodes 2-replica, durability 2=2; fires only for a 1-replica btree node) | show-super Durability=1 on both devices kills the earlier "nvme dur=0 under-replication" theory; class retained for map completeness |
| P-C. Sticky pending / no retry: pending phases run only with a pending-scan cookie (`work.rs:871-874`); cookie requested only by topology/config/opt events, recovery boundaries, sysfs, SIGUSR1 (`scan.rs`, `opts/change.rs:59,76`, `dev.c` leftovers, `telemetry.rs:356`). No freed-space event exists **in C either** — "nothing retries the pending list… the configuration has to change first" (Kent, `plan.rs:313-315`; `check_reconcile_pending_err()` referenced there does not exist). | `tools/fs/data/reconcile/work.rs:871-874`, `plan.rs:313-315`, C: `fs/bcachefs/data/reconcile/work.c:132-166` | **upstream invariant** (automation beyond upstream = bcf025 territory) | upstream-gap research: full C↔Rust event-matrix table, no material gap; upstream 1437 commits changed none of it |
| P-D. io-clock gate: thread sleeps in `Copygc::sleep` → `io_clock::wait_until`; deadline = `capacity >> 6` WRITE sectors of the smaller RW disk (`work.rs:914`) ≈ 128 GiB for 4 TB; reads don't tick the clock, so read-only stretches sleep unboundedly. Gate *between* kick windows — the enabler of zero drain, not the backlog creator. | `tools/fs/data/reconcile/work.rs:905-923` | **gate** | live ring `reconcile_status`: "17.2G WRITE wait / 10.8G remaining, duration waited 8-9h", backtrace `Copygc::sleep → io_clock::wait_until`; thread worked only ~20 min after the 11-16 00:07 scan event |
| P-E. dev1 leaving-limbo drip (growth engine): dev1 in leaving limbo → parked keys oscillate pend ↔ tgt(=dev_leaving) — 512-sector drips (~47 s) and bulk reparks every 4-9 h; excess ≈ +1.4M sectors / 9 d. The only load-dependent term (+3% of a write burst). All of it swept 1:1 into pend by the USR1 probe — the floor absorbed the limbo. | trigger-path re-eval: `needs_reconcile.rs:180-188`, `trigger.rs:217-228`; repark: `plan.rs:316-337` | explained residual churn (swept; re-accumulates only via new burst-created tgt accounting) | ring quasi-conservation over 9,673 samples; probe: tgt 206,848 → pend +206,848 exactly, tgt→0 |
| P-F. ENOSPC-class parks (user data): `parks_on` on no_rw_devs / insufficient_devices / ENOSPC | `plan.rs:316-337`, commit path `plan.rs:368` | **zero in this tail** — the 144M ENOSPC-era tail (full HDD target, 11-06/07) drained at ~240 MB/s; what remained is not space-dependent | accounting: cmp=ec=rep=chk=hipri=str=0 all window; verdict ENOSPC=0 |
| P-G. EC/NoStripe parks | `plan.rs:160-162`, `plan.rs:296-306` | not applicable — EC off (data_replicas=1 ⇒ erasure_code=0), rw_ec=0 all window | accounting zeros |
| P-H. Observability gap: per-key park traces (`events::reconcile_set_pending`) go to a tracefs tracepoint, **compiled out** of the FUSE build (`cfg(kernel)` never set, `CONFIG_TRACEPOINTS` unset → `trace(){}`); port sysfs fd is an inert /dev/null placeholder; `/sys/fs/bcachefsfs/<uuid>/` doesn't exist on FreeBSD; CLI `reconcile status` fails "resolving sysfs fd 5". Per-key WHY is unreachable on this line; classification = ring arithmetic + code. | `tools/fs/build_config.rs:61-77`, `tools/fs/sb/counters.rs:111-127`, `tools/src/wrappers/handle.rs:335-354`, `tools/src/wrappers/sysfs.rs:71` | **tooling gap** (fix candidate for a future read-only debug channel) | kit 065 (sysfs stub receipt), kit 066 (ring snapshot); CLI runbook repro |

## 3. Evidence chronology (2026-11-06 → 11-17)

- **11-06** — Ф3-LIVE: first rw on the prod pool (19a). HDD-target-full era
  parks 144M of user data (ENOSPC class, P-F).
- **11-06 → 11-07** — USR1 drainage windows: 144M → 18.8M → floor, ~240 MB/s
  while a window was open. Drain stopped at the floor: pending phases need a
  scan cookie (P-C) and windows are io-clock-gated (P-D). The btree-sized
  residue was already parked (P-A) — space-independent, so space relief
  couldn't touch it.
- **11-07 20:50** — ring minimum: `rw_pend = 10,843,648` (the sticky floor).
- **11-09 → 11-13** — floor stable 10.89–11.19M; dev1 leaving-limbo
  oscillation established (tgt ≡ dev_leaving[1], P-E). **11-13**: bcf012 card
  created (audit tail); evening bursts +0.9M → 11.81M.
- **11-14 12:42** — daemon death signal 6/core during the power outage
  (ops f3814c9; pool survived unclean power-off). 12:17–15:07: four short-lived
  gen-1 daemons with **foreign uuids** (48b5471a/5bab6da4/daa79144/a955a331 —
  fresh test FSes) sample pend=0 → later misread as "fresh daemon had
  rw_pend=0". Second artifact source: siginfo "rw_pend=0/12206080" is a
  used/total pair (0 = no work in flight, not the backlog).
- **11-15 00:07** — pool gen-1 (pid 3325) first sample already 12,207,104,
  before any load: the backlog **persists across remounts** (pending bits in
  the btree; journaled scan cookie).
- **11-16 09:31** — ring window closes: 12,262,400 (9,673 samples since 11-07).
  Passive falsifiers run: accounting `cmp=ec=rep=chk=hipri=str=0` at pend>0 →
  pure tgt/replicas-class stock (H1 holds); pend↔tgt 512-quantum transfer →
  drip mechanics (P-E) live.
- **11-16 09:59 +0700** — **USR1 probe (ops 7aca4d1)**: kick woke the thread;
  tgt limbo 206,848 sectors swept into pend 1:1; zero sectors drained in 6 m;
  thread re-armed the full io-clock wait. Verdict: repark-to-floor —
  watermark-trigger fix class dead for the sticky tail.
- **11-16** — research wave: measurement-artifact audit (H-series, H1–H5
  ranked with passive falsifiers); upstream gap (full C↔Rust wakeup event
  matrix — no material gap; C itself parks the same way); upstream staleness
  (1437 commits in 16 days, Kent's solo Rust-ification sprint, the three
  bcf012 mechanics byte-for-byte unchanged). Commits cece408 (typed park
  classes), fb00350 (synthesis: sticky floor, upstream invariant).
- **11-16/17** — **falsification wave closes the verdict**: (a) show-super
  (read-only): `metadata_replicas=2, data_replicas=1, journal_replicas=0`,
  fg=nvme, bg=hdd, promote=nvme, `metadata_target=none`, nvme Durability=1,
  hdd Durability=1 → the dur-0 under-replication theory is dead; P-B does not
  fire. (b) Skeptic #2 re-derives the condition from code:
  none→foreground fallback (`inode_opts.rs:214`) + `write_btree_feasible`
  2=2 → P-A stands as the mechanism. (c) Trace-classification: ring
  arithmetic proves the tail == whole btree (§4); per-key traces unreachable
  (P-H). Orchestral corrections of 11-16/17 override the earlier drafts where
  they conflict (dur-0, "regrow", ENOSPC share).

## 4. The tail: arithmetic and the probe

Ring snapshot (kit 066, 11-16/17), btree node = 256 KiB = 512 sectors:

| Quantity | Sectors | Nodes | Receipt |
|---|---|---|---|
| rw_pend (pre-probe) | 12,467,200 | 24,350 (×512 exactly) | ring `reconcile_work.pend=[0,12467200,0]` |
| btree on dev0 (nvme) | 12,467,712 | 24,351 | ring `dd_dev0_btree=[9550,12467712,26649088]` |
| btree on dev1 (hdd) | 12,467,712 | 24,351 | ring `dd_dev1_btree=[9554,12467712,26665472]` |
| btree_total | 24,935,424 = 2×12,467,712 | 24,351 × 2 replicas | ring `btree_total=[24935424,24351,32]` |

Pre-probe: 24,350 of 24,351 nodes parked (exactly one node = the 512-sector
tgt limbo still in Move class). **USR1 probe**: tgt 206,848 (= 404 nodes of
accumulated limbo accounting) → pend 1:1 → **pend = 12,467,712 =
dd_dev0_btree = the full btree replica set in sectors**; zero sectors moved
down; tgt/dev_leaving → 0. The probe is the strongest single confirmation of
P-A: a kick cannot drain a placement invariant — it only re-tickets it.

Composition by cause: Replicas/target-class ≈ 100% of parked sectors;
ec-stripe = 0; ENOSPC-class = 0 (was 0 pre-probe too; the 512-sector drip was
Move-class, now absorbed). Multiple-of-512 is *not* used as evidence — the
identity `pend == dd_dev0_btree` across independent ring counters is.

## 5. Fix options (owner decision; prod actions out of scope here)

| Option | Mechanism | Effect | Cost / risk |
|---|---|---|---|
| (a) `metadata_replicas=1` | metadata opt change → opt-change bracket requests a pending scan itself (`opts/change.rs` metadata bracket) → need converges (no off-target replica: 1-replica node on nvme has dur 1≥1; the hdd replica becomes excess → drop-sim = progress) → tail merges on its own, no USR1 needed | confirmed feasible by code (2-replica → drop path gives nr_ptrs>replicas = progress) | **formal metadata redundancy 2→1**; physically also 1 after GC drops the hdd replicas. A metadata-device loss before the next replication change = btree rebuild territory. journal_replicas is already 0, so the pool's marginal loss is smaller than it looks — still an owner trade |
| (b) `metadata_target=disk-group(nvme+hdd)` | both replicas on-target → improves_placement becomes true → moves proceed; redundancy preserved | no redundancy reduction | needs a disk group + opt change; practical at the next planned bounce (remount); per-node moves then actually rewrite the btree (io cost spread over io-clock windows) |
| (c) upstream discussion: `metadata_target=none` → `foreground` fallback semantics | a 2-replica metadata setting silently resolving to a 1-device target parks every btree node on any 2-device pool with default opts — worth an upstream issue/discussion (material for the bcf014 pipeline) | none here; may fix the class at the root for everyone | upstream bandwidth; Kent's queue is a solo sprint (1437 commits, zero issue refs in window) |

Interim posture while undecided: document the floor as an invariant (this
note); keep bcf030 alert signature on `reconcile_work.pend[1]` from
accounting.json (never the siginfo used-field); bcf025 cron-USR1 is
NO-GO as drainage (reparks 1:1 — measured), at most a liveness probe.

## 6. Pointers

Research drafts (raw, pre-correction — superseded where this note conflicts):

- `tmp/research/bcf012-park-map-draft.md` — pending-drainage mechanics,
  cookie-callback census (work.rs/scan.rs/dev.c/change.rs/telemetry.rs)
- `tmp/research/bcf012-upstream-gap.md` — full C↔Rust wakeup event matrix,
  drifts D1–D3, no-material-gap verdict
- `tmp/research/bcf012-hypotheses.md` — measurement-artifact audit, H1–H5
  with passive falsifiers, drip arithmetic
- `tmp/research/bcf012-park-condition-rederive.md` — skeptic #2: P-matrix
  (P1/P2a/P2b…), the none→foreground fallback derivation, USR1 re-read
- `tmp/research/bcf012-upstream-staleness.md` — 1437-commit window scan,
  per-commit table, issue/PR landscape

Ops/evidence:

- ops 7aca4d1 — USR1 probe, repark-to-floor verdict (2026-11-16 09:59)
- ops f3814c9 — 11-14 power outage; pool survived unclean power-off
- docs cece408 / fb00350 — bcf012 actualization; synthesis (sticky floor,
  upstream invariant)
- kit 065 — sysfs /dev/null stub receipt; kit 066 — ring snapshot with the
  btree arithmetic; ring: `/var/run/bcachefs-fuse/0ec475a1-*/accounting.json`
- tasks/bcf012-background-threads-audit.md — the card this map closes;
  consumes → bcf021 (landscape verdict), bcf025 (drainage GO/NO-GO → NO-GO
  as drain), bcf030 (alert signature), bcf014 (upstream arm, option c)

SEE ALSO

- docs/notes/19a-dogfood-engine.md — Ф3-LIVE era in which the 144M ENOSPC
  tail formed and drained to the floor
- docs/notes/17a-frame-zero.md — stop-stack and read-only discipline the
  probe operated under
