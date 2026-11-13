---
id: "bcf025"
title: "cron-USR1: pending-scan drainage automation — owner GO/NO-GO"
status: pending
priority: medium
effort: small
dependencies: []
tags: [ops, decision]
created_at: 2026-11-13
---

# cron-USR1: drainage automation — owner GO/NO-GO

## Objective

SIGUSR1 drainage is confirmed live (bcf012: 144M→18.8M sectors, ~240MB/s); currently manual `kill -USR1 <pid>` only. The decision: whether to put a periodic pending-scan on cron. This is an owner decision (the prod machine's risk profile), not code.

## Tasks

- [ ] The directives for the decision: the period (a day? hours?), a storm guard (one scan at a time), the svcj-safety of the invocation, what gets logged.
- [ ] GO: a cron line + a runbook entry (an ops commit).
- [ ] NO-GO: a runbook entry with the reason — the question is closed, do not revive without a new incident.

## Acceptance Criteria

- [ ] The runbook records the GO verdict (with the cron line) or NO-GO (with the reason).
- [ ] On GO: the first fired scan visible in the daemon log.

## Source

Split out of bcf012 (2026-11-13, the task-set review: a different deliverable type).
