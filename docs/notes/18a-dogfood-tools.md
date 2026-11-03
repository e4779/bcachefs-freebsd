# 18a — Обзор инструментов для dogfood-движка (Task Ф2)

Read-only survey, без сборок и прогонов. Хост: hlab, FreeBSD 15.1-RELEASE-p5.
Вопрос: какие роли движка (дизайн совета 16a) закрываются готовыми
инструментами, что берём pkg'ом, что дешёвым мини-портом, что остаётся нашим
кодом. Источники: pkg-index 15.1, /usr/src, gh api (axboe/fio, kdave/xfstests,
kdave/fsx-fsstress, asomers/fsx-rs, pjd/pjdfstest, ColinIanKing/stress-ng).

## 1. Наличие

Установлено на хосте: ничего из списка (fusefs.ko загружен, юзерленд-тулов нет).

| Инструмент | Статус | Где / происхождение |
|---|---|---|
| fio 3.43 | в портах | benchmarks/fio; FreeBSD первоклассна: os/os-freebsd.h, engine posixaio |
| dbench 4.0 | в портах | benchmarks/dbench (Samba-профиль) |
| postmark 1.53 | в портах | benchmarks/postmark |
| stress-ng 0.20.00 | в портах | benchmarks/stress-ng |
| fsx-rs 0.3.2 | в портах | devel/fsx — Rust-переписывание Apple-fsx от asomers (мейнтейнер fusefs(4)!) |
| pjdfstest 0.2.2 | в портах | filesystems/pjdfstest; апстрим pjd/pjdfstest (383★, жив, 2026-08) |
| bonnie++ 2.00a | в портах | benchmarks/bonnie++ — избыточен при fio |
| iozone 3.510 | в портах | benchmarks/iozone — избыточен при fio |
| filebench 1.5-a3 | в портах | benchmarks/filebench — тяжёлый фреймворк, пропускаем |
| fsstress | ОТСУТСТВУЕТ | нет в портах; апстрим жёстко Linux — см. §3 |
| fsx (C, base) | base-дерево | /usr/src/tools/regression/fsx/fsx.c — Apple-оригинал (имп. в FreeBSD 5.0, dev-only, никуда не ставится) |
| — | base-tests | /usr/tests/sys/fs/fusefs — тесты fusefs(4) kernel-side: референс протокола, не нагрузка |

## 2. fio 3.43: что закрывает нативно

verify= (полный список из man): md5, crc64, crc32c (+crc32c-intel), crc32,
crc16, crc7, xxhash, sha512, sha256, sha1, sha3-224/256/384/512, meta, pattern.
Каждый блок получает заголовок (offset, номер блока, timestamp, seed) —
верификация всегда «заголовок + контент». Связка: verify=sha512 + verify_fatal=1
+ do_verify=1 (+ verify_async=N, verify_backlog=).

Фазовая ротация write-heavy → read-heavy: один job-файл с секциями, фазы
переключает наш оркестратор (fio сам их не ротирует):

    [phase-w]
    directory=/mnt/stage/dogfood  rw=randwrite  bs=1m  nrfiles=64  filesize=256m
    ioengine=posixaio  iodepth=4  verify=sha512  verify_fatal=1
    time_based=1  runtime=600
    [phase-r]
    directory=/mnt/stage/dogfood  rw=randread   bs=1m  nrfiles=64  filesize=256m
    ioengine=posixaio  iodepth=4  time_based=1  runtime=600

- nrfiles / filesize / openfiles / file_service_type=random — файловая постель;
  unlink=1 — зачистка после джоба.
- fill_fs=1: «size ставится огромным, ENOSPC/EDQUOT — условие завершения»
  (man) — готовый ENOSPC-препаратор для хаос-дрилла (только seq write).
- continue_on_error (man 3.43): продолжает job только на non-fatal EIO/EILSEQ —
  ENOSPC job всё равно роняет; в дрилле опираться на fill_fs, не на этот флаг.
- Телеметрия p50/p99: clat-percentiles в выводе + write_lat_log= /
  log_hist_msec= — per-job, не per-path.

FUSE-кейвты (наш стек fuser→fusefs(4)):
- движки: только sync/psync/posixaio (libaio/io_uring на FreeBSD нет);
- direct=1 требует FOPEN_DIRECT_IO от демона — нашим стеком не согласовывается:
  пишем buffered (writeback через FUSE_WRITEBACK_CACHE и так даёт честный путь);
- параллельность режется о max_background: fuser выставляет 16 (fuser
  src/lib.rs:230, дефолт; bcachefs не переопределяет) — iodepth>16 это очередь
  в ядре, не параллелизм. Мерить решёткой 1/4/8/16;
- buffered-write ошибки видны только на вымывании — man сам предупреждает
  (continue_on_error, Note): в критичных джобах добавлять fsync/fdatasync.

Гэпы fio (НЕ закрывает): hardlink/rename-операции отсутствуют вообще; контент
не адресуем как f(path,epoch) (seed-воспроизводимость внутренняя); корпус не
проверяем внешним верификатором (сентинелы 17a остаются); нет bcachefs-семантики
(extattr, chflags); нет фазовой ротации и хаоса.

## 3. Метаданные

- dbench 4.0 (Samba-профиль): loadfile client.txt — реалистичный SMB-профиль
  create/unlink/rename/mkdir + xattr + byte-range locks. Нулевая цена.
  Кейвты: xattr (extattr) и flock через наш FUSE-порт не проверялись — первый
  прогон = dogfood-находка, не блокер. Телеметрия грубая (per-op max latency),
  p50/p99 не даёт.
