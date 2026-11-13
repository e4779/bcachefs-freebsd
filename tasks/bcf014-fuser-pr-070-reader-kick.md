---
id: "bcf014"
title: "PR: 070 SIGURG reader-kick → koverstreet/fuser (демон переживает umount -f)"
status: pending
priority: high
effort: medium
type: chore
tags: [upstream, fuser]
dependencies: ["bcf013"]
created_at: 2026-11-13
context: [overlay/files/, docs/f3-runbook.org, docs/evidence/core-69055-umount-hang/]
---

# PR: 070 SIGURG reader-kick → koverstreet/fuser

Апстрим-PR с фиксом liveness: FreeBSD доставляет FUSE_DESTROY ровно ОДНОМУ читателю на общем fd — остальные спят в read(2) вечно (Linux шлёт ENODEV всем). Наш фикс: блокирующий read + EINTR-чек флага; Destroy-arm ставит флаг и пинает всех зарегистрированных читателей `pthread_kill(SIGURG)` с no-op хендлером БЕЗ SA_RESTART — read возвращает EINTR, поток видит флаг, выходит. Нулевая стоимость на запрос. Живо проверено: `umount -f` → демон вышел сам за ≤4с.

## Материал

- Правки: fuser-vendored/{channel.rs, session.rs} + зеркала в overlay/files (коммит b1a110f, патч 070).
- Diagnosis evidence: core 69055 (docs/evidence/core-69055-umount-hang/) — стеки читателей в read(2) после Destroy.
- История v1 (poll+флаг) не сработала — общий fd: poll готов для всех до Destroy; в PR не включать, но в описании упомянуть почему выбран kick-подход.

## Шаги

1. Дифф против main koverstreet/fuser (ветка destroy-before-reply уже в форке — сверить базу, не тащить лишнее).
2. Проверить дубли в трекере koverstreet/fuser и cberner/fuser issue #29 (BSD-тема) — кросс-ссылки.
3. Текст PR по скиллу opensource-contribution: evidence-first (стеки, репродюс umount -f), без AI-slop.
4. **Ссылка на проект** https://github.com/e4779/bcachefs-freebsd как мотивация (прод-догфудинг bcachefs FUSE на FreeBSD).

## Definition of done

- PR открыт, ссылка записана в задачу (`--add-pr`), CI/фидбек отслежен.

Корпус: docs/notes/upstream-corpus-2026-11-13/ + topics (maintainer-tone-fuser-fusefs-2026-11 — тон апстрима, freebsd-contribution-path-2026-11).

## Source

docs/f3-runbook.org:14 «070 не в koverstreet/fuser»; решение владельца 2026-11-13 (трек публикации).
