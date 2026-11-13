---
id: "bcf003"
title: "P3a: named-mutex fix — spinlock_types.h → pthread_spin"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001"]
tags: [port]
created_at: 2026-11-13
---

# P3a: named-mutex fix — spinlock_types.h → pthread_spin

## Objective

Spin semantics per the P0 verdict: static spinlock init on FreeBSD = no-op (NULL handle → a silent EINVAL lock; core class 83736). The named mutex must spin honestly: spinlock_types.h → pthread_spin. Invariant: no sleeping under a spinlock.

## Tasks

- [ ] overlay/files/include/linux/spinlock_types.h: pthread_spin handles, real initialization.
- [ ] rg audit: zero sleep-like calls under spinlock sections.
- [ ] apply.sh from a clean clone — reproducibility.

## Acceptance Criteria

- [ ] apply.sh is idempotent from a clean clone.
- [ ] rg audit of sleep-under-spinlock: zero hits.
- [ ] The bcf001 acid test is green with the patch in the stack.

## Source

P0 verdict (runbook); core class 83736; 069 comment spinlock_types.h.
