---
id: "bcf002"
title: "P2: qbt return with staggered fastresume (+ f3-heal sunset)"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001", "bcf024"]
tags: [ops, soak]
created_at: 2026-11-13
---

# P2: qbt return with staggered fastresume (+ f3-heal sunset)

## Objective

After P1a (bcf001) + P3b (bcf024) land, bring qbt back to prod. Hard
fact: a qbt restart = 3/3 livelock — the "retry fix will help"
premise is unproven until bcf001 lands. amuled svcj return is a
SEPARATE deliverable now: tasks/bcf027-amuled-svcj-return.md (split
by task-writer review 2026-11-14 — different gates, different fail
modes; tombstone bcf006 feeds bcf027).

## Tasks

- [ ] qbt back into the boot chain with staggered fastresume
      (bcf024 mechanics).
- [ ] f3-heal sunset criterion: formulate and write it down.

## Acceptance Criteria

- [ ] qbt 48h: zero wedges, poolwatch perr=0.
- [ ] f3-heal sunset recorded (proposal: 2 weeks without incidents →
      remove or keep — owner's call).

## Source

Runbook council 2026-11-06; split per task-writer review 2026-11-14
(C1: different gates and fail modes; amuled = bcf027).
