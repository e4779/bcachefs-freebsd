---
id: "bcf016"
title: "Thread on the FreeBSD forums: bcachefs-vm bridge + native FUSE port (project announcement)"
status: completed
priority: medium
effort: medium
type: docs
tags: [upstream, announcement]
dependencies: ["bcf005", "bcf014"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/00-status.md]
completed_at: 2026-11-16
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

## POSTED — LIVE (2026-11-15, approved same day)

- Thread: https://forums.freebsd.org/threads/running-a-bcachefs-pool-on-freebsd-a-vm-bridge-and-a-fuse-daemon-port.104370/
- Секция: Storage (48), префикс «Other» (её дефолтный).
- Task COMPLETE: DoD закрыт (тред опубликован, линк в карточке и в README).

## POSTED (2026-11-15, pending moderation)

- Куда: forums.freebsd.org, секция **Storage (48)** (решение владельца при
  постинге 2026-11-15: тема про storage, не про портинг). Аккаунт свежий →
  пост ждёт премодерации. Текст: docs/notes/draft-bcf016-forum-post.md (v4 + правки
  владельца при постинге: короткие линк-лейблы, «Real performance feels not
  native, but enough.», closer «Open for discussion.»).
- После апрува: записать URL нити сюда + в README → completed.
- Fallback при отказе (свежий аккаунт): секция General (3).
- Etiquette: не пинговать; после апрува — отвечать только по существу.

## Definition of done

- The thread published (by the owner), the link in the README and in this task.

## Source

Owner decision 2026-11-13: "make a thread on the freebsd forum — about bcachefs-vm and what we are doing in this project; prepare the PRs before that" (ru: «сделать тред на форуме freebsd — про bcachefs-vm и что мы делаем в этом проекте; перед этим подготовить PR-ы»).
