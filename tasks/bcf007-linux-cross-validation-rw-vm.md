---
id: "bcf007"
title: "Linux cross-validation of the port's rw writes (VM)"
status: cancelled
priority: low
effort: medium
type: chore
tags: [vm]
created_at: 2026-11-13
context: [docs/f3-runbook.org, bench]
cancelled_at: 2026-11-13
---

# Linux cross-validation of the port's rw writes (VM)

CANCELLED 2026-11-13 (owner's decision): as a standalone task — a zombie. The substance moved into bcf013 (the gate before the upstream PR): parity evidence on reviewer demand — probe file /mnt/pool/.f3-probe/f001-200mb.bin, verify sha256 599b9472… against the Linux side (appliance or a Linux machine), fsck from the Linux side. Cheap to revive within bcf013 if upstream asks.

## Acceptance Criteria

- [ ] Linux-side fsck (VM) on the image after an rw run — clean.
- [ ] The image sha256 599b9472… matches on both sides (ported writes = byte-identical).
- [ ] The result recorded in the runbook.

## Source

docs/f3-runbook.org (the org→taskmd migration journal; history: git log --grep 'Refs: bcf[0-9]+').
