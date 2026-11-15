---
id: "bcf014"
title: "PR: 070 SIGURG reader-kick → koverstreet/fuser (daemon survives umount -f)"
status: completed
priority: high
effort: medium
type: chore
tags: [upstream, fuser]
dependencies: ["bcf013"]
created_at: 2026-11-13
completed_at: 2026-11-15
context: [overlay/files/, docs/f3-runbook.org, docs/evidence/core-69055-umount-hang/]
---

# PR: 070 SIGURG reader-kick → koverstreet/fuser

An upstream PR with a liveness fix: FreeBSD delivers FUSE_DESTROY to exactly ONE reader on the shared fd — the rest sleep in read(2) forever (Linux sends ENODEV to everyone). Our fix: a blocking read + an EINTR check of a flag; the Destroy-arm sets the flag and kicks all registered readers `pthread_kill(SIGURG)` with a no-op handler WITHOUT SA_RESTART — read returns EINTR, the thread sees the flag, exits. Zero per-request cost. Verified live: `umount -f` → the daemon exits on its own within ≤4s.

## Superseded (2026-11-15, owner decision)

Closed completed, not abandoned: the real goal of this card was reached —
the publication package is council-approved (dry-run 2026-11-14,
docs/notes/council-dryrun-070-memo-2026-11-14.md: the session_dead
pre-read amend, SIGURG disposition hygiene, framing kit, mechanical
gates) and the publication route is researched (see Route research
above). What changed is the FORM of publication: instead of one PR to
koverstreet/fuser, the owner split the track into two children —
«014 закрыть с комментарием (переосмыслили задачу), из неё вывести
две новых задачи» (decision 2026-11-15):

- bcf032 — Kent arm: contact koverstreet (channel choice at start),
  council-clean branch, logged outcome;
- bcf033 — cberner issue: the README-sanctioned issue-first door,
  filed after the Kent arm.

No open work remains here; the PR-text kit and framing rules live on
in the memo and the two children.

## Material

- The changes: fuser-vendored/{channel.rs, session.rs} + mirrors in overlay/files (commit b1a110f, patch 070).
- Diagnosis evidence: core 69055 (docs/evidence/core-69055-umount-hang/) — reader stacks in read(2) after Destroy.
- The v1 history (poll+flag) failed — shared fd: poll is ready for everyone before Destroy; do not include in the PR, but mention in the description why the kick approach was chosen.

## Steps

1. Diff against koverstreet/fuser main (the destroy-before-reply branch is already in the fork — verify the base, do not drag in extras).
2. Check for duplicates in the koverstreet/fuser tracker and cberner/fuser issue #29 (the BSD topic) — cross-links.
3. The PR text per the opensource-contribution skill: evidence-first (stacks, an umount -f repro), no AI-slop.
4. **The project link** https://github.com/e4779/bcachefs-freebsd as motivation (prod dogfooding of bcachefs FUSE on FreeBSD).

## Definition of done

- PR opened, the link recorded into the task (`--add-pr`), CI/feedback tracked.

Corpus: docs/notes/upstream-corpus-2026-11-13/ + topics (maintainer-tone-fuser-fusefs-2026-11 — the upstream tone, freebsd-contribution-path-2026-11, **fuser-pr-landscape-closed** — cberner PR door CLOSED since 2026-07-17: route = issue-first / Kent coordination; fuser-rust-code-standards — the 12-point checklist for if/when the door reopens).

## Route research (2026-11-15, researcher 032ddd49) — supersedes the PR-first framing

- koverstreet/fuser: issues DISABLED (has_issues=false), 0 PRs, fork created
  2026-10-02; «идти в ишуи Кента» в форк физически некуда. «Ад ишуев» владельца =
  koverstreet/bcachefs-tools (226 open/289 closed, живой).
- cberner/fuser: alive-but-quiet — release 0.18.0 2026-11-14; post-closure merges 49,
  все от самого cberner (agent-driven, автор коммитов «Claude»); внешних мерджей 0.
- Door closure reason: AI-slop в PR (cberner #755: «too many AI generated
  contributions»; README 17.07: «file an issue, or fork instead»). В issues слопа
  ~0% — стайл #760 (symptom-title, версии, repro) = наш стандарт.
- Kent отвечает живьём в bcachefs-tools: same-day (#1207, #1173), ≤4d (#1214);
  в fuser-контексте #757 (наша зона DESTROY) — 0 ответов 5.5 недель.

## Plan (dual-track)

1. PRIMARY: новый issue в cberner/fuser (README-sanctioned door) — symptom-title,
   body ≤2.5K: окружение, wchan/backtrace из core-69055, минимальный repro, фикс =
   ВЕТКА В НАШЕМ ФОРКЕ (паттерн #755 «point me to the branch»), без диффа в тексте;
   cross-ref #757 + #29 (BSD/asomers) + коммиты Кента 8fc86cf6/792855c8/88195892
   (destroy-before-reply — sibling-фикс той же болезни). Дисклеймер tooling — коротко.
2. KENT ARM (выбор владельца): (a) короткий heads-up issue в bcachefs-tools (его
   same-day lane; наш порт = его vendored fuser), (b) почта kent.overstreet@linux.dev,
   (c) ветка-PR в koverstreet/fuser (форк без трекера, но Кент его оператор).
3. Полный PR-текст из council dry-run — держать готовым (если дверь приоткроется).

## Council dry-run findings (2026-11-14) — merge into PR prep

Full memo: docs/notes/council-dryrun-070-memo-2026-11-14.md (pass 1
+ cross-exam, seats council-style/skeptic/maintainer). Converged:

1. MERGE PRECONDITION — one-line amend to 070: top-of-loop
   `session_dead` check (Acquire) in `receive_session_aware` before
   `receive` (channel.rs:66-67 insert); flag = source of truth,
   SIGURG only wakes readers already in read(2). State the
   invariant in the commit message.
2. SOLE REMAINING PR BLOCKER — SIGURG disposition hygiene:
   cfg(freebsd) gate + oldact save/verify (warn on foreign handler)
   or Config opt-in (session.rs:297, 522-530).
3. FRAMING KIT: koverstreet/fuser ONLY; #757 = one neutral
   technical cross-ref + "does not change reply ordering"
   disclaimer (Kent audience); grievance/momentum claims banned;
   evidence language cites POSIX sigaction (no SA_RESTART ⇒ EINTR);
   n=1 live fire is confirmation, not proof.
4. TEST STORY: in-CI Linux /dev/fuse flag/EINTR unit
   (drop_waits_for_destroy harness); out-of-CI FreeBSD interleaving
   repro (magic-path slow-dispatch, n>=3 + idle control arm —
   skeptic's outcome table in the memo); state CI-infeasibility
   honestly.
5. MECHANICAL GATES: cargo fmt --check + clippy; pin b1a110f in
   corpus and PR text; name the fork rev targeted; strip non-070
   items from the diff (writev-retry channel.rs:117-145,
   SessionACL::to_mount_option, n_threads lift).

## Source

docs/f3-runbook.org:14 "070 is not in koverstreet/fuser" (ru: «070 не в koverstreet/fuser»); owner decision 2026-11-13 (the publication track).
