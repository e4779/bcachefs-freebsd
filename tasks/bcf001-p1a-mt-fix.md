---
id: "bcf001"
title: "P1a: MT wedge fix — 8 fuser threads"
status: pending
priority: high
effort: large
dependencies: []
tags: [port, wedge]
created_at: 2026-11-13
---

# P1a: MT wedge fix — 8 fuser threads

## Objective

The MT build (8 threads) as the base of stabilization package P1: remove the single-threaded narrowness of the reply-path, where the daemon's sync disk IO blocks FUSE replies. Fact: core#2 (MT build, kill -5) showed fuser-0 in preadv on the HDD — sync disk IO inline.

## Tasks

- [ ] Confirm in the fuser-vendored code: the 8-thread gate is lifted, the threads actually start.
- [ ] Enable 8 threads by default in the prod config.
- [ ] Acid test (qbt init) on the test pool.
- [ ] Prod pool under f3-heal for 24h — observation.

Build — ONLY in the orchestrator slot (AGENTS rule).

## Acceptance Criteria

- [ ] Acid test qbt init: 3 consecutive runs without a wedge.
- [ ] Prod 24h: zero wedge incidents in poolwatch.
- [ ] The deadline layer (watchdog/heartbeat) is NOT here — it lives in bcf022 (explicit boundary).

## Source

Runbook 2026-11-06 council (wedge shape model); core#2 stacks.
