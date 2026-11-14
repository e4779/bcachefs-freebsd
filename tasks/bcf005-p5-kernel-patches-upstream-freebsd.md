---
id: "bcf005"
title: "P5: kernel patches fuse_io/fuse_ipc upstream to freebsd-src"
status: in-progress
priority: high
effort: medium
type: chore
tags: [upstream, kernel]
dependencies: ["bcf013"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches/kernel/]
---

# P5: kernel patches fuse_io/fuse_ipc upstream to freebsd-src

## COUNCIL VERDICT (2026-11-14) — supersedes the naive two-patch plan

Full memo: docs/notes/council-memo-bcf013-kernel-2026-11-14.md.
Findings the rework MUST implement (council converged, receipts in
memo):

1. fuse_io REWORK (3 edits, commit draft delivered by style):
   (a) drop B_EINTR from the ETIMEDOUT branch (sync lane: bufwait
   checks B_EINTR before BIO_ERROR — EINTR masked the real errno);
   (b) extend fuse_io.c:669-672 check to `EINTR || ETIMEDOUT` or the
   discontiguous-append lane keeps grinding (TEST3 covers);
   (c) rewrite the comment to the true contract (style pass-2 draft:
   b_error → fsync epilogue; B_EINTR ordering; brelse clears
   BIO_ERROR not b_error).
2. fuse_ipc DEMOTED out of this PR: the cap is a no-op without
   `-o intr` (poolfuse mounts without it — the qbittorrent story is
   probably misattributed), and daemon_timeout=0 is a blocker
   (unguarded cap kills the legal 0-configuration). Survival path
   as a separate later patch: intr-only bounded-wait reframe +
   daemon_timeout≠0 guard + dtrace trace + receipts that the service
   sat on an intr mount. Until then: receipts only.
3. Packaging: regenerate from a fresh main worktree as git diffs
   (current diffs are /root-backup GNU-diffs — won't apply); DCO
   Signed-off-by; checkstyle9.pl = 0 explicit; anchors re-verified
   on 15.1-RELEASE, re-check after rebase to main; two separate PRs.
4. Tests: TEST2 fsync ETIMEDOUT ≤2s vs grind-kill (fails on
   unpatched = failing-then-passing); TEST3 append-lane; TEST1 cap
   (only if fuse_ipc returns); mount-option plumbing in the harness.
5. Honesty: NO production-validation claims for the cap (it never
   executed in prod); run the timeout= transit-probe (dtrace
   sdt:fusefs:::ipc-trace arg0==3 on a test mount) before writing
   PR text; link the repo explicitly (300130 pattern).

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
