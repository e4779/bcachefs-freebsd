bcf012 fix-B: metadata_target = диск-группа (pool.nvme + pool.hdd) на FUSE-порте
================================================================================

Source: чтение кода tools/ (tree @ 7aca4d1), `./tools/bcachefs --help` (CLI-surface, без устройств)
-> refs/bcachefs-fuse-port -> refs/bcf012 -> refs/bcachefs-native-consilium-verdict

ДИДЖЕСТ (вердикт ≤12 строк)
---------------------------

ВЕРДИКТ: **B применим — только офлайн** (unmount + суперблок-мутации; mount-option маршрут на этой линии мёртв).
Последовательность: (0) `show-super /dev/nda0p3 -f all` — снять откаточные значения → (1) `service poolfuse onestop`,
проверить что демон погас → (2) `set-fs-option -d 0 --label=pool.nvme /dev/nda0p3` → (3) `set-fs-option -d 1
--label=pool.hdd /dev/nda0p3` → (4) verify show-super → (5) `set-fs-option --metadata-target=pool /dev/nda0p3`
(обязательно отдельным вызовом ПОСЛЕ 2–3) → (6) `service poolfuse onestart` → (7) `kill -WINCH <новый pid>`
(полный re-triage) → (8) наблюдение по ring `/var/run/bcachefs-fuse/<uuid>/accounting.json` (jq `.reconcile`,
`.scan_pending`; SIGUSR1 = kick).
rc.d — БЕЗ изменений: metadata_target персистентен в суперблоке; `-o metadata_target=…` при mount тихо
дропается (flags mount_old + parse требует открытый fs, parse_later не подключён: mount.rs:780, fusemount.rs:1979,
opts.rs:548-566).
Главный риск: `set-fs-option` при живом демоне на FreeBSD молча идёт офлайн-путём и пишет суперблок ПОД
работающим демоном (open_if_mounted не матчит device-path, handle.rs:217-243) → жёсткое правило unmount-first.
Q5: подтверждено кодом — need не потребует третьей реплики (см. §5).

1. Диск-группы: как создать parent-группу "pool" с детьми nvme/hdd
------------------------------------------------------------------

CLI-surface (проверено `device --help`): подкоманды `device` = add / online / offline / remove / evacuate /
set-state / resize / resize-journal. **`device set-label` НЕ существует.** `format --label=pool.nvme` — только
при форматировании (реформат живого пула не вариант); `device add -l` — только для нового устройства.

Единственный рабочий путь на этой линии: **`set-fs-option --label=<dotted-path>` офлайн**.

- `label` — device-scoped opt: `flags = device | format | runtime`, `sb = bch_member::group`
  (opts_types.rs:548-552). CLI-алиасы: `--label` (opts.rs:35 — short `-l` есть только у device add).
- Офлайн-парсинг: `opt_parse(Some(&fs), …)` → `LABEL_OPT.parse` → `dev_label_resolve` →
  `disk_path_find_or_create` (disk_groups.rs:381-394): находит или **создаёт всю цепочку** "pool" → "nvme"
  за один вызов; `groups_reserve` растит секцию disk_groups all-or-nothing (disk_groups.rs:199-213), затем
  `group_add` в первый deleted-слот (disk_groups.rs:219-236).
- Запись: `opt_set_sb(Some(ca), …)` member.group = leaf-index+1, затем `write_super_ret` (set_option.rs:131-150,
  236-253) → **мутация суперблока**, офлайн.
- Runtime-путь (Linux: sysfs `dev-N/label`, opt_hook пересобирает дерево: opts/change.rs:62-70) у нас недоступен:
  online `set-fs-option` умеет писать ТОЛЬКО sysfs (set_option.rs:81-100), а sysfs fd = /dev/null-заглушка
  (handle.rs:335-354) → `openat("options/…") → ENOTDIR`. Так что label-set **исключительно офлайн**.

Точная последовательность создания дерева (см. §4, шаги 2-3):

    ./tools/bcachefs set-fs-option -d 0 --label=pool.nvme /dev/nda0p3
    ./tools/bcachefs set-fs-option -d 1 --label=pool.hdd /dev/nda0p3

