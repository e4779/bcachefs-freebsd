# bcf012: пере-вывод условия парковки pending-хвоста из кода

Дата: 2026-11-17. Автор: adversarial reviewer (fresh eyes). Репозиторий: только чтение.
Prod: НЕ тронут (ноль команд к девайсам; все команды ниже — ПРОПИСАНЫ, не выполнены).
База: tools/fs/data/reconcile/{needs_reconcile,plan,work,scan,trigger}.rs, tools/fs/data/update_feasible.rs,
tools/fs/fs/inode_opts.rs, tools/fs/data/durability.rs, tools/fs/data/update_feasible.rs + show-super факты из задачи.

## Дайджест (≤12 строк)

1. **Топ-1 условие (btree, «нельзя улучшить раскладку»):** btree-узел с 2 репликами (nvme+hdd): metadata_target=none
   резолвится в entry.background_target = **foreground_target = nvme** (inode_opts.rs:214) → need target по hdd-реплике
   (needs_reconcile.rs:110-116) → kill → Move → но write_btree_feasible (update_feasible.rs:152-161):
   improves_placement (1>1)=false, improves_durability (2<2)=false → **no_rw_devs by design** → parks_on (plan.rs:316-325,
   work.rs:495-496) → pending, ноль движения. При 2 девайсах и metadata_replicas=2 второй реплике некуда встать в target —
   **узел паркуется навсегда; это инвариант конфигурации, не space-проблема.** Comment в коде прямо говорит: «a rewrite
   that can't improve placement "succeeds" off target and requeues forever».
2. **Запасное (btree 1 реплика):** durability total=1 < metadata_replicas=2 (needs_reconcile.rs:159-160, hipri) →
   только need replicas, kills пусты → `only(data_replicas)` → **Plan::Park(Replicas)** (plan.rs:187-188) на уровне
   плана. Работает при dur=1 не хуже, чем при ошибочном dur=0 прошлой версии вывода: факт dur=0 был ложный, а
   механизм 1<2 — выжил пере-проверку.
3. **Точная read-only команда подтверждения:** `bcachefs reconcile status -t pending,target,replicas,high_priority <mount>` —
   таблица «тип работы × [data, metadata]» из диска-учёта (ioctl чтение, sysfs): `pending[metadata]≈12.4M + pending[data]≈0`
   ⇒ хвост — btree (пункты 1-2). Подтверждение per-key: `kvdb <devs> list reconcile_scan 3:0-4:0 --key-only` (parked
   btree-узлы, work id pending=3) и `kvdb <devs> list reconcile_pending --key-only` (parked user-экстенты).

## Производная опционная матрица (что кормит reconcile из суперблока)

get_io_opts (inode_opts.rs:336+) → get_fs(metadata): btree-поинтеры берут **metadata_***: data_replicas=metadata_replicas=2,
checksum=metadata_checksum, compression=0, ec=0, **background_target = metadata_target≠0 ? metadata_target : foreground_target
= nvme** (inode_opts.rs:214). User-данные берут инодные/fs опты: data_replicas=1, background_target=hdd, promote_target=nvme
(promote в need-логике не участвует вовсе — нет need-бита). fixups: data_replicas==1 ⇒ erasure_code=0 (inode_opts.rs:182-183).

Durability-семантика (durability.rs): total = сумма dur некэшированных поинтеров (девайс считается 1 раз), cached=0,
BCH_SB_MEMBER_INVALID=0, min_durability = минимум per-pointer desired (padding-поинтер даёт 0). Оба девайса dur=1.

## Таблица: все условия, дающие Park вместо Move/Nothing

