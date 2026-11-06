# B-lite — контроль-канал телеметрии демона (ЗАМОРОЖЕННЫЙ спек)

**Статус: FROZEN DESIGN — НЕ СТРОИМ.** Спек сфризован решением консилиума P4 (Ф2,
runbook `docs/f3-runbook.org` строка P4, записи council/2026-11-06-15-39-18):
цель телеметрии закрывает A+ (снапшот-кольцо), B-lite строится только по триггерам
(§9). Документ фиксирует дизайн, чтобы будущая реализация не изобретала протокол.

База доказательств: `tmp/p4/{ioctl,daemon,gate}.md` (read-only разведка 2026-11);
все file:line ниже оттуда либо проверены по дереву.

## 1. Назначение и не-цели

Живые QUERY_ACCOUNTING / QUERY_COUNTERS / READ_SUPER из демона без участия ядра:
unix-сокет рядом с маунтом, клиент = CLI tools с FreeBSD-веткой в `open_mounted_path`.

Не-цели (кат консилиума): mutating-ioctl'ы НАВСЕГДА (DATA, FSCK_ONLINE, DISK_*,
SUBVOLUME_* — все `_IOW`-записывающие, полный список `tools/fs/bcachefs_ioctl.rs:53-91`);
`fs top`/timestats (sysfs/tracefs — отдельная вселенная); «stock CLI end-to-end»
как планка приёмки. QUERY_UUID (`_IOR(0xbc,1,...)`, 0x8010BC01) сознательно НЕ в
вайтлисте: определение «это маунт» закрывает A+ fstype-гейт, а не зонд handle.rs:170.

## 2. Транспорт

- Сокет: `/var/run/bcachefs-fuse/ctl.sock` (unix, stream), режим 0700, владелец = uid демона.
- Гейт клиента: LOCAL_PEERCRED на принятом соединении → struct xucred.cr_uid;
  отказ всем, кроме своего uid. Единственный одновременный клиент: второй accept
  закрывается немедленно (упрощает freshness и серию запросов).
- Фрейминг: запрос `{ u32 cmd; u32 cap; u8 payload[cap] }`, ответ `{ i32 errno; u32 len; u8 payload[len] }`.
  `payload` запроса = байты ioctl-структуры (первые _IOC_SIZE(cmd) байт значимы, как
  при ioctl(2) с буфером емкости cap); ответ = errno + до len байт данных. Блокирующий
  request/reply, одна операция — один обмен.

## 3. Структуры на проводе — verbatim

Источник: `tools/fs/bcachefs_ioctl.rs` (C-parity; `bch_bindgen::c` реэкспортирует,
`bch_bindgen/src/lib.rs:8-11`). На проводе — те же байты, что ioctl(2) у Linux-ядра.

```rust
// v1, bcachefs_ioctl.rs:732-747 — sizeof 32
pub struct bch_ioctl_query_accounting {
    pub capacity: u64,
    pub used: u64,
    pub online_reserved: u64,
    pub accounting_u64s: u32,        /* input parameter */
    pub accounting_types_mask: u32,  /* input parameter */
    pub accounting: [BkeyI<c::Accounting>; 0],   // trailing, не входит в _IOC_SIZE
}

// v2, :773-785 — sizeof 160; добавляет (FREE_NR = 8, :748):
//   pub free: [u64; 8],  pub free_now: [u64; 8]

// counters, :796-802 — sizeof(header) 8, d[] trailing
pub struct bch_ioctl_query_counters {
    pub nr: u16, pub flags: u16, pub pad: u32,
    pub d: [u64; 0],
}

// read_super, :590-597 — sizeof 32
pub struct bch_ioctl_read_super {
    pub flags: u32, pub pad: u32, pub dev: u64, pub size: u64, pub sb: u64,
}
```

| cmd | кодировка (`include/asm/ioctl.h:29,39`) | sizeof |
|---|---|---|
| BCH_IOCTL_QUERY_ACCOUNTING | 0x4020BC15 (magic 0xbc, nr 21) | 32 |
| BCH_IOCTL_QUERY_ACCOUNTING_v2 | 0x40A0BC25 (nr 37) | 160 |
| BCH_IOCTL_QUERY_COUNTERS | 0x4008BC15 (nr 21, Head<> = 8) | 8+flex |
| BCH_IOCTL_READ_SUPER | 0x4020BC0C (nr 12) | 32 |

Ловушка: QUERY_COUNTERS и QUERY_ACCOUNTING_v1 **делят (0xbc, 21)** и различаются
только битами размера — матчить полный 32-битный cmd, не (type, nr). Это же
предупреждение в док-комментарии v2 (`:757-767`): sizeof зашит в номер команды.

