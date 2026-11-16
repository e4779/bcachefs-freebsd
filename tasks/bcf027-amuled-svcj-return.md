---
id: "bcf027"
title: "amuled: return under svcj"
status: completed
priority: medium
effort: small
dependencies: ["bcf006"]
tags: [ops, svcj]
created_at: 2026-11-14
completed_at: 2026-11-16
---

# amuled: return under svcj

## Objective

Bring amuled back under svcj (it was stopped preemptively during the
amuled-chaos wave — the only real fatality was boot against an empty
pool mount, not svcj itself). Independent of the qbt track: no
bcf001 gate, own gate = clean state + manual verification.

## Tasks

- [x] Manual svcj sanity check on a clean state (from bcf006 body).
- [x] `amuled_svcj=YES` + autostart enabled.
  DONE 2026-11-16 (BrightTiger, homelab session; receipts below): rc.conf:44-45
  `amuled_svcj=YES` + `net_basic`; cell live, daemon pid 30095 under `_p2p`
  inside, listeners EC 4712 + 4662/4665/4672 from the cell, EC client connect
  OK (127.0.0.1:4712 <- node).
- [ ] Survive a reboot.
  DEFERRED by owner's no-reboots rule (2026-11-16): test at the next planned
  reboot window — bundle with bcf005's pending kyua-after-reboot step.
- [x] onestop → onestart cycle leaves no stale jail (known svcj
      jail-leak on out-of-band kill — f3-heal v2.0 hit "jail N
      already exists"; runbook).
  DONE 2026-11-16: onestop dismantled the cell (jls empty), onestart built
  the new one (JID 13 → JID 14), zero "already exists"; the rc.d:51
  `jail -r svcj-amuled` guard stayed unneeded this cycle. Ops journal entry
  in homelab repo carries Refs: bcf027 (BrightTiger).

## Acceptance Criteria

- [x] amuled runs jailed (svcj) and survives a reboot.
  VERIFIED jailed 2026-11-16 (live receipts above); the reboot half is
  DEFERRED to the next planned reboot window (see Tasks) — closure does not
  wait for it.
- [x] onestop → onestart cycle cleans up the jail cell (no "already
      exists" on restart).

## Source

Split from bcf002 per task-writer review 2026-11-14 (C1: different
gates and fail modes). Tombstone: bcf006 (absorbed predecessor,
cancelled 2026-11-13).