| # | Условие | Код | Совместимо с суперблоком (meta_rep=2, data_rep=1, dur 1+1, fg=nvme, bg=hdd, meta_tgt=none)? | Какой prod-read подтвердит |
|---|---------|-----|-----|------|
| P1 | `only(data_replicas)` при need=replicas и пустых kills: «data_replicas не сходится точно» — недореплицированный (total<replicas, hipri) без bad/evac-девайсов, или переваренная без допустимого drop | plan.rs:187-188; need: needs_reconcile.rs:159-160,163-164; kills: plan.rs:213-217 (total<=want → только bad/evac) | **ДА для btree:** узел с 1 репликой на nvme: total=1<2, hipri, kills пусты (девайсы healthy) → Park(Replicas). **НЕТ для user data:** при replicas=1 и dur 1+1 total=1: 1<1 false; 1≥1+1 false — need replicas вообще не ставится; over-replication (2 поинтера) всегда даёт drop → Move | `fs usage`/`reconcile status`: строка `replicas` [metadata]>0, [data]=0; `kvdb get extents <pos>`: `need_rb=data_replicas hipri` |
| P2a | Move запланирован, но write-проверка говорит «переписывание ничего не улучшит»: btree-узел nvme+hdd, resolved target=nvme: improves_placement (avail_nvme 1 > on_target 1) false; improves_durability (dur 2 < rep 2) false; degrades false → no_rw_devs **by design** | work.rs:495-496 → plan.rs:316-325 (`parks_on`: no_rw_devs \| insufficient_devices \| ENOSPC, кроме transient ec) ← update_feasible.rs:128-161 (`write_btree_feasible`, no_room:161) | **ДА — главный кандидат на статичный хвост:** каждый полностью реплицированный btree-узел со 2-й репликой на hdd паркуется навсегда (2 девайса → 2-я реплика неизбежно вне target). «ENOSPC-stuck» карточки — это placement-инвариант, не space | `reconcile status`: `target[metadata]`→0 после кика при `pending[metadata]` росте 1:1 (это и наблюдалось); `kvdb list reconcile_scan 3:` count × btree_sectors == pending[metadata] |
| P2b | Move nvme→hdd для user-экстента падает ENOSPC-классом: hdd нет свободных бакетов на watermark без шансов copygc (no_rw_devs), insufficient_devices, ENOSPC | тот же parks_on; feasibility для данных: update_feasible.rs:162-190 (`durability_available` по target-девам, free==0 && !copygc-progress) | **Частично совместим — не решён из конфига:** hdd RW, 3.6T при ~1T данных ⇒ ожидался бы дрейн. Если `pending[data]>0` — реальный фейл аллокации на hdd (watermark/free_now) | `reconcile status`: `pending[data]`>0 и/или `target[data]`>0; `fs usage` Free/free_now; dev_usage hdd |
| P3 | Уже-parked ключ перепроверяется: can_do_data_update снова фейлится тем же классом → остаётся parked (не новый park — механика «статичности» хвоста) | work.rs:472-476 | ДА — поддерживает «переживает перемонты, ноль движения»: pending-бит в extent-entry (btree, journaled) | сам факт статичности floor'а |
| P4 | EC: `need(ec) && entry.ec≠0 && !can_form_ec_stripe && only(ec)` → Park(NoStripe) | plan.rs:160-162; can_form: fs.can_form_ec_stripe | **НЕТ:** EC выключен (data_replicas=1 форсирует erasure_code=0, inode_opts.rs:182; ec-поинтеров нет) | `reconcile status`: строки `erasure_code`, `stripes` = 0 |
| P5 | Страйпы: stripes_pending (память, ин-мемо парк) | work.rs (StripeRepair Err→stripe_park) | НЕТ — только EC-страйпы | то же |

Move-условия (≠park), для границы: kill-маска по checksum/compression/target mismatch (plan.rs:148-159), bad/evacuating-поинтеры и drop-sim переварки (plan.rs:212-260), extra_replicas (EC, plan.rs:170). Nothing: нет entry/need=0, wb-race, ec_pending, «confused» (plan.rs:190-196).

Разблокировка (unpark): need сошёлся → entry снесена (needs_reconcile.rs:172-181: pending сохраняется пока need не сжался; новый hipri сбрасывает pending); удачный move; уход с pending для движимого на rotational (work.rs:482-483); смена конфига/девайсов → pending scan cookie (scan.rs; opts/change.rs:59,76; sysfs trigger; USR1→telemetry.rs:356→work.rs:963). Для P2a **ни один unpark-триггер не помогает** — need воспроизводится сразу: конфиг должен измениться (см. ниже).

## Ответы на (а)-(д)