- postmark 1.53: малые файлы, транзакции create/delete/read/append; один поток,
  batch-cfg. Вторичный churn-источник, без verify.
- fsstress: в портах нет. Standalone-репо kdave/fsx-fsstress жёстко требует
  liburing.h, libaio.h, btrfsutil.h, linux/fiemap.h, sys/xattr.h (проверено по
  include-листу исходника) — порт = дни работы и вечный форк. Вердикт: NO-GO;
  random-op суп закрываем своим churner'ом (файловые штормы в regression.sh
  уже есть).
- fsx: три источника — (a) порт devel/fsx = asomers/fsx-rs: «on every read
  verifies the expected data», 100% seed-воспроизводимость, конфиг fsx.toml,
  активен (2026-09); (b) base /usr/src/tools/regression/fsx/fsx.c — Apple
  оригинал, собирается одним cc; (c) kdave/fsx-fsstress — Linux-only (libaio,
  io_uring). Берём (a) pkg'ом.
- pjdfstest (filesystems/pjdfstest): POSIX-семантика (mkdir/creat/rename/unlink/
  link/... через prove), FreeBSD-родной, дешёвый. Роль: bcachefs-semantic smoke
  через FUSE. Запускать подмножеством, root-кейсы (chown/chflags) отдельно.

## 4. stress-ng 0.20.00

--fsmode (список методов не подтвердить без man (стрессор-файл не найден по листингу; уточнить после pkg install — на вердикт не влияет: smoke-only)).
Роль: вспомогательный smoke по link/rename/lock-путям; не профильный: не
детерминирован, per-class телеметрии нет.

## 5. Rust-крейты (быстрый скан)

Готового fs-workload-харнеса нет. Реальное рядом:
- asomers/fsx-rs — см. §3 (единственный «настоящий» Rust-инструмент в нише,
  и уже в портах);
- mbuesch/disktest (Rust, 56★, жив) — integrity-тестер дисков/файлов
  PRNG-контентом; целые устройства, не иерархии путей — не наш случай.
Вывод: корпус/hardlink/оркестрация — свой код; выбор стека крейтами не диктуется.

## 6. Композиция: роль → инструмент

| Роль движка | Инструмент | Как | Кейвт |
|---|---|---|---|
| raw write + контент-verify | fio verify=sha512 | профиль §2 | buffered-only; iodepth≤16 (max_background) |
| read-heavy фаза | fio rw=randread | тот же корпус файлов, без unlink | percentiles per-job |
| ENOSPC-препаратор | fio fill_fs=1 (seq write) | перед хаос-дриллом | ENOSPC завершает job — это и нужно |
| samba-профиль | dbench client.txt | dbench 16 -c /usr/local/share/dbench/client.txt -t 900 -D <mnt>/db | xattr/flock через FUSE проверить до счёта |
| small-file churn | postmark (опц.) | batch-cfg | один поток, без verify |
| single-file adversarial | fsx-rs (devel/fsx) | fsx <mnt>/fsx.test (итерации/seed — флаги и fsx.toml, см. man fsx) | seed фиксировать в отчёте; mmap идёт через writeback |
| POSIX-семантика smoke | pjdfstest | prove -r (подмножество) | root-кейсы отдельно |
| metadata storm (random-op) | СВОЙ churner | — | fsstress NO-GO (§3) |
| корпус f(path,epoch) | СВОЙ (сентинелы 17a) | — | fio-контент наружу не адресуем |
| hardlink-ферма | СВОЙ | — | fio/dbench топологию линков не дают |
| chaos kill-9/SIGSTOP/ENOSPC | СВОЙ оркестратор | поверх работающих тулов | прецедент regression.sh --kill-drill |
| p50/p99 per-op-class | fio логи + СВОИ тайминги | write_lat_log, log_hist_msec + свои пер-оп замеры | fio per-job only |

Все сторонние инструменты — ТОЛЬКО внутри stage-session.sh (17a): канарейка
L0/L1 ловит зависания демона, сентинел L2 — дрифт данных, rctl-кап — память.
Ошибки самих тулов = dogfood-находки, не красная ночь (кроме L2/fsck).

## 7. buildVsReuse

- Reuse как есть (pkg install, ноль сборок): fio, dbench, fsx-rs, pjdfstest;
  опционально postmark, stress-ng.
- Мини-порт: не нужен — base fsx.c не требуется при fsx-rs; свой churner — это
  код движка, не порт.
- Не тратим: fsstress (Linux-bound), filebench (роли закрыты fio+dbench),
  bonnie++/iozone (дублируют fio, слабее verify).
- Наш код остаётся: корпус f(path,epoch), hardlink-фермы, фазовая ротация,
  хаос-дриллы, per-class телеметрия, bcachefs-специфика.

## 8. Сверка источников

- pkg-index 15.1 (pkg search, 2026-11-06): версии в §1; origins fsx=devel/fsx,
  pjdfstest=filesystems/pjdfstest (freebsd-ports@HEAD).
- /usr/src/tools/regression/fsx/{Makefile,fsx.c} — Apple-копирайт 1998–2001,
  «imported into FreeBSD 5.0, never installed» (fsx-rs README).
- fio: man 3.43 (fio.1 @ axboe/fio HEAD), engines/posixaio.c, os/os-freebsd.h.
- kdave/fsx-fsstress: include-листы fsstress.c/fsx.c (liburing, libaio,
  btrfsutil, linux/fiemap) — сняты по исходникам 2026-09-10.
- fuser (koverstreet fork, checkout 8819589): src/lib.rs:230 max_background=16.
- asomers/fsx-rs: README (2026-09-09), CI, crates.io/crates/fsx.
