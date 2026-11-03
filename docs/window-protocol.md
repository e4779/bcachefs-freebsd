# Протокол окна ro-маунта живого пула (Q1 final step)

> Статус: все технические гейты зелёные (dirty-ro PASS, crash-recovery PASS, multi-device PASS, T08 PASS). Окно = решение владельца. Диск ada0 — «NEVER-TOUCH»-константа: работаем только чтением, НИ ОДНОЙ записи.

## Предусловия (все обязательны)

1. vmm-дебаг-сессия закрыта; bcachefsbox VM репетирована stop→start→сервисы на новом железе.
2. `scripts/window-baseline.sh` прогнан: dump-super обоих членов пула сохранён (baseline).
3. Пул не шифрован (проверка владельцем); если шифрован — стоп, keyutils-заглушка не пройдёт.
4. Память: free+inactive ≥ 1.2 GB; демон под `rlimit-run.sh`.
5. Окно запланировано 60–90 минут; откат = старт VM через run-hlab.sh.

## Последовательность окна

1. Чистый shutdown bcachefsbox (НЕ destroy) → референсный fsck «clean» в VM (последняя проверка журнала).
2. Диски освобождены (VM выключена) → `camcontrol identify` серийники совпадают с ожидаемыми (nda0p3 = NVMe, ada0 = HDD).
3. ro-маунт: `doas nice -n 19 ./scripts/rlimit-run.sh 2500 ./tools/bcachefs mount -o fuse,ro /dev/nda0p3:/dev/ada0 /mnt/pool-check` (точки — по факту GEOM).
4. Внешний счётчик записей ВСЁ окно: `gstat -d ada0` / iostat — первый ненулевой write = немедленный `umount -f` + разбор.
5. Обход + выборочные sha256 против манифеста; замер RSS демона; тайм-бокс.
6. `umount` → `dump-super` → `diff` с baseline — бит-бит.
7. Старт VM (run-hlab.sh), проверка сервисов, poolmount.

## Kill-критерии (немедленный выход)

- Любая ошибка чексумм при чтении (= kill review проекта, §8).
- Любой write-BIO на члены пула.
- Паника/смерть демона.
- Грязный журнал на входе (после чистого shutdown VM его быть не должно).