**(а) Сходится ли need.** User data (replicas=1, dur 1): need replicas **не ставится никогда** в этом конфиге
(1<1 нет; 1≥2 нет) — Park(Replicas) для user data невыводим; возможен только P2b. Btree (replicas=2, dur 1+1):
1-реплиочный узел → P1; 2-реплиочный (nvme+hdd) → P2a; 2-реплиочный целиком в target **невозможен** (в target 1 девайс).
Итого: **каждый btree-узел паркуется тем или иным путём** — need сходится, хвост объясняется метаданными, а не данными.
Прошлый вывод был фальсифицирован в факте (nvme dur=1, не 0), но его класс (replicas-мисматч метаданных) выжил — с
исправленной механикой: не «поинтер весит 0», а «2<2 недобор» и «нельзя улучшить раскладку». «Фикс metadata_replicas=1»
действительно осушает btree-парки (1<1 нет; 2 поинтера → drop-sim → nr_ptrs>replicas = progress, update_feasible.rs:144-146),
но это понижение избыточности метаданных + journal_replicas=0 — решение владельца, не рекомендация.
Альтернатива без понижения: добавить 2-й девайс в nvme-target (improves_placement станет true) или принять floor как инвариант.

**(б) bg_target mismatch: экстенты на nvme — Move или Park?** На уровне плана — **Move** (kill nvme-поинтера,
plan.rs:154-157). Park только рантаймом (P2b). Важно: extent «реальная реплика на hdd + cached-копия на nvme» (promote)
нужды не имеет вовсе (hdd-поинтер в target; cached пропускается, needs_reconcile.rs:110-113 guard `cached()==0`) —
promote-копии не создают работу и не мешают ей. «tgt-лимбо» 206,848 до кика — это ключи с need target ещё БЕЗ pending — их Move ещё ни разу не фейлился park-классом (или попытки не доходили:
гейт io-clock между проходами); USR1-проход как раз и дошёл до них, каждый фейл → parks_on → pending. Учётный переток 1:1 — это буквально rb_accounting_counters (trigger.rs:217-228): pending
**заменяет** биты target|replicas в учёте.

**(в) promote_target=nvme и 907GiB dd_dev0_cached.** Promote не участвует в need/парк-логике (нет need-бита, cached
невидим для durability). 907GiB cached на dev0 ⇒ основная масса данных имеет реальную реплику на hdd (дома) + кэш на
nvme ⇒ она чистая, работы не требует. Хвост — не «вся данные», а свежее/некэшированное (≈6GiB floor) или метаданные.
Cached-копии parked-экстентов остаются на месте и учёту pending не мешают.

**(г) compression-opts mismatch.** Механика: crc.compression_type ≠ opt → need(bg_compression) (needs_reconcile.rs:106)
→ kill → Move (сжать+переписать, target=hdd). Incompressible/unwritten снимают need (needs_reconcile.rs:135-140).
Сам по себе mismatch **не паркует** — парк только в связке с P2b-фейлом записи; фейл не-park-классом (freelist_empty от
alloc_nowait, plan.rs:106-111) даёт skip+ретрай без pending. Если «компрессия 42МБ не применяется» = форграунд-записи
выходят несжатыми при установленном opt — вся новая запись течёт в reconcile-work (не в pending). Различается мгновенно:
строка `compression` в `reconcile status` (data колонка).

**(д) Классификация без tracefs — команды ПРОПИСАНЫ, НЕ ВЫПОЛНЕНЫ (граница задачи).**

| Команда (примерный синтаксис) | Что покажет | Риск (честно) |
|---|---|---|
| `bcachefs reconcile status -t pending,target,replicas,high_priority,compression,checksum,erasure_code <mountpoint>` (src/commands/reconcile.rs:73-77,86-133) | Таблица «тип × [data, metadata]» секторов + `Scan pending` + sysfs reconcile_status (фаза/wait/backtrace). **Главный дискриминатор**: pending[metadata] vs pending[data] | Read-only: query_accounting ioctl + чтение sysfs-атрибутов. Admin-gated. Конкуренция — read-локи, при idle-пуле ≈0. Самый безопасный первый шаг |
| `bcachefs fs usage -f rebalance_work <mountpoint>` (src/commands/fs_usage.rs:131-137,272-285) | То же accounting + `dev_leaving` (дробь dev1-limbo drip H2) + replicas-строки | Read-only ioctl. Безопасно |
| `kvdb <devs> list reconcile_pending --key-only` (src/commands/kvdb.rs; online: только чтение через BCH_IOCTL_QUERY_BTREE_KEYS, «writes are refused», Fs открыт noexcl\|nostart «never started, journal never read») | Parked **user-data/reflink** ключи: позиции (data pos), число. Позиция маппится назад 1:1 (rb_work_to_data_pos) | Read-only stateless ioctl, без recovery/repair/replay (fs смонтирован). Read-локи на wb-btree — короткие. НЕ путать с `kvdb --rw` и с `reconcile wait`/sysfs `trigger_*` — те пишут/будят |
| `kvdb <devs> get extents <inode:offset>` | Полный ключ с reconcile-entry текстом: `need_rb=... hipri/pending replicas=2 checksum=... background_target=nvme` (trigger.rs:extent_reconcile_to_text) — **per-key WHY** | То же, одна ключ-читка |
| `kvdb <devs> list reconcile_scan 3:0-4:0 --key-only` | Parked **btree-узлы**: backpointer'ы work id pending=3 (trigger.rs: add_reconcile_bp; level>0 ключи живут в reconcile_scan, НЕ в reconcile_pending). Каждый bp.v.pos = (btree_id, level, pos) узла | То же. Подсчёт count × btree_sectors (nodesize>>9; при дефолт 256KiB = 512) против pending[metadata] — проверка identity **без подгонки** |
| `bcachefs dump` (src/commands/dump.rs, qcow2) | Полные метаданные снапшотом | **Наибольший риск-класс: читает сырые девайсы** — по границе задачи НЕ выполняется; выполнение — отдельное решение владельца. Для классификации хвоста избыточен |