`-d N` выбирает member по индексу; позиционный device (≥1 обязателен) служит для открытия ФС (set_option.rs:37-39,
`devices: required(true)`). Открытие офлайн: `open_online_or_offline` → scan-l, `nostart`/`will_not_start`
(set_option.rs:57-61); `opt_hook_io` не регистрирует reconcile-сканы пока `!BCH_FS_started` (opts/change.rs:30-33) —
чисто.

Нюанс, который надо знать: старые leaf-группы `nvme`/`hdd` (parent=0) **остаются в таблице пустыми** — CLI удаления
групп нет. `group_find` возвращает ПЕРВЫЙ match (disk_groups.rs:189-197), поэтому после relabel
`--metadata-target=nvme` резолвится в старую ПУСТУЮ группу (0 устройств). После перехода на дерево leaf-имена не
таргетить; пустые остатки косметика.

2. metadata_target как mount-option: группа vs лист
---------------------------------------------------

**Не работает — тихий no-op.** Цепочка по коду:

- flags metadata_target: `fs | format | mount_old | runtime` — флага `mount` НЕТ (opts_types.rs:208-211).
- Точка монтирования: `mount.rs:780` и `fusemount.rs:1979` — `parse_mount_opts(None, fs_opts, ignore_unknown=true)`,
  т.е. fs=None, `parse_later` не передан.
- `TARGET_OPT.parse` требует открытый ФС (`opt_parse_args` → `option_needs_open_fs`, disk_groups.rs:556-560);
  в `parse_one_mount_opt` ветка needs_open_fs при `parse_later=None` просто делает `return Ok(())` — опция
  **тихо выбрасывается** (opts.rs:548-551, 617-629).
- Даже если бы ФС был открыт: ветка `OPT_MOUNT_OLD` (opts.rs:563-566) логирует "option … may no longer be
  specified at mount time; set via sysfs opts dir" и тоже дропает значение.

Куда резолвится значение, когда парсинг всё же происходит (офлайн `set-fs-option`, runtime-sysfs в Linux):
`opt_target_parse` (disk_groups.rs:536-557):

1. `none`/пусто → `Target::Null` (=0) — путь отката;
2. имя устройства (с/без `/dev/`) → `Target::Dev`;
3. иначе `disk_path_find` — точный dotted-path по секции disk_groups суперблока → `Target::Group(TARGET_GROUP_START+g)`.

Parent-группа и leaf резолвятся одинаково (обе — Group-индекс); разница в membership: маска parent-группы включает
всех потомков — `groups_to_cpu` идёт от member.group вверх по цепочке родителей и ставит бит девайса в каждой
(alloc/disk_groups.rs:407-425; юнит-тесты на вложенность: disk_groups.rs:836-849). То есть `metadata_target=pool`
с детьми pool.nvme/pool.hdd = {dev0, dev1}.

Вывод для rc.d: строку `-o` НЕ менять и metadata_target туда НЕ добавлять — не подхватится. Персистентность даёт
суперблок (`sb = bch_sb::metadata_target`): офлайн-set подхватывается при следующем монтировании автоматически
(sb → fs.opts при старте ФС).

3. set-fs-option: живая/офлайн ФС
---------------------------------

- **Online**: только sysfs-запись. metadata_target — OPT_RUNTIME, поэтому CLI доходит до
  `sysfs_write_str(fd, "options/metadata_target")`; на порте fd = /dev/null → ENOTDIR → "Error setting
  metadata_target: …", в конце `bail!("1 of 1 option(s) could not be set")` (set_option.rs:81-130). Фейлится
  безопасно, но не работает. (Комментарий в коде прямо говорит: online path can only write sysfs.)
- **Offline**: `open_scan` c nostart → `opt_parse(Some(&fs), …)` (лейблы создадут цепочку, таргет резолвится по
  sb) → `opt_hook_pre_set` → `opt_set_sb` → `write_super_ret` (set_option.rs:131-160, 236-253) = **мутация
  суперблока**. Работает у нас только так.
