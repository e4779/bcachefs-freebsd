---
id: "bcf017"
title: "Порт скилла fabric-council в pi-etc: council на нативном subagent"
status: cancelled
priority: medium
effort: medium
dependencies: []
tags: ["skills", "pi-etc", "orchestration"]
created_at: 2026-11-13
context: ["~/projects/pi-fabric/skillsets/python/fabric-council/SKILL.md"]
cancelled_at: 2026-11-13
---

# Порт скилла fabric-council в pi-etc: council на нативном subagent

## VERDICT (владелец, 2026-11-13): ОТМЕНЕНА

Сравнение показало: скиллы отличаются незначительно, процесс немного другой — суть та же. council-mode покрывает; порт смысла не имеет. **Adopted replacement (владелец, 2026-11-14): pi-subagents council-mode skill** — зарегистрирован как механика консилиума в bcf013 (зависимость bcf013 → bcf017 кодирует это решение в графе); места council-* — bcf020; dry-run обкатан (memo docs/notes/council-dryrun-070-memo-2026-11-14.md). Уникальные fabric-механики (mesh-паркинг отчётов, per-run model/thinking оверрайды) сейчас не нужны. Триггер пересмотра: появится потребность в кросс-сессионном паркинге отчётов или per-run моделях мест — открыть НОВУЮ задачу, эту не реанимировать.

## Objective

Перенести механику консилиума из fabric-эры в текущий контур. Прокопано 2026-11-13: в pi-subagents (npm, vendor) УЖЕ есть скилл **council-mode** — протокол консилиума на нативном subagent. Слепой порт НЕ нужен; задача — сборка из двух половин и авторство мест.

## Что уже есть (сравнение — см. журнальную запись 2026-11-13)

- **council-mode** (протокол): персистентные профили `council-*` (2–3, max 4), 3-pass cap, cross-exam через resume с курируемыми challenge-пакетами, родитель курирует claims (≤5 на место), строгий memo, pass-contracts outputSchema. НЕ хранит отчёты сам, НЕ умеет per-run model/thinking оверрайды (stance живёт в профиле).
- **fabric-council** (py/ts, pi-fabric): 3–8 произвольных ролей per-run ({role, model, thinking}), mesh-паркинг отчётов (runId, ifVersion=0, ретраи), синтез отдельной моделью в одном fabric_exec.
- **Старые места fabric-консилиума**: shell-lab-old/docs/council/council-seat-1..5.md — готовые stance'ы для профилей.
- **На hlab сейчас**: ноль профилей `council-*` (только Explore/researcher/rust-coder/script-kiddie/skeptic) — council-mode уйдёт в fallback oracle/reviewer.

## Work

- [ ] Профили для ЭТОГО проекта выделены в bcf020 (не дублировать здесь); bcf017 — только общая механика: паркинг, оверрайды, записка «когда консилиум».
- [ ] Паркинг: fabric-механику mesh (runId + ifVersion=0) перевести на файлы (`tmp/council/<ts>/`), или принять, что council-mode достаточно (run id'ы в memo) — по итогам сухого прогона.
- [ ] Если council-mode не покрывает per-run model/thinking оверрайды — расширить profiles или скилл-обвязку в pi-etc (НЕ форк npm-пакета).
- [ ] Записка в pi-etc: когда консилиум, когда одиночный skeptic (всякая проверка — не консилиум); связка с bcf013.

## Acceptance Criteria

- [ ] Консилиум 3 мест на тестовом вопросе проходит по протоколу council-mode: pass1 receipts, cross-exam, memo с run id'ами.
- [ ] Профили мест переживут обновление pi-subagents (не в vendor-каталоге).
- [ ] Профильтр+записка закоммичены в pi-etc.

## Source

Решение владельца 2026-11-13 («раньше пользовал fabric-council, перенеси в pi-etc и адаптируй»), уточнено 2026-11-13 после сравнения с council-mode.
