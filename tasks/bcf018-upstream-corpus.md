---
id: "bcf018"
title: "Corpus for FreeBSD upstream contributions: ai-policy, contribution path, code requirements"
status: in-review
priority: high
effort: medium
dependencies: []
tags: ["upstream", "research", "docs"]
created_at: 2026-11-13
context: ["tasks/bcf005-p5-kernel-patches-upstream-freebsd.md", "tasks/bcf014-fuser-pr-070-reader-kick.md", "tasks/bcf016-freebsd-forum-thread.md"]
---

# Corpus for FreeBSD upstream contributions

Boundary with bcf019: this task = COLLECT (the material, the index, receipts links); distilling the conclusions into pi-topics = bcf019. Sections 3 and 5 are collect-only.

## Objective

Assemble a structured corpus that backs the PR texts (bcf005, bcf014, bcf015) and the forums thread (bcf016). **The settling place is pi-topics** (owner decision): the distilled conclusions + receipts live in topic memory; raw material larger than a digest — into the librarian cache (remote git/docs) or files with a link. Not a link dump: every item carries a capture date, a location, and a "why" paragraph.

## Sections to collect

1. **FreeBSD AI-policy drafts** (the owner's frame: the policy is NOT about a ban — it is about process/transparency; we record the actual requirements and their status as of the date; this affects the PR and thread formatting): fresh drafts on wiki.freebsd.org / freebsd-src / lists, what is required from a contributor, precedents.
2. **The contribution path 2026**: freebsd-src on GitHub (the PR flow for externals), reviews.freebsd.org — is the Phabricator path alive, Documentation/Committer instructions for externals, MFC/HEAD expectations.
3. **Code requirements**: style(9) (kernel C — our case for the fuse_io/fuse_ipc patches), the src commit-message conventions, repro/test expectations (pjdfstest, KYUA?).
4. **Our bhyve history as prior art**: the patches we already brought to bhyve. IMPORTANT: the memory index covers only the hot sessions of 2026-11-11..13 — the bhyve-contribution era did not make it in. Dig: homelab docs/runbooks, the owner's freebsd-src forks on GitHub, mailing-list mail/archives. What to find: the format, where it went (Differential? a mailing list?), what was accepted/rejected and why.
5. **The tone and practice of specific maintainers/subsystems** (feeds the council-maintainer seat in bcf020): who maintains sys/fs/fuse and koverstreet/fuser — the tone of past discussions and the reaction to external PRs (fuser#757, cberner/fuser issue #29), what they accept/reject and how they argue it.
6. **The duplicate check**: bugs.freebsd.org for fuse EINTR/wedge/timeout (bcf005 needs this too — merge the findings here).

## Acceptance Criteria

- [x] The corpus settled: 4 pi-topics (ai-policy / contribution-path / bhyve-prior-art / maintainer-tone; receipts in every claim) + CORPUS.md as the map.
- [x] Raw material larger than a digest — not in the topics: docs/notes/upstream-corpus-2026-11-13/raw/ (the AI guide, the Committer's Guide, the Q3 report, D50650, GSOC, the PR 300130/475/480 threads, bz snapshots); in the topics — links only.
- [x] AI-policy: the status as of the date + the checkpoint "re-verify before sending each PR" (topic freebsd-ai-policy-status-2026-11).
- [x] The bhyve history: the full list (PR 300130/300475/300480 + the nct668x prep) with dates/statuses/pattern — topic freebsd-upstream-prior-art-bhyve-2026-11.
- [x] The corpus referenced from bcf005/bcf014/bcf016 (a "Corpus" line in each).
- [x] The duplicates section §6: the dup-sweep done 2026-11-14 — dup = none (LIVE-ADDENDUM-2026-11-14.md §1; the REST workaround for multi-word documented). The task is pending owner acceptance.

## Source

Owner decision 2026-11-13 ("assemble a good corpus: from the ai-policy drafts to the code requirements, quality standards" (ru: «собрать хороший корпус: от драфтов ai-policy до требований к коду, стандарты качества»)).
