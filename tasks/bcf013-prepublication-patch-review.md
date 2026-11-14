---
id: "bcf013"
title: "Pre-publication review of the port patches: overlay 001–070 + kernel patches, gate before the upstream PR"
status: completed
priority: high
effort: large
type: chore
tags: [review, overlay, upstream, kernel]
dependencies: ["bcf020", "bcf026", "bcf017"]
created_at: 2026-11-13
context: [overlay/README.md, overlay/patches/, overlay/patches/kernel/, docs/f3-runbook.org]
completed_at: 2026-11-14
---

# Pre-publication review of the port patches (gate before PR)

Quality gate: no patch goes into an upstream PR (bcf005, bcf014) before an independent review. The public repo https://github.com/e4779/bcachefs-freebsd is already visible to the world — what we send upstream becomes the face of the project.

## Scope

- **Kernel patches** (`overlay/patches/kernel/`, 2 pcs): fuse_io-etimedout-fail-fast, fuse_ipc-deadline-cap. Review against FreeBSD main semantics (not only our /usr/src 15.1): do they break legitimate retries, is the PCATCH/ETIMEDOUT handling correct, is the diff minimal. Evidence from the journal (shape-4 wedge, stacks from cores) — being prepared for attachment in bcf005.
- **Daemon patches 001–070** (overlay/patches + mirrors in overlay/files): selectively — everything that goes into the fuser PR (070: channel.rs/session.rs, the Destroy-arm flag + reader registry + SIGURG) and everything claimed in the repo README. Criteria: no debug debris, no dead code, the patch is self-contained and reproducible via apply.sh from a clean clone, comments honest (EN).
- **A fresh run of the chain** from git-restored sources before sending (apply.sh stamp-idempotency — verify).
- **Parity evidence (on reviewer demand)**: cross-validation of the rw writes against Linux — probe /mnt/pool/.f3-probe/f001-200mb.bin, verify sha256 599b9472… on both sides + fsck from the Linux side (legacy of the cancelled bcf007; environment — the appliance or any Linux machine with bcachefs).

## Method

The review material comes from the upstream-practices corpus (bcf018) and the quality standards (bcf019 — without them a review is taste, not criteria). The tool — council-mode with the project council-* seats (bcf020, live
since 2026-11-14: council-style / council-skeptic / council-
maintainer / council-ops; council-ops joins only for live-pool
impact): a **mandatory precondition of the gate** — without seats
the gate does not open (owner decision 2026-11-13: "how do you
review when there is nothing to review with yet" (ru: «как
ревьювить, если ещё нечем»)).

A worker does not judge itself: review is a separate look (a verifier subagent or the owner's second pair of eyes). Verdicts per patch go into the git journal (commits with `Refs: bcf013`), found problems — as fix commits before the PR is sent.

## Definition of done

- For every patch on the PR track: a verdict "fit / fixes / not sending" in the journal.
- All "fixes" closed, the tree builds, apply.sh runs from a clean clone.

## Gate verdict (2026-11-14, delivered)

Council converged (pass 1 + pass 2 cross-exam, all three seats):
full memo docs/notes/council-memo-bcf013-kernel-2026-11-14.md.
Verdicts:
- fuse_io-etimedout-fail-fast → REWORK (3 edits: drop B_EINTR,
  extend :669-672 check, rewrite comment) then SUBMIT. Commit draft
  ready (style pass-2).
- fuse_ipc-deadline-cap → NOT SENDABLE as-is; demoted from bcf005
  to receipts (no-op without intr; qbittorrent story probably
  misattributed; daemon_timeout=0 blocker). Survival path:
  intr-only reframe + guard + dtrace + receipts, or defer.
- Cross-cutting: two PRs, fresh-main git-diff packaging (current
  /root-backup diffs won't apply), DCO, checkstyle9=0 gate, tests
  TEST2/TEST3/TEST1, transit-probe of timeout= before PR text.
- Live-mine escalation recorded (owner decision pending):
  /boot/kernel/fusefs.ko carries the unguarded cap; next reboot =
  ETIMEDOUT storm at timeout=0.

## Source

Owner decision 2026-11-13 (publication track planning: PRs before the FreeBSD forums thread, the PRs link to the project).
