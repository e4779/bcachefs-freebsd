---
id: "bcf-012"
title: "Аудит фоновых потоков порта (reconcile/compression/copygc): стартуют ли вообще (fs.start(), fusemount.rs:2477)"
status: pending
priority: high
effort: large
type: bug
tags: [port]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/notes/19a-dogfood-engine.md]
---

# Аудит фоновых потоков порта (reconcile/compression/copygc): стартуют ли вообще (fs.start(), fusemount.rs:2477)

Из вердикта Ф0 (утро 2026-11-07, 9.3ч soak, 552 срезов): инфраструктура телеметрии работает (ring 60с, 0 инцидентов за ночь), но ДАННЫЕ вскрыли: reconcile_work.pend=144308320 и cmp=42114776 — ЕДИНСТВЕННЫЕ значения за все 9ч (sort -u = 1 строка) при живых dev_leaving (0->210432 секторов) и растущем btree_total => дренаж reconcile/compression в порту не ведётся: бэклог стоит; тиринг-политика декоративна (на тот момент). Компрессия 42МБ не применяется, pending 144МБ не переезжает. Влияние на прод некритично (данные целы, IO верен).
Вопросы задачи: стартуют ли фоновые потоки вообще (fs.start(), fusemount.rs:2477), какие recovery passes нужны.
Уточнения из журнала 2026-11-07 (инструмент 066 + патч 067): потоки стартуют и работают; «заморозка» счётчиков = wait-условие 17.2ГБ io-clock[WRITE] между pass'ами + Linux-era запаркованные entries (ENOSPC-парковка на полном HDD-target); ретрай pending-листа = опер-сигнал SIGUSR1 (reconcile_pending_wakeup) — дренаж подтверждён живьём (~240МБ/с, rw_pend 144М→18.8М секторов). Открытый остаток: автоматизация cron-USR1 — решение владельца; park-условия (needs_reconcile.rs update_reconcile_opts, plan.rs parks_on).

## Source

docs/f3-runbook.org:41 — ВЕРДИКТ Ф0, «Новая задача порта: аудит фоновых потоков (reconcile/compression/copygc)…» (хроника вердикта остаётся в org; задача мигрирована 2026-11-13).
