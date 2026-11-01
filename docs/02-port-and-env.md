# 02 — Карта порта и окружение (проверено на хосте 2026-11-01)

## Поверхность порта (по исследованию runbook 18, код 1.39.7)

| Компонент | Объём | Роль | Ожидание на FreeBSD |
|---|---|---|---|
| `fs/` C (226 файла, 76.5K LOC) | ядро ФС | собирается и в модуль, и в userspace | собирается на шимах; точечные `#ifdef` |
| `linux/` (41/13.9K) | userspace-реализации kernel-примитивов (bio, blkdev, fs, kobject…) | клей ФС↔POSIX | главный источник патчей (syscall-различия) |
| `include/` (154/15.6K) | вендоренные заголовки | API-поверхность | почти как есть |
| `c_src/` (14/2.3K) | C-клей инструментов incl. `fuse_shims.c` | мост C↔Rust для FUSE-маунта | как есть |
| Rust-воркспейс (~862 файла) | команды + fs-сборка | бинарь `bcachefs`, fusemount.rs | cargo build; крейты переносимы |
| fuser (форк Кента, destroy-before-reply) | FUSE-транспорт | mount/unmount | **фича `libfuse` → libfuse3 (fusefs-libs3)**; лекало — fuse-ufs (fuser 0.16+libfuse работает на FreeBSD сегодня) |

Лекало: realchonk/fuse-ufs — его Cargo.toml: *«the libfuse dependency is only needed on FreeBSD»*; mount через mount_fusefs(8).

## Окружение хоста (замерено 2026-11-01)

**Есть:** rustc 1.98.1 (нужно ≥1.85), clang 19.1.7 (base), gmake 4.4.1, cargo; libsodium, zstd, libudev-devd; mdconfig; порты содержат pjdfstest-0.2.2, fusefs-libs3-3.18.3.

**Отсутствует (поставить в T03, списком на утверждение):** `pkgconf`, `liburcu`, `e2fsprogs-libuuid`, `lz4`, `fusefs-libs3`, `pjdfstest` + добор по факту аудита T02. `keyutils` в портах нет — заглушить (tools используют для keyring; для FUSE-маунта не критично — проверить в T04).

**Ядро:** `kldload fusefs` перед FUSE-фазой (sysctl `vfs.fusefs.*` появится после загрузки). ABI 7.x, per-mount кэш ≥7.23 (write-through/write-back — см. man fusefs(4)).

## Тестовая ФС

Образ-файл + `mdconfig -t vnode -f test.img` → `/dev/mdN` → `bcachefs format` НАШЕЙ сборкой. Всё в `tmp/` (gitignored). Живой пул не трогаем (константа AGENTS.md).

## Тест-сьют

xfstests на FreeBSD не портирован — **замена: pjdfstest** (POSIX-смоук, развивается в портах) + собственные паттерны нагрузки (ed2k-ферма хардлинков: create/rename/link/unlink шторм; см. bench/). CI-xfstests апстрима покрывает FUSE-режим на Linux — наш слой отличий (fuser+libfuse+mount_fusefs) закрываем контролем fuse-ufs (порт fusefs-ufs: собрать и прогнать как референс в T08).
