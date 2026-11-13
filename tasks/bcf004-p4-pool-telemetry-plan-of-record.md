---
id: "bcf004"
title: "P4-Ф3: C-lite restricted ioctl — спека + имплементация"
status: pending
priority: medium
effort: large
dependencies: []
tags: [port, telemetry]
created_at: 2026-11-13
---

# P4-Ф3: C-lite restricted ioctl — спека + имплементация

## Objective

Единственный исполнимый кусок плана-of-record: Ф3 C-lite (restricted, фикс-размеры only). План-of-record (Ф0 закрыт, Ф1 доставлен, Ф2/Ф4 триггер-гейтед, инварианты, cut-list, фальсификаторы) переехал в `docs/notes/p4-plan-of-record.md` — читать её перед работой, она задает границы.

## Tasks

- [ ] Спека C-lite: restricted-only FUSE_IOCTL, фикс-размеры (НЕ flex-array — КОНТРФАКТ: `_IOC_SIZE(QUERY_ACCOUNTING)` несёт только заголовок, метрики тиринга едут flex-array ⇒ C-full рост 3-5x).
- [ ] Имплементация C+Rust по спеке.
- [ ] CLI читает счётчики с живого демона.

## Acceptance Criteria

- [ ] Спека ревьюнута владельцем до имплементации.
- [ ] CLI читает счётчики с живого прод-демона.
- [ ] rg-аудит: ноль mutating-ioctl (DATA/FSCK_ONLINE/DISK_*).

## Source

Консилиум 2026-11-06; мемо переехало в docs/notes/p4-plan-of-record.md (2026-11-13).
