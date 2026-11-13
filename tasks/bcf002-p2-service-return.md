---
id: "bcf002"
title: "P2: return of deferred services after the stabilization package (qbt, amuled svcj)"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001", "bcf024"]
tags: [ops, soak]
created_at: 2026-11-13
---

# P2: return of deferred services after the stabilization package (qbt, amuled svcj)

## Objective

After P1a (bcf001) + P3b (bcf024) land, return to prod what was removed for the sake of stabilization. Hard fact: a qbt restart = 3/3 livelock — the "retry fix will help" premise is unproven until bcf001 lands. f3-heal is deployed and validated (fact, details in the git journal) — the open part of the task is only the service return and the sunset.

## Tasks

- [ ] qbt back into the boot chain with staggered fastresume (bcf024).
- [ ] amuled back under svcj (absorbed from bcf006; autostart).
- [ ] f3-heal sunset criterion: formulate and write it down.

## Acceptance Criteria

- [ ] qbt 48h: zero wedges, poolwatch perr=0.
- [ ] amuled runs jailed (svcj), survives a reboot.
- [ ] f3-heal sunset recorded (proposal: 2 weeks without incidents → remove or keep — owner's call).

## Source

Runbook council 2026-11-06; bcf006 (absorbed, cancelled).
