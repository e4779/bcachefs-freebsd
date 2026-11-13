---
id: "bcf003"
title: "P3: поименованный мьютекс-фикс, staggered fastresume qbt, Ф4-дрели"
status: pending
priority: medium
effort: large
type: bug
dependencies: ["bcf001", "bcf002"]
tags: [port, soak]
created_at: 2026-11-13
context: [docs/f3-runbook.org]
---

# P3: поименованный мьютекс-фикс, staggered fastresume qbt, Ф4-дрели

В org заголовок был без тела. Контекст: поименованный мьютекс-фикс — семантика спина (P0-вердикт: spinlock_types.h → pthread_spin, оверлей overlay/files/include/linux/spinlock_types.h; под spinlock не спят); staggered fastresume — против детерминированного close-шторма qbt (711 fastresume = шторм close/release/forget, kit 092614); Ф4-дрели — C-full телеметрия (RETRY/UNRESTRICTED, явное перепринятие решения, см. bcf004).
Модель форм wedge и дискриминаторы — Council 2026-11-06 в docs/f3-runbook.org.

## Source

docs/f3-runbook.org:36 — org-заголовок «TODO P3: поименованный мьютекс-фикс, staggered fastresume qbt, Ф4-дрели» (мигрировано 2026-11-13).
