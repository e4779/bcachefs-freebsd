---
id: "bcf029"
title: "events_unbound worker leak: percpu slots not freed on exit"
status: pending
priority: critical
effort: medium
dependencies: []
tags: ["port", "kernel", "hotfix"]
created_at: 2026-11-14
---

# events_unbound worker leak: percpu slots not freed on exit

## Objective

Prod incident 2026-11-14 (12:42:51, SIGABRT, core 77GB, pool down ~6min, restored by f3-heal deep-bounce): the daemon aborted at `percpu.c:301` "too many live threads (max 256)". The lldb thread table (committed evidence) shows 266 live threads, 157 of them `events_unbound/` workqueue workers (normal: single digits).

Root cause: the port's workqueue implementation spawns `events_unbound` workers on per-work contention, but they never exit / never free their percpu slots — `bch_percpu_nr_cpus` creeps toward `BCH_PERCPU_MAX_CPUS=256` over days of respawns; then any new kthread spawn aborts the daemon (the stderr table from percpu.c:301 was lost with the process). The core at the repo root (77GB) is post-mortem gold.

Goal: fix the worker lifecycle so percpu slots are freed on worker exit, and/or bound the unbound-worker pool so the counter can never reach the cap.

## Tasks

- [ ] Locate the workqueue/kthread worker-exit path in the port (`tools/linux/workqueue.c` or equivalent under `tools/csrc/`; `tools/fuser-vendored` is irrelevant): where `events_unbound` workers terminate, and where `bch_percpu_thread_exit` / slot-free should be called.
- [ ] Pinpoint why slot-free is not called on worker exit (missing call, wrong exit ordering, or workers that never exit at all). Record file:line.
- [ ] Apply the fix: free the percpu slot on worker exit and/or bound the unbound-worker pool (cap + reuse) so `bch_percpu_nr_cpus` cannot creep to 256.
- [ ] Audit the sibling worker classes seen live in the dump for the same leak: `events_highpri` (23 live) and `wb_flush` (17); fix if affected.
- [ ] Add a regression guard: percpu slot-counter assert or max-bounds warn near `BCH_PERCPU_MAX_CPUS`, so a recurrence is loud before it aborts the daemon.
- [ ] Verify: spawn/exit cycle of a worker returns its slot (test or instrumented run — slot counter before == after).

## Acceptance Criteria

- [ ] Root cause identified with file:line in the port's worker-exit path, explaining concretely why `bch_percpu_thread_exit`/slot-free was never reached for `events_unbound` workers (a stranger lands the fix PR without re-doing the investigation).
- [ ] After the fix, a spawn/exit cycle demonstrably returns the slot: instrumented run or test shows `bch_percpu_nr_cpus` back to its pre-spawn value (it FAILS if the leak persists).
- [ ] Respawn bound: repeated worker churn cannot drive the slot counter to `BCH_PERCPU_MAX_CPUS=256` — guarded by assert or max-bounds warn that fires before the fatal `percpu.c:301` abort.
- [ ] `events_highpri` and `wb_flush` audited with the same lens: either patched or explicitly cleared as non-leaking, with the verdict recorded.

## Source

Incident 2026-11-14 (ops commit `843a068`; evidence dir `docs/evidence/percpu-slot-exhaustion-20261114/`, incl. `lldb-thread-table.txt`; 77GB core at repo root). Crash context: `council-memo-bcf013-kernel-2026-11-14.md`.
