---
id: "bcf026"
title: "Standards distillation: cberner/fuser (Rust side) → pi-topic"
status: in-review
priority: high
effort: medium
type: chore
dependencies: ["bcf019"]
tags: ["upstream", "fuser", "research", "knowledge"]
created_at: 2026-11-14
---

# Standards distillation: cberner/fuser (Rust side) → pi-topic

Boundary: the Rust userspace side of our port feeds cberner/fuser directly; this task distills its contribution norms into pi-topics. Kernel-side distillation is bcf019 (in flight) — sibling, not duplicate: no style(9) here, fuser has its own unwritten norms.

## Objective

Distill "how to write a mergeable PR for cberner/fuser". The Rust userspace side of our port feeds it: bcf014 (PR 070 reader-kick) is already aimed there, destroy-before-reply hardening (bcf022) will follow, and the nmount path goes via issue #29. Conventions differ from the kernel side — their norms, not ours.

## Evidence to mine

- Local vendored clone `fuser-vendored/` — the code style of the codebase we actually patch.
- Corpus `raw/live-2026-11-14/closed100.jsonl` — external-PR merge stats (corrected: 11/29 merged, 38%).
- Merged exemplars as ACCEPTED style samples: #643 (FreeBSD tests), #680 (BSD CI), #683, #695.
- Rejected contrasts: #692 syncfs (self-landed as #738), #645, #688, #757 (third-party issue, zero comments).
- Maintainer-tone topic facts (pi-topics bundle).
- CI: #680 merged ⇒ a BSD CI gate exists — find what it runs.

## Questions to answer

- Code style rules of fuser: fmt/clippy config present? module layout (`session.rs`/`channel.rs`) — what patterns does a patch have to follow?
- Test norms: how are upstream tests structured (e.g. the `drop_waits_for_destroy`-style session tests), and do PRs need tests to land?
- PR framing that landed vs rejected: size, additive-vs-semantics framing, evidence attachment (perf numbers? repro scripts?).
- CI gates: which checks run, and how does a FreeBSD-adjacent PR pass them?

## Acceptance Criteria (DoD = pi-topics)

- [x] Two stable pi-topics created (2026-11-14, receipts = file:line/CI-config/PR numbers, triggers set): `fuser-rust-code-standards` (style gate = CI not configs; error layering; session.rs real-mount test canon; FreeBSD VM job) and `fuser-pr-landscape-closed` (PR door CLOSED 2026-07-17 — plan-changing; strategy issue-first/Kent).
- [x] Nothing-derivable: topics hold conclusions + pointers; distillate persisted as corpus `distill-bcf026.md`, raw in `raw/live-2026-11-14-corpus4/`.
- [x] PR-writer checklist for bcf014: 12 points in `fuser-rust-code-standards` (channel-first caveat: door closed — checklist applies when/if the door reopens).

## Source

Sibling distillation of bcf019 (same corpus, same method, other
upstream target: cberner/koverstreet instead of the freebsd-src
kernel). Sources: maintainer-tone-fuser-fusefs-2026-11 topic +
corpus closed100.jsonl. Wired into the gate chain 2026-11-14: its
topic feeds the fuser lane of bcf013's council and the bcf014 PR
prep (owner: "bcf026 hangs in the air and is not linked as part of
013 - it emerged from 019").
