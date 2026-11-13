---
id: "bcf014"
title: "PR: 070 SIGURG reader-kick → koverstreet/fuser (daemon survives umount -f)"
status: pending
priority: high
effort: medium
type: chore
tags: [upstream, fuser]
dependencies: ["bcf013"]
created_at: 2026-11-13
context: [overlay/files/, docs/f3-runbook.org, docs/evidence/core-69055-umount-hang/]
---

# PR: 070 SIGURG reader-kick → koverstreet/fuser

An upstream PR with a liveness fix: FreeBSD delivers FUSE_DESTROY to exactly ONE reader on the shared fd — the rest sleep in read(2) forever (Linux sends ENODEV to everyone). Our fix: a blocking read + an EINTR check of a flag; the Destroy-arm sets the flag and kicks all registered readers `pthread_kill(SIGURG)` with a no-op handler WITHOUT SA_RESTART — read returns EINTR, the thread sees the flag, exits. Zero per-request cost. Verified live: `umount -f` → the daemon exits on its own within ≤4s.

## Material

- The changes: fuser-vendored/{channel.rs, session.rs} + mirrors in overlay/files (commit b1a110f, patch 070).
- Diagnosis evidence: core 69055 (docs/evidence/core-69055-umount-hang/) — reader stacks in read(2) after Destroy.
- The v1 history (poll+flag) failed — shared fd: poll is ready for everyone before Destroy; do not include in the PR, but mention in the description why the kick approach was chosen.

## Steps

1. Diff against koverstreet/fuser main (the destroy-before-reply branch is already in the fork — verify the base, do not drag in extras).
2. Check for duplicates in the koverstreet/fuser tracker and cberner/fuser issue #29 (the BSD topic) — cross-links.
3. The PR text per the opensource-contribution skill: evidence-first (stacks, an umount -f repro), no AI-slop.
4. **The project link** https://github.com/e4779/bcachefs-freebsd as motivation (prod dogfooding of bcachefs FUSE on FreeBSD).

## Definition of done

- PR opened, the link recorded into the task (`--add-pr`), CI/feedback tracked.

Corpus: docs/notes/upstream-corpus-2026-11-13/ + topics (maintainer-tone-fuser-fusefs-2026-11 — the upstream tone, freebsd-contribution-path-2026-11).

## Source

docs/f3-runbook.org:14 "070 is not in koverstreet/fuser" (ru: «070 не в koverstreet/fuser»); owner decision 2026-11-13 (the publication track).