Что команды НЕ дадут: per-key trace `reconcile_set_pending` (event_add_trace) без tracefs-канала; историю фейлов
(каким именно ENOSPC-классом упал P2b) — только текущее состояние. Для P2b-диагноза достаточно dev_usage/free_now hdd.

## Перечитка USR1-эксперимента (код-механика наблюдения)

USR1 → `fs.reconcile_pending_wakeup()` (telemetry.rs:356) → `request_scan(pending, wakeup=true)` (work.rs:963) →
следующий pass: scan-фаза видит pending-cookie (`scan.rs`, work.rs scan_step: `p.pending=Some`) → гоняются ВСЕ фазы,
pending-фазы — последними (work.rs PHASES, run_phases: `phase.is_pending() && p.pending.is_none() → return`).
tgt-ключи (need target, не parked) лежат в reconcile_work и ходятся normal-фазой каждого прохода; при проходе их Move
фейлится park-классом → `pending_mod(true)` → учёт: target-биты сняты, pending-бит поставлен (trigger.rs:221-223) —
**вот 1:1 «tgt→pend, ноль движения»**. Важное следствие: если бы фейл был need_copygc — парк НЕ ставится (work.rs phase_walk:
need_copygc → copygc_wakeup + wait, ретрай); значит наблюдаемый фейл — no_rw_devs/insufficient_devices/ENOSPC. Для btree
это гарантировано by-design (P2a); для user data — вопрос открыт (P2b). Backtrace Copygc::sleep→io_clock (copygc.rs:675,
work.rs wait:1136+) — гейт прогресса между kick-окнами (io-clock тикает только от записей), не причина парков —
подтверждается кодом: wait() = 1/64 capacity меньшего RW-девайса WRITE-секторов (work.rs:1112-1136).

## Дисциплина фальсификатора

- «pend = 24350×512» **не используется как доказательство**. Любые суммы ключей кратны 512 (сектор-юниты) — кратность
  не диагностична. Identity «pend[metadata] == (число bp в reconcile_scan:3) × btree_sectors» проверяется ЛИСТИНГОМ
  (команда 5), и только она.
- Всё, что не выведено прямо из кода+суперблока, помечено: composition хвоста (btree vs data) — НЕ подтверждён,
  даётся командой; P2b-фейл hdd — НЕ подтверждён; nodesize prod — НЕ подтверждён (btree_sectors условно 512).

## Остаточные риски / неизвестные

1. Состав хвоста: если `pending[metadata]≈12.4M` — инвариант P1+P2a, дрейн триггерами невозможен in-principle;
   bcf025 (cron USR1) тогда бессмыслен как дренаж (кик перепаркует 1:1 — что и наблюдалось).
2. Если `pending[data]>0` — реальный аллокационный фейл на hdd (watermark/free_now) — отдельная задача с dev_usage.
3. Ремеди P1/P2a — только конфиг (metadata_replicas=1 — с потерей избыточности; 2-й девайс в nvme-target — железо) или
   документировать floor как upstream-инвариант (карточка bcf012 уже допускает «document it as an invariant»).
4. kvdb-команды требуют admin-gated доступ к смонтированному fs; на FreeBSD/FUSE — через handle fusemount (ioctl chardev);
   если QUERY_BTREE_KEYS на wb-btree в бортовой реализации что-то ограничит — fallback: `bcachefs list` (list.rs, тот же ioctl).
