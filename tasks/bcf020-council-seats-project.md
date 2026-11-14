---
id: "bcf020"
title: "Project-local council-* seats (.pi/agents/): stances for the port review"
status: completed
priority: medium
effort: medium
dependencies: ["bcf019"]
tags: ["skills", "council", "review"]
created_at: 2026-11-13
context: ["tasks/bcf013-prepublication-patch-review.md", "tasks/bcf017-council-skill-port.md", "tasks/bcf018-upstream-corpus.md", "tasks/bcf019-quality-standards-research.md"]
completed_at: 2026-11-14
---

# Project-local council-* seats (.pi/agents/)

## Objective

Project (not user) councilor profiles for council-mode — for the review of this project's patches. The capability is confirmed: council-mode looks for `council-*` in the user OR project agent directories; here — `~/projects/bcachefs-freebsd/.pi/agents/` (currently empty). The chain (owner decision 2026-11-13): the corpus (bcf018) → the standards (bcf019) → the seats (this task) → the bcf013 gate. The seat stances rest on material, not taste; the seats are the gate's mandatory tool, validated on real patch material prepared for review (070 and the neighbors — the material is prepared in advance, the gate opens after the dry run).

## Roster (candidates, council-mode: max 4)

1. **council-style** — FreeBSD src style and conventions: style(9), the commit format, the sys/fs review expectations. Fed by the bcf019 topics.
2. **council-skeptic** — adversarial against our journal: evidence-first, every claim with receipts from docs/evidence and the runbook; catches "vibecoded" weaknesses (ru: «навайбкодил») in patches.
3. **council-maintainer** — an emulation of the fuse(4)/fuser maintainer's tone: a minimal diff, regression risks, "why does this belong upstream" questions; fed by the bcf018 corpus (past discussions, the ai-policy frame).
4. **council-ops** — the prod perspective: dogfooding facts (f3-heal, poolwatch, the wedge shapes), the patch's impact on the running pool. Optional — enabled for disputes over ops effects.

## Work

- [ ] `council-*.md` profiles in `.pi/agents/`: the model, the tools (a read-only set), the context, the stance in the body — per the council-mode/pass-contracts format.
- [ ] The git nuance (owner decision 2026-11-13: "let's add them" (ru: «давай добавим»)): the profiles are tracked in git — `git add -f .pi/agents/`; the stances live in the repo, recovery = checkout. A pi-topics duplicate is not needed.
- [ ] A dry run: pass 1 on a real patch from the bcf013 queue (070 SIGURG-kick and the neighbors, the material is prepared in advance) with 2–3 seats — receipts, disputes, a memo. The bcf013 gate opens after this run.
- [ ] Register the seats as available for bcf013 (update its Method: the council = these seats).

## Acceptance Criteria

- [x] `subagent({action:"list"})` sees the seats — proven: pass 1
      ran all three seats as children; council-mode ran without the
      fallback oracle.
- [x] Dry-run memo attached to the journal:
      docs/notes/council-dryrun-070-memo-2026-11-14.md (pass 1 +
      cross-exam on patch 070; findings folded into bcf014;
      corpus stat erratum found and fixed).
- [x] The stances committed (`.pi/agents/` force-added against the
      gitignore; commit 63bcec5), they survive a move via git.

Status note: awaiting owner glance on the memo → completed.

## Source

Owner decision 2026-11-13 ("after collecting the corpus — create the council-* subagents inside the current project" (ru: «после сбора корпуса — создать субагентов council-* внутри текущего проекта»)).
