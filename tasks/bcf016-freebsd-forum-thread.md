---
id: "bcf016"
title: "Thread on the FreeBSD forums: bcachefs-vm bridge + native FUSE port (project announcement)"
status: pending
priority: medium
effort: medium
type: docs
tags: [upstream, announcement]
dependencies: ["bcf005", "bcf014"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/00-status.md]
---

# Thread on the FreeBSD forums: bcachefs-vm + native FUSE port

An announcement thread on forums.freebsd.org after the PRs are prepared (the dependencies): tell the story and the current state. The order is not accidental — the thread points to the open PRs as proof of working with upstream, not "dump it and run".

## Content (sketch)

- **Context**: the bcachefs history on FreeBSD — the VM bridge (bcachefsbox: NFS via VM diod, the homelab runbook 02 baseline) as a working workaround and its tax (metadata ×10.7).
- **The project**: the native FUSE port (tools + the fuser fork) — public repo https://github.com/e4779/bcachefs-freebsd (pins: fuser@8819589, tools@d48ba1a).
- **Prod status**: honest — the pool is in dogfooding (the ro era is done, rw under f3-heal/observation), metadata 0.54 ms/file (~24× the bridge), pjdfstest 0 fail / 380 pass, fsck clean.
- **Boundaries**: what is NOT ready (a large backlog of reconcile parks, the kernel patches not upstream, the format irreversible) — so that nobody keeps prod on this before acceptance.
- **Links**: the open PRs (bcf005 kernel, bcf014 fuser), issue #29 cberner/fuser.

Corpus: docs/notes/upstream-corpus-2026-11-13/ + topic freebsd-ai-policy-status-2026-11 (the AI-disclosure checkpoint before publication).

## Steps

1. The text per the opensource-contribution skill (the tone of a forum post, not a press release; no AI-slop).
2. The choice of a forum section ( ports? / storage? ), a draft in docs/ for owner review BEFORE publication.
3. Publication by the owner; the thread link — into the repo README.

## Definition of done

- The thread published (by the owner), the link in the README and in this task.

## Source

Owner decision 2026-11-13: "make a thread on the freebsd forum — about bcachefs-vm and what we are doing in this project; prepare the PRs before that" (ru: «сделать тред на форуме freebsd — про bcachefs-vm и что мы делаем в этом проекте; перед этим подготовить PR-ы»).