## 4. Вайтлист: query-only по построению

Диспетчер сервера содержит ровно четыре opcode выше; всё прочее → ENOTTY (по
образцу `tools/fs/init/chardev.rs:77-145`, default `_ => Err(c::ENOTTY)` :144).
Мутирующие пути физически недостижимы: их нет в таблице. Обработчики — существующие
функции rust-«ядра»: query_accounting_v1/v2 (`chardev.rs:280/297`, чтение живого
состояния :255-277), query_counters (`tools/fs/sb/counters.rs:416-436`),
read_super (`chardev.rs:351`).

## 5. Кэп ответа 1 МиБ и протокол ERANGE

- Клиент начинает с 1 КиБ и растёт по ERANGE — как `grow_on_erange` у tools
  (`src/wrappers/accounting.rs:48-64`; upstream-потолок 1 ГиБ, MAX_REPLY `accounting.rs:91`).
- B-lite: жёсткий потолок ответа **1 МиБ**. Требуемый размер > cap клиента →
  `ERANGE` + len = требуемый размер. Требуемый размер > 1 МиБ → честный ERANGE без
  роста дальше: усечение и молчание запрещены. Обоснование: per-inode accounting
  прод-пула — килобайты; 1 МиБ ограничивает память capsicum-обработчика (§7).

## 6. Верность errno

- **ENOTTY означает ровно одно: cmd не в вайтлисте.** Транспорт не имеет права
  возвращать ENOTTY для своих ошибок: CLI молча даунгрейдит v2→v1 при ENOTTY
  (`src/wrappers/accounting.rs:36-44` — «ENOTTY is the only error that means too
  old»), утечка ENOTTY из транспорта = тихая потеря free/free_now.
- Транспортные ошибки — своими errno (ECONNRESET, EPIPE, ETIMEDOUT), ошибки
  обработчика — проброс errno 1:1 как вернул rust-«kernel» (EINVAL от bad flags,
  ERANGE от роста, BCH_ERR-коды — как есть).

## 7. Изоляция и инварианты

- Обработчик в capability mode: на FreeBSD cap_enter(2) **процессный**, не
  потоковый — инвариант формулируется как «после setup демон в capsicum: все fd
  (fuse-dev, ctl.sock, члены пула) открыты ДО cap_enter; в пути обработки нет
  open/exec/path». Handler трогает только сокет-фd и in-memory `Fs` (bch_fs
  internally locked, `fusemount.rs:886-887`).
- Инварианты консилиума Ф1/Ф2 переносятся: без unwrap (rctl-SIGKILL = смерть
  маунта), чтение через mem_read (не locked), nice, stale-выглядит-stale (в ответе
  ts/gen/pid/uuid провенанса A+), снапшот не станит единственного воркера.

## 8. Коллапс в C

Тот же провод = механическая миграция: когда C-full (Ф4) даёт FUSE_IOCTL с
flex-массивами, серверная диспетчеризация (§4) переезжает как есть в
`Filesystem::ioctl` демона (мост в `fs/vfs/ioctl.rs:162` fs_file_ioctl уже
существует), клиентский код CLI (`grow_on_erange`, parse) не меняется вовсе.
Из B-lite удаляется только сокет-транспорт, в `handle.rs` откатывается
FreeBSD-ветка. Экономия спека: ноль переделок формата.

## 9. Триггеры постройки (консилиум, дословно из плана-of-record)

1. Инцидент-часы до зрелости A+ — интерактив понадобился чаще, чем снапшоты.
2. C-full отклонён или стоит 2+ спринта.
3. RCA lost-WRITE блокирует окна — нужны живые счётчики во время инцидента.

Фальсификатор (тот же план): апстрим+RETRY-прототип на стейдже → C-full возвращается,
B-lite уходит в отставку.

## 10. Индекс доказательств

- Разведка: `tmp/p4/ioctl.md` (структуры, кодировки, диспетчер, errno),
  `tmp/p4/daemon.md` (живое состояние демона, accounting/counters),
  `tmp/p4/gate.md` (почему handle.rs не открывает маунт сегодня).
- Код: `tools/fs/bcachefs_ioctl.rs:54,69,85-86,93,732-747,748,773-785,796-802` ·
  `tools/fs/init/chardev.rs:71,92,137-144,218,280,297,351` ·
  `tools/fs/sb/counters.rs:416-436` · `tools/src/wrappers/accounting.rs:36-91` ·
  `tools/src/wrappers/handle.rs:106,135,170,234-260` · `tools/include/asm/ioctl.h:29,39`.
