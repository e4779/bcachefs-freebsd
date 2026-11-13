---
id: "bcf005"
title: "P5: kernel patches fuse_io/fuse_ipc upstream to freebsd-src"
status: pending
priority: high
effort: medium
type: chore
tags: [upstream, kernel]
dependencies: ["bcf013"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches/kernel/]
---

# P5: kernel patches fuse_io/fuse_ipc upstream to freebsd-src

Both patches live in overlay/patches/kernel/ (reproducible from 9218d0c/c426039):
- fuse_io-etimedout-fail-fast.patch — ETIMEDOUT on a write must not be retried silently forever (redirty loop)
- fuse_ipc-deadline-cap.patch — PCATCH msleep was restarted with a new window on every periodic signal (shape-4 wedge: the thread never saw ETIMEDOUT)
Path: a PR to github.com/freebsd/freebsd-src (or reviews.freebsd.org).
Before sending: verify against current main fuse_ipc.c/fuse_io.c (our /usr/src 15.1), attach the repro/justification from the journal (shape-4, stacks from cores), the text per the opensource-contribution skill (no AI-slop, evidence-first). Check for duplicates re fuse EINTR wedges — single owner: bcf018 §6.

## Acceptance Criteria

- [ ] PR opened on freebsd-src, the number recorded into the task (`taskmd set bcf005 --add-pr <url>`).
- [ ] CI/maintainer feedback tracked, fixes sent. The PR description carries the project link https://github.com/e4779/bcachefs-freebsd (prod dogfooding as motivation). Companion bug report — bcf015.

Corpus: docs/notes/upstream-corpus-2026-11-13/ + topics (freebsd-ai-policy-status-2026-11, freebsd-contribution-path-2026-11, maintainer-tone-fuser-fusefs-2026-11).

## Source

docs/f3-runbook.org:45 — org heading "TODO P5: kernel patches upstream to freebsd-src (sys/fs/fuse)" (ru: «TODO P5: кернел-патчи в апстрим freebsd-src (sys/fs/fuse)»; migrated 2026-11-13).
