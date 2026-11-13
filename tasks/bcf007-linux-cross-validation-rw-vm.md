---
id: "bcf007"
title: "Linux-кросс-валидация rw-записей порта (VM)"
status: blocked
priority: low
effort: medium
type: chore
tags: [vm]
created_at: 2026-11-13
context: [docs/f3-runbook.org, bench]
---

# Linux-кросс-валидация rw-записей порта (VM)

Ждём: пересборка bcachefs-vm (параллельная сессия).
Затем: VM монтирует пул, fsck Linux-стороной, чтение /mnt/pool/.f3-probe/f001-200mb.bin — сверка sha256 599b9472… с обеих сторон.

## Source

docs/f3-runbook.org:66 — org-заголовок «WAITING Linux-кросс-валидация наших rw-записей» (мигрировано 2026-11-13).
