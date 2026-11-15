---
title: "Kent arm: put the 070 SIGURG reader-kick in front of koverstreet — channel, council-clean branch, logged outcome"
id: "bcf032"
status: in-progress
priority: high
type: chore
tags: [upstream, fuser, coordination]
created_at: "2026-11-15"
dependencies: ["bcf014"]
effort: medium
context: [overlay/files/fuser-vendored/src/channel.rs, overlay/files/fuser-vendored/src/session.rs, docs/notes/council-dryrun-070-memo-2026-11-14.md, docs/evidence/core-69055-umount-hang/, docs/notes/upstream-corpus-2026-11-13/]
---

# Kent arm: put the 070 SIGURG reader-kick in front of koverstreet

## Objective

One deliverable: koverstreet contacted about the 070 SIGURG reader-kick through one owner-approved channel, with a permanent receipt and a closed loop (substantive outcome OR an owner-judged sufficient-silence) logged in this card. First move of the upstream track; its logged outcome feeds bcf033 (the cberner issue).

The fix we present (commit b1a110f): FreeBSD delivers FUSE_DESTROY to exactly one blocked reader on the shared fd — the rest sleep in read(2) forever (Linux ENODEV-broadcasts), so Session::run's sequential join hangs the daemon on every umount -f. Destroy arm sets a session_dead flag and kicks every registered reader with pthread_kill(SIGURG), no-op handler WITHOUT SA_RESTART — interrupted read returns EINTR, the thread sees the flag, exits; zero steady-state per-request cost; live-verified umount -f → clean daemon exit ≤4s (n=1 = confirmation, not proof). Council merge precondition folded in: one-line pre-read session_dead check (Acquire) in receive_session_aware — the flag is the source of truth, SIGURG only wakes readers already parked. Mention why poll-based v1 fails (shared fd: poll is ready for everyone before Destroy). Sibling fix: Kent's destroy-before-reply (8fc86cf6 / 792855c8 / 88195892, Oct 2026) addresses reply ordering, not parked readers — frame 070 as a bugfix on his OWN arm.

Channel (FIXED by owner 2026-11-15): (a) heads-up issue in koverstreet/bcachefs-tools — the README-documented front door ("GitHub issues for bug reports and focused feature requests"); Kent's live triage lane (same-day: #1207/#1173; ≤4d: #1214); our port carries his vendored fuser. Fallback ladder: (b) email kent.overstreet@linux.dev if (a) stalls by owner judgment; mailing list (linux-bcachefs@vger, mirrored at mail-archive.com, lore behind Anubis) deferred for later visibility. The DIFF LINK for the issue = cross-fork compare URL: https://github.com/koverstreet/fuser/compare/master...e4779:fuser-070:<branch> (renders the would-be-PR diff; +.diff suffix = raw patch). Requires the fix published in a public fork e4779/fuser.

## Tasks

