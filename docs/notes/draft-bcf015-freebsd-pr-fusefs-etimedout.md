# DRAFT — bcf015: FreeBSD bug report (fusefs ETIMEDOUT write path)

**Status: DRAFT, НЕ ОТПРАВЛЕН. Сабмит — только после одобрения владельца.**
Собрано: 2026-11-14, код main HEAD + release/15.1.0 (обе ветки сверены,
блок идентичен), дубликаты проверены по bugzilla REST 2026-11-14.

## Сабмит-чеклист (для владельца)

- Канал: bugs.freebsd.org, product `Base System`, component `kern`,
  категория `fusefs` в заголовке (конвенция трекера: `[fusefs]: ...`).
  Bugzilla-first: linimon «convert to Attachment using git diff — new
  preferred submission method» (CORPUS.md §6; PR 300130 c2). GitHub-PR
  дверь формально запретительная (bcf026) — PR открывать ТОЛЬКО если
  триаж попросит.
- Текст ниже — готов к вставке (EN). Attachment: git diff фикса (прикладывать
  сразу, референс: linimon конвертировал патч из PR в attachment 276661).
- Disclosure-нота обязательна (прецедент 300130/300475/300480 — linimon
  триажил штатно): уже в тексте.
- Вложения >20 строк — файлами: `procstat`-выдержки, полный вывод теста.
- Двойная проверка перед отправкой: все file:line по свежему main; номера
  приложений (236474, 293028) актуальны.
- Стратегия (по прецеденту 300130): ОДИН bug-report с аттачментами —
  (1) git diff фикса fuse_io, (2) git diff тестов. НЕ два отдельных
  сабмита — двойная очередь. PR на GitHub — только если триаж попросит.
