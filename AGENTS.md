# AGENTS.md — bcachefs-freebsd

Инженерный проект порта bcachefs-tools+FUSE на FreeBSD. Эксплуатационный контекст (прод-мост, шрамы, замеры) живёт в репо homelab — сюда не дублировать.

## Немодные константы (из консилиума, runbook 18 §8)

- **Живой пул (1.1T NVMe + 3.6T HDD, формат 1.39) не трогаем rw — никогда до полной приёмки.** Формат необратим (incompat-биты с 1.36), fsck существует только на Linux.
- Ro-mount живого пула — отдельное решение о риске, принимать на планировании спринта, не по ходу.
- Всё новое сначала на тестовой ФС (vn-образ / спойка).
- D (ВМ+NFS) — прод; этот проект не меняет прод до приёмки.

## Ключевые ссылки

- Решение/план: homelab `docs/freebsd/18-bcachefs-native-research.md` (особенно §4A, A-приложение, §8)
- Замеры моста (базовая линия): homelab `docs/freebsd/02-poc-bcachefsbox.md`
- Лекало порта: realchonk/fuse-ufs (fuser 0.16 + фича `libfuse` → fusefs-libs3 → mount_fusefs)
- Апстрим: koverstreet/bcachefs-tools (клон в `tools/`, gitignored), fuser-форк koverstreet/fuser (ветка destroy-before-reply)
- Upstream-тема BSD: cberner/fuser issue #29

## Раскладка

- `overlay/` — патчи/файлы поверх клона tools (пока не станет PR'ом)
- `bench/` — скрипты замеров; сравнение против NFS-моста (метаданные — главный налог, ×10.7)
- `docs/` — инженерные заметки спринта
- `tools/` — gitignored клон bcachefs-tools

## Правила

- Коммиты Conventional Commits; отдельные атомарные патчи под будущие PR.
- Каждое отклонение от лекала fuse-ufs фиксировать в docs/ с причиной.
- Rust на хосте 1.98 (нужно ≥1.85) — ок.