- ЛОВУШКА ПОРТА: на FreeBSD `open_if_mounted` для **device-path** не распознаёт смонтированную ФС —
  `snapshot_lookup` сравнивает канонический путь только с mountpoint (handle.rs:217-243), QUERY_UUID-ioctl на
  блочном девайсе не отвечает. Значит `set-fs-option /dev/nda0p3 …` при ЖИВОМ демоне молча выбирает офлайн-ветку
  и пишет суперблок на диск под работающим демоном (его следующая запись sb перекроет, или останется рассинхрон).
  **Жёсткое правило: сначала unmount, демона больше нет — потом set-fs-option.**

4. ИТОГ: безопасная последовательность применения B
---------------------------------------------------

Каждый шаг помечен: [safe-live] безопасен при живом демоне / [unmount] требует unmount / [SB] мутация суперблока.

    # ── 0. [safe-live] откаточные значения (read-only; noexcl/nochanges/nostart, super_cmd.rs:69-74)
    cd ~/projects/bcachefs-freebsd
    ./tools/bcachefs show-super /dev/nda0p3 -f all > tmp/pool-sb-before.txt
    #  зафиксировать в нём: metadata_target (секция ext) и labels обоих member'ов (disk_groups/members)

    # ── 1. [unmount] остановить сервис
    service poolfuse onestop
    mount | grep " /mnt/pool " || echo OK-unmounted
    pgrep -f "bcachefs mount" || echo OK-daemon-gone

    # ── 2. [SB] дерево лейблов: создаёт цепочку pool→nvme (шаг 3 создаст pool→hdd под тем же pool)
    ./tools/bcachefs set-fs-option -d 0 --label=pool.nvme /dev/nda0p3

    # ── 3. [SB] второй member в то же дерево
    ./tools/bcachefs set-fs-option -d 1 --label=pool.hdd /dev/nda0p3

    # ── 4. [safe] verify дерева (read-only)
    ./tools/bcachefs show-super /dev/nda0p3 -f all | sed -n '/disk_groups/,/^\[/p'

    # ── 5. [SB] metadata_target = группа; ОБЯЗАТЕЛЬНО отдельным вызовом ПОСЛЕ шагов 2-3
    ./tools/bcachefs set-fs-option --metadata-target=pool /dev/nda0p3
    # (в одном вызове с --label не совмещать: opts обрабатываются в порядке таблицы OPTS —
    #  metadata_target (opts_types.rs:211) раньше label (opts_types.rs:552) → "no device or disk label pool")

    # ── 6. [safe] verify: metadata_target=pool в ext
    ./tools/bcachefs show-super /dev/nda0p3 -f all | grep -i metadata_target

    # ── 7. [bounce] поднять обратно
    service poolfuse onestart
    tail /var/log/poolfuse-start.log

    # ── 8. [safe-live] полный re-triage скан: SIGWINCH новому демону
    PID=$(pgrep -f "bcachefs mount"); kill -WINCH "$PID"
    # (эквивалент one-shot set_fs_needs_reconcile recovery-pass, telemetry.rs:101-105; pids меняются при bounce)

    # ── 9. [safe-live] наблюдение: ring обновляется каждые 60s
    U=$(ls /var/run/bcachefs-fuse/); cat /var/run/bcachefs-fuse/$U/accounting.json | jq '.reconcile, .scan_pending'
    #  pend (background_target / data_replicas счётчики) не должен расти по метаданным;
    #  kick pending-скана при необходимости: kill -USR1 "$PID" (telemetry.rs:90-95)

    # rc.d (/usr/local/etc/rc.d/poolfuse, source scripts/rc.d/poolfuse): ИЗМЕНЕНИЙ НЕ НУЖНО.

Что наблюдать после: (а) ring `.reconcile` pend-счётчики не растут (у 2/2 on-target need нет вовсе);
(б) `.scan_pending` → "0"; (в) оконность не меняется (timeout=0 в rc.d остаётся); metadata-записи теперь
распределяются nvme+hdd — чуть больше HDD-мета-активности, латентность со soak-сервисов (amule/qbt) смотреть как
обычно. `reconcile status` CLI на порте мёртв: `sysfs_path_from_fd` делает readlink /proc/self/fd/N на
/dev/null-fd → «resolving sysfs fd N» (sysfs.rs:69-72; команда падает до всяких запросов) — наблюдение только
через ring.

