# P4 телеметрия пула — план-of-record (мемо, переехало из tasks/bcf004 2026-11-13)

Консилиум 2026-11-06; хроника вердиктов — docs/f3-runbook.org.

## Стадии

- **Ф0 (закрыт 2026-11-07)**: SIGINFO-дамп accounting 24ч под прод — ГЕЙТ ЦЕЛИ пройден: инфраструктура телеметрии работает (ring 60с, 0 инцидентов за ночь).
- **Ф1 (доставлен)**: A+ снапшот-кольцо `/var/run/bcachefs-fuse/<uuid>/` — свежесть ts/gen/pid/uuid, провенанс live|snapshot, атомарная запись, fstype-гейт, handle.rs fallback. Дашборд-ценность ~90% hlmon.
- **Ф2 (B-lite): НЕ строим.** Триггеры пересмотра: инцидент-часы до зрелости A+; C-full отклонён/стоит 2+ спринта; RCA lost-WRITE блокирует окна.
- **Ф3 (= tasks/bcf004)**: C-lite restricted, фикс-размеры only — апстрим-подарок freebsd (TODO у них в дереве).
- **Ф4 (C-full): явное перепринятие решения** — владеет security-напряжением RETRY/UNRESTRICTED.

## КОНТРФАКТ (проверен синтезом, receipts)

`_IOC_SIZE(cmd) QUERY_ACCOUNTING` несёт ТОЛЬКО фикс-запись (32B/160B) — метрики тиринга едут flex-array ⇒ restricted-only вариант НЕ доставит цель: CLI молча получит пустые метрики. Записи консилиума: mesh council/2026-11-06-15-39-18/reports; спеки: docs/notes/p4-b-lite-spec.md, docs/notes/p4-c-lite-design.md.

## Инварианты Ф1

Без unwrap (rctl-SIGKILL = смерть маунта!), mem_read (не locked), nice, stale-должен-выглядеть-stale, снапшот не становится единственным воркером.

## Cut

Mutating-ioctl навсегда (DATA/FSCK_ONLINE/DISK_*), fs top/timestats — вне решения, «stock CLI end-to-end» — не планка приёмки.

## Фальсификаторы

Счётчики мёртвые под нагрузкой ⇒ цель недействительна, задача = инструментация; апстрим + RETRY-прототип на стейдже ⇒ C-full обратно, B-lite в отставку.
