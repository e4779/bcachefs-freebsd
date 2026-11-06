# 19a — Ф2: dogfood-движок (корпус, шторм, fio, хаос, ротатор)

**Статус: см. §4 (dry-run приёмка).** Движок собирает роли из обзора 18a в один
ротатор фаз; всё исполнение — ТОЛЬКО внутри `stage-session.sh` (инварианты 15b §5:
живой пул не-rw, kill-критерии абсолютны, стейдж одноразовый, rctl-капы на тяжёлом).

## 1. Артефакты (`scripts/dogfood/`)

| Файл | Роль | Контракт |
|---|---|---|
| `corpus.sh` | детерминированный корпус | `gen\|verify\|epoch-bump <root> [epoch]`; контент = sha256(relpath\|\|epoch), тиленый 32-байтовыми блоками до размера; проверка без хранимых хэшей; профили torrent/library/farm/db; farm: nlink==6; db: append/truncate/overwrite с сохранением инварианта |
| `churn.sh` | metadata-шторм | `churn.sh <work> <rounds> <batch> <tsv>`; раунд = create/rename (вкл. поверх существующего)/hardlink/unlink/readdir-deep/stat-walk; каждая операция отдельно в TSV (round, op, dt_ms); p50/p95/p99 считает ротатор |
| `fio-jobs/write-verify.fio` | raw write + verify | verify=sha512, verify_fatal, fdatasync=1, buffered, iodepth≤16 — кейвты FUSE из 18a §2 |
| `fio-jobs/read.fio` | read-фаза | randread по ТОМУ ЖЕ набору файлов (dir+format+nrfiles/filesize совпадают) |
| `fio-jobs/fill.fio` | ENOSPC-препаратор | fill_fs=1, отдельный каталог под зачистку |
| `chaos.sh` | дрели a/b/c | a: kill -9 демона в середине шторма → umount -f → recovery fsck -n → remount (рецептом обёртки, rctl-кап) → verify-subset; b: SIGSTOP → канарейка L0 ≤15 c → CONT → RECOVERED → verify; c: fill → запись должна УПАСТЬ → зачистка → verify |
| `engine.sh` | ротатор | `engine.sh <image> <mnt> [--mode dry\|full] [--drill a\|b\|c\|none] [--skip ...]`; ВСЕ фазы одной ротации — одна инвокация stage-session.sh; телеметрия → `<session>/engine.log` |

Ротация: `corpus-gen → fio-write-verify → churn → read-phase (corpus-verify +
fio-read) → dbench (xattr-находки!) → fsx (seed в логе) → chaos-pick-one`.
Выход ненулевой при любом verify-failure (VERDICT обёртки 3) или провале дрели.

## 2. Ключевые решения

1. **Zvol как image обёртки.** Стейдж-цель — `/dev/zvol/zdata/stage-pool`
(300G, одноразовый, отформатирован нашим бинарем, fsck-чист). Это
character-device: обёртка Ф0 принимала только regular files. Минимальное
расширение `stage-session.sh` (commit 4bc2195): `-c`-image монтируется
напрямую (без md-прослойки), `<session>/dev` хранит полный путь, fsck -n —
через doas (zvol = root:operator, пользователь не читает). Файл-путь Ф0
проверен повторно: VERDICT 0 clean.
2. **Абсолютные пути в обёртке.** Все mount-table grep'ы обёртки матчат
абсолютизированные ядром записи; относительный путь молча пропускал
umount/detach и оставлял живой демон + прицепленный md (найдено пробой,
вычищено руками, добавлен guard-нормализатор).
3. **Контент-инвариант вместо хранимых хэшей.** digest = sha256(relpath\|\|epoch);
файл = digest-tiled до размера. Verify пересчитывает digest из (relpath, epoch)
и сравнивает чанками — ноль состояния, переносимо, epoch-bump = массовый
rewrite. db-профил мутирует append/truncate/overwrite'ами, каждый из которых
остаётся tiled ⇒ инвариант переживает мутации (найдено смоуком: truncate() НЕ
двигает file position — без явного seek появляется zero-hole; исправлено).
4. **Per-op тайминги через python3.** FreeBSD date без %N; python3 в хосте есть;
TSV (round/op/dt_ms) → awk p50/p95/p99 per op-class в engine.log.
5. **fio-кейвты из 18a зашиты:** buffered-only, iodepth≤16 (fuser
max_background=16), fdatasync=1 в критичном job (buffered-write ошибки видны
на вымывании). Сетка глубин — через `FIO_IODEPTH`.
6. **Tolerant churn для дриллей.** Хаос убивает демон ПОД штормом: ошибки I/O
тогда — суть дрели; 50 подряд ошибок = tolerated-abort (шторм не крутится
вхолостую на мёртвом маунте).
7. **fsx-rs конфиг в сессии:** flen 64 MiB (dry) / 256 MiB (full), align=1
(байт-точный adversarial), mmap-веса оставлены (writeback-путь — часть
dogfood), seed фиксируется в engine.log (воспроизводимость).
8. **Ресурсы:** fio под rctl-капом 3000 (verify-mode ест RAM), dbench/fsx —
1024, corpus/churn — 1024; перед каждой тяжёлой фазой memgate: ждать ≤600 c
свободных ≥1 GiB (правило AGENTS), иначе WARN и дальше под капами.
9. **Канарейка после recovery-remount.** После дрели a канарейка обёртки уже
вышла (mount-gone): chaos.sh поднимает свою на восстановленном маунте
(`canary-recovery.log`) — L0-покрытие хвоста сессии.

