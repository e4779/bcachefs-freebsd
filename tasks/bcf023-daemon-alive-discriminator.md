---
id: "bcf023"
title: "P1c: daemon-alive discriminator at wedge — evidence gate for the bug report"
status: completed
priority: high
effort: small
dependencies: []
tags: [evidence, wedge]
created_at: 2026-11-13
completed_at: 2026-11-14
---

# P1c: daemon-alive discriminator at wedge

## Objective

One run at the next live wedge splits the guilty in two: the daemon serves → the kernel (redirty-no-redrive, the material in bcf015); the daemon does not serve → our reply-path (bcf022). Without this run bcf015 is hand-waving; upstream will not accept it.

## Tasks

- [ ] At a wedge: procstat -k of the daemon BEFORE any reset (the recipe: scripts/wedge-catcher.sh — kill -5→core→lldb).
- [ ] kill -INFO the daemon + a ring snapshot (/var/run/bcachefs-fuse/).
- [ ] The daemon-alive probe: a local request through the mount + a webui response.
- [ ] The verdict — as an ops commit into the runbook (Refs: bcf023).

## Acceptance Criteria

- [ ] The "daemon serves / daemon does not serve" verdict recorded with command output (not an opinion).
- [ ] bcf015 unblocked or closed as unconfirmed.

## Source

Split from bcf001 restructuring 2026-11-13; core 69055 as the evidence exemplar.
