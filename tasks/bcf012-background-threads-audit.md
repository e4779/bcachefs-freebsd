---
id: "bcf012"
title: "Background threads audit tail: reconcile park conditions"
status: pending
priority: high
effort: medium
dependencies: []
tags: [port]
created_at: 2026-11-13
---

# Background threads audit tail: park conditions

## Objective

The audit is closed: the threads start and run; drainage confirmed live (SIGUSR1 → rw_pend 144M→18.8M sectors, ~240MB/s). The open remainder — the causes of parks. Drainage automation is split out into bcf025 (a different deliverable type: an owner decision, not code).

## Tasks

- [ ] Park conditions: map them (`needs_reconcile.rs` update_reconcile_opts, `plan.rs` parks_on) — where and why parking happens.
- [ ] Remove at least one park with a patch OR document it as an invariant.

Facts to start from: a park on ENOSPC with a full HDD target (Linux-era entries); "freezing" of counters = a 17.2GB io-clock[WRITE] wait between passes.

## Acceptance Criteria

- [ ] A park-condition map in docs/notes (condition → file/line → status).
- [ ] One park removed with a patch or documented as an invariant.

## Source

F0 verdict + journal 2026-11-07 (066/067); the audit chronicle remains in docs/f3-runbook.org.
