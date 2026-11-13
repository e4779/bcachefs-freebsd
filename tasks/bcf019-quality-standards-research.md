---
id: "bcf019"
title: "FreeBSD code quality standards research, DoD = correct pi-topics"
status: in-progress
priority: medium
effort: medium
dependencies: ["bcf018"]
tags: ["upstream", "research", "knowledge"]
created_at: 2026-11-13
context: ["tasks/bcf018-upstream-corpus.md"]
---

# FreeBSD code quality standards research → pi-topics

Boundary: the input = the bcf018 corpus; here only the distillation into topics. Material collection is not here.

## Objective

Distill the corpus (bcf018) into verifiable conclusions. Gather "how it's done" in FreeBSD upstream at a level sufficient for a patch to pass review on the first or second attempt: not only the letter of style(9) but the unwritten reviewer expectations.

## Questions to answer

- What in style(9) do reviewers actually catch (tabs, braces, declarations mixed with code), and what is noise?
- The src commit-message conventions: the subject format, the tags (MFC:, PR:, Differential Revision:), what the patch author does vs the committer (we are external — does someone commit our PR?).
- The expectations for kernel patches beyond style: lock-ordering notes, error-path behavior, regression risks, tests.
- The fuse(4) specifics as a subsystem: who is the maintainer, the tone of past commits in sys/fs/fuse.

## Acceptance Criteria (DoD = pi-topics)

- [ ] 2–4 `topic_save`s: the candidates — "FreeBSD contribution path 2026 (GitHub PR flow, the committer role)", "style(9) + the unwritten sys/fs review expectations", "FreeBSD AI-policy status" (the last one with a date and a re-check trigger).
- [ ] Each topic: status stable, receipts (specific style/commit points as evidence, not a paraphrase), triggers for recall.
- [ ] The nothing-derivable rule: the topics hold only distilled conclusions and links; the raw material stays in the bcf018 corpus.

## Source

Owner decision 2026-11-13 ("a task for the quality-standards research too; the DoD — correct pi-topics" (ru: «на исследование стандартов качества тоже задачу; DoD — корректные pi-topics»)).