- [ ] Pick the channel (a/b/c); record choice + rationale in the git journal (Refs: bcf032) before sending.
- [ ] Shape the council-clean branch: apply the session_dead pre-read amend (channel.rs:66-67 insert) + SIGURG disposition hygiene (cfg(freebsd) gate + oldact save/verify, session.rs:297, 522-530); cargo fmt --check + clippy; strip non-070 items (writev-retry channel.rs:117-145, SessionACL::to_mount_option, n_threads lift); publish as a pullable branch in a public repo we control (dedicated fuser fork preferred — create e4779/fuser fork of koverstreet/fuser, push the branch there); record the base rev (8819589 or koverstreet HEAD) and the fix rev; build the cross-fork compare URL (koverstreet/fuser master...e4779:branch) and smoke-test it renders the intended diff.
- [ ] Draft the message per the council framing kit (memo §3-5): evidence-first; mechanism = POSIX sigaction (no SA_RESTART ⇒ EINTR); one neutral #757 cross-ref + "does not change reply ordering" disclaimer; n=1 live fire labeled confirmation; project link https://github.com/e4779/bcachefs-freebsd as motivation; short tooling disclaimer; grievance/momentum claims banned.
- [ ] Send through the chosen channel; record the permanent receipt (issue URL or Message-ID + saved copy) in this card.
- [ ] Drive the loop to closure: the OWNER judges when the wait has earned its keep — a substantive reply, or a deliberate decision that silence is the answer. No fixed window, no ping schedule. Lane info (not a schedule): Kent answers same-day..≤4d when engaged in bcachefs-tools (#1207/#1173/#1214); the absence of a reply within that ballpark is itself signal.
- [ ] Log the outcome (blessing / form correction / merge / redirect / owner-judged silence) + the exact line bcf033 inherits, via taskmd worklog and the card body.

## Acceptance Criteria

- [ ] A permanent receipt of an actual contact exists in the card (issue URL or Message-ID with a saved copy); a stranger can open it and find our message.
- [ ] The published branch is council-clean: fmt/clippy pass; the diff contains ONLY 070 items; the session_dead pre-read check and cfg(freebsd) SIGURG hygiene are present; base + fix revs are recorded in the card.
- [ ] The sent message satisfies the framing kit: POSIX sigaction mechanism cited; #757 referenced neutrally with the reply-ordering disclaimer; zero grievance/momentum phrasing; n=1 labeled as confirmation.
- [ ] The loop is closed in the card: a substantive outcome logged, OR an explicit owner-judgment of sufficient-silence logged with the receipt; the handoff line states exactly what bcf033 inherits.

Kent's actual reply is NOT an acceptance criterion — silence is handled by the owner-judgment closure, not by failure.

## Receipts (2026-11-15, worker 988f0fa4)

- Base: c0420fc (koverstreet/fuser master HEAD 2026-08-07). Нюанс: наш vendored — на
  линии Кента (destroy-before-reply 8819589, окт), а публикуем 070 поверх cberner
  master — правильно для апстрим-видимости; на линию Кента переносится отдельно
  (там destroy-before-reply — сиблинг, не конфликт 070).
- Fix rev: 9475151 (e4779/fuser, ветка 070-reader-kick, 1 коммит, tree clean;
  f5d1e5e перезаписан amend'ом — верификатор поймал «FreeBSD 14» в сообщении,
  прод 15.1-RELEASE-p6; force-push до отправки Кенту, никто не видел).
- Compare: https://github.com/koverstreet/fuser/compare/master...e4779:070-reader-kick
  gh-api verify: files=2 (channel.rs +35/−0, session.rs +78/−1), commits=1, сумма +113/−1.
- fmt: cargo fmt --check CLEAN (toolchain 1.85, style_edition 2024).
- Портировано: receive_session_aware + pre-read session_dead (Acquire); Destroy-arm
  Release-store + SIGURG кик (cfg(freebsd)); P2 hygiene (oldact save/verify + warn,
  идемпотентно); реестр читателей (pthread_self) + поля SessionEventLoop.
- Стрипнуто: writev-retry, n_threads-lift, SessionACL::to_mount_option (уже идентичен
  на master), destroy-before-reply arm + RwLock-FilesystemHolder (линия 8819589).
- Pending: work-verifier — VERIFIED 5/5 (branch/compare, strip-лист, framing kit
  в commit message + лексикон-скан 0 grievance-слов, fmt/clippy, lane-факты
  свежи с точностью до часов; один failed пойман и исправлен — версия FreeBSD
  в commit message).
- Council #3 (style/skeptic/maintainer): все FIX→SEND, ноль hold; blocker'ы
  сняты (evidence двух-моментно по lldb-инвентарю; base-неоднозначность явной
  фразой). Owner правки: пины цифр сняты (протухнут), Environment → «I ported
  bcachefs… the bcachefs pool lives in my homelab», body → GitHub Markdown.

## SENT (2026-11-15, owner-approved)

- Receipt: https://github.com/koverstreet/bcachefs-tools/issues/1234 —
  канал (a), GitHub Markdown; канонический текст = сама ишуя (draft-файл удалён за неактуальностью, история эволюции — в git-журнале).
- Loop: OPEN — watching; closure по owner-judgment (ответ Кента или
  тишина-как-сигнал). Handoff line для bcf033 — после первого исхода:
  «coordination attempted via bcachefs-tools issue 1234 on 2026-11-15,
  receipt <link>, <outcome>». Драфт ишуи: docs/notes/draft-bcf032-kent-issue.md (~2.2K).
  Отправка — owner decision.

## Source

Route research in bcf014 (2026-11-15); council dry-run memo docs/notes/council-dryrun-070-memo-2026-11-14.md; corpus docs/notes/upstream-corpus-2026-11-13/; topics: fuser-pr-landscape-closed, maintainer-tone-fuser-fusefs-2026-11, fuser-rust-code-standards; owner decision 2026-11-15 (bcf014 split, Kent arm first, gate expiry replaced by owner-judgment closure).
