---
id: "bcf028"
title: "Live-mine defusal: guarded fusefs rebuild + install + transit-probe"
status: completed
priority: critical
effort: medium
type: chore
dependencies: ["bcf013"]
tags: ["ops", "kernel", "hotfix"]
context: [overlay/patches/kernel/, docs/notes/council-memo-bcf013-kernel-2026-11-14.md, docs/f3-runbook.org]
created_at: 2026-11-14
completed_at: 2026-11-14
---

# Live-mine defusal: guarded fusefs rebuild + install + transit-probe

## Objective

Defuse the live mine in `/boot/kernel/fusefs.ko`: an unguarded `fuse_ipc-deadline-cap` sits on disk, and the poolfuse rc passes `-o timeout=0` (default `poolfuse_timeout_s=0`, "Linux semantics" owner decision 12:5x Nov 6). If the kernel sees `daemon_timeout=0`, the unguarded cap yields instant `ETIMEDOUT` on every operation — the NEXT reboot/kldload arms an `ETIMEDOUT` storm = pool outage. Current prod survives only because the IN-MEMORY module predates the rebuild and cannot be unloaded (`EBUSY`, 107k vnodes) — council-maintainer H1. Full analysis: `docs/notes/council-memo-bcf013-kernel-2026-11-14.md` (Live-mine escalation section).

KEY UNCERTAINTY to resolve first (transit discriminator — safe to run on a TEST image with the CURRENT running module): does `timeout=0` even reach kernel `daemon_timeout`? Test protocol: mount on a test image with `timeout=0`, park the daemon (mockfs silent pattern or a real slow FS), wait 90 s —

- NO `ETIMEDOUT` → kernel has `0` (transit works; MINE ARMED: the on-disk cap module will storm).
- `ETIMEDOUT` at ~60 s → transit broken (demux loses the option; kernel on default 60 → the on-disk cap is harmless at 60, mine disarmed).

Record the verdict with a dtrace receipt (`sdt:fusefs:::ipc-trace arg0==3` fires only with the cap) in the runbook ops-commit.

## Findings 2026-11-14 (transit discriminator executed)

- [x] Transit discriminator executed 2026-11-14: kernel daemon_timeout
      = DEFAULT 60s (timeout=0 lost in demux; ETIMEDOUT observed at
      T+60s with stopped daemon; runbook erratum appended). THE MINE
      IS DISARMED — the on-disk unguarded cap is a no-op at 60s on
      no-intr mounts. The guarded rebuild is no longer safety-
      critical: reduced to upstream-parity only (the daemon_timeout!=0
      guard ships in bcf005 PR content).

## Tasks (updated by findings — most are obsolete)

- [x] Transit discriminator on a TEST image (never the pool), verdict
      recorded — done 2026-11-14, see Findings above.
- [ ] ~~Apply the daemon_timeout≠0 guard to the working-tree source;
      rebuild; install~~ — OBSOLETE for safety (mine disarmed), the
      guard ships only upstream via bcf005 PR content.
- [ ] Runbook erratum — done (appended to docs/f3-runbook.org).

## Acceptance Criteria

- [x] Transit verdict recorded with receipts (ETIMEDOUT at T+60s
      with a SIGSTOPped daemon on a test image; runbook erratum).
- [x] Reboot-safety resolved by evidence: the on-disk unguarded cap
      is a no-op at kernel default 60s on no-intr mounts — no storm
      possible. (Original AC assumed transit works; it does not.)
- [x] Runbook ops-commit exists.

## Source

Council memo `docs/notes/council-memo-bcf013-kernel-2026-11-14.md` (Live-mine escalation); owner decision 2026-11-14 (create + execute; install gated on explicit approval).