ОТКАТ (старое значение opts обратно):

    service poolfuse onestop
    ./tools/bcachefs set-fs-option --metadata-target=<значение из tmp/pool-sb-before.txt> /dev/nda0p3
    #  если там было 0/не задано:  --metadata-target=none   ("none" → Target::Null, disk_groups.rs:539-541)
    ./tools/bcachefs set-fs-option -d 0 --label=nvme   /dev/nda0p3   # старые группы ещё в таблице → резолвится
    ./tools/bcachefs set-fs-option -d 1 --label=hdd    /dev/nda0p3
    service poolfuse onestart && kill -WINCH "$(pgrep -f 'bcachefs mount')"

5. Риск-чек Q5: need не потребует трёх
--------------------------------------

Утверждение «при metadata_target=группа need исчезает у всех узлов» подтверждается кодом построчно:

- Для btree-ключей io-opts = metadata: `background_target := metadata_target` (если задан), `data_replicas :=
  metadata_replicas` (inode_opts.rs:213-216); btree-указатели идут по metadata scan-cookie (needs_reconcile.rs:284-287,
  комментарий "btree node pointers follow the metadata options").
- Таргет-чек **per-pointer** (needs_reconcile.rs:110-117): `need(background_target)` ставится только если
  `!fs.dev_in_target(dev, …)`. `dev_in_target(Group(g))` = бит девайса в маске группы (disk_groups.rs:316-326);
  маска `pool` содержит ОБА дева (ancestor-walk, disk_groups.rs:414-425) → обе реплики on-target → need не
  выставляется ни одному из 2 указателей (2 из 2).
- Дюрабильность (needs_reconcile.rs:154-163): `durability.total` считает каждый девайс один раз (seen-mask,
  durability.rs:247-253) = 1(nvme)+1(hdd) = 2; `replicas` = metadata_replicas. Недобор: `2 < 2` — false.
  Перебор-чек `durability >= replicas + min`: min = min по указателям dev_durability_desired = 1 → `2 >= 3` —
  false. Ни один `need(data_replicas)` не срабатывает.
- Паддинг (needs_reconcile.rs:168-170): `invalid_devs = acct(2) + invalid(0) − replicas(2) = 0` — ни одного
  BCH_SB_MEMBER_INVALID. **Требования «третьей» реплики нет.**
- ГРАНИЦА ПРИМЕНИМОСТИ: расчёт сходится при metadata_replicas = 2. Если бы было 3 → invalid_devs = −1 →
  фантомный invalid-паддинг. Проверка на шаге 0 (show-super) обязательна; dur=1/dur=1 у обоих девайсов уже
  подтверждена условием задачи.

Риски (сводка)
--------------

1. [главный] `set-fs-option` при живом демоне молча пишет sb в обход демона (device-path не матчится как mounted,
   handle.rs:217-243) → гонка/клоббер. Жёсткое unmount-first, проверка pgrep.
2. Совмещённый вызов `--label` + `--metadata-target` фейлится частично (порядок OPTS: metadata_target раньше
   label) → только раздельные вызовы в порядке §4.
3. Пустые старые leaf-группы nvme/hdd перехватывают резолв по имени (group_find первый match) → после relabel
   leaf-имена не таргетить; удаления групп CLI нет.
4. `-o metadata_target=…` при mount — silent no-op (mount_old + needs-open-fs с parse_later=None) → персистентность
   только через суперблок; rc.d не трогать.
5. `reconcile status/wait` CLI на порте не работают (sysfs-заглушка) — наблюдение только через
   /var/run/bcachefs-fuse ring; pid демона меняется при каждом bounce (SIGUSR1/SIGWINCH — новому pid).

SEE ALSO
--------

bcachefs-native consilium verdict (A=FUSE) — линия, на которой это живёт; fuser 070 SIGURG memo — ring/telemetry
(SIGUSR1/SIGWINCH семантика); hmlb-005 α-окно — soak-наблюдение после bounce.
