---
id: "bcf027"
title: "amuled: return under svcj"
status: pending
priority: medium
effort: small
dependencies: ["bcf006"]
tags: [ops, svcj]
created_at: 2026-11-14
---

# amuled: return under svcj

## Objective

Bring amuled back under svcj (it was stopped preemptively during the
amuled-chaos wave — the only real fatality was boot against an empty
pool mount, not svcj itself). Independent of the qbt track: no
bcf001 gate, own gate = clean state + manual verification.

## Tasks

- [ ] Manual svcj sanity check on a clean state (from bcf006 body).
- [ ] `amuled_svcj=YES` + autostart enabled.
- [ ] Survive a reboot.
- [ ] onestop → onestart cycle leaves no stale jail (known svcj
      jail-leak on out-of-band kill — f3-heal v2.0 hit "jail N
      already exists"; runbook).

## Acceptance Criteria

- [ ] amuled runs jailed (svcj) and survives a reboot.
- [ ] onestop → onestart cycle cleans up the jail cell (no "already
      exists" on restart).

## Source

Split from bcf002 per task-writer review 2026-11-14 (C1: different
gates and fail modes). Tombstone: bcf006 (absorbed predecessor,
cancelled 2026-11-13).
