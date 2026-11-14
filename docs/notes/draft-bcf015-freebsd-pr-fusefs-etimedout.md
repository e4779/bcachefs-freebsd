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

---

## Текст отчёта (EN, paste-ready)

**Title:** `[fusefs]: timed-out writes return bogus EINTR and the buffer is re-dirtied without recording the error`

**Environment:**
FreeBSD 15.1-RELEASE-p6 amd64; the cited code is identical in
stable/15 (release/15.1.0) and current main. FUSE server: bcachefs
over FUSE (https://github.com/e4779/bcachefs-freebsd), default
daemon_timeout (60 s). Observed live in production, then confirmed
by code reading and a deterministic test.

**Reproduction:**

1. Deterministic test (repro against a stock kernel): the gtest suite
   `tests/sys/fs/fusefs/fusefs_timeout.cc` from
   https://github.com/e4779/bcachefs-freebsd (patch in
   `overlay/patches/kernel/fusefs-tests-etimedout.patch`). A mock FUSE
   server delays FUSE_WRITE replies beyond `daemon_timeout`, then a
   writer times out. Against stock fusefs(4), `Timeout.append_lane_etimedout`
   fails: the writer observes EINTR instead of ETIMEDOUT and the buffer
   stays dirty. Against the patched module the test passes (ETIMEDOUT in
   one window, 3.0 s wall-clock assert). Neighbouring suites (Fsync,
   Interrupt) pass unchanged on both.

2. Live observation (production wedge, 2026-11-06): a qbittorrent
   thread parked in `fdisp_wait_answ` inside
   `fuse_write_directbackend -> fuse_io_strategy -> fuse_vnop_write`
   while all daemon threads were idle (FUSE reader in poll, control
   socket in accept, workers sleeping); the daemon's web UI answered
   200 during the same wedge and the daemon processed ~65k ops/s
   (dtrace). The daemon served; the wedge lived in the kernel's
   timeout handling.

**Observed:**

The errno chain, with file:line (main; stable/15 identical):

1. `sys/fs/fuse/fuse_ipc.c:436-444` — `fdisp_wait_answ` sleeps
   `daemon_timeout` seconds and converts `EWOULDBLOCK` into
   `ETIMEDOUT`. The kernel now knows the op timed out.
2. `sys/fs/fuse/fuse_io.c:896-904` — `fuse_io_strategy` receives
   `ETIMEDOUT`, re-dirties the buffer (`bdirty`, clears `B_DONE`) and
   records **nothing**: no `BIO_ERROR`, no `b_error`. For synchronous
   callers (`!B_ASYNC`) it sets `B_EINTR` — for both `EINTR` and
   `ETIMEDOUT`.
3. `sys/kern/vfs_bio.c:4574-4577` — `bwait` converts `B_EINTR` into a
   bare `EINTR` return.

Consequences:

- A synchronous writer gets `EINTR` for a syscall that was never
  signalled. POSIX-wise EINTR means "retry me": applications retry —
  each retry burns another full `daemon_timeout` window in
  `fdisp_wait_answ`. In our production this surfaced as an
  infinite EINTR-retry churn (libtorrent retrying a write against a
  healthy daemon forever).
- An asynchronous writeback buffer is re-dirtied with no error marker
  and no retry scheduling; the failure is invisible to every consumer
  that reads `b_error`/`BIO_ERROR`.
- `fsync(2)`: `vn_fsync_buf` (`sys/kern/vfs_vnops.c:3245`, `maxretry =
  10000` at `:3253`) reads `b_error == 0` on the re-dirtied buffer and
  keeps flushing; each pass costs one `daemon_timeout` window; after
  maxretry passes it returns `EAGAIN` instead of the real error.

**Expected:**

The timeout error should reach the writer as `ETIMEDOUT`, and the
buffer should carry the error (`BIO_ERROR` + `b_error`) so that flush
and fsync loops terminate after one window instead of churning.

**Analysis (what we ruled out):**

- The FUSE server: at every observed wedge the daemon was alive and
  serving (idle-in-poll thread stacks on both sides, web UI 200
  mid-wedge, ~65k ops/s dtrace throughput). Stacks captured at two
  independent wedges show the client parked in `fdisp_wait_answ`
  inside `fuse_vnop_write` / `fuse_vnop_read` while the daemon slept
  in poll/accept.
- Server-side reply-path bugs (lost writev, MT lockups) existed and
  were fixed in our server earlier; this wedge class persisted after
  those fixes, until we fixed the errno path in the kernel (below).
- A non-serving daemon is detectable and distinct: with the daemon
  SIGSTOPped, ops time out with ETIMEDOUT after one window (verified
  on a test mount).

**Suggested direction:**

In the timeout branch of `fuse_io_strategy`, record the error on the
buffer — `bp->b_ioflags |= BIO_ERROR; bp->b_error = ETIMEDOUT;` — keep
`bdirty` so data is not lost, and reserve `B_EINTR` for genuine
`EINTR`. Our working patch does exactly this (three write lanes
covered: IO_SYNC, discontiguous appends, fsync), with tests:
https://github.com/e4779/bcachefs-freebsd
(`overlay/patches/kernel/fusefs-151-inverse-fuse_io.patch`). Happy to
submit it as a git-diff attachment here.

**Related but distinct:** PR 236474 (fsync returns asynchronously —
completion semantics, not timeout errno handling); PR 293028 (EINTR in
cp(1)/copy_file_range(2) over fuse — userland copy path).

**Note on tooling:** prepared with LLM-assisted tooling under my
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