## 3. Полноформатный runbook (mode=full)

```
# одна ротация (~25-40 мин нагрузки + fsck-финиш обёртки)
scripts/dogfood/engine.sh /dev/zvol/zdata/stage-pool \
  /home/e4779/projects/bcachefs-freebsd/tmp/dogfood-mnt --mode full --drill b

# последующие ротации: чередовать дрели a/b/c (c — считается самой долгой:
# fill_fs пишет до ENOSPC на ~165+ ГБ свободных, закладывать ≥40-60 мин)
scripts/dogfood/engine.sh ... --mode full --drill a
scripts/dogfood/engine.sh ... --mode full --drill c

# повторное использование корпуса (без gen): --skip corpus-gen
# iodepth-решётка: FIO_IODEPTH=1|4|8|16 scripts/dogfood/engine.sh ...
```

Параметры full: corpus ~22 GiB (6000 малых + 4×2G torrent; 64 кат×16 файлов
library + 16×64M; farm 500×1M×6 ссылок; db 64×64M), fio write 300 c + read
180 c (64×256M), churn 40 раундов×100 (кап 300 c), dbench 8×120 c, fsx
200k ops / 256 MiB. Каждая ротация оставляет корпус на месте — следующая с
`--skip corpus-gen` переиспользует (corpus verify фазы read-phase — регресс
целостности между ротациями).

Вердикты: VERDICT обёртки 0 + `ENGINE RESULT: PASS` в engine.log = зелёная
ротация. Любой FAIL — разбирать `<session>/engine.log`, findы дриллей —
строки `FINDING:`. Красная ночь (VERDICT 2) = морозка ступеней (15b §5).

## 4. Dry-run приёмка (mode=dry, drill=b)

<!-- DRYRUN-EVIDENCE -->

## 5. Открытые хвосты

- dbench xattr/extattr через FUSE: находки логируются (`FINDING:` в engine.log),
  счёт статуса — после первых полных ротаций.
- pjdfstest-подмножество в ротацию не входит (роль — недельная батарея
  regression.sh, 17a §3).
- drill c на full не прогонялся в dry (по плану dry = только b): первый full
  прогон c — отдельная сессия с запасом времени.

## Dogfood-двигатель: dry-ротация ЗЕЛЁНАЯ (2026-11-04 01:58)

Полный цикл за 11.5 мин: corpus-gen (1050 файлов) → fio write+verify (psync) → churn (percentiles: stat p50=0.002ms, hardlink p50=0.041ms, readdir p99=3.2ms) → fio-read (9.3 ГБ/с из кэша) → dbench (160 МБ/с, 4 клиента, xattr/flock живы) → fsx (20k ops чисто) → chaos-дрель b (SIGSTOP→канарейка L0 за 12с→восстановление→сверка чисто). VERDICT 0.

Находки dry-прогона (2 бага двигателя, 0 багов ФС): posixaio EOPNOTSUPP (fusefs без POSIX AIO → psync), CORPUS_SIZE env-mismatch в chaos (ложный дрифт; ФС была чиста).

