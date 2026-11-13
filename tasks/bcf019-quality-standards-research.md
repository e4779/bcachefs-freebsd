---
id: "bcf019"
title: "Исследование стандартов качества кода FreeBSD, DoD = корректные pi-topics"
status: pending
priority: medium
effort: medium
dependencies: ["bcf018"]
tags: ["upstream", "research", "knowledge"]
created_at: 2026-11-13
context: ["tasks/bcf018-upstream-corpus.md"]
---

# Исследование стандартов качества кода FreeBSD → pi-topics

Граница: вход = корпус bcf018; здесь только дистилляция в topics. Сбор материала — не здесь.

## Objective

Дистилляция корпуса (bcf018) в проверяемые выводы. Собрать «как принято» в апстриме FreeBSD на уровне, достаточном чтобы патч прошёл ревью с первого-второго захода: не только буква style(9), но и неписаные ожидания ревьюеров.

## Questions to answer

- Что в style(9) реально ловят ревьюеры (табуляции, скобки, объявления перемешанные с кодом), что шум?
- Конвенции commit-сообщений src: формат subject, теги (MFC:, PR:, Differential Revision:), что делает автор патча против коммиттера (мы внешние — наш PR кто-то коммитит?).
- Ожидания к кернел-патчам вне стиля: lock-ordering заметки, поведение при ошибке, регрессия-риски, тесты.
- Специфика fuse(4) как подсистемы: кто мейнтейнер, тон прошлых коммитов в sys/fs/fuse.

## Acceptance Criteria (DoD = pi-topics)

- [ ] 2–4 `topic_save`: кандидаты — «FreeBSD contribution path 2026 (GitHub PR flow, роль коммиттера)», «style(9) + неписаные ожидания ревью sys/fs», «AI-policy статус FreeBSD» (последний с датой и триггером перепроверки).
- [ ] Каждый topic: status stable, receipts (конкретные пункты стайла/коммитов как доказательства, не пересказ), triggers для recall.
- [ ] Nothing derivable rule: в topics — только дистиллированные выводы и ссылки, сырьё остаётся в корпусе bcf018.

## Source

Решение владельца 2026-11-13 («на исследование стандартов качества тоже задачу; DoD — корректные pi-topics»).
