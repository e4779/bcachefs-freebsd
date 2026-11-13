---
id: "bcf018"
title: "Корпус материалов для апстрим-контрибуций FreeBSD: ai-policy, путь контрибуции, требования к коду"
status: in-review
priority: high
effort: medium
dependencies: []
tags: ["upstream", "research", "docs"]
created_at: 2026-11-13
context: ["tasks/bcf005-p5-kernel-patches-upstream-freebsd.md", "tasks/bcf014-fuser-pr-070-reader-kick.md", "tasks/bcf016-freebsd-forum-thread.md"]
---

# Корпус материалов для апстрим-контрибуций FreeBSD

Граница с bcf019: эта задача = СОБРАТЬ (материалы, индекс, receipts-ссылки); дистилляция выводов в pi-topics = bcf019. Секции 3 и 5 — collect-only.

## Objective

Собрать структурированный корпус, на который опираются тексты PR (bcf005, bcf014, bcf015) и тред на форумах (bcf016). **Место оседания — pi-topics** (решение владельца): дистиллированные выводы + receipts живут в topic-памяти; сырьё крупнее дайджеста — в librarian-кэш (remote git/docs) или файлы со ссылкой. Не линк-дамп: каждый материал — с датой съёма, местом и абзацем «зачем».

## Sections to collect

1. **AI-policy драфты FreeBSD** (рамка владельца: политика НЕ про запрет — это про процесс/прозрачность; фиксируем фактические требования и их статус на дату, влияет на оформление PR и треда): свежие драфты на wiki.freebsd.org / freebsd-src / lists, что требуется от контрибутора, прецеденты.
2. **Путь контрибуции 2026**: freebsd-src на GitHub (PR-флоу для внешних), reviews.freebsd.org — жив ли Phabricator-путь, Documentation/Committer instructions для внешних, ожидания по MFC/HEAD.
3. **Требования к коду**: style(9) (кернел-C — наш случай для fuse_io/fuse_ipc патчей), конвенции commit-сообщений src, ожидания по репродюсам/тестам (pjdfstest, KYUA?).
4. **Наша bhyve-история как prior art**: патчи, которые мы уже приносили в bhyve. ВАЖНО: индекс памяти покрывает только горячие сессии 2026-11-11..13 — эра bhyve-контрибуций туда не попала. Копать: homelab docs/runbooks, форки freebsd-src на GitHub владельца, почта/архивы рассылок. Что нашли: формат, куда шли (Differential? рассылка?), что приняли/отклонили и почему.
5. **Тон и практика конкретных мейнтейнеров/подсистем** (кормит место council-maintainer в bcf020): кто мейнтейнит sys/fs/fuse и koverstreet/fuser — тон прошлых обсуждений и реакция на внешние PR (fuser#757, cberner/fuser issue #29), что принимают/отклоняют и как аргументируют.
6. **Дубли-проверка**: bugs.freebsd.org по fuse EINTR/wedge/timeout (нужно и bcf005 — объединить находки сюда).

## Acceptance Criteria

- [x] Корпус осел: 4 pi-topics (ai-policy / contribution-path / bhyve-prior-art / maintainer-tone; receipts в каждом утверждении) + CORPUS.md как карта.
- [x] Сырьё крупнее дайджеста — не в топиках: docs/notes/upstream-corpus-2026-11-13/raw/ (AI-гайд, Committer's Guide, отчёт Q3, D50650, GSOC, треды PR 300130/475/480, bz-снапшоты); в топиках — только ссылки.
- [x] AI-policy: статус на дату + чек-пункт «перепроверить перед отправкой каждого PR» (topic freebsd-ai-policy-status-2026-11).
- [x] bhyve-история: полный список (PR 300130/300475/300480 + nct668x prep) с датами/статусами/паттерном — topic freebsd-upstream-prior-art-bhyve-2026-11.
- [x] Корпус сослан из bcf005/bcf014/bcf016 (строка «Корпус» в каждой).
- [x] Дубли-секция §6: dup-sweep выполнен 2026-11-14 — dup = none (LIVE-ADDENDUM-2026-11-14.md §1; REST-обход multi-word задокументирован). Задача к приёмке владельцем.

## Source

Решение владельца 2026-11-13 («собрать хороший корпус: от драфтов ai-policy до требований к коду, стандарты качества»).
