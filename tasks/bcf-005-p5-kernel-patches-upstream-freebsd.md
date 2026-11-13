---
id: "bcf-005"
title: "P5: кернел-патчи fuse_io/fuse_ipc в апстрим freebsd-src"
status: pending
priority: high
effort: medium
type: chore
tags: [upstream, kernel]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches/kernel/]
---

# P5: кернел-патчи fuse_io/fuse_ipc в апстрим freebsd-src

Оба патча живут в overlay/patches/kernel/ (воспроизводимо с 9218d0c/c426039):
- fuse_io-etimedout-fail-fast.patch — ETIMEDOUT на записи не должен молча ретраиться вечно (redirty-цикл)
- fuse_ipc-deadline-cap.patch — PCATCH msleep перезапускался с новым окном на каждый периодический сигнал (форма-4 wedge: поток никогда не видел ETIMEDOUT)
Путь: PR на github.com/freebsd/freebsd-src (или reviews.freebsd.org).
До отправки: сверить с текущим main fuse_ipc.c/fuse_io.c (наш /usr/src 15.1), приложить репродюс/обоснование из журнала (форма-4, стеки из китов), текст — по скиллу opensource-contribution (без AI-slop, evidence-first). Проверить дубликаты: багрепорты про fuse EINTR wedges в bugs.freebsd.org.

## Source

docs/f3-runbook.org:45 — org-заголовок «TODO P5: кернел-патчи в апстрим freebsd-src (sys/fs/fuse)» (мигрировано 2026-11-13).
