# 00 — Живой статус спринта A

> Обновляется оркестратором на гейтах. Хронология — git log; детали — docs/notes/*.

## ⏸️ ПАУЗА (2026-11-01 ~18:30, ребут хоста по решению владельца)

**Всё зафиксировано, ребут безопасен.** Resume — см. docs/RESUME-AFTER-REBOOT.md.

## Ворота

| Гейт | Условие | Статус |
|---|---|---|
| G0 | `tools/bcachefs version` на FreeBSD | ✅ v1.39.7-1539-gd48ba1a7a1d0-dirty (Run 24) |
| G1 | format→fsck (fill→verify в T11) | ✅ полный offline fsck чисто |
| T10 | FUSE ro-маунт | ✅ первый bcachefs-маунт на FreeBSD; umount+fsck чисты |
| T11 core | rw семантика | ✅ write/hardlink(nlink=2)/rename-over/unlink + fsck clean |
| G2 | FUSE rw + pjdfstest | ✅ **0 failed / 380 passed / 10 expected (chflags) / 125 skipped** + fsck clean (046 errno-host-нумерация, 047 rename-цикл, 045 setattr — три корня G2) |
| G3 | метаданные < 12.8 мс/файл | ждать G2; bench/ готов |

## Задачи

T01-T05, T09 ✅ (46 overlay-патчей); T06-T08 скрипты готовы (T08 нужен порт fusefs-ufs — одобрения владельца нет); T10 ✅; T11 🟡 (045 применён, пересборка+прогон после ребута); T12-T13 ждут.

## Оркестрационные константы (уроки — в AGENTS.md)

- Слот тяжёлой сборки — ТОЛЬКО оркестратор; агенты никогда не собирают.
- apply.sh штамп-идемпотентен; при сомнениях — свежий прогон цепочки по восстановленным из git исходникам.
- Прогоны: PKG_CONFIG_PATH=overlay/pkgconfig CARGO_BUILD_JOBS=2 rlimit-run 2500 gmake -j1 (nice 19).
- ktrace GENIO на демоне — wire-tap /dev/fuse без пересборки (не забыть ktrace -c).

## Git (сводка последних)

- ca72376 fix(overlay): 045 fuse setattr merges permission bits, keeps file type
- 0d7bc84 docs(notes): T11 bisect — pjdfstest panic root-caused
- 044/043/042/041… — см. git log
