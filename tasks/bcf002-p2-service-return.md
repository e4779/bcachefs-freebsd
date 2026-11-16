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

- [ ] Acid test qbt init: 3 consecutive runs without a wedge.
      MOVED here from bcf001 (owner, variant A 2026-11-16): bcf001 (MT-8) removed the
      reply-path narrowness, but the bcf023 discriminator proved the residual qbt-init
      wedge is the kernel class (bug 300785) — a clean 3-run series is provable only
      in this task's return window, on the prod pool with staggered fastresume active.

- [ ] qbt 48h: zero wedges, poolwatch perr=0.
- [ ] f3-heal sunset recorded (proposal: 2 weeks without incidents →
      remove or keep — owner's call).

## Source

Runbook council 2026-11-06; split per task-writer review 2026-11-14
(C1: different gates and fail modes; amuled = bcf027). AC1 (3x acid
test) moved from bcf001 per owner decision 2026-11-16 (variant A).
Context: bcf001 findings — MT necessary, not sufficient for qbt-init;
close-storm class rides on kernel fixes (bcf005 fail-fast locally,
bug 300785 upstream) + this task's staggered return.
