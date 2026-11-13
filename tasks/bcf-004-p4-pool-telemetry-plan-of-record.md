---
id: "bcf-004"
title: "P4: телеметрия пула — план-of-record Ф1/Ф2/Ф3/Ф4 (консилиум 2026-11-06)"
status: blocked
priority: medium
effort: large
type: feature
tags: [port, telemetry]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/notes/p4-b-lite-spec.md, docs/notes/p4-c-lite-design.md]
---

# P4: телеметрия пула — план-of-record Ф1/Ф2/Ф3/Ф4 (консилиум 2026-11-06)

КОНТРФАКТ (синтез проверил сам, receipts): _IOC_SIZE(cmd) QUERY_ACCOUNTING несёт ТОЛЬКО фикс-заголовок (32B/160B) — метрики тиринга едут flex-array => restricted-only FUSE_IOCTL (вариант C как заявлен) НЕ МОЖЕТ доставить цель: CLI молча получит пустые метрики. C-full (RETRY/UNRESTRICTED) = рост scope 3-5x. Записи консилиума: mesh council/2026-11-06-15-39-18/reports; спеки: docs/notes/p4-b-lite-spec.md, docs/notes/p4-c-lite-design.md.
План-of-record: Ф0 (часы, ГЕЙТ ЦЕЛИ): SIGINFO-дамп accounting/counters из демона, 24ч под прод-нагрузкой — если reconcile_work мёртв, транспорт не нужен вовсе (закрыт: вердикт Ф0 от 2026-11-07 в runbook — инфра работает). Ф1 (дни): A+ = снапшот-кольцо /var/run/bcachefs-fuse/<uuid>/ (свежесть ts/gen/pid/uuid + провенанс live|snapshot, атомарная запись) + fstype-гейт + handle.rs fallback (~20 строк) — дашборд-ценность ~90% hlmon (инцидент 2х дней диагностировался трендом, не интерактивом). Ф2: B-lite spec-freeze (НЕ строим; триггеры: инцидент-часы до зрелости A+, C-full отклонён/стоит 2+ спринта, RCA lost-WRITE блокирует окна). Ф3: C-lite (restricted, фикс-размеры only) — отдельный трек, апстрим-подарок freebsd (TODO у них в дереве). Ф4: C-full — явное перепринятие решения (владеет security-напряжением RETRY/UNRESTRICTED).
Инварианты Ф1: без unwrap (rctl-SIGKILL = смерть маунта!), mem_read (не locked), nice, stale-должен-выглядеть-stale, снапшот не станит единственный воркер.
Cut: mutating-ioctl'ы навсегда (DATA/FSCK_ONLINE/DISK_*), fs top/timestats из решения, «stock CLI end-to-end» как планка приёмки.
Фальсификаторы: счётчики мёртвые под нагрузкой => цель недействительна, задача=инструментация; апстрим+RETRY-прототип на стейдже => C-full обратно, B-lite в отставку.

## Source

docs/f3-runbook.org:37 — org-заголовок «WAITING P4: телеметрия пула — план-of-record от консилиума…» (мигрировано 2026-11-13).
