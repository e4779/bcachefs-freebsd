---
id: "bcf004"
title: "P4-F3: C-lite restricted ioctl — spec + implementation"
status: pending
priority: medium
effort: large
dependencies: []
tags: [port, telemetry]
created_at: 2026-11-13
---

# P4-F3: C-lite restricted ioctl — spec + implementation

## Objective

The only executable piece of the plan-of-record: F3 C-lite (restricted, fixed sizes only). The plan-of-record (F0 closed, F1 delivered, F2/F4 trigger-gated, invariants, cut-list, falsifiers) has moved to `docs/notes/p4-plan-of-record.md` — read it before working, it sets the boundaries.

## Tasks

- [ ] C-lite spec: restricted-only FUSE_IOCTL, fixed sizes (NOT flex-array — COUNTERFACT: `_IOC_SIZE(QUERY_ACCOUNTING)` carries only the header, tiered metrics ride flex-array ⇒ C-full growth 3-5x).
- [ ] C+Rust implementation per the spec.
- [ ] The CLI reads counters from the live daemon.

## Acceptance Criteria

- [ ] The spec is reviewed by the owner before implementation.
- [ ] The CLI reads counters from the live prod daemon.
- [ ] rg audit: zero mutating ioctls (DATA/FSCK_ONLINE/DISK_*).

## Source

Council 2026-11-06; the memo moved to docs/notes/p4-plan-of-record.md (2026-11-13).
