# Протокол окна ro-маунта живого пула (Q1 final step, Zen5-правка 2026-11-04)

> Все технические гейты зелёные. Окно = решение владельца.
> **НЕМОДНАЯ КОНСТАНТА (переезд Zen5): ada0 = zdata (TOSHIBA 41PCK0WLFAYG) — NEVER-TOUCH. bcachefs-члены: nda0p3 (KINGSTON 50026B7383F5EDA1) + ada1 (TOSHIBA 41OYK6J4FAYG).** Имена могли поменяться снова — перед окном сверять по СЕРИЙНИКАМ (camcontrol), не по именам.

## Предусловия

1. vmm-сессия закрыта; VM репетирована stop→start (закрыто 2026-11-04, runbook 19).
2. `scripts/window-baseline.sh` прогнан: show-super обоих членов + серийники сохранены.
3. Пул не шифрован — подтверждено разведкой (show-super: encrypted-полей нет, External UUID 0ec475a1-…, 2 члена).
4. Память free+inactive ≥ 1.2 GB ✅ (замер разведки ~7.1 GB; учитывать llama-zoo нагрузку).

## Последовательность окна

0. **ПРИСТАВКА (шрам 2026-11-03, без неё хост виснет):** `doas service copyparty navidrome qbittorrent stash amutorrent amuled stop` → `doas service poolmount stop` → убедиться `/mnt/pool` отмонтирован.
1. Чистый shutdown VM (в консоли; НЕ destroy): `poweroff` в госте → дождаться выхода bhyve (run-hlab.sh луп сам завершится).
2. Референсная проверка в VM НЕ возможна после выключения — вместо неё: `show-super` обоих членов с хоста, ожидать **Clean: 1**; если Clean: 0 → стоп, разбор (журнал грязный).
3. Сверка серийников (camcontrol) → ro-маунт: `doas nice -n 19 ./scripts/rlimit-run.sh 2500 ./tools/bcachefs mount -o fuse,ro /dev/nda0p3:/dev/ada1 /mnt/pool-check` (BCACHEFS_FUSE_LOG=/var/log/bcachefs-window.log).
4. Счётчик записей ВСЁ окно: `gstat -d ada1 -I 1` в отдельном окне — первый ненулевой write на ada1/nda0 = немедленный `umount -f` + разбор.
5. Обход + выборочные sha256 против манифеста (tmp/pool-manifest.sha256); замер RSS демона; тайм-бокс.
6. `umount` → `show-super` → diff с baseline — бит-бит.
7. Откат/завершение: `doas sh /vm/bcachefsbox/run-hlab.sh` (или service bcachefsbox start) → service poolmount start → сервисы → проверка /mnt/pool.

## Kill-критерии (немедленный выход + разбор)

- Любая ошибка чексумм при чтении (= kill review проекта).
- Любой write-BIO на члены пула.
- Паника/смерть демона.
- Clean: 0 после чистого shutdown VM (грязный журнал на входе).
