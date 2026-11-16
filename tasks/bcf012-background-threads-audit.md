---
id: "bcf012"
title: "Background threads audit tail: reconcile park conditions"
status: pending
priority: high
effort: medium
dependencies: []
tags: [port]
created_at: 2026-11-13
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

- [ ] A park-condition map in docs/notes (condition → file/line → status).
- [ ] One park removed with a patch or documented as an invariant.

## Findings (actualization 2026-11-16)

1. Code anchors moved/evolved since 2026-11-13: `update_reconcile_opts` lives
   in `needs_reconcile.rs` (called from `check.rs:215,372`, `scan.rs:264`);
   parking got a typed, traced reason enum upstream (`plan.rs:72`). The card's
   original "needs_reconcile.rs updatereconcileopts, plan.rs parks_on" is
   confirmed current.
2. LIVE prod evidence (ring, daemon 3325, 2026-11-16 ~08:30): the backlog
   regrows under load — rw_pend = 12,262,912 sectors (~5.9 GB) and tgt
   = 205,312, vs ZERO on the fresh daemon 2026-11-14. Regrowth over ~2 days
   of normal load; the bcf030 alert threshold (10M sectors) is effectively
   breached right now — that stopgap earned its keep.
3. The "17.2G io-clock WRITE wait" freeze from the Source facts is visible
   live: reconcile_status = waiting, io wait duration 17.2G / remaining
   10.8G, duration waited 8h, backtrace = Copygc::sleep → io_clock::wait_until
   (reconcile::work::wait). Class (c) above is not historical — it holds the
   thread right now.
4. Monitoring cluster wiring (2026-11-14, commits 78fc141/8e3cd7f): this task
   feeds bcf021 (landscape verdict consumes the park map), bcf030 (stopgap
   alert), bcf025 (reactive GO/NO-GO). Closing bcf012 likely retires bcf025.

## Source

F0 verdict + journal 2026-11-07 (066/067); the audit chronicle remains in
docs/f3-runbook.org; live ring evidence 2026-11-16.
