---
id: "bcf007"
title: "Linux-кросс-валидация rw-записей порта (VM)"
status: cancelled
priority: low
effort: medium
type: chore
tags: [vm]
created_at: 2026-11-13
context: [docs/f3-runbook.org, bench]
cancelled_at: 2026-11-13
---

# Linux-кросс-валидация rw-записей порта (VM)

ОТМЕНЕНО 2026-11-13 (решение владельца): как отдельная задача — зомби. Суть перенесена в bcf013 (гейт перед апстрим-PR): паритет-эвиденс по требованию ревьюверов — probe-файл /mnt/pool/.f3-probe/f001-200mb.bin, сверка sha256 599b9472… против Linux-стороны (appliance или Linux-машина), fsck Linux-стороной. Дешёво возродить в рамках bcf013, если апстрим спросит.

## Source

docs/f3-runbook.org:66 — org-заголовок «WAITING Linux-кросс-валидация наших rw-записей» (мигрировано 2026-11-13).
