---
id: "bcf001"
title: "P1a: MT wedge fix — 8 fuser threads"
status: in-progress
priority: high
effort: large
dependencies: []
tags: [port, wedge]
created_at: 2026-11-13
context: [docs/f3-runbook.org, tools/src/commands/fusemount.rs, tools/fuser-vendored/src/session.rs, tasks/bcf002-p2-service-return.md]
---

# P1a: MT wedge fix — 8 fuser threads

## Objective

The MT build (8 threads) as the base of stabilization package P1: remove the single-threaded narrowness of the reply-path, where the daemon's sync disk IO blocks FUSE replies. Fact: core#2 (MT build, kill -5) showed fuser-0 in preadv on the HDD — sync disk IO inline.

## Tasks

- [x] Confirm in the fuser-vendored code: the 8-thread gate is lifted, the threads actually start.
  DONE 2026-11-16: gate lifted in the vendored fork — `fuser-vendored/src/session.rs:262-303`
  (`n_threads` from config, `clone_fd=false` path spawns N readers on the shared /dev/fuse fd —
  legal on FreeBSD, fuse(4) ms_pop serializes dequeue; SIGURG reader-kick for clean destroy).
  Prod config: `tools/src/commands/fusemount.rs:2485-2493` — `#[cfg(target_os = "freebsd")]`
  sets `n_threads = Some(8)`, `clone_fd = false` (the old single-thread comment removed).
- [x] Enable 8 threads by default in the prod config.
  DONE (deployed 2026-11-06/07, re-verified live 2026-11-16): rc.d `poolfuse` runs the local
  build (`rlimit-run.sh ./tools/bcachefs mount -o fuse,allow_other,timeout=0`); live daemon
  pid 3325 = 8 worker threads `fuser-0..fuser-7` (procstat -t), binary
  `target/release/bcachefs` (2026-11-14 14:43, bcf029 retirement build) carries
  `install_reader_kick_handler`.
- [x] Acid test (qbt init) on the test pool.
  PARTIAL, outcome reattributed: 1 run 2026-11-07 = 1 wedge. The bcf023 discriminator
  (2026-11-14, receipts from the 2026-11-06 kits) proved the daemon SERVES during that
  wedge class — the residual is kernel-side (client parked in `fdisp_wait_answ`),
  filed upstream as bug 300785 (bcf015). A 3-run clean series is only meaningful in
  the qbt-return window (bcf002) — re-scope proposal below.
- [x] Prod pool under f3-heal for 24h — observation.
  DONE: f3-heal v2.1 on post since 2026-11-07 (pid live 2026-11-16); poolwatch events.log
  2026-11-07 → 2026-11-16: zero wedge-class incidents. Alarm days since MT-8: Nov 9 =
  owner-initiated reboot window (shutdown at 15:24 in messages.0.bz2); Nov 14 = SIGABRT
  class (fixed by bcf029 retirement build, deployed 15:16) + sudden power cut
  (owner-confirmed, commit f3814c9). ~9 days of soak, not just 24h.

Build — ONLY in the orchestrator slot (AGENTS rule).

## Acceptance Criteria

- [ ] Acid test qbt init: 3 consecutive runs without a wedge.
  BLOCKED outside bcf001 scope: the residual wedge is the kernel class (bcf023 verdict),
  not reply-path narrowness. Proposal: move this AC to bcf002 (qbt return proves it
  in the window where it matters). Owner decision pending.
- [x] Prod 24h: zero wedge incidents in poolwatch.
  VERIFIED 2026-11-16: ~9 days, zero wedge-class events (receipts in Tasks above).
- [x] The deadline layer (watchdog/heartbeat) is NOT here — it lives in bcf022 (explicit boundary).

## Findings (actualization 2026-11-16)

1. Tasks 1-2 and the 24h AC are satisfied by live receipts; the only open item is the
   3x acid test, which cannot pass by daemon MT alone (bcf023: daemon serves, residual
   is kernel-side).
2. Scope note: MT is necessary but not sufficient for qbt-init; the close-storm class
   is handled by kernel patches (bcf005 fail-fast locally, bug 300785 upstream) + the
   bcf002 return plan.
3. Unblocks on close: bcf002, bcf003, bcf022, bcf024.

## Owner decision (open)

Close bcf001 with AC1 moved to bcf002, or keep open until the 3x acid test runs on the
test pool first (needs a test-pool qbt harness — vn image + qbt config copy; no scripted
harness exists yet).

## Source

Runbook 2026-11-06 council (wedge shape model); core#2 stacks; bcf023 discriminator
verdict 2026-11-14.
