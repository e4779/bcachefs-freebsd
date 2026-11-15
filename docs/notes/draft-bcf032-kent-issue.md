# DRAFT — bcf032: heads-up issue для koverstreet/bcachefs-tools (канал (а))

**Status: DRAFT, НЕ ОТПРАВЛЕН. Сабмит — после owner review + зелёного work-verifier.**
Канал: новая ишуя в koverstreet/bcachefs-tools (README: «GitHub issues for bug reports»).
Формат: symptom-title, body ≤2.5K (plain text, no markdown), fix = compare-линк ветки
(паттерн «point me to the branch»), own voice, кросс-рефы как факты.

---

BUGZILLA-аналог: TITLE FIELD:

FreeBSD: FUSE_DESTROY delivered to one blocked reader — daemon hangs on umount -f (fix branch available)

BODY:

Environment: FreeBSD 15.1-RELEASE-p6 amd64. Our project runs bcachefs on FUSE
in production (https://github.com/e4779/bcachefs-freebsd) on the fuser vendored
from your tree (fuser-vendored, base destroy-before-reply 8819589).

What we observed:

On umount -f, FreeBSD delivers FUSE_DESTROY to exactly ONE reader blocked on
the shared /dev/fuse fd. Unlike Linux, there is no ENODEV broadcast — the
other readers stay parked in read(2) forever, and Session::run's sequential
join never completes: the daemon survives every umount as an orphan.

procstat excerpt at the hang (from a captured core, 2026-11-07):

    7 threads of the daemon in read(2) on the fuse fd, one of them
    holding the delivered FUSE_DESTROY; all in sleepq_wait_sig.

Our fix (branch 070-reader-kick, would-be-PR diff:

    https://github.com/koverstreet/fuser/compare/master...e4779:070-reader-kick

): the destroy arm stores a session_dead flag (Release) and kicks every
registered reader with pthread_kill(SIGURG) under a no-op handler installed
WITHOUT SA_RESTART — the interrupted read returns EINTR, the thread checks
the flag and exits. receive_session_aware also checks the flag (Acquire)
before parking, so the flag is the source of truth and SIGURG only wakes
readers already parked. All of it is cfg(target_os = "freebsd")-gated, the
prior sigaction state is saved/verified with a warn on a foreign handler,
and it is idempotent. Zero steady-state per-request cost. It does not
change reply ordering.

Live-verified once: umount -f → the daemon exits cleanly within 4 s
(n=1 - a confirmation, not a proof).

Relation to your destroy-before-reply work (8819589): different lane —
that fixes reply ordering on the destroy path; this fixes parked-reader
liveness after the destroy is delivered. Complementary; the branch applies
to master (c0420fc) and rebases onto the destroy-before-reply line if you
prefer it there.

Related: cberner/fuser#757 (reply handling around FUSE_DESTROY).

Note on tooling: prepared with LLM-assisted tooling under my supervision.

---

## Мета (RU — не отправляется)

- Порядок отправки: work-verifier зелёный → owner «го» → файлит владелец
  (gh под его аккаунтом) → квитанция (URL) в карточку bcf032 → пинг-политика:
  тишина = сигнал, closure по owner-judgment.
- Если Кент ответит «PR'ь в форк» — ветка уже есть; PR создаётся ТОЛЬКО по его слову.
- Размер: ~2.2K chars — в лимите 2.5K.
- Спорно и отброшено: упоминание core 69055 по имени файла (внутренний артефакт),
  упоминание bcf-номеров, grievance про cberner (запрещено framing kit'ом).