Следующий шаг: непрерывный soak (mode=full) — по решению владельца утром.

## Q4 ЗАВЕРШЕНО (2026-11-04 02:16)
zdata/pool-irreplaceable: lib 153G (on-disk, sparse-aware) + seeds-mule 32.1G + снапшот q4-initial. Незаменимое под двойной защитой (ada0, отдельный физический диск от обоих членов пула).

## SOAK PAUSED (2026-11-04 21:10, для сборки-разборки машины)
13 чистых ротаций, 0 сбоев, RSS 450-584 MB (плато).
Resume: fresh engine.sh --mode full на /dev/zvol/zdata/stage-pool.

## SOAK PAUSED #2 (ночная тишина, 2026-11-05)
13+3=16 чистых ротаций суммарно, 0 сбоев. Resume: engine.sh --mode full.

## SOAK PAUSED #3 (reboot, 2026-11-05 ~12:00)
20 clean rotations total (13+3+4). RSS: 561-621 MB corridor. Resume: engine.sh --mode full.

## SOAK PAUSED #4 (reboot, 2026-11-05 ~19:30)
26 clean rotations total. RSS plateau 540-575 MB. Resume: engine.sh --mode full.

# 🎯 Ф2 SOAK COMPLETE — 30 CLEAN ROTATIONS (2026-11-05 23:48)

30/30 green. 0 failures. RSS 450-621 MB (plateau, no leak). All chaos drills green.
All corpus verifies 100%. All tools (fio verify, dbench, fsx) passed every rotation.

Ф2-exit criteria MET. Next: Ф3 (stash write on FUSE).

## RO-окно #2: полный прод-сервис на живом пуле (2026-11-05, в ходу)

- stash v0.32.0-hlab.2: UI+GraphQL+стрим 73MB/s, scan+generate (job FINISHED)
- qbittorrent-nox: сидирование на ro, WebUI :8094, соединения живут
- FUSE metadata: 477k files/s (walk), 9k/s (stat), 700/s (open+read) — против x10.7 налога NFS
- Демон RSS: 1.7-1.9GB (кэш полной библиотеки), кэп 2500 держит
- Записи на пул: НОЛЬ за всё окно (gstat-сторож + EROFS-проба)

