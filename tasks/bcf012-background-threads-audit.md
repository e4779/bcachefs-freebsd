---
id: "bcf012"
title: "Хвост аудита фоновых потоков: cron-USR1 автоматизация + park-условия reconcile"
status: pending
priority: high
effort: medium
dependencies: []
tags: [port]
created_at: 2026-11-13
---

# Хвост аудита фоновых потоков: cron-USR1 + park-условия

## Objective

Аудит закрыт: потоки стартуют и работают; дренаж подтверждён живьём (SIGUSR1 → rw_pend 144М→18.8М секторов, ~240МБ/с). Открытый остаток — две вещи: автоматизация дренажа и причины парковок.

## Tasks

- [ ] cron-USR1: периодический pending-scan (svcj-безопасный guard от шторма) — ИЛИ явное NO-GO владельца, записанное в рунбук.
- [ ] Park-условия: картировать (`needs_reconcile.rs` update_reconcile_opts, `plan.rs` parks_on) — где и почему паркуются.
- [ ] Снять минимум одну парковку патчем ИЛИ задокументировать как инвариант.

Факты для старта: парковка на ENOSPC при полном HDD-target (Linux-era entries); «заморозка» счётчиков = wait 17.2ГБ io-clock[WRITE] между pass'ами.

## Acceptance Criteria

- [ ] cron-USR1 настроен ИЛИ NO-GO записан владельцем.
- [ ] Карта park-условий в docs/notes (условие → файл/строка → статус).
- [ ] Один park снят патчем или задокументирован как инвариант.

## Source

Вердикт Ф0 + журнал 2026-11-07 (066/067); хроника аудита осталась в docs/f3-runbook.org.
