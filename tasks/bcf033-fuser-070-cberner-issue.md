---
title: "cberner/fuser issue: FreeBSD FUSE_DESTROY parked-reader hang — evidence-first report, fix offered as our fork branch"
id: "bcf033"
status: pending
priority: high
type: chore
tags: [upstream, fuser, issue]
created_at: "2026-11-15"
dependencies: ["bcf014", "bcf034"]
effort: medium
context: [docs/evidence/core-69055-umount-hang/, docs/notes/upstream-corpus-2026-11-13/, docs/notes/council-dryrun-070-memo-2026-11-14.md, tasks/bcf032-fuser-070-kent-arm.md]
---

# cberner/fuser issue: FreeBSD FUSE_DESTROY parked-reader hang

## Objective

One deliverable: a live issue in cberner/fuser reporting the FreeBSD FUSE_DESTROY parked-reader hang, evidence-first, with the fix offered as a branch in our fork — never a PR. This is the README-sanctioned door: since 2026-07-17 cberner mass-closed all external PRs (AI-slop, #755 boilerplate) and the README says "file an issue, or fork instead". Issue-slop rate ≈ 0% — the style canon is #760 (symptom-title, versions, minimal repro).

Filed AFTER the Kent arm (bcf032, hard dependency by owner's work order 2026-11-15, not a formality): the coordination-status paragraph of this issue is determined by bcf032's logged outcome — a blessing/merge strengthens the report, owner-judged silence gets reported factually with a receipt link.

Body discipline: ≤2.5K chars; overflow evidence (full stacks, repro script) goes to a follow-up comment on our own issue, not into the body. Strictly own voice ("we observed…"); cross-references are facts with links; no sentence attributes a position or intent to Kent or cberner.

## Tasks

- [ ] Duplicate check over cberner/fuser issues (DESTROY / hang / FreeBSD / BSD-asomers; #757 and #29 are known landmarks); record the decision (file-new vs cross-comment) + rationale in the journal BEFORE filing.
- [ ] Verify claims about current upstream before writing them: inspect whether master / 0.18.0 (released 2026-11-14) teardown still parks readers; state affected versions ONLY as far as verified.
- [ ] Draft the issue: symptom-title; env block (FreeBSD prod appliance with uname -r verbatim; fuser base rev; our vendored tree); wchan/backtrace excerpt from core-69055 (docs/evidence/core-69055-umount-hang/); minimal repro (umount -f with ≥2 concurrent readers, one slow dispatch, idle control arm per skeptic's outcome table in the memo); mechanism paragraph (shared fd; POSIX sigaction, no SA_RESTART ⇒ EINTR is our fix path; why poll-based v1 fails); fix = branch in our fork with the exact rev published by bcf032 (pattern #755 "point me to the branch"); no diff pasted into the issue text.
- [ ] Add the coordination-status line from bcf032's logged outcome — strictly factual; on silence: "coordination attempted via <channel> on <date>, receipt <link>, no response yet".
- [ ] File the issue; record number/URL in this card; cross-refs #757 + #29 + koverstreet commits 8fc86cf6/792855c8/88195892 as facts; short tooling disclaimer; re-check body ≤2.5K before submit.
- [ ] First-response watch ≤14 days: log any maintainer action (reply / merge / close / release note) as a worklog entry; no further action inside this card.

## Acceptance Criteria

- [ ] The issue is live with URL/number recorded here; a stranger can reproduce the claim from the issue alone: versions/env, backtrace or wchan excerpt, and repro steps are all present.
- [ ] Body ≤2.5K with a symptom-title; no AI-slop markers (no filler praise, no hedging boilerplate); the tooling disclaimer is present and short; the fix is offered ONLY as our-fork branch with an exact rev; no diff in the issue text; no PR opened against cberner/fuser.
- [ ] Every cross-reference is a link + fact; zero sentences attribute intent or position to Kent or cberner; the coordination-status line matches the bcf032 log exactly.
- [ ] The duplicate-check decision is recorded before filing (file-new vs cross-comment + why); if a live duplicate existed, no second issue was filed.
- [ ] Watch closed: a maintainer action logged, or the 14-day expiry logged.

## Source

Route research in bcf014 (2026-11-15); cberner/fuser #755 (closure boilerplate), #760 (style canon), #757 (DESTROY zone), #29 (BSD/asomers); council dry-run memo docs/notes/council-dryrun-070-memo-2026-11-14.md (framing kit, test story); topics: fuser-pr-landscape-closed, fuser-rust-code-standards, maintainer-tone-fuser-fusefs-2026-11; owner decision 2026-11-15 (bcf014 split; Kent arm first, cberner issue second).
