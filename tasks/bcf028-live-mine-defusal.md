---
id: "bcf028"
title: "Live-mine defusal: guarded fusefs rebuild + install + transit-probe"
status: pending
priority: critical
effort: medium
type: chore
dependencies: ["bcf013"]
tags: ["ops", "kernel", "hotfix"]
context: [overlay/patches/kernel/, docs/notes/council-memo-bcf013-kernel-2026-11-14.md, docs/f3-runbook.org]
created_at: 2026-11-14
---

# Live-mine defusal: guarded fusefs rebuild + install + transit-probe

## Objective

Defuse the live mine in `/boot/kernel/fusefs.ko`: an unguarded `fuse_ipc-deadline-cap` sits on disk, and the poolfuse rc passes `-o timeout=0` (default `poolfuse_timeout_s=0`, "Linux semantics" owner decision 12:5x Nov 6). If the kernel sees `daemon_timeout=0`, the unguarded cap yields instant `ETIMEDOUT` on every operation — the NEXT reboot/kldload arms an `ETIMEDOUT` storm = pool outage. Current prod survives only because the IN-MEMORY module predates the rebuild and cannot be unloaded (`EBUSY`, 107k vnodes) — council-maintainer H1. Full analysis: `docs/notes/council-memo-bcf013-kernel-2026-11-14.md` (Live-mine escalation section).

KEY UNCERTAINTY to resolve first (transit discriminator — safe to run on a TEST image with the CURRENT running module): does `timeout=0` even reach kernel `daemon_timeout`? Test protocol: mount on a test image with `timeout=0`, park the daemon (mockfs silent pattern or a real slow FS), wait 90 s —

- NO `ETIMEDOUT` → kernel has `0` (transit works; MINE ARMED: the on-disk cap module will storm).
- `ETIMEDOUT` at ~60 s → transit broken (demux loses the option; kernel on default 60 → the on-disk cap is harmless at 60, mine disarmed).

Record the verdict with a dtrace receipt (`sdt:fusefs:::ipc-trace arg0==3` fires only with the cap) in the runbook ops-commit.

## Tasks

- [ ] Transit discriminator on a TEST image (never the pool), verdict recorded
- [ ] Apply the `daemon_timeout≠0` guard to the working-tree kernel source (same guard goes upstream in bcf005 — one code, two uses)
- [ ] Rebuild `fusefs.ko` in the orchestrator build slot (agents never build)
- [ ] Install to `/boot/kernel` ONLY after the owner's explicit "ставь" (pre-install gate is the owner's; the running module stays until reboot — no live disruption)
- [ ] Post-install: runbook ops-commit (mine defused, reboot safe, transit verdict documented)

## Acceptance Criteria

- Transit verdict recorded with receipts (mount/dtrace output) — H2 (kernel sees 0) vs demux (kernel on 60) resolved
- Guarded `fusefs.ko` built in the orchestrator slot and installed after owner approval; guard verified present in the built source
- Reboot-safety restored: at `timeout=0` the on-disk module preserves infinite-wait semantics (no `ETIMEDOUT` storm possible)
- Runbook ops-commit exists (Context/Rollback/Refs trailers)

## Source

Council memo `docs/notes/council-memo-bcf013-kernel-2026-11-14.md` (Live-mine escalation); owner decision 2026-11-14 (create + execute; install gated on explicit approval).
