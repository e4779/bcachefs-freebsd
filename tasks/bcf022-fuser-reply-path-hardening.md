---
id: "bcf022"
title: "P1b: fuser reply-path hardening — destroy-before-reply, writev retry, watchdog"
status: pending
priority: high
effort: large
dependencies: ["bcf001"]
tags: [port, wedge, fuser]
created_at: 2026-11-13
---

# P1b: fuser reply-path hardening — destroy-before-reply, writev retry, watchdog

## Objective

The reply-path survives client death and a slow disk. Three mechanics in one package: destroy-before-reply (fuser#757; the destroy-before-reply branch is already in the koverstreet fork — carry it over), writev bounded retry (5×10ms on EAGAIN/EWOULDBLOCK/EINTR/ENOMEM), reply-registry + watchdog + reader-heartbeat. Verify the escape codes against fuse_io.c.

## Tasks

- [ ] Check: destroy-before-reply may ALREADY be in vendored (Cargo pins @8819589) — do not port what is already there.
- [ ] Carry destroy-before-reply over from the fork branch, verify against fuser#757.
- [ ] writev bounded retry in channel.rs.
- [ ] Reply-registry/watchdog/reader-heartbeat in session.rs.
- [ ] Test: an artificial client death under load; umount -f under load.

Material: fuser-vendored/{channel.rs,session.rs}; core 69055 (readers stuck forever in read(2) after Destroy — 070 cures only umount -f, this is the general case).

## Acceptance Criteria

- [ ] umount -f under load: zero hung readers (procstat).
- [ ] Client death: the reply-path frees up ≤1s.
- [ ] The sync disk IO of one request does not block the replies of others.

## Source

Runbook Shape-1 (close-storm → reply-path failure → an abandoned mutex); fuser#757; core 69055.
