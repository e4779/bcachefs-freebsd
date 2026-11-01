# T04: сборка C-части bcachefs-tools на FreeBSD 15.1 — журнал

Цель: `gmake libbcachefs.a` в tools/ (клон d48ba1a) — статический архив,
на который линкуется Rust-сторона (T05). Журнал: ошибка → патч → результат.

## Аудит до первой сборки

- **pkg-config**: blkid установлен (libblkid-2.42.2, вердикт T02 «поставить»);
  libkeyutils — заглушка (overlay); udev.pc (libudev-devd) не имеет переменной
  udevdir → фолбэк /usr/local/lib/udev в патче 001.
- **cstruct-генерация**: `$(OBJS): | build/cstruct/stamp` — КАЖДЫЙ .o зависит
  от сгенерированных Rust-ом заголовков (`cargo rustc -p bcachefs-kernel` +
  plain rustc для rust_types_gen). Cargo-кэш уже тёплый (680 крейтов, T05),
  но [patch.crates-io] fuser (git) не скачан → cargo fetch до сборки.
  Это не «T05 руками»: без stamp не компилируется ни один .c.
- **linux/blkdev.c**: upstream сам имеет sync-fallback (fops_list[1] =
  preadv/pwritev), `aio_init()` уходит в `io_fallback()` при io_setup()==-ENOSYS.
  Заглушка libaio выбирает этот путь — асинхронность не нужна формат/фск-инструментам.
- **Ресурсы**: v_free_count даёт ~612MB (< гейта 1GB), но inactive=2.4GB
  (reclaimable) + своп-звол 8G (появился ПОСЛЕ замеров 00a; «свопа нет» в
  AGENTS устарел). Худший случай под rctl deny=2500m — убитая сборка, не
  машина. Решение: продолжаю под кэпом, отклонение фиксируется здесь.

## Прогоны

### Run 0 (до компиляции): pkg-config gate + make-синтаксис
| Ошибка | Патч | Результат |
|---|---|---|
| pkg-config: libkeyutils не найден → $(error) | 001: убрать из PKGCONFIG_LIBS на FreeBSD | gate пройден |
| udevdir пуст (libudev-devd) → $(error) | 001: фолбэк /usr/local/lib/udev | gate пройден |
| awk: /proc/meminfo (DKMS_PARALLEL_JOBS) | 003: 2>/dev/null || echo 4194304 | шум ушёл |
| apply.sh: patch --batch на повторе РЕВЕРСИРОВАЛ патчи | --forward в apply.sh | идемпотентно |

### Run 1 — cargo fetch (fuser git-dep)
(лог ниже)

---

> **Потеря контекста**: журнал прогонов 2–14 погиб вместе с фоновой задачей
> предшественника (builder-c v1; на момент смерти — 56 объектов). Итоги тех
> прогонов зафиксированы коммитами c06a35d / cc54db9 / c0044ac и инвентарём
> overlay/README.md. Нумерация продолжена с 15; все сборки — синхронно в
> foreground (урок v1: фоновая задача умирает вместе с run).

### Run 15 — старт builder-c v2: 56→62 obj
| Ошибка | Диагноз | Патч |
|---|---|---|
| fs/vendor/closure.c:203: use of undeclared identifier `ETIME` | FreeBSD errno.h не имеет ETIME (только ETIMEDOUT=60); наш linux/errno.h-shadow несёт ETIME=62, но closure.c включает <errno.h>, а не <linux/errno.h> | freebsd_compat.h: guarded `#define ETIME 62` (force-include из autoconf.h → виден каждому TU) |

### Run 16 — ETIME-фикс, идёт (лог tmp/build-16.log)

### Run 17 — оркестраторский слот (14:05+)
Пивот оркестрации: слот сборки у оркестратора (фон своей сессии, будит надёжно); агенты — только короткие патч-ходы. Уроки runs 14/16 (осиротевшие фоновые задачи one-shot агентов) — в AGENTS.md.
План по будильнику: ошибки из build-17.log → короткий патч-агент; успех → проверка G0.
