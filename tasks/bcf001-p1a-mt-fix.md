---
id: "bcf001"
title: "P1a: MT-фикс wedge — 8 потоков fuser"
status: pending
priority: high
effort: large
dependencies: []
tags: [port, wedge]
created_at: 2026-11-13
---

# P1a: MT-фикс wedge — 8 потоков fuser

## Objective

MT-билд (8 потоков) как база стабилизационного пакета P1: убрать однопоточную узость reply-path, где sync disk IO демона блокирует FUSE-ответы. Fact: core#2 (MT-билд, kill -5) показал fuser-0 в preadv на HDD — sync disk IO inline.

## Tasks

- [ ] Подтвердить в коде fuser-vendored: gate 8 потоков снят, потоки реально стартуют.
- [ ] Включить 8 потоков по умолчанию в прод-конфиге.
- [ ] Acid-тест (qbt init) на тестовом пуле.
- [ ] Прод-пул под f3-heal 24ч — наблюдение.

Сборка — ТОЛЬКО в слоте оркестратора (правило AGENTS).

## Acceptance Criteria

- [ ] Acid-тест qbt init: 3 прогона подряд без wedge.
- [ ] Прод 24ч: ноль инцидентов wedge в poolwatch.
- [ ] Deadline-слой (watchdog/heartbeat) здесь ОТСУТСТВУЕТ — он в bcf022 (граница явная).

## Source

Runbook 2026-11-06 консилиум (модель форм wedge); core#2 стеки.
