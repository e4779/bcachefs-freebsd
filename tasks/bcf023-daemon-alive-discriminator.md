---
id: "bcf023"
title: "P1c: дискриминатор daemon-alive при wedge — evidence-гейт для баг-репорта"
status: blocked
priority: high
effort: small
dependencies: []
tags: [evidence, wedge]
created_at: 2026-11-13
---

# P1c: дискриминатор daemon-alive при wedge

## Objective

Один прогон при следующем живом wedge делит виновных надвое: демон служит → ядро (redirty-no-redrive, материал bcf015); демон не служит → наш reply-path (bcf022). Без этого прогона bcf015 — голословие, апстрим не примет.

## Tasks

- [ ] При wedge: procstat -k демона ДО любого ресета (scar-рецепт из AGENTS).
- [ ] kill -INFO демона + снапшот ring (/var/run/bcachefs-fuse/).
- [ ] Probe daemon-alive: локальный запрос через маунт + webui ответ.
- [ ] Вердикт — ops-коммитом в рунбук (Refs: bcf023).

## Acceptance Criteria

- [ ] Вердикт «демон служит / демон не служит» записан с выводом команды (не мнением).
- [ ] bcf015 разблокирован или закрыт как неподтверждённый.

## Source

tasks/bcf001 (исходная формулировка дискриминатора); core 69055 как образец evidence.
