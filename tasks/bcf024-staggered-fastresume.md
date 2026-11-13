---
id: "bcf024"
title: "P3b: staggered qbt fastresume — spreading the start against the close-storm"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001"]
tags: [port, ops]
created_at: 2026-11-13
---

# P3b: staggered qbt fastresume

## Objective

A deterministic close-storm: 711 fastresumes at once = a wave of close/release/forget (kit 092614). Spread the torrent starts over time so that the request peak does not coincide.

## Tasks

- [ ] The spread mechanism: a qbt launch wrapper or an ordering of the fastresume files (a ~5-10 min window).
- [ ] A run on the test pool with full fastresume.
- [ ] The tie-in with the qbt return (bcf002): staggered is part of the standard launch.

## Acceptance Criteria

- [ ] A qbt restart with full fastresume — zero wedges.
- [ ] poolwatch perr=0 over the run window.

## Source

Runbook council 2026-11-06 (Shape-1); kit 092614.
