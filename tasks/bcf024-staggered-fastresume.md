---
id: "bcf024"
title: "P3b: staggered fastresume qbt — разброс старта против close-шторма"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001"]
tags: [port, ops]
created_at: 2026-11-13
---

# P3b: staggered fastresume qbt

## Objective

Детерминированный close-шторм: 711 fastresume одновременно = волна close/release/forget (kit 092614). Разбросать старт торрентов по времени, чтобы пик запросов не совпадал.

## Tasks

- [ ] Механизм разброса: обёртка запуска qbt или сортировка fastresume-файлов (окно ~5-10 мин).
- [ ] Прогон на тестовом пуле с полным fastresume.
- [ ] Связка с возвратом qbt (bcf002): staggered — часть штатного запуска.

## Acceptance Criteria

- [ ] Перезапуск qbt с полным fastresume — ноль wedge.
- [ ] poolwatch perr=0 за окно прогона.

## Source

Runbook консилиум 2026-11-06 (Shape-1); kit 092614.
