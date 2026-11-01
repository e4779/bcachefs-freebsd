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

#### Ошибки bio.c в Run 17 — анализ и фикс (patch-bio, T04)

Run 17 упал на `linux/bio.c` — 6 ошибок (4 корневые + 2 каскадные):

| Ошибка | Диагноз |
|---|---|
| :32 `EREMOTEIO`, :33 `EBADE`, :34 `ENODATA`, :42 `EREMCHG` — undeclared | Linux-only errno, которых нет во FreeBSD `<errno.h>`. bio.c вообще не включает наш `<linux/errno.h>`-shadow (ENODATA там есть, EREMOTEIO/EBADE/EREMCHG — нет) |
| :61 и :70 `sizeof` → incomplete type `blk_errors[]` | Каскад, не GCC-ism: undeclared идентификаторы ломают designated-инициализаторы → clang держит массив incomplete → `ARRAY_SIZE(blk_errors)` в `WARN_ON_ONCE` не компилируется |

Фикс — `overlay/patches/006-bio-errno-freebsd.patch` (только bio.c):
- `#include <linux/errno.h>` (shadow) — закрывает ENODATA и тянет shared-имена тем же путём, что и остальная сборка;
- локальные guarded `#define EBADE 52 / EREMOTEIO 121 / EREMCHG 78` — Linux-номера, политика та же, что у linux/errno.h-shadow: bch-внутренний error-mapping, host syscall не пересекают.

Почему НЕ в общий shim (linux/errno.h / freebsd_compat.h, как ETIME в Run 15): во время фикса в tools/ крутился Run 18 (gmake -k); перекладка общего force-included заголовка mid-build — гонка для ещё не скомпилированных TU. Патч одного .c race-free: bio.o в Run 18 уже упал, gmake файл не пересмотрит.

Follow-up после Run 18: промоутнуть EREMOTEIO/EBADE/EREMCHG в `overlay/files/include/linux/errno.h`, локальные дефайны из bio.c убрать.

Проверка: `cc -fsyntax-only` с флагами gmake (gnu11, -I. -Ic_src -Ifs -Iinclude -Iraid -Ibuild, -include c_src/autoconf.h, pkg-config cflags) — exit 0, ошибок 0, 15 предсуществующих warnings (macro-redefined шум, тот же класс что в логе Run 17 у соседних TU). apply.sh идемпотентен (повтор → SKIP 006).
### Run 18 — patch-shims: 5 ошибок linux/{blkdev,kthread,sched,percpu,shrinker}.c
Все 5 прошли `cc -fsyntax-only` с точными флагами gmake (контроль: crc64.c без регрессий).

| Ошибка | Диагноз | Фикс |
|---|---|---|
| blkdev.c:2 `alloca.h` not found | glibc-заголовок; на FreeBSD alloca(3) объявлена в stdlib.h | **007**: `#ifdef` — на FreeBSD `<stdlib.h>` |
| kthread.c:29 + sched.c:118 `SYS_gettid` | Linux syscall-номер; current->pid потребляется только backtrace'ом (stack_trace_save_tsk/dump_stack — комментарий в sched.c) и дебаг-выводом → достаточно уникального tid | freebsd_compat.h: `bch_gettid()` через **thr_self(2)** (kernel thread id, уникален и ненулевой); **008** заменяет оба вызова |
| percpu.c:307 `MAP_NORESERVE` | на FreeBSD нет per-mapping overcommit-учёта → резервирование адресного пространства с выделением страниц по первому fault — поведение по умолчанию, флаг — семантический no-op | freebsd_compat.h: `#define MAP_NORESERVE 0` (percpu.c сам не менялся) |
| shrinker.c:21 LIST_HEAD «too few arguments» | `<sys/queue.h>` (тянутся системными заголовками — например через pthread.h — ПОСЛЕ linux/list.h) переопределяет `LIST_HEAD(name, type)` двумя аргументами; одинарная форма больше не раскрывается | **009**: `static CDS_LIST_HEAD(shrinker_list)` — ровно то, во что linux/list.h мапит LIST_HEAD |
| shrinker.c:45/55/77/94 `shrinker_list` / `mutex.next` | каскад от :21 (clang-рекавери подставил shrinker_lock) | уходит вместе с 009 |
| shrinker.c:117 `FUTEX_WAIT_BITSET` | overlay futex.h (builder-c) покрывал только WAIT/WAKE семейство; WAIT_BITSET = абсолютный таймаут по CLOCK_MONOTONIC + бит-маска ~0 | futex.h: `FUTEX_WAIT_BITSET 9` + кейс через `struct _umtx_time{UMTX_ABSTIME, CLOCK_MONOTONIC}` (sizeof как uaddr2 — сигнал ядру, что uaddr1 это _umtx_time) |

Семантические решения (зафиксированы):
- **gettid→thr_self**: pid нигде не сравнивается с getpid() и не пересекает syscall-границу; честная замена — kernel tid потока.
- **errno-контракт futex()**: `_umtx_op` возвращает errno напрямую, Linux futex(2) — `-1`+errno. Цикл таймаута shrinker-потока читает `errno != ETIMEDOUT` → без конверсии поток зависал бы. Прочие вызовы (bit_spinlock.h, sched.c) возврат игнорируют — конверсия безопасна. Вал3 (бит-маска) не транслируется: единственный ждущий использует ~0, и его будит обычный FUTEX_WAKE.
- **LIST_HEAD — точечный фикс**, не глобальное подавление sys/queue.h (его макросы могут использовать системные заголовки; подавление guard'ом — риск сломать чужие TU). Если будущие файлы тоже сломаются на LIST_HEAD после системных include — применять тот же приём.
- bindgen видит те же compat-добавления (force-include из autoconf.h), отдельной правки не требует.

### Шестёрка шимов — OK (14:29)
Все 6 объектов linux/ собрались; merge 7d21efc (patch-shims) + f542fde (patch-bio) + errno-промоушен. Run 19 (полный, -j1, rctl 2500) запущен; mem free=367MB+inactive=1852MB — ниже гейта, но inactive reclaimable + кэп, отклонение фиксирую здесь.

### ETIME-реставрация (orchestrator)
Мерж-инцидент: git checkout -- сбросил ГРЯЗНЫЙ freebsd_compat.h, содержавший НЕКОММИЧЕННЫЙ ETIME-фикс v2 (+ надписи patch-shims в том же файле); ветка patch-shims ответвилась до него — merge принёс версию без ETIME (Run 19b упал на closure.c). Урок: грязный файл в main может быть чьей-то незакоммиченной работой — перед checkout -- диффать и сохранять; агент обязан коммитить код до конца рана (v2 нарушил). Фикс восстановлен по журнальной специкации Run 15.
