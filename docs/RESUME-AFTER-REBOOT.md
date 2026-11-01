# RESUME после ребута hlab (спринт A, финиш G2)

> Написано 2026-11-01 перед ребутом. Всё закоммичено (HEAD на момент паузы), маунтов/md/процессов нет, дерево tools/ с инкрементальными артефактами цело (сборка продолжится с места).

## Контекст одной строкой

bcachefs УЖЕ работает на FreeBSD (G0/G1/T10/T11-core ✅); остался G2: пересборка с патчем 045 (chmod-затирание S_IFDIR — убийца pjdfstest) → полный прогон на свежей ФС → G3 бенчи.

## Шаги

1. **Re-arm среды:** `doas kldload fusefs` (модуль не переживает ребут); проверить `sysctl vfs.fusefs.kernelabi_major` (=7).
2. **Пересборка (Run 28-продолжение, слот оркестратора):**
   ```sh
   cd ~/projects/bcachefs-freebsd/tools
   PKG_CONFIG_PATH=$PWD/../overlay/pkgconfig CARGO_BUILD_JOBS=2 \
     nice -n 19 ../scripts/rlimit-run.sh 2500 gmake -j1
   ```
   (инкрементально: .o-файлы целы, cargo дособерёт fusemount-зависимые крейты; ожидание ~5-10 мин; сторож: tail -F /var/log/messages | grep -iE 'oom|rctl|killed')
3. **Свежая тестовая ФС:** `rm -f /tmp/bch-file.img && truncate -s 512m /tmp/bch-file.img && doas ./tools/bcachefs format --label g2final /tmp/bch-file.img`
4. **G2 прогон:**
   ```sh
   doas ./tools/bcachefs mount -o fuse /tmp/bch-file.img /tmp/bch-mnt   # sleep 8, проверить mount | grep bch
   cd /tmp/bch-mnt && doas env RUST_BACKTRACE=1 /usr/local/bin/pjdfstest > /tmp/pjdf-final.log 2>&1
   doas umount /tmp/bch-mnt && sleep 2
   doas ./tools/bcachefs fsck /tmp/bch-file.img   # нужен чистый 'clean shutdown'
   ```
   Оценка: failures по FUSE-присущей механике (mknod/xattr/extattr, RENAME_*, flock, fallocate — список-кандидатов из 11a) — фиксируем как expected; всё остальное — баги на разбор.
5. **G3 бенчи:** `bench/run-all.sh /tmp/bch-mnt` (на rw-маунте), сравнение с планкой моста 12.8 мс/файл (базовые числа — homelab runbook 02).

## Не забыть

- Патч 045 уже применён в tools/ (штамп стоит) — НЕ пере-apply'ить вслепую.
- Память: перед сборкой free+inactive ≥ 1.2GB (правило AGENTS).
- T08 (контроль fuse-ufs) всё ещё ждёт одобрения порта fusefs-ufs.
- Журналы: docs/notes/04a (C-сборка), 05a (Rust+T10), 11a (бисект) — полная хроника с корнями.
