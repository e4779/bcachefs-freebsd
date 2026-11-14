# PASS-3 (подмена контекста принятa): реворк-артефакты прочитаны с нуля. Ответы на два вопроса

Вердикт-строка: **fsync-лань — корректна как есть; append-лань — нужен двухстрочный фикс retval (два конкретных окна ложного errno); тестовый патч — хард-блокер: не самодостаточен, `fusefs_timeout.cc` не компилируется против стока.** Инвентарь коммит-драфта — L1 в теле, L2 только примечанием, L3 назван — с оговорками ниже.

## Q1. Trace: bufwrite retval vs bp->b_error на обеих ланях

**Цепочка фактов (все проверены в живом дереве):**
- `bwrite()` — static inline → `BO_WRITE` → `bufwrite` (sys/buf.h:432-440 → vfs_bio.c:100-106).
- `bufwrite` при входе чистит **только** `BIO_ERROR|BIO_EXTERR` (vfs_bio.c:2361), `b_error` **не трогает**. Sync-путь: `retval = bufwait(bp)` (vfs_bio.c:2384). `bufwait` (vfs_bio.c:4582-4596): `B_EINTR` → EINTR (b_error не ставит!), иначе `BIO_ERROR` → `b_error ?: EIO`, иначе 0.
- В vfs_bio.c **нет ни одного присваивания** `b_error =` — grep находит только чтения (:2747, :4595, :5526). `brelse`/`bqrelse`/`getblk` b_error не чистят (наши буфы вдобавок идут ранним B_MANAGED-return, vfs_bio.c:2717-2719). Единственный чистильщик в дереве — loop1-скан `vn_fsync_buf` (vfs_vnops.c:3224-3226), и он выполняется только в fsync.

**Лань L1 (fuse_io_strategy :896-927 + vn_fsync_buf):** bawrite → B_ASYNC → **retval не существует** (отбрасывается), потребитель — эпилог по `b_error`, свежесть на каждый проход гарантирована loop1-очисткой. Здесь `b_error`-keying **правилен и замены не требует**. ✓

**Лань L2 (append, fuse_io.c:667-675):** sync bwrite → retval доступен и авторитетен. Нынешний `err = bp->b_error` имеет **два окна ложного errno**, потому что b_error персистентен между завершениями:
- **S1**: таймаут (b_error=ETIMEDOUT, буф redirtied) → демон ожил → следующий write того же буфа **успешен** → bufwrite очистил BIO_ERROR, strategy-успех b_error не трогает → проверка ловит протухший ETIMEDOUT → успешная запись возвращает ETIMEDOUT.
- **S2**: после таймаута EINTR на том же буфе → bufwait уходит по B_EINTR, retval=EINTR, b_error остаётся ETIMEDOUT → репорт ETIMEDOUT вместо EINTR.
- Историческая ирония (стоит одного предложения в PR): старая проверка `b_error == EINTR` была фактически мертва для свежих значений — EINTR-ветка strategy b_error не ставила, bufwait тоже — поэтому append-лань и не выходила из `goto again`. Реворк клин починил, но открыл S1/S2.

**Фикс (ровно то, что сформулировал оркестратор):**
```c
err = bwrite(bp);
if (err == EINTR || err == ETIMEDOUT)
        break;
goto again;
```
retval — посуходостенный (BIO_ERROR чистится при входе bufwrite :2361, ставится только этим проходом), закрывает S1+S2, заодно честно проводит ранние выходы bufwrite (BO_DEAD → ENXIO, vfs_bio.c:2329-2335) и соответствует канону UFS — `ufs_vnops.c:2217: ((error = bwrite(bp)))`. Поведение на generic-ошибках не меняется (они и сейчас уходили в `goto again`).
**RMW-нога** (fuse_io.c:601-613, `if ((err = bp->b_error))` после прямого вызова strategy) — тот же латентный stale, но это **пре-экзистент** (патч её не трогает; лишь расширяет популяцию персистентных ETIMEDOUT). В код не трогать; в PR known-limitation sharpen: назвать оба маска (S1/S2) и что append-лань закрыта retval-фиксом.

## Q2. Инвентарь трёх ланей vs COMMIT-DRAFTS

| Лань | В диффе | В верbatim-теле | Статус |
|---|---|---|---|
| L1 strategy (:896-927) | ✓ | ✓ (механизм-предложения верифицированы) | OK; косметика: «brelse clears BIO_ERROR when redirtying» описывает generic-путь — у наших B_MANAGED буфов скраб не выполняется вовсе; вывод верен, но точнее писать «b_error persists on the redirtied buffer (brelse(9) scrubs only BIO_ERROR in its redirty path)» |
| L2 append (:667-675) | ✓ | ✗ — только packaging-note («draft predates the append-lane edit») | Предложенное предложение втиснуть в тело ДО заморозки; после retval-фикса — «reports it via bwrite(9)'s return value» |
| L3 tests (Makefile + fusefs_timeout.cc) | ✓ (GTESTS алфавитно ✓, имена тестов совпадают ✓) | только в notes | **ХАРД-БЛОКЕР, см. ниже** |

**Хард-блокер L3:** тестовый патч содержит только Makefile + fusefs_timeout.cc. Но: (а) `m_daemon_timeout` в стоковом харнессе **не существует** (grep по tests/: 0 hits; члены — m_init_flags/m_nointr/m_maxread, utils.hh:61-98) → `SetUp() { m_daemon_timeout = 1; }` не компилируется; (б) в mount-билдере mockfs.cc:471-530 нет ветки `timeout=` (шаблон — m_maxread :479-486) → даже при компиляции тест монтировался бы на дефолтные 60s и оба теста висели бы до kyua timeout=20 (Makefile:76) **даже на пропатченном ядре**. `git apply --check` это не ловит — apply ≠ build. Фикс: расширить тестовый патч двумя харнесс-хунками (член в utils.hh + iovec-ветка в mockfs.cc по образцу max_read), тогда тест самодостаточен и тайминг ASSERT_LE(2.0) при timeout=1 честен.
Остальная упаковка — ✓: git-diff формат против свежего main 12a57b078 (закрывает pass-1 B3), subject 59, футеры PR:/Signed-off-by:/MFC ✓, два PR с демоцией fuse_ipc ✓, оговорка «dtrace counts in the PR» согласована с memo-правилом (числа снять до отправки).