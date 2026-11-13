---
id: "bcf022"
title: "P1b: fuser reply-path hardening — destroy-before-reply, writev retry, watchdog"
status: pending
priority: high
effort: large
dependencies: ["bcf001"]
tags: [port, wedge, fuser]
created_at: 2026-11-13
---

# P1b: fuser reply-path hardening — destroy-before-reply, writev retry, watchdog

## Objective

Reply-path переживает смерть клиента и медленный диск. Три механики одним пакетом: destroy-before-reply (fuser#757; ветка destroy-before-reply уже в форке koverstreet — перенести), writev bounded retry (5×10ms на EAGAIN/EWOULDBLOCK/EINTR/ENOMEM), reply-registry + watchdog + reader-heartbeat. Escape-коды сверить с fuse_io.c.

## Tasks

- [ ] Проверить: destroy-before-reply возможно УЖЕ в vendored (Cargo pins @8819589) — не портировать то, что есть.
- [ ] Перенести destroy-before-reply из ветки форка, сверить с fuser#757.
- [ ] writev bounded retry в channel.rs.
- [ ] Reply-registry/watchdog/reader-heartbeat в session.rs.
- [ ] Тест: искусственная смерть клиента под нагрузкой; umount -f под нагрузкой.

Материал: fuser-vendored/{channel.rs,session.rs}; core 69055 (читатели вечно в read(2) после Destroy — 070 лечит только umount -f, это общий случай).

## Acceptance Criteria

- [ ] umount -f под нагрузкой: ноль висящих читателей (procstat).
- [ ] Смерть клиента: reply-path освобождается ≤1с.
- [ ] Sync disk IO одного запроса не блокирует ответы других.

## Source

Runbook Shape-1 (close-шторм → reply-path failure → брошенный мьютекс); fuser#757; core 69055.
