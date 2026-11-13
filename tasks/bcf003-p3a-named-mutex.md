---
id: "bcf003"
title: "P3a: поименованный мьютекс-фикс — spinlock_types.h → pthread_spin"
status: pending
priority: medium
effort: medium
dependencies: ["bcf001"]
tags: [port]
created_at: 2026-11-13
---

# P3a: поименованный мьютекс-фикс — spinlock_types.h → pthread_spin

## Objective

Семантика спина по P0-вердикту: статическая инициализация spinlock на FreeBSD = no-op (NULL-хендл → тихий EINVAL-лок; класс core 83736). Named mutex должен спинить честно: spinlock_types.h → pthread_spin. Инвариант: под spinlock не спят.

## Tasks

- [ ] overlay/files/include/linux/spinlock_types.h: pthread_spin-хендлы, инициализация реальная.
- [ ] rg-аудит: ноль sleep-подобных вызовов под spinlock-секциями.
- [ ] apply.sh с чистого клона — воспроизводимость.

## Acceptance Criteria

- [ ] apply.sh идемпотентен с чистого клона.
- [ ] rg-аудит sleep-under-spinlock: ноль попаданий.
- [ ] Acid-тест bcf001 зелёный с патчем в стеке.

## Source

P0-вердикт (runbook); класс core 83736; 069-комментарий spinlock_types.h.