### Бэкап-факт для rw-решения (подтверждён владельцем 2026-11-06)
- Незаменимое = lib/* (вся кураторская библиотека, вкл. lib/music 85G) + seeds/mule = 184G,
  НА ДРУГОМ ДИСКЕ (zdata/pool-irreplaceable, ada0, свежий 2026-11-03).
- Остальные ~2.2T (seeds/adult, music, misc, movies, ed2k_share, migration) = перекачиваемое p2p.
- Вывод: rw-риск на живом пуле = риск времени/трафика, НЕ данных.

## Ф3-LIVE START: первый rw на живом пуле (2026-11-06 00:45)

Решение владельца: бэкап незаменимого закрыт (lib+mule=184G, zdata, 2026-11-03),
остальное перекачиваемо => rw-риск = риск времени, не данных. VM (ремонтный инструмент)
пересобирается, откат = reformat + restore (задокументирован).

Лестница принята:
- write-probe 200MB: checksum MATCH, fsync ok
- umount -> super seq 19611->19631, Clean:1
- fsck -n: CLEAN (journal seq 10762292)
- probe пережил umount/fsck/mount с той же суммой
- stash (302) + qbittorrent (200) подняты на rw-маунте
- монитор: /tmp/f3-monitor.sh (RSS/сервисы/ошибки, алармы)

Проба хранится как /mnt/pool/.f3-probe/ — кросс-валидация Linux-стороной при возврате VM.

### rctl-урок (2026-11-06 01:30)
- Сервисный режим демона: кэп 2500 оказался тесным (btree-кэш библиотеки дорос до 2429MB за чек-волну).
- Живой swap правила: rctl -r process:PID:memoryuse:deny=старое; rctl -a ...deny=4294967296 (4G).
- Сервисные маунты дальше: rlimit-run.sh 4000, не 2500.
- nice 19 в сервисном режиме запрещён (шрам шторма 01:05) — только nice 0.
- Демон под rctl-кэпом при превышении: malloc ENOMEM -> abort (смерть, не замедление).

### Логирование Ф3 (2026-11-06 01:25)
- УРОК: BCACHEFS_FUSE_LOG потерялась через doas (doas чистит env) — FUSE-опс-лог не ведётся до следующего ремоунта.
  Правильно: doas sh -c "BCACHEFS_FUSE_LOG=... exec ..." или setenv в doas.conf.
- Ротация: /etc/newsyslog.conf.d/p2p-stack.conf (qbt/amut/amuled/stash, 10M x5, copy-truncate).
- Монитор v4: rss/stash/qbt/dl-up/free/kerr + ежечасная проверка пробы (sha256).

## ИНЦИДЕНТ #1: потерянный FUSE write-ответ (2026-11-06 ~02:30, daemon 96931)

Симптом: qbt (поток libtorrent-network) навсегда завис в fuse_write_directbackend -> fdisp_wait_answ.
WebUI qbt молчал (000), процесс жив. Kill -9 спасает, но restart натыкается на тот же путь при загрузке resume.

Диагноз (артефакты: tmp/fuse-stall-incident1/):
- Демон ВСЕ потоки idle (procstat -kk) — запрос не обрабатывался
- FUSE-лог не содержит зависший WRITE — демон его НЕ ПОЛУЧАЛ
- => запрос потерян kernel->daemon (канал /dev/fuse), ответ не придёт никогда, клиент без таймаута

Гипотеза: race в fuser (класс destroy-before-reply, cberner/fuser#29) — пропуск чтения
из /dev/fuse под нагрузкой. Воспроизводимость: 2+ зависания за вечер (WebUI-голодания).

Следующие шаги: (1) воспроизвести под sysctl vfs.fusefs debug, (2) таймаут-обход на
стороне клиента не существует => нужен фикс демона, (3) кандидаты: fuser форк upstream.

## РАЗГОВОР С ИСТОЧНИКАМИ: полный диагноз wedge + boot-fail (2026-11-06 утро)

Исследователи: fuse-kernel (releng/15.1 исходники) + bcachefs-fuser (клон + gh).

### Wedge (баг #1) — механизм доказан
- fdisp_wait_answ: таймаут ЕСТЬ (mount timeout=, дефолт 60с, clamp 0..600)
- НО fuse_io_strategy на ETIMEDOUT: bdirty + ~B_DONE + ретрай (fuse_io.c:896-902)
- fuse_write_biobackend: goto again по всем ошибкам кроме EINTR (:602-607)
- => через bufwrite (data_cache_mode=1) = вечный 60с-цикл, очередь ms_head растёт
- Демон-триггер: стеки инцидента #1 - НИ ОДИН поток демона в read(/dev/fuse);
  event-loop застрял в umtx (userspace) => fuser/bcachefs мьютекс-дедлок
- Kernel-side: lost-wakeup исключён (push+wakeup под одним ms_mtx)

### Rescue-рычаг (доказан)
mount -u -o timeout=N /mnt/pool - меняет на живом маунте (fuse_vfsops.c:237)
Применение при wedge: переводит вечный цикл в фейлящиеся записи => сервисы получают
ошибки и живут, демон можно перезапустить по-человечески.

### Boot-fail (баг #2) - fuse_mounted false-negative
fusemount.rs:2340-2375: сравнивает f_mntfromname с одиночным девайсом;
на multi-device там СКЛЕЕННАЯ строка "/dev/nda0p3:/dev/ada1" => никогда true =>
healthy mount не распознан => arm "shutting down" => 300s ожидание => boot-fail.
Фикс: сверять по mntonname (маунт-поинт), не по fromname.

### fuser read-loop: надёжен
EAGAIN/EINTR ретраятся; partial read = ENODEV + смерть сессии (не потеря);
ENODEV = штатный выход. Молчаливая потеря возможна ТОЛЬКО в reply (writev err ->
error!() -> kernel ждёт unique). fuser#757, koverstreet destroy-before-reply.

### План
1. overlay: fuse_mounted по mntonname (маленький)
2. порт: демон-дедлок — поймать umtx-владельца при следующем wedge
   (стек-снимок демона ДЛЯТСЯ в момент wedge; искать владельца мьютекса)
3. runbook: rescue-рычаг mount -u -o timeout=
