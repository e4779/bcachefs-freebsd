# 01 — План спринта A: bcachefs-tools+FUSE на FreeBSD

> Решение: homelab runbook 18 §8 (A = прототип; D = прод до полной приёмки). Цель спринта: **FUSE rw-маунт тестовой ФС нашей сборкой + бенчмарк метаданных против моста**. Всё, что дальше (ro живого пула, публикация) — отдельные решения.

## Гейты

| Гейт | Условие | Фаза |
|---|---|---|
| **G0** | `bcachefs version` (наша сборка) работает на FreeBSD | P0 |
| **G1** | format→fsck→fill→verify roundtrip на тестовом образе userspace-инструментами | P1 |
| **G2** | FUSE rw-маунт тестовой ФС: pjdfstest зелёный, хардлинк-паттерн живёт | P2 |
| **G3 (выход)** | метаданные (sync-create) статистически лучше 12.8 мс/файл NFS-моста; ноль артефактов корректности | P3 |

Kill-критерии (из §8): форк fuser не собирается с `libfuse` и обход >2 недель; метаданные не лучше моста; ошибки чексумм при ro-чтении чистого пула.

## Фазы и задачи

### P0 — Почва (сборка)
- **T01 clone-tools** (0.5h): клон koverstreet/bcachefs-tools → `tools/` (gitignored). deps: —
- **T02 deps-audit** (1h): INSTALL.md/Makefile → таблица зависимостей «порт/отсутствует/заглушка», отчёт `docs/notes/02a-deps.md`. deps: T01
- **T03 deps-install** (0.5h + человек): `pkg install` по списку T02 (базовый список в 02-port-and-env.md). deps: T02. **Гейт человека: утвердить список pkg.**
- **T04 build-c** (2–6h): `gmake` C-часть; все поломки → патчи в `overlay/`, логи `docs/notes/04a-*.md`. deps: T03
- **T05 build-rust** (1–3h): `cargo build`; фетч форка fuser. deps: T03
- → **G0**

### P1 — Тестовая ФС (userspace)
- **T06 test-image** (1h): образ 2G + mdconfig + `bcachefs format` нашей сборкой. deps: G0
- **T07 fsck-roundtrip** (1–2h): fsck чистого; fill→fsync→fsck→read-back→verify; итерации. deps: T06
- → **G1**

### P2 — FUSE
- **T08 fuse-up** (0.5h): `kldload fusefs`; контрольный тест: собрать порт `fusefs-ufs`, примонтировать образ UFS — доказывает ядерный слой без нашего кода. deps: T03
- **T09 fuser-port** (2–8h, главный риск): форк fuser Кента с фичей `libfuse` против fusefs-libs3; патчи → `overlay/`; отклонения от лекала fuse-ufs фиксировать. deps: T03
- **T10 fuse-ro** (1–3h): `bcachefs mount -o fuse` ro тестовой ФС; обход find/tar; pjdfstest ro-группа. deps: G1, T08, T09
- **T11 fuse-rw-testfs** (2–4h): rw ТОЛЬКО тестовая ФС; pjdfstest полный; симуляция ed2k-фермы (create/link/rename шторм). deps: T10
- → **G2**

### P3 — Бенчмарк
- **T12 bench-harness** (2h): `bench/` скрипты: sync-create, rename-storm, deep-readdir, seq r/w; прогон на FUSE-маунте. deps: G2
- **T13 bench-report** (1h): `docs/notes/bench-2026-11.md`, сравнение: мост 12.8 мс/файл, sshfs 1.2 мс, FUSE-bcachefs — ?. deps: T12
- → **G3**

### P4 — Пост-спринт (отдельные решения, НЕ входит в A)
- ro-маунт живого пула: требует остановки bcachefsbox (диски заняты ВМ) → окно обслуживания; решение с владельцем.
- Публикация: форк bcachefs-tools (ветка freebsd) + PR'ы Кенту; патчи overlay/ конвертируются в PR.

## Рой

- Доска: mesh `runs/sprint-a/tasks/<id>` (fabric-swarm: CAS-клеймы `ifVersion`, статусы ready/blocked/doing/done, зависимости).
- Роли-актёры: **builder-c** (T04,T06), **rustacean** (T05,T09), **tester** (T07,T10,T11), **bench** (T12,T13). Короткие задачи — workflow-батчами, длинные — акторами.
- Эксклюзивы оркестратора: гейты G0–G3 (верификатор `{passed, reason, nextAction}`), коммиты, T03 (pkg — с человеком), всё, что касается homelab/прода.
- Отчёты воркеров: `docs/notes/` + mesh-дайджест; после каждой фазы — compact сессии (контекст живёт в файлах).

## Сводка бюджета

Σ активной работы ≈ **15–34 фокус-часа**; критический путь T01→T02→T03→T04/T05→G0→T06→T07→T10(≤T09,T08)→T11→T12→T13. Пик неопределённости: T04 и T09.
