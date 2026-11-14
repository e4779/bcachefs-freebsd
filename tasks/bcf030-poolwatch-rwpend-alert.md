---
id: "bcf030"
title: "poolwatchd: rw_pend threshold alert (drain-relevance trigger for bcf025)"
status: pending
priority: medium
effort: small
dependencies: []
tags: ["ops", "monitoring"]
created_at: 2026-11-14
type: improvement
---

# poolwatchd: rw_pend threshold alert

## Objective

poolwatchd gains a rw_pend threshold alert — the trigger that makes
the bcf025 GO/NO-GO decision relevant. Until pending actually grows,
drain automation is churn on an empty queue (live data 2026-11-14:
rw_pend=0 on the fresh daemon; the old daemon accumulated 144M over
3 days under heavy torrent IO — growth happens under load, so the
trigger is a threshold, not a calendar).

## Tasks

- [ ] poolwatch.sh: periodic `kill -INFO` to the fuse daemon (find
      via `pgrep -f '/mnt/pool'`) + parse `rw_pend=<used>/<total>`
      from `/var/run/bcachefs-fuse/*/siginfo-latest.txt`.
- [ ] Threshold var `POOLWATCH_RWPEND_ALERT` (default 10000000
      sectors); alert via the existing `!!EV` mechanism
      (`!!EV RWPEND_HIGH used=<N>`) + syslog line; one alert per
      breach (re-arm when it drops back below).
- [ ] Deploy: poolwatchd restart (safe, monitoring-only).

## Acceptance Criteria

- [ ] Fake-high siginfo → alert fires (testable without prod risk).
- [ ] Live prod check: rw_pend=0 → no alert, poolwatchd loop healthy.
- [ ] Threshold documented in the runbook (next to the drain recipes).

## Source

Owner decision 2026-11-14 (bcf025 deferred until this trigger is
live; NO-GO-now recommendation based on rw_pend=0 live data). The
fuse daemon pid discovery: `pgrep -f '/mnt/pool'`; SIGINFO write
target: `/var/run/bcachefs-fuse/<uuid>/siginfo-latest.txt`
(format verified live: `rw_pend=0/12206080`).
