---
id: "bcf020"
title: "Места council-* внутри проекта (.pi/agents/): stance'ы под ревью порта"
status: pending
priority: medium
effort: medium
dependencies: ["bcf018", "bcf019"]
tags: ["skills", "council", "review"]
created_at: 2026-11-13
context: ["tasks/bcf013-prepublication-patch-review.md", "tasks/bcf017-council-skill-port.md", "tasks/bcf018-upstream-corpus.md", "tasks/bcf019-quality-standards-research.md"]
---

# Места council-* внутри проекта (.pi/agents/)

## Objective

Проектные (не пользовательские) профили советников для council-mode — под ревью патчей этого проекта (bcf013) и будущие архитектурные споры. Возможность подтверждена: council-mode ищет `council-*` в user ИЛИ project agent-каталогах; здесь — `~/projects/bcachefs-freebsd/.pi/agents/` (сейчас пуст). Зависимость от корпуса (bcf018) и стандартов (bcf019) — потому что stance мест должен опираться на материал, не на вкус.

## Roster (кандидаты, council-mode: max 4)

1. **council-style** — стиль и конвенции FreeBSD src: style(9), формат commit'ов, ожидания ревью sys/fs. Кормится темами bcf019.
2. **council-skeptic** — adversarial по нашему журналу: evidence-first, каждое утверждение с receipts из docs/evidence и runbook; ловит «навайбкодил»-слабости в патчах.
3. **council-maintainer** — эмуляция тона мейнтейнера fuse(4)/fuser: минимальный дифф, риски регрессий, вопросы «зачем это в апстриме»; кормится корпусом bcf018 (прошлые обсуждения, ai-policy рамка).
4. **council-ops** — прод-перспектива: догфудинг-факты (f3-heal, poolwatch, форму wedge), влияние патча на работающий пул. Опционально — включать при спорах об ops-эффектах.

## Work

- [ ] Профили `council-*.md` в `.pi/agents/`: модель, tools (read-only набор), context, stance в теле — по формату council-mode/pass-contracts.
- [ ] Нюанс git (решение владельца 2026-11-13: «давай добавим»): профили трекуем в git — `git add -f .pi/agents/`; stance'ы живут в репо, восстановление = checkout. Дубль в pi-topics не нужен.
- [ ] Сухой прогон: pass 1 на реальном патче (070 SIGURG-kick) с 2–3 местами — receipts, споры, memo.
- [ ] Регистрация мест как доступных для bcf013 (обновить его Метод: консилиум = эти места).

## Acceptance Criteria

- [ ] `subagent({action:"list"})` видит места; council-mode запускается без fallback oracle.
- [ ] Memo сухого прогона приложен к журналу (Refs: bcf020).
- [ ] Stance'ы закоммичены (`.pi/agents/` форс-адд вопреки gitignore), переживают переезд через git.

## Source

Решение владельца 2026-11-13 («после сбора корпуса — создать субагентов council-* внутри текущего проекта»).
