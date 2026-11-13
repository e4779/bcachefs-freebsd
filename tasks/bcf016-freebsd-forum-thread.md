---
id: "bcf016"
title: "Тред на форумах FreeBSD: bcachefs-vm мост + нативный FUSE-порт (анонс проекта)"
status: pending
priority: medium
effort: medium
type: docs
tags: [upstream, announcement]
dependencies: ["bcf005", "bcf014"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/00-status.md]
---

# Тред на форумах FreeBSD: bcachefs-vm + нативный FUSE-порт

Анонс-тред на forums.freebsd.org после подготовки PR-ов (зависимости): рассказать историю и текущее состояние. Порядок неслучаен — тред ссылается на открытые PR как на доказательство работы с апстримом, а не «выкладываем и убегаем».

## Содержание (набросок)

- **Контекст**: bcachefs-история на FreeBSD — VM-мост (bcachefsbox: NFS через VM diod, базовая линия homelab runbook 02) как работающий обходной путь и его налог (метаданные ×10.7).
- **Проект**: нативный FUSE-порт (tools + fuser форк) — публичный репозиторий https://github.com/e4779/bcachefs-freebsd (пины: fuser@8819589, tools@d48ba1a).
- **Прод-статус**: честно — пул в догфудинге (ro-эра пройдена, rw под f3-heal/наблюдением), метаданные 0.54 мс/файл (~24× моста), pjdfstest 0 fail / 380 pass, fsck чист.
- **Границы**: что НЕ готово (крупный бэклог reconcile-парковки, кернел-патчи не в апстриме, формат необратим) — чтобы никто не хранил прод на этом до приёмки.
- **Ссылки**: открытые PR (bcf005 kernel, bcf014 fuser), issue #29 cberner/fuser.

Корпус: docs/notes/upstream-corpus-2026-11-13/ + topic freebsd-ai-policy-status-2026-11 (чек-пункт AI-дисклоужа перед публикацией).

## Шаги

1. Текст по скиллу opensource-contribution (тон форумного поста, не пресс-релиза; без AI-slop).
2. Выбор раздела форума ( ports? / storage? ), черновик в docs/ на ревью владельца ДО публикации.
3. Публикация владельцем; ссылка на тред — в README репозитория.

## Definition of done

- Тред опубликован (владельцем), ссылка в README и в этой задаче.

## Source

Решение владельца 2026-11-13: «сделать тред на форуме freebsd — про bcachefs-vm и что мы делаем в этом проекте; перед этим подготовить PR-ы».
