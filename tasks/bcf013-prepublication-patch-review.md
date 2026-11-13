---
id: "bcf013"
title: "Pre-publication review of the port patches: overlay 001–070 + kernel patches, gate before the upstream PR"
status: pending
priority: high
effort: large
type: chore
tags: [review, overlay, upstream, kernel]
dependencies: ["bcf020"]
created_at: 2026-11-13
context: [overlay/README.md, overlay/patches/, overlay/patches/kernel/, docs/f3-runbook.org]
---

# Pre-publication review of the port patches (gate before PR)

Quality gate: no patch goes into an upstream PR (bcf005, bcf014) before an independent review. The public repo https://github.com/e4779/bcachefs-freebsd is already visible to the world — what we send upstream becomes the face of the project.

## Scope

- **Kernel patches** (`overlay/patches/kernel/`, 2 pcs): fuse_io-etimedout-fail-fast, fuse_ipc-deadline-cap. Review against FreeBSD main semantics (not only our /usr/src 15.1): do they break legitimate retries, is the PCATCH/ETIMEDOUT handling correct, is the diff minimal. Evidence from the journal (shape-4 wedge, stacks from cores) — being prepared for attachment in bcf005.
- **Daemon patches 001–070** (overlay/patches + mirrors in overlay/files): selectively — everything that goes into the fuser PR (070: channel.rs/session.rs, the Destroy-arm flag + reader registry + SIGURG) and everything claimed in the repo README. Criteria: no debug debris, no dead code, the patch is self-contained and reproducible via apply.sh from a clean clone, comments honest (EN).
- **A fresh run of the chain** from git-restored sources before sending (apply.sh stamp-idempotency — verify).
- **Parity evidence (on reviewer demand)**: cross-validation of the rw writes against Linux — probe /mnt/pool/.f3-probe/f001-200mb.bin, verify sha256 599b9472… on both sides + fsck from the Linux side (legacy of the cancelled bcf007; environment — the appliance or any Linux machine with bcachefs).

## Method

The review material comes from the upstream-practices corpus (bcf018) and the quality standards (bcf019 — without them a review is taste, not criteria). The tool — council-mode with the project council-* seats (bcf020): a **mandatory precondition of the gate** — without seats the gate does not open (owner decision 2026-11-13: "how do you review when there is nothing to review with yet" (ru: «как ревьювить, если ещё нечем»)).

A worker does not judge itself: review is a separate look (a verifier subagent or the owner's second pair of eyes). Verdicts per patch go into the git journal (commits with `Refs: bcf013`), found problems — as fix commits before the PR is sent.

## Definition of done

- For every patch on the PR track: a verdict "fit / fixes / not sending" in the journal.
- All "fixes" closed, the tree builds, apply.sh runs from a clean clone.

## Source

Owner decision 2026-11-13 (publication track planning: PRs before the FreeBSD forums thread, the PRs link to the project).