- Формат: секции Environment/Description/How-To-Repeat/Fix (канон
  гайда problem-reports), plain text без разметки (без бэктиков/**),
  ASCII, строки <=76, патчи только аттачментами (guide: quoted-printable
  убивает inline-диффы).
- Синтаксис кросс-ссылок bugzilla (автолинки) — НЕ из памяти, а из живого
  шаблона: gh api repos/freebsd/bugzilla/contents/template/en/custom/global/textarea.html.tmpl
  --jq '.content' | base64 -d | grep -B1 -A2 'To link'  (пример: bug #N,
  comment #N, bug #N, comment #N, base rN, review DN). Ссылки на внешние
  файлы — pin-SHA blob URL целиком (URL не ломать).

---

## Текст отчёта (EN, paste-ready, PLAIN TEXT — канон
## docs.freebsd.org/articles/problem-reports: секции Environment /
## Description / How-To-Repeat / Fix; патчи аттачментами; ASCII; строки
## <=76; никакой разметки)

BUGZILLA SUMMARY FIELD:

[fusefs]: timed-out writes return bogus EINTR and the buffer is
re-dirtied without recording the error


Environment:

FreeBSD 15.1-RELEASE-p6 amd64. The cited code is identical in
stable/15 (release/15.1.0) and current main. FUSE server: bcachefs
over FUSE (https://github.com/e4779/bcachefs-freebsd), default
daemon_timeout (60 s). Observed live in production, then confirmed
by code reading and a deterministic test.


Description:

fuse_ipc.c waits daemon_timeout seconds for a reply and then returns
ETIMEDOUT (sys/fs/fuse/fuse_ipc.c:436-444, main; stable/15
identical). The write path discards that knowledge.

fuse_io_strategy (sys/fs/fuse/fuse_io.c:896-904) receives ETIMEDOUT,
re-dirties the buffer (bdirty, clears B_DONE) and records nothing: no
BIO_ERROR, no b_error. For synchronous callers (!B_ASYNC) it sets the
B_EINTR flag - for both EINTR and ETIMEDOUT. bwait
(sys/kern/vfs_bio.c:4574-4577) then converts B_EINTR into a bare EINTR
return.

Consequences:

1. A synchronous writer gets EINTR for a syscall that was never
   signalled. EINTR reads as "retry me": applications retry, and each
   retry burns another full daemon_timeout window inside
   fdisp_wait_answ. In our production this surfaced as an endless
   EINTR-retry loop (qbittorrent/libtorrent retrying a write against a
   healthy daemon).

2. An asynchronous writeback buffer is re-dirtied with no error marker
   and no retry scheduling; the failure is invisible to every consumer
   reading b_error or BIO_ERROR.

3. fsync(2): vn_fsync_buf (sys/kern/vfs_vnops.c:3245; maxretry = 10000
   at :3253) reads b_error == 0 on the re-dirtied buffer and keeps
   flushing; each pass costs one daemon_timeout window; after maxretry
   passes it returns EAGAIN instead of the real error.

What we ruled out:

- The FUSE server. At every observed wedge the daemon was alive and
  serving: thread stacks on both sides show the client parked in
  fdisp_wait_answ inside fuse_vnop_write / fuse_vnop_read while the
  daemon slept in poll/accept; the daemon web UI answered 200 during
  the same wedge, and dtrace measured ~65k ops/s throughput.

- Server-side reply-path bugs (lost writev, MT lockups) existed and
  were fixed in our server earlier; this wedge class survived those
  fixes.

- A non-serving daemon is detectable and distinct: with the daemon
  SIGSTOPped, ops time out with ETIMEDOUT after one window (verified
  on a test mount).


How-To-Repeat:

1. Deterministic test against a stock kernel. The gtest suite
   tests/sys/fs/fusefs/fusefs_timeout.cc - the full patch is at
   https://github.com/e4779/bcachefs-freebsd/blob/ab6e591/overlay/patches/kernel/fusefs-tests-etimedout.patch
   It mounts a mock
   FUSE server that delays FUSE_WRITE replies beyond daemon_timeout;
   a writer then times out. On stock fusefs(4),
   Timeout.append_lane_etimedout fails: the writer observes EINTR and
   the buffer stays dirty. With the attached fix the test passes
   (ETIMEDOUT in one window, 3.0 s wall-clock assert); the
   neighbouring Fsync and Interrupt suites pass unchanged on both
   kernels.

2. Live stacks from a production wedge (2026-11-06, qbittorrent
   writing):

       client: fdisp_wait_answ+0x150
           <- fuse_write_directbackend <- fuse_io_strategy
           <- bufwrite <- fuse_write_biobackend <- fuse_vnop_write
           <- sys_write
       daemon: FUSE reader in poll, control socket in accept, workers
           asleep

   Full procstat -k excerpts of both sides attached.


Fix:

Record the error on the buffer and reserve B_EINTR for genuine EINTR.
In the timeout branch of fuse_io_strategy:

    bp->b_ioflags |= BIO_ERROR;
    bp->b_error = ETIMEDOUT;

keep bdirty so data is not lost. Our working patch covers all three
write lanes (IO_SYNC, discontiguous appends, fsync) and includes the
test suite above. Attached as a git diff (tests patch attached
separately); the same files are also at:
https://github.com/e4779/bcachefs-freebsd/blob/ab6e591/overlay/patches/kernel/fusefs-151-inverse-fuse_io.patch

Related but distinct (bugzilla problem reports, not pull requests):
bug #236474 (fsync returns asynchronously - completion semantics, not
timeout errno handling); bug #293028 (EINTR in cp(1) and
copy_file_range(2) over fuse - userland copy path).

Note on tooling: prepared with LLM-assisted tooling under my
supervision.

---

## Receipts-инвентарь (для сверки перед отправкой)

| Claim | Receipt | Где проверить |
|---|---|---|
| ETIMEDOUT рождается в ядре | fuse_ipc.c:436-444 (main = 15.1) | `/tmp/fuseio-pristine/fuse_ipc.c` |
| bdirty + B_EINTR, нет b_error | fuse_io.c:896-904 (main = 15.1) | `/tmp/fuseio-pristine/fuse_io.c`, `fuse_io_151.c` |
| B_EINTR → EINTR наружу | vfs_bio.c:4574-4577 | `/tmp/fuseio-pristine/vfs_bio.c` |
| append-лейн: только EINTR ломает loop | fuse_io.c:668-674 (main = 15.1) | там же |
| fsync maxretry 10000 → EAGAIN | vfs_vnops.c:3245/:3253 (main); /usr/src (15.1) `vfs_vnops.c:3195/:3202` | `/tmp/fuseio-pristine/vfs_vnops.c` |
| Демон жив при клине | kits 100133/103304: клиент в fdisp_wait_answ, демон в poll/accept; webui 200; dtrace 65K ops/s | `docs/evidence/fuse-wedge-20261106-*/` |
| SIGSTOP-демона → ETIMEDOUT за окно | bcf028 transit-probe | `tasks/bcf028` (Findings) |
| Тест: на стоке EINTR, с фиксом ETIMEDOUT ≤3s | runtime-green 2026-11-14 | `docs/evidence/percpu-slot-exhaustion-20261114/kyua-fusefs-timeout.log` |
| Дубликаты отсутствуют | bugzilla REST, свип EINTR/ETIMEDOUT/timeout/wedged/redirty/hang/stuck/dirty, 2026-11-14 | лог сессии |
