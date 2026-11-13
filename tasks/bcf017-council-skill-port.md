---
id: "bcf017"
title: "Порт скилла fabric-council в pi-etc: council на нативном subagent"
status: pending
priority: medium
effort: medium
dependencies: []
tags: ["skills", "pi-etc", "orchestration"]
created_at: 2026-11-13
context: ["~/projects/pi-fabric/skillsets/python/fabric-council/SKILL.md"]
---

# Порт скилла fabric-council в pi-etc: council на нативном subagent

## Objective

Перенести проверенный механику консилиума из fabric-эры в текущий контур (нативный pi, tool `subagent`, без fabric_exec/mesh). Владелец решением 2026-11-13: скилл живёт в pi-etc (свой репо — переживает обновления пакетов, в отличие от vendor-скиллов pi-subagents).

## Source material

- `~/projects/pi-fabric/skillsets/python/fabric-council/SKILL.md` (138 строк) и `.../typescript/fabric-council/SKILL.md` (191 строк).
- Ценные механики, которые сохранить: 3–8 ролей с осмысленными разногласиями (не дубли-ревьюеры), роль = строка или {role, model, thinking}; независимые отчёты + best-effort синтез; паркинг отчётов (в fabric — mesh, runId-база, ifVersion=0 create-only, ретраи коллизий).
- Записи прошлого консилиума по этому проекту: mesh council/2026-11-06-15-39-18/reports (см. bcf004).

## Adaptation (fabric → native pi)

- `agents.run`/`fabric_exec` → tool `subagent`: parallel workflow для мест, async для фоновых; синтез — отдельный шаг оркестратора (или llm-комплит).
- mesh-паркинг → файлы: отчёты мест в `tmp/` (или `.pi/`), синтез в git-журнал/doks — как решит владелец.
- Персоны/роли: project `.pi/agents/` + user `~/.pi/agent/agents/` (Explore, skeptic, researcher... — скилл pi-subagents описывает).
- Имя без «fabric»: `council` (в pi-etc skills/). Frontmatter по правилам скилла skill-author (валидатор).
- Ограничения текущего контура учесть: агентные бюджеты, без LLM-фонов вне workflow.

## Acceptance Criteria

- [ ] Скилл `pi-etc/skills/council/SKILL.md` проходит валидатор skill-author.
- [ ] Сухой прогон: консилиум из 3 ролей на тестовом вопросе — отчёты мест + синтез, всё через нативный subagent, ни одного fabric-артефакта.
- [ ] Записка в скилле: когда council, а когда одиночный skeptic/верификатор (не всякая проверка — консилиум).
- [ ] Связь с bcf013 упомянута: места ревью могут зваться этим скиллом.

## Source

Решение владельца 2026-11-13 («раньше пользовал fabric-council, перенеси в pi-etc и адаптируй под текущий сетап»).
