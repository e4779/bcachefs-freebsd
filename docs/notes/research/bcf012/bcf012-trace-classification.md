All evidence is in. I have the complete picture — writing the report now.

**The full artifact:**

````markdown
# bcf012 — классификация застрявшего pending-хвоста пула bcachefs (READ-ONLY)

Дата: 2026-11-17 (по ts ring-снапшота 1794798272 ≈ 2026-11-16/17, gen 2038, pid 3325 — подтверждён ring'ом)
Пул: `0ec475a1-a0c1-4877-9f6d-ae54986f43f8`, /mnt/pool, `/dev/nda0p3` (NVMe 1.1T, dev0) + `/dev/ada1` (HDD 3.6T, dev1), формат 1.39.
Хвост: rw_pend = 12,467,200 секторов (ring, kit 066). USR1-проба (ops 7aca4d1): репаркуется 1:1.

---

## 1. Путь трассы reconcile_set_pending — ГЛАВНЫЙ ОТВЕТ: читаемого sysfs-атрибута НЕ СУЩЕСТВУЕТ на этой линии

Проверено по коду и живой системе:

| Что проверено | Результат | Receipt |
|---|---|---|
| Куда пишет текст трассы `event_add_trace(events::reconcile_set_pending, …)` | **Kernel tracepoint** `rust_do_trace_reconcile_set_pending` (TRACE_SYSTEM=`bcachefs`, класс `fs_str`) → **tracefs**, не sysfs | `tools/fs/sb/counters.rs:118-124`, `tools/fs/debug/trace.h:14-40`, `tools/fs/debug/trace.c:25-27` |
| Апстримный (Linux) путь чтения | `/sys/kernel/tracing/events/bcachefs/reconcile_set_pending/{enable,filter,format}` + буфер `/sys/kernel/tracing/trace`. В sysfs bcachefs есть только счётчик `/sys/fs/bcachefs/<uuid>/counters/reconcile_set_pending` (ro-чтение; **запись = reset, запрещено**) | `tools/fs/debug/sysfs.rs:356-403` |
| `/sys/fs/bcachefsfs/0ec475a1-…/` на этой машине | **Не существует.** `/sys` на этом хосте — дерево исходников ядра FreeBSD (в `/sys/fs` — cd9660/fuse/nullfs/…, исходники). linsysfs (`/compat/linux/sys`) содержит только bus/class/dev/devices/kernel — дерева bcachefs нет | ls `/sys/fs`, `/compat/linux/sys`, mount-evidence `docs/evidence/fuse-wedge-20261106-103304/mounts.txt:33-35` |
| sysfs у FUSE-порта | **`/dev/null`-заглушка** (kit 065): «FreeBSD: no sysfs and no FS_IOC_GETFSSYSFSPATH — the sysfs fd is an inert /dev/null placeholder» | `tools/src/wrappers/handle.rs:121-141, 335-354, 364-370` |
| Возможен ли tracepoint в бинаре демона | **Нет: скомпилирован out.** В userspace-сборке `cfg(kernel)` не выставляется («cargo never sets it») и `CONFIG_TRACEPOINTS` не задаётся → `trace_enabled()==false`, `trace(){}` — текст трассы никогда не генерится, работает только счётчик `event_add` | `tools/fs/build_config.rs:61-77`, `tools/fs/build.rs:12-14`, `tools/fs/sb/counters.rs:111-127` |
| BCH_IOCTL-канал CLI к живому демону | **Не реализован**: «FreeBSD: the FUSE daemon's ioctl is unimplemented, so BCH_IOCTL_QUERY_UUID can never answer» → `list`/`counters`/`fs usage`/`reconcile status` против /mnt/pool не работают | `tools/src/wrappers/handle.rs:226-231` |

**Реальные читаемые источники на этой линии (все read-only, использовано в отчёте):**
- Кольцо телеметрии: `/var/run/bcachefs-fuse/0ec475a1-a0c1-4877-9f6d-ae54986f43f8/accounting.json` (каждые 60с, атомарно tmp+rename) — `tools/src/commands/fusemount/telemetry.rs:518-607`. Несёт: `reconcile_work` (по классам pend/tgt/ec/rep/str/chk/cmp/hipri), `reconcile_status`+бэктрейс, `dev_leaving`, `sectors`, `top` (per-dev accounting: dd_dev0_btree/dd_dev1_btree/dd_dev0_cached/leaving_dev1/…), `counters[]` (BCH_COUNTER-массив), `scan_pending`, `recovery_status`.
- SIGINFO (`kill -INFO <pid>` → `siginfo-latest.txt` в ring-dir) и USR1/WINCH — сигнальные рычаги (уже вне моих границ; не использовались, USR1-проба была ранее оператором).

---

## 2. Классификация хвоста по причинам

### 2.0. Формат трассы (что ДОЛЖНО было бы читаться)
- `park()` — `tools/fs/data/reconcile/plan.rs:296-306`: `«can't form ec stripe\n<ключ>» + can_form_ec_stripe(...)` | `«can't match data_replicas=N\n<ключ>»`
- `parks_on()` — `plan.rs:316-337`: `«<ошибка>\n<ключ>\n<data_update_opts>\n» + can_do_data_update(...)` — ошибки только ENOSPC-класса: `data_update_fail_no_rw_devs` | `insufficient_devices` | `ENOSPC` (`plan.rs:319-322`); `ec_alloc_failed_transient` не паркует.

### 2.1. Разбиение хвоста по классам (из ring + арифметики кода)

Узел btree = 512 секторов (256 KiB). Точная арифметика ring-снапшота:

| Величина | Значение | В узлах | Receipt |
|---|---|---|---|
| rw_pend (parked) | **12,467,200 сект.** | **24,350 узлов** (×512 ровно) | ring `reconcile_work.pend=[0,12467200,0]` |
| btree на dev0 (nvme) | 12,467,712 сект. | 24,351 узел | ring `dd_dev0_btree=[9550,12467712,26649088]` |
| btree на dev1 (hdd) | 12,467,712 сект. | 24,351 узел | ring `dd_dev1_btree=[9554,12467712,26665472]` |
| btree_total | 24,935,424 сект. = 2×12,467,712 | 24,351 узел × 2 реплики | ring `btree_total=[24935424,24351,32]` |

→ **Хвост = ВСЯ btree (24,350 из 24,351 узлов; исключён ровно 1 узел), каждый узел в 2 экземплярах (nvme+hdd).** Пользовательских extent'ов в хвосте нет.

| Класс причины | Записей | Секторов | Доля |
|---|---|---|---|
| **replicas** — `can't match data_replicas=N` (park(), plan.rs:305) | ~24,350 | **12,467,200** | ~100% |
| **ec stripe** — `can't form ec stripe` (park(), plan.rs:302) | 0 | 0 | 0% — btree никогда не EC; rw_ec=0 в ring |
| **ENOSPC-класс** — parks_on() (plan.rs:316-337) | 0…≤1 | 0…512 | место свободно (free=3.6G сект.); единственный Move-класс работы = tgt-капля 512 сект. (1 узел, `rw_tgt=[0,512,0]`, `leaving_dev1=[512,0,0]` — H2-«drip») |

### 2.2. Репрезентативные примеры ключей
Тексты bkey+data_update_opts из трассы недоступны (п.1: tracepoints скомпилированы out). Шаблон записи, которую генерил бы ретрай каждого узла (work.rs:454-462 → plan() → Park):
```
can't match data_replicas=2
btree=extents u64s … len=512 [reconcile: need_rb=data_replicas, hipri=1, pending=1, data_replicas=2, background_target=…]
ptr: dev=0(nvme) … | ptr: dev=1(hdd) …
```
Пер-ключевую выгрузку даст (read-only, см. §5): `kvdb`-list `reconcile_pending` / `fs show` — офлайн-пути.

### 2.3. Механика 1:1-репарковки (почему USR1 не двигает хвост)
work.rs:454-462: pending-ретрай → `plan()` → `Plan::Park(Replicas)` → `park()` → снова pending. `pending_mod()` «Nothing without work, or if it's already so» (plan.rs:344-348). Хвост сам НЕ распаркуется: entry unpark'ится только если need-биты ушли (needs_reconcile.rs:183-188), а need воспроизводится конфигурацией при каждом скане.

---

## 3. Конфигурация, которая держит хвост

Факты (ring + код + runbook):
1. **NVMe (dev0) — durability=0 (cache/promote-тир):** в ring есть `dd_dev0_cached=[482295,1901785373,73694953]` (~907 GiB cached-реплик) и НЕ существует `dd_dev1_cached`. В bcachefs-аккаунтинге cached = реплики на durability-0 устройствах. [вывод-инференс, сильный]
2. **Каждый btree-узел лежит на обоих девайсах** (dd_dev0_btree == dd_dev1_btree побайтно) → писалсь с replicas=2 → **metadata_replicas=2** (у btree io-opts = metadata-opts). [вывод-инференс; проверка командой §5]
3. Итог: durability каждого узла = nvme(0) + hdd(1) = **1 < 2** → каждый узел under-replicated → needs_reconcile ставит `need(data_replicas)+hipri` (needs_reconcile.rs:155-162) → plan(): durability.total(1) ≤ want(2), kill'ить нечего (нет bad/evacuating-поинтеров) → **`Park(Replicas 2)`** (plan.rs:204-207, 186-189). Насытить 2 durable-реплики физически невозможно: 1 dur-1 + 1 dur-0 девайс, same-device реплики запрещены.
4. Хронология сходится: reconcile-фича активировалась портом 2026-11-07 (incompat-feature `reconcile`, needs_reconcile.rs:68) → скан пометил ВСЮ btree → парк. 144M-хвост того дня (ENOSPC на полном HDD-target, runbook 11:4x) слился при USR1-дренаже ~240 МБ/с; btree-часть осталась — она не зависит от свободного места.
5. «17.2G io-clock WRITE wait» (Copygc::sleep, ring reconcile_status) — вратá дренажа, не причина парка (bcf012 п.3 подтверждён живьём: backtrace в ring тот же).
6. dev_leaving dev1 = 512 сект. = 1 узел — «limbo-drip» (H2): единственный узел с evacuating/bad-поинтером — он единственный, чей plan() даёт Move (tgt-класс), и он же объясняет creep +1.4M/9д.

## 4. ВЕРДИКТ (одной строкой)

**Хвост паркуется из-за: metadata_replicas=2 при фактической durability btree-узлов = 1 (nvme dur=0 + hdd dur=1) → каждый из 24,350 узлов under-replicated, `can't match data_replicas=2`, ENOSPC=0, EC=0; конфиг-фикс = `metadata_replicas=1` (консервативно; entry-need уйдёт, pending-скан запросится сам при смене опции) ЛИБО durability NVMe → 1 (если NVMe больше не cache-тир) — после чего хвост дольётся без USR1.**

## 5. Проверочные команды для оператора (все read-only, я не выполнял — нет shell)

```sh
# конфиг-факты (офлайн-чтение суперблока, безопасно при живом маунте):
doas ./tools/bcachefs dump-super -f /dev/nda0p3 | grep -E 'replicas|durability|target|label'
doas ./tools/bcachefs dump-super -f /dev/ada1   | grep -E 'replicas|durability|target|label'
doas ./tools/bcachefs fs show /dev/nda0p3        # офлайн по девайсу (fs show БЕЗ аргумента-маунта не пойдёт: ioctl к демону не реализован)
# пер-ключевые записи pending (осторожно: офлайн-чтение живой ФС — на усмотрение владельца, bcf025-класс):
doas ./tools/bcachefs kvdb /dev/nda0p3 list reconcile_pending   # default = norecovery/read-only
```
Ожидание-фальсификатор: `metadata_replicas=2` + `durability: 0` у nda0p3 → гипотеза подтверждена; `metadata_replicas=1` → искать дальше (например, need от background_target: но тогда rw_tgt был бы ~12M, а не 512).

## 6. Остаточные риски / неопределённости
- `metadata_replicas=2` и `nvme dur=0` — инференсы из ring-арифметики и cached-аккаунтинга; не подтверждены dump-super (нет shell). Контрпример: если durability nvme=1, а хвост гоним background_target-несоответствием — но тогда rw_tgt ≈ 12M, а не 512 (ring), и парк шёл бы через parks_on/no_rw_devs с тем же конфиг-фиксом по сути (target-класс не выполним на одном девайсе).
- `counters[]` ring'а не мапится на имена текущего дерева надёжно (в массиве 145 значений = BCH_COUNTER_NR текущего xmacro, но позиция idx42=reconcile_set_pending=0 при живых репарках → либо бинарь демона старше дерева по порядку счётчиков, либо счётчики пересидированы при последнем маунте). Классификация построена на reconcile_work/аккаунтинге/арифметике, не на counters[].
- Пермиссив-ошибки чтения на двух core-файлах docs/evidence (Permission denied) — не мешало.
- Все действия строго read-only: ни sysfs-записей, ни USR1, ни записей в пул, ни сборок.
````

---

**Дайджест (≤12 строк):**
- Путь трассы: **sysfs-атрибута не существует на этой линии** — tracefs-точка (`bcachefs/reconcile_set_pending`, debug/trace.h:22-40) в FUSE-демоне скомпилирована out (`cfg(kernel)`/`CONFIG_TRACEPOINTS` off, counters.rs:111-127); sysfs-fd порта = `/dev/null`-заглушка (handle.rs:335-354); `/sys/fs/bcachefsfs/<uuid>/` на хосте нет, linsysfs дерева не имеет; CLI-ioctl к демону не реализован (handle.rs:226-231).
- Читаемое = ring `/var/run/bcachefs-fuse/0ec475a1-…/accounting.json` (прочитан).
- Разбиение хвоста: **replicas-класс `can't match data_replicas=2` ≈ 12,467,200 сект. = 24,350/24,351 btree-узлов (≈100%); ec-stripe = 0; ENOSPC/parks_on = 0…512 сект.** (tgt-капля 1 узел, H2-drip).
- Хвост = вся btree: узел (512 сект.) на обоих девайсах; nvme dur=0 (cached-тир, `dd_dev0_cached` есть, `dd_dev1_cached` нет) + hdd dur=1 → durability узла 1 < metadata_replicas=2 → under-replicated → Park(Replicas) вечно; насытить 2 durable-реплики на 1+0 девайсах физически нельзя.
- **Вердикт: хвост паркуется из-за metadata_replicas=2 при реальной durability btree = 1 (nvme dur=0); конфиг-фикс = `metadata_replicas=1` (или durability NVMe→1), после смены опции pending-скан запросится сам и хвост дольётся без USR1.**
- Проверка-фальсификатор для оператора: `doas ./tools/bcachefs dump-super -f /dev/nda0p3 | grep -E 'replicas|durability'` (read-only).
- Риск: metadata_replicas=2/dur-0 — инференсы из ring-арифметики (dump-super не прогнан); `counters[]` ring'а к именам текущего дерева не мапится надёжно.