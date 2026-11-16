---
id: "bcf012"
title: "Background threads audit tail: reconcile park conditions"
status: completed
priority: high
effort: medium
dependencies: []
tags: [port]
created_at: 2026-11-13
completed_at: 2026-11-17
context: [docs/f3-runbook.org, tools/fs/data/reconcile/plan.rs, tools/fs/data/reconcile/needs_reconcile.rs, tasks/bcf021-pool-health-monitoring.md, tasks/bcf025-cron-usr1-gonogo.md, tasks/bcf030-poolwatch-rwpend-alert.md]
---

# Background threads audit tail: reconcile park conditions

## Objective

The audit is closed: the threads start and run; drainage confirmed live (SIGUSR1 → rw_pend 144M→18.8M sectors, ~240MB/s). The open remainder — the causes of parks. Drainage automation is split out into bcf025 (a different deliverable type: an owner decision, not code).

## Tasks

- [ ] Park-condition map: enumerate every park/sleep site where reconcile work
      stalls, in docs/notes (condition → file/line → status). Three classes
      known as of 2026-11-16:
      (a) ENOSPC-class move failures — `plan.rs:313-324` (`parks_on`), commit
      path `plan.rs:368` (`DiskReservation` + `NO_ENOSPC`);
      (b) planner parks with typed reason — `plan.rs:72` `ParkReason`
      (`NoStripe{target, redundancy}`, `Replicas(u32)`), `plan.rs:296` `park()`,
      `plan.rs:82` `Plan::Park` — reasons are traced ("Why a key's parked,
      for the trace", plan.rs:70), so the map can be built partly from the
      trace format itself;
      (c) io-clock sleep freeze — reconcile thread parks in
      `Copygc::sleep` via `io_clock::wait_until` (live backtrace in the ring,
      see Findings) and holds the whole work loop while the io clock
      doesn't advance.
- [ ] Remove at least one park with a patch OR document it as an invariant.

## Acceptance Criteria

- [x] A park-condition map in docs/notes (condition → file/line → status).
  DONE 2026-11-17: docs/notes/20a-reconcile-park-map.md — TL;DR verdict,
  condition table (class → code → status → confirmation), evidence chronology
  (11-06 → 11-17), tail arithmetic + USR1 probe, fix options. Assembled by a
  researcher child from docs/notes/research/bcf012/bcf012-* (5 research runs) + orchestrator
  corrections.
- [x] One park removed with a patch or documented as an invariant.
  DOCUMENTED AS INVARIANT 2026-11-17: the sticky tail (entire btree, 12.47M
  sectors) parks by configuration invariant — metadata_replicas=2 on a
  2-device pool with metadata_target=none (fallback → foreground nvme; the
  hdd replica is off-target forever; improves_placement=false). Watermark
  trigger class falsified live (USR1 probe, ops 7aca4d1: tgt-limbo 1:1 into
  pend, zero drained). Upstream carries the same invariant (no freed-space
  event in C; 1437 commits didn't touch the mechanics). Config fix B
  (metadata_target = nvme+hdd group) approved by owner 2026-11-16;
  application = ops act at the next planned bounce (feasibility/command
  plan in docs/notes/research/bcf012/bcf012-fix-b-command-plan.md, child in flight).

## Findings (actualization 2026-11-16)

1. Code anchors moved/evolved since 2026-11-13: `update_reconcile_opts` lives
   in `needs_reconcile.rs` (called from `check.rs:215,372`, `scan.rs:264`);
   parking got a typed, traced reason enum upstream (`plan.rs:72`). The card's
   original "needs_reconcile.rs updatereconcileopts, plan.rs parks_on" is
   confirmed current.
2. CORRECTED 2026-11-16 (skeptic audit + orchestrator spot-check): the earlier
   "backlog regrows 0 -> 12.2M" claim here was a MEASUREMENT ARTIFACT — the
   zero-pend samples of 2026-11-14 12:17-15:06 belong to four freshly created
   TEST filesystems (uuids 48b5471a/5bab6da4/daa79144/a955a331, 671 samples),
   not the pool; and siginfo "rw_pend=0/12206080" is used/total. Pool truth:
   9017 ring samples, pend min 10,843,648 / max 12,459,520 — a STICKY floor
   since 2026-11-07 (the undrained tail of the 144M drain), conserved across
   remounts (pending bits live in the btree; journaled scan cookie). Slow
   creep +1.4M over 9d = dev1 leaving-limbo drip (H2), not load-driven bulk.
3. The "17.2G io-clock WRITE wait" freeze from the Source facts is visible
   live: reconcile_status = waiting, io wait duration 17.2G / remaining
   10.8G, duration waited 8h, backtrace = Copygc::sleep → io_clock::wait_until
   (reconcile::work::wait). Mechanism (Explore): wait() deadline =
   capacity>>6 WRITE sectors of the smaller RW disk (live: 17.2G on the
   1.1T nvme ≈ capacity/64; a 4 TB disk would be ≈ 60 GB);
   the WRITE clock ticks only from write paths, so read-heavy stretches
   sleep without limit. This gate is the enabler of zero drain between
   kick windows, not the backlog creator.
4. Upstream reality (C reference + staleness check, 2026-11-16): the wakeup
   event matrix is ported without gaps (full C-vs-Rust table in
   docs/notes/research/bcf012/bcf012-upstream-gap.md) — and C ITSELF has NO freed-space
   event: pending scan is requested only on topology/config/opt changes,
   recovery boundaries, sysfs, power. Kent's own comment plan.rs:310-315:
   "nothing retries the pending list... the configuration has to change
   first" — an UPSTREAM INVARIANT, not a port defect. Upstream moved 1437
   commits past our base (16 days, Kent's solo Rust-ification sprint) with
   the three bcf012 mechanics byte-for-byte unchanged. Research evidence
   (raw, 5 runs, committed): docs/notes/research/bcf012/ — park-map draft,
   C-reference gap table, hypotheses + falsifiers, upstream staleness,
   trace classification. Falsified-in-flight theories recorded there, incl.
   the nvme-dur-0 under-replication theory (killed by show-super: both
   devices Durability=1) and the 0→12.2M regrowth claim (test-uuid artifact).
5. Monitoring cluster wiring (2026-11-14, commits 78fc141/8e3cd7f): this task
   feeds bcf021 (landscape verdict consumes the park map), bcf030 (stopgap
   alert), bcf025 (reactive GO/NO-GO). Closing bcf012 likely retires bcf025.
   USR1 PROBE (owner go, 2026-11-16): repark-to-floor verdict — tgt-limbo
   206,848 sectors swept into pend 1:1, zero drained in 6m (ops 7aca4d1).
   Watermark-trigger fix class is dead for the sticky tail; confirmed tail
   condition = target-fallback invariant (map P-A, docs/notes/20a §2).
   Verifier 2026-11-17: AC1 verified (line-precision spot-checks: plan.rs
   316-325/368/72-82-296, inode_opts.rs:214 exact); AC2 verified after this
   commit's pointer fixes.

## Source

F0 verdict + journal 2026-11-07 (066/067); the audit chronicle remains in
docs/f3-runbook.org; live ring evidence 2026-11-16.
