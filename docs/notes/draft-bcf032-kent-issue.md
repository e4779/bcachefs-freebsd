# DRAFT — bcf032: heads-up issue для koverstreet/bcachefs-tools (канал (а))

**Status: DRAFT v2 (post council #3), НЕ ОТПРАВЛЕН. Сабмит — owner decision.**
Канал: новая ишуя в koverstreet/bcachefs-tools (README: «GitHub issues for bug reports»).
Плоский текст, fix = compare-линк ветки, own voice, кросс-рефы как факты.
Council #3 (2026-11-15): style FIX→SEND, skeptic FIX (блокер снят — evidence
переписан двух-моментно по lldb-инвентарю core 69055), maintainer FIX→SEND
(базовая неоднозначность снята явной фразой; прогноз Кента: молча заберёт или
«Applied to testing as <hash>»).

=== НЕ SENDABLE: TITLE FIELD (вставить в поле заголовка) ===

FreeBSD: FUSE_DESTROY delivered to one blocked reader — daemon hangs on umount -f (fix branch available)

=== BODY (paste, ≤2.5K) ===

Environment: FreeBSD 15.1-RELEASE-p6 amd64. Our project runs bcachefs on FUSE
in production (https://github.com/e4779/bcachefs-freebsd) on the fuser vendored
from your tree (running your destroy-before-reply line, 8819589).

What we observed:

On umount -f, FreeBSD delivers FUSE_DESTROY to exactly one blocked reader of
the shared /dev/fuse fd. Unlike Linux, there is no ENODEV broadcast - the
other readers stay parked in read(2) forever, and Session::run's sequential
join never completes: the daemon survives every umount as an orphan. The bug
needs two or more reader threads to matter.

Evidence from one incident (2026-11-07): 7 readers parked in read(2); the
FUSE_DESTROY recipient ran destroy + reply and exited; lldb on the captured
core then showed the remaining 6 still in __sys_read, with main in join.

Our fix - branch 070-reader-kick @ 9475151, would-be-PR diff:

    https://github.com/koverstreet/fuser/compare/master...e4779:070-reader-kick

A single commit (+113/-1, channel.rs/session.rs) on master (c0420fc), all
FreeBSD-gated. The destroy arm stores a session_dead flag (Release) and kicks
every registered reader with pthread_kill(SIGURG) under a no-op handler
installed WITHOUT SA_RESTART - the interrupted read returns EINTR and the
thread exits. receive_session_aware checks the flag (Acquire)
before parking, so the flag is the source of truth and SIGURG only wakes
readers already parked. The prior sigaction state is verified with a warn;
idempotent; zero steady-state cost; reply ordering unchanged. cfg(freebsd)-only: Linux already ENODEV-broadcasts to every
reader, so there the flag would be dead code.

Poll-based v1 failed: on a shared fd poll(2) is ready for every reader as
soon as Destroy is in flight, so all repark in read(2); the kick targets
readers already parked.

Live-verified once: umount -f -> the daemon exits cleanly within 4 s
(n=1 - a confirmation, not a proof). A Linux-runnable unit test for the
flag/EINTR path is easy to add; the full hang path is FreeBSD-only.

Relation to your destroy-before-reply work (8819589): different lane - that
fixes reply ordering on the destroy path; this fixes parked-reader liveness
after the destroy is delivered. The branch sits on master and rebases
cleanly onto the destroy-before-reply line if you prefer - say the word and
I'll PR or rebase either way.

Related: cberner/fuser#757 (reply handling around FUSE_DESTROY).

Note on tooling: prepared with LLM-assisted tooling under my supervision.

=== /BODY ===

## Мета (RU — не отправляется)

- Council #3 findings, все закрыты: (1) BLOCKER evidence — переписан
  двух-моментно («7 parked; recipient exited; lldb: remaining 6 in
  __sys_read, main in join»), метод назван честно (lldb на core, не procstat);
  (2) poll-v1 rationale добавлен; (3) why-cfg(freebsd) добавлен (Linux ENODEV
  уже будит — флаг был бы dead code); (4) single-reader disclaimer добавлен;
  (5) fix-rev пин 9475151; (6) базовая неоднозначность 8819589-vs-c0420fc
  снята фразой в Relation-абзаце + «on master (c0420fc)» у compare;
  (7) low-cost ask («say the word... PR or rebase either way»); (8) тест-оффер
  одной строкой (offer, не done — план в memo §5); (9) path anchor
  tools/fuser-vendored/ в Environment; (10) TITLE/`/BODY` маркеры не-сендабельности.
- Если body >2.5K при вставке — резать path anchor (решение maintainer), не
  base-clarification.
- Порядок: owner «го» → файлит владелец → квитанция в карточку → bcf032 loop
  closed по owner-judgment (тишина = сигнал).
- Скептик change-my-mind: не сработал (мы правим, а не спорим).
