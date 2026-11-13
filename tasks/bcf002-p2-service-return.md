---
id: "bcf002"
title: "P2: возврат отложенных сервисов после стабилизационного пакета (qbt, amuled svcj)"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001", "bcf024"]
tags: [ops, soak]
created_at: 2026-11-13
---

# P2: возврат отложенных сервисов после стабилизационного пакета (qbt, amuled svcj)

## Objective

После лендинга P1a (bcf001) + P3b (bcf024) вернуть на прод то, что снималось ради стабилизации. Жёсткий факт: перезапуск qbt = 3/3 livelock — премиса «retry-фикс поможет» не доказана до лендинга bcf001. f3-heal задеплоен и валидирован (факт, детали в git-журнале) — открытая часть задачи только возврат сервисов и sunset.

## Tasks

- [ ] qbt обратно в boot-цепь со staggered fastresume (bcf024).
- [ ] amuled вернуть под svcj (поглощено из bcf006; автостарт).
- [ ] Sunset-критерий f3-heal: сформулировать и записать.

## Acceptance Criteria

- [ ] qbt 48ч: ноль wedge, poolwatch perr=0.
- [ ] amuled работает jailed (svcj), переживает ребут.
- [ ] Sunset f3-heal записан (предложение: 2 недели без инцидентов → снять или оставить — решение владельца).

## Source

Runbook консилиум 2026-11-06; bcf006 (поглощена, cancelled).
