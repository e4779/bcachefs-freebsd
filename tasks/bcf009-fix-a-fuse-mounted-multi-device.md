---
id: "bcf009"
title: "Fix A: fuse_mounted multi-device false-negative (boot-fail)"
status: completed
priority: medium
effort: medium
type: bug
tags: [port, boot]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches]
---

# Fix A: fuse_mounted multi-device false-negative (boot-fail)

fusemount.rs:2340-2375 сверяет f_mntfromname с одиночным путём девайса; на multi-device там склеенная строка /dev/nda0p3:/dev/ada1 => никогда true => здоровый маунт не распознан => arm "shutting down" => 300s => boot-fail.
Фикс: сверять по mntonname (маунт-поинт). Overlay-патч (059), пересборка tools, деплой без ребута (umount/remount + рестарт сервисов).
Завершено: задеплоен 2026-11-06 09:11 — маунт с первой попытки, проба цела (журнал Ф3 в runbook).

## Source

docs/f3-runbook.org:52 — org-заголовок «DONE Fix A: fuse_mounted multi-device false-negative» (мигрировано 2026-11-13).
