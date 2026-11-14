---
id: "bcf021"
title: "Pool health monitoring: utility landscape and what to port"
status: pending
priority: medium
effort: large
dependencies: ["bcf012"]
tags: ["telemetry", "research"]
created_at: 2026-11-13
---

# Pool health monitoring: utility landscape and what to port

## Objective

An open-ended "think it over" task: how to monitor bcachefs pool health PROPERLY in
our setup. Not code — an inventory and a verdict.

Related: bcf030 (rw_pend threshold alert in poolwatch.sh — the immediate
stopgap; this landscape's verdict decides its fate: keep as the poolwatch
stopgap or fold into the chosen monitor). Related: bcf004 (P4 telemetry —
the A+ snapshot ring is a data source any monitor would read).
GATE NOTE (owner evidence-gating pattern): the landscape VERDICT consumes
bcf012's park-conditions map as a core input — a monitor verdict that
ignores the known park symptom is incomplete; hence the dependency.

Context: hmlb-007 (homelab) cancelled — legacy-hlmon (a Rust dashboard of the Debian
era, the sources on the thinkpad, described in homelab `docs/debian/23-hlmon.md`)
was written against Linux sysfs (`/sys/fs/bcachefs/`: reconcile_blocked,
copygc_waiting_for_bytes, reconcile_target_pending_bytes), which does not exist on
the FreeBSD host-FUSE line, and since 2026-11-10 the pool's prod plane is exactly
host-FUSE. Generic dashboards (netdata/beszel/node_exporter) do not parse bcachefs
sysfs — that was hlmon's motivation.

## Tasks

- [ ] Inventory: what is observable on each plane — host-FUSE (the fuser fork,
      kit 066 reconcile-visibility, f3-heal v2.1 ring-staleness), VM-appliance
      (the Alpine guest: Linux sysfs exists when the pool is mounted), generic
      FreeBSD (gstat/iostat — what they give, what they don't)
- [ ] The hlmon legacy teardown: which metrics were valuable, what is portable to
      the fuser fork (the reconcile_blocked/copygc_waiting equivalents in
      daemon-side counters), what to discard together with the docker/bollard part
- [ ] The utility landscape: what exists in the bcachefs-tools (Linux) ecosystem
      for health/fsck statuses and which of it makes sense to port or
      reimplement on top of fuser
- [ ] Thresholds and alerts: the existing f3-heal triggers (ring staleness) —
      is the frame extensible, what is missing (drift, perr, wedge precursors)
- [ ] The verdict: a minimally sufficient monitor for prod (host-FUSE) + a port
      list with effort estimates; a separate decision — whether anything is
      needed inside the appliance in case of its return

## Acceptance Criteria

- [ ] A verdict document in docs/ (or a pi-topic): the metrics per plane, the
      chosen minimal monitor, a port list with effort estimates
- [ ] Every claim of "utility X does Y" verified (man/sources), not taken
      from memory
- [ ] The decision recorded (a council if contested); nothing changes in the
      code — the implementation will be separate tasks

## Source

Owner decision 2026-11-13 (splitting the monitoring landscape into a separate track; the heir of the cancelled hmlb-007/hlmon).
