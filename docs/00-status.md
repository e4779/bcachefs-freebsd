# 00 — Живой статус спринта A

> Обновляется оркестратором на гейтах. Хронология — git log; детали — docs/notes/*.

## Ворота

| Гейт | Условие | Статус
|---|---|---|
| G0 | `tools/bcachefs version` на FreeBSD | ⏳ Run 19b (cargo-фаза, CARGO_BUILD_JOBS=2, rctl 2500)
| G1 | format→fsck→fill→verify на тест-образе | ожидает G0
| G2 | FUSE rw тест-ФС + pjdfstest | ожидает G1
| G3 | метаданные лучше 12.8 мс/файл моста | ожидает G2

## Задачи

| ID | Статус | Исполнитель | Улики
|---|---|---|---|
| T01 клон | ✅ | orchestrator | d48ba1a, notes/01a
| T02 аудит deps | ✅ | orchestrator | notes/02a (8/10 было)
| T03 pkg | ✅ | orchestrator (+owner) | 6 пакетов, notes/00a
| T04 сборка C | 🏃 113+/~500 объектов + все 6 linux/-шимов собраны; Run 19b линкует | orchestrator/buildslot + patch-bio (f542fde) + patch-shims (merge 7d21efc) | notes/04a, overlay/patches 001-009
| T05 cargo | частично в Run 19b (gmake гоняет cargo сам; cstruct-стемп уже был) | — | —
| T06 образ | скрипт готов (scripts/mk-test-fs.sh) | — | —
| T07 fsck | скрипт готов (clean/fill режимы) | — | —
| T08 контроль FUSE | скрипт готов; нужен порт fusefs-ufs (не в одобренном списке — спросить owner) | — | scripts/control-fuse-test.sh
| T09 fuser-форк | следующий после G0 — главный риск | — | лекало fuse-ufs
| T10/T11 FUSE mount+rw | скрипты-обёртки готовы | — | —\n| T12 bench | каркас готов (bench/*) | — | планка: 12.8 мс/файл

## Оркестрационные константы (уроки)

- Слот тяжёлой сборки — у оркестратора (фоновые задачи агентов осиротевают; runs 14/16).
- Параллельные патч-агенты — в worktree, патчи применяют в main tools/ по непересекающимся файлам; слияние — только оркестратор.
- Cargo-фазы всегда с CARGO_BUILD_JOBS=2.
- Своп 8G есть; rctl-кэп 2500 на всё тяжёлое; free+inactive гейт 1.2G.

## Git (сводка)

```
528512c feat(scripts): T07 fsck roundtrip (clean/fill modes) + T10/T11 pjdfstest wrapper | Task: T07 Agent: orchestrator
3fd7a1b feat(scripts): T06 test-image maker (mdconfig vnode + bcachefs format via our build) | Task: T06 Agent: orchestrator
e57f035 docs(notes): six shim objects green; Run 19 launched (mem deviation noted) | Task: T04 Agent: orchestrator
7d21efc merge(T04): patch-shims — five linux/ shim FreeBSD fixes (alloca, gettid, MAP_NORESERVE, LIST_HEAD clash, FUTEX_WAIT_BITSET)
7953731 docs(notes): run-18 analysis - five linux/ shim fixes
9662e8a fix(overlay): futex FUTEX_WAIT_BITSET via _umtx_time UMTX_ABSTIME
24841c9 fix(overlay): shrinker.c LIST_HEAD vs sys/queue.h clash
5799dc8 fix(overlay): define MAP_NORESERVE 0 for percpu chunk mmap
f883d21 fix(overlay): SYS_gettid -> bch_gettid() via thr_self(2)
3ee6832 fix(overlay): blkdev.c alloca include guard for FreeBSD
f79bc51 chore(overlay): promote Linux-only errnos (EBADE/EREMOTEIO/EREMCHG) to shadow errno.h; bio.c-local guards now inert | Task: T04 Agent: orchestrator
f542fde fix(overlay): bio.c blk_errors incomplete-type + 5 more
aa5f052 feat(scripts): T08 control test — kernel FUSE proof via fuse-ufs (needs fusefs-ufs
```
