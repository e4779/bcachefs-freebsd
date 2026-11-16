---
id: "bcf037"
title: "Tiering drain: full background_target=hdd pass after the RAM-upgrade reboot"
status: pending
priority: medium
effort: medium
dependencies: []
tags: ["ops", "soak"]
created_at: 2026-11-16
---

# Tiering drain: full background_target=hdd pass after the RAM-upgrade reboot

## Objective

fix-B for bcf012 (ops eb79db9: metadata_target=pool + labels pool.nvme/pool.hdd
in the superblock) killed the btree tail, but the post-change WINCH re-triage
marked ALL user data as tiering-pending: ring pend[0] = 5,732,213,368 sectors
(~2.9 TB) — the background_target=hdd job that never ran on the FUSE port
(pending scans never ran before bcf012). The pass sits static behind the
io-clock gate (deadline = capacity>>6 WRITE sectors of the smaller RW disk;
reads don't tick). The owner approved one full drain pass (option Б, decision
2026-11-17), to start after the planned shutdown + RAM upgrade + reboot.
Proven pace ~240 MB/s → 2.9 TB ≈ 3.5–4 h of HDD-heavy IO.

Preconditions — a post-reboot sanity gate checked BEFORE any kick: pool mounts
via the boot chain (poolfuse); canary /mnt/pool/.f3-probe/f001-200mb.bin
sha256 matches the runbook value (599b9472…); ring gen ticks; f3heal +
poolwatchd up post-boot.

## Tasks

- [ ] Post-reboot sanity gate: pool mounted via boot chain (poolfuse), canary
      sha256 matches runbook value, f3heal + poolwatchd PIDs present, ring gen
      ticking across ≥2 samples.
- [ ] Open the drain window: `doas kill -USR1 <daemon pid>`; confirm pend[0]
      starts declining in the first ring samples after the kick.
- [ ] Monitor the pass to completion: expect ~240 MB/s. If the io-clock gate
      re-closes mid-drain (pend[0] stalled >15 min), re-kick USR1 — bounded at
      ≤6 kicks total; beyond that, stop and report the stall with ring evidence.
- [ ] Post-drain verification: dd_dev1 (hdd) used-sectors growth matches moved
      sectors; pend[0] < 100M (residual H2 limbo drip ~512 sectors/47 s is
      acceptable).

## Acceptance Criteria

- [ ] Post-reboot: pool mounted, canary sha256 599b9472… matches — zero data
      loss across shutdown + RAM upgrade + boot.
- [ ] Drain complete: pend[0] < 100M sectors, zero poolwatch wedge incidents
      during the window, zero daemon restarts (f3heal silent except its own
      logs).
- [ ] Tiering actually in effect: dd_dev1 (hdd) used-sectors growth over the
      window ≈ moved sectors — cold data physically on hdd (background_target
      works on the port, first time).

## Bundle note (same boot)

This reboot also closes the DEFERRED reboot AC of bcf027 (amuled survives
reboot — check jail svcj-amuled after boot) and opens the kyua window of
bcf005 — verify both in the same boot before closing anything else.

## Source

Owner decision 2026-11-17 (option Б after the RAM upgrade); ops eb79db9
(fix-B application); ops 7aca4d1 (USR1 probe, park floor);
docs/notes/20a-reconcile-park-map.md; tasks/bcf012-background-threads-audit.md
(completed — this card is its ops tail).
