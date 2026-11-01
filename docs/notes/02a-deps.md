# T02: аудит зависимостей bcachefs-tools (d48ba1a) → FreeBSD

Источник: INSTALL.md + Makefile:161 \`PKGCONFIG_LIBS="blkid uuid liburcu libsodium zlib liblz4 libzstd libudev libkeyutils libunwind"\`, Makefile:187 \`LDLIBS+=-lm -lpthread -lrt -lkeyutils -laio -ldl\`; bindgen-cli на PATH; Rust MSRV 1.85 (хост 1.98 ✅).

| Зависимость | Статус на хосте | Вердикт |
|---|---|---|
| pkg-config | ✅ pkgconf | ок |
| uuid | ✅ libuuid 2.42.4 | ок |
| liburcu | ✅ | ок (версия порта свежее bookworm — RCU polling API есть) |
| libsodium | ✅ | ок |
| zlib | ✅ базовый libz | ок |
| liblz4 | ✅ | ок |
| libzstd | ✅ | ок |
| libudev | ✅ libudev-devd | shim, ок |
| fuse3 | ✅ fusefs-libs3 (libfuse3.so.4) | для FUSE-фазы |
| **blkid** | есть в портах | поставить |
| **libkeyutils** | ❌ нет порта | заглушка в overlay (keyring не нужен для тест-маунта) |
| **libunwind** | порт есть | поставить |
| **libclang** | не найден | нужен bindgen; поставить порт или использовать из llvm |
| bindgen-cli | ❌ | cargo install bindgen-cli (под rlimit-run) |
| **-laio (Linux AIO)** | ❌ | главный вопрос T04: linux/ шимы (bio/blkdev) — под FreeBSD reimplement в overlay (POSIX AIO/pread-pwrite) |
| **-lrt** | база? есть | вероятно убрать/пустышка |
| -ldl | обычно в libc | проверить |
| libaio(пакет), valgrind | — | valgrind только для тестов, пропускаем |

Вывод: 8/10 pkg-config-библиотек уже стоят; реальные работы T04 = **blkid, keyutils, unwind (линковка) + -laio/-lrt/-ldl + linux/-шины bio/blkdev**. Всё через overlay/, атомарными коммитами.
