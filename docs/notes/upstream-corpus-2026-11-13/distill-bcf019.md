# bcf019 — дистиллят стандартов качества FreeBSD (fuse-патчи)
Дата: 2026-11-14. Вход: corpus bcf018 (CORPUS.md, LIVE-ADDENDUM, raw/guide.md §5.8+§9, raw/aiguide.md) + локальный /usr/src (stable/15, БЕЗ .git).

## Q1. style(9): буква vs шум

Жёсткие формулировки ("must"/"forbidden"):
- Объявления переменных в блоке — до операторов: style.9:675 "Declarations may be in any block, but **must** be placed before statements".
- K&R-декларации функций **запрещены** (obsolete, forbidden в C23): style.9:777.
- KNF-совместимый код **не должен** деградировать: style.9:927 "must not diverge from compliance".
- Соло-стилевые коммиты **must be avoided** (мешают MFC/blame; отдельный коммит + .git-blame-ignore-revs): style.9:905-912.
- Табуляция = 8, продолжение переноса = 4 пробела; только tab→spaces, никаких spaces перед tab, никакого trailing whitespace: style.9:591-596.

Сформулировано как "should/preferred" (ревьюеры ловят, но мягче):
- Ширина 80; исключение — диагностические/error/panic-строки НЕ бить по строкам (grep-friendly): style.9:35-40 (важно: наш KASSERT/SDT-текст — не резать).
- "Many of the style rules are implicit in the examples": style.9:40 — проверяй примеры, не только текст.
- return-значения в скобках (C; в C++ наоборот): style.9:761 vs :945.
- NULL: `(p = f()) == NULL`, не `!(p=f())`; `if (*p == '\0')` не `if (!*p)`; `if (count != 0)` не `if (count)`: style.9:728-737.
- Пробел после ключевых слов if/while/for/return/switch; никаких пробелов после имени функции; оператор в конце строки при переносе: style.9 (примеры 585-600, 627-634).
- Два стиля скобок для single-statement — либо везде, либо по необходимости, консистентно внутри функции; `} else` на одной строке: style.9:598-611.
- internal_underscores вместо camelCase: style.9:345. uintXX_t вместо u_intXX_t; bool вместо int/boolean_t; true/false: style.9 (~:297-315).
- Комментарии: /* */ или //, консистентно в файле; многострочные — заполненные абзацы: style.9:42-70.
- FALLTHROUGH для cascade case'ов; #endif-комментарии только для регионов >20 строк: style.9 (~:400-430).
- err(3)/warn(3), не самодельные; __predict_true/false только с эмпирикой: style.9 (~:765-800, ~:855).
- Инструменты: tools/build/checkstyle9.pl (существует, проверено ls), freebsd.el/vim.

Шум (не ловят в fuse-патчах): переформатирование чужих строк, конверсия u_int→uint в тронутых функциях без веской причины, стиль чужих комментариев. В самом fuse_io.c есть исторический долг: 13 строк с trailing whitespace, строки :121 (84 col) и :249 (81 col) — никого не смущает, трогать нельзя.

Первый взгляд ревьюера на fuse-дифф (по практике файла): (1) чек-скрипт checkstyle9; (2) tab-отступы и перенос длинных условий с 4-пробельным continuation; (3) объявления до кода в изменённых функциях; (4) симметрия error-веток (b_ioflags/b_error/b_flags в том же духе, что соседний EINTR-бранч); (5) форма многострочных комментариев (заполненный абзац, строчные буквы как в соседях); (6) отсутствие style-чёрных дыр вне диффа; (7) diagnostic-строки неразрывны.

## Q2. Коммит-конвенции + внешняя роль

Формат (guide.md §9, строки 2279-2508):
- Subject <67 символов (цель ~50), префикс компонента `foo:` — тот же, что в прошлых коммитах этих файлов (§9.4; для fuse по дереву исторически "fusefs: " — проверить по git log, локально не могу).
- Первая буква subject заглавная (префикс — нет), без точки в конце, blank line после subject, body ≤72 col, present tense imperative (§9.3-9.9).
- Что и почему, не как; бенчмарки — в сообщение; ограничения — тоже (§9.10); сообщение самодостаточно, ссылки + сабжект референсного коммита (§9.13).
- Футеры: key: tab-отступ значение. PR: (можно списком), Reported by:, Reviewed by: (внешний = Full Name <email>; для мейнтейнера портов — суффикс (maintainer)), Tested by:, Discussed with:, Approved by: (abc (mentor/maintainer/re (user))), Obtained from: (только проекты), Fixes: <short-hash> ("<subject>") — формат из `git log -n1 --format='%h ("%s")'`, MFC after: N days/weeks/months, MFC to:, Relnotes: yes, Security:, Event:, Sponsored by:, Pull Request:/Closes: (полный URL), Co-authored-by:, Signed-off-by: (DCO). **Differential Revision: — строго последняя строка** (guide.md §9.14 таблица).

Внешняя роль (§5.8, guide.md:1951-2014 + Example 4):
- Наш PR коммитит коммиттер: `git fetch github pull/$PR/head:staging` → `git rebase -i main staging` (правит commit message: добавляет `Pull Request: https://github.com/freebsd-src/pull/$PR`) → тестирует → `Reviewed by:` ставит сам (себя + github-аппруверов) → ff-merge → `git push freebsd --push-option=confirm-author` → закрывает PR через веб.
- author ставится коммиттером через `git commit --author "Full Name <email>"` (Example 4); `Submitted by:` — discouraged.
- Красные флаги коммиттера: анонимный author (noreply.github.com), style-мусор, зловредный код — "extra care" прямо в тексте.
- Значит НАША работа = максимум готового: валидный author, один логический коммит (fixup-ы сквошены, правки = rebase+force-push), зелёный CI, checkstyle9 чисто, готовый commit-message с PR:/Fixes: черновиком, Signed-off-by, ≤10 файлов/≤200 строк, ответ на фидбек ≤1 мес (CONTRIBUTING.md, corpus §2.2).

## Q3. Ожидания от кернел-патча (вне стиля)

Из нашего bugzilla-прецедента (c300130.txt, corpus §4):
- Формат репорта = репродюс + dtrace/числа + control-run + "related but distinct" с чужими номерами + production dogfooding + LLM-disclosure. Receipt: c300130.txt:146 (linimon: "convert to Attachment using git diff — new preferred submission method"), c8 (:226) — вопрос про порядок патчей → ответ: каждый аттачмент standalone к stock-дереву.
- Ревьюер вправе оспорить предпосылку (rmacklem c17: "lease expiry should never happen") — патч должен нести данные, что сценарий реален (наши qbittorrent/bcachefs dogfood-наблюдения).
- Очереди реальны: rmacklem — "end of Nov" (c17). Пинг-культура: срочный раз в 2 дня, обычный раз в неделю (§8, guide.md:2255-2277); таймаут не заменяет явный "looks good"; большие патчи сплитить.
- От кернел-патча ждут: репродюс, тест (CONTRIBUTING.md: "kyua tests same before/after; ideally a test case showing the actual bug"), lock-ordering заметки (наш fuse_ipc — msleep под tk_aw_mtx, без новых lock-порядков: сказать явно), поведение при ошибке (каждая ветка errno), MFC-план (MFC after:), оценку риска регрессии (кого заденет: все fusefs-юзеры с медленным демоном).

fusefs-сьют (tests/sys/fs/fusefs, 52 файла):
- Паттерн теста-на-баг: fixture = FuseTest → expect_*-хелперы ставят EXPECT_CALL на mockfs process() (мок демона /dev/fuse), затем реальный syscall + ASSERT errno. Пример: fsync.cc:164 `TEST_F(Fsync, eio)` — `expect_fsync(ino, FUSE_FSYNC_FDATASYNC, EIO)` → `fdatasync` → `ASSERT_EQ(EIO, errno)`.
- Норма: комментарий перед тестом объясняет семантику (fsync.cc:190-193 про ENOSYS).
- Сигнальный/интерапт-механизм ГОТОВ: interrupt.cc:188/190 fixture'ы Intr (демон поддерживает FUSE_INTERRUPT) / Nointr; тесты in_kernel_restartable (:404) и in_kernel_nonrestartable (:476): fork-ребёнок делает op, родитель шлёт сигнал, мок ловит FUSE_INTERRUPT, EXPECT_EQ(EINTR, errno). bad_server.cc — кривые ответы (UnknownUnique :44, ShortWrite :59).
- Гэп сьюта: grep ETIMEDOUT по *.cc — 0 совпадений → таймаут-путь НИКОГДА не тестировался. Тест к нашим патчам: (a) fuse_ipc — Intr-подобный сценарий: сигнал доставлен, демон НЕ отвечает до deadline → ожидаем возврат за ≤1 daemon_timeout (а не вечный fu_ans); (b) fuse_io — демон не отвечает на FUSE_WRITE → write/fsync возвращает ETIMEDOUT, буфер остаётся dirty (не B_INVAL), повторный вызов ретраит. Механизм «молчащего демона» в mockfs не验证 — ближайший шаблон fork+signal из interrupt.cc; прототипировать.

## Q4. fuse(4) специфика

- ГЭП: /usr/src НЕ git-репо (`git -C /usr/src log` → "fatal: not a git repository") → тон/формат последних 30 коммитов sys/fs/fuse локально не снимается. Замещение: MAINTAINERS:56 `fusefs(4)  asomers  Pre-commit review requested.`; pjdfstest — asomers,ngie,pjd,#test (:50). Префикс сабжа и типичные Reviewed by: — снять с github-зеркала отдельным прогоном.
- Стиль файлов: каждое нетривиальное событие = SDT_PROBE2(fusefs, , io|ipc, trace|..., N, msg/arg); KASSERT с коротким сообщением ("filesize should've been cached"); длинные заполненные многострочные комментарии-абзацы; перенос условий 4-пробелами; errno-коды как статусы.
- Наши хунки УЖЕ в рабочем дереве (mtime fuse_io.c/fuse_ipc.c = Nov 6 2026, остальные fuse-файлы Jun 12 13:36): fuse_io.c:904-922 ETIMEDOUT-ветка зеркалит соседнюю EINTR-ветку :898-903 (тот же bdirty/B_DONE/B_EINTR танец + BIO_ERROR/b_error) — дифф читается как симметричное продолжение; fuse_ipc.c:430 retry-метка, :443-449 комментарий-обоснование deadline (qbittorrent, bcachefs dogfood 2026-11), :451-459 EWOULDBLOCK→ETIMEDOUT через slptime<=0.
- Качество наших хунков по style: 0 строк >80 col в обеих файлах (превышения только старые :121/:249), 0 trailing whitespace в наших строках (13 старых в fuse_io.c не тронуты). Патч ложится в стиль файла без остатка; перед сабмитом — только перебазировать на актуальный main (файлы могли уехать с Jun 12).

## Чек-лист патчера fuse-PR (готовый)
1. `perl /usr/src/tools/build/checkstyle9.pl` на тронутых файлах — 0 варнингов.
2. Табы-8, continuation-4 пробела, ≤80 col, без trailing whitespace; diagnostic-строки (KASSERT/SDT-текст) не переносить.
3. Ноль style-чёрных дыр вне диффа (не трогать 13 старых trailing-ws строк fuse_io.c).
4. В изменённых функциях: объявления до операторов; `return (err)`; `(p = f()) == NULL`; `if (count != 0)`.
5. Каждый новый бранч ошибки — SDT_PROBE2(fusefs, , io|ipc, trace, N, "msg") по образцу соседей.
6. Error-ветки симметричны EINTR-ветке: b_ioflags|BIO_ERROR, b_error=errno, bdirty/B_EINTR по флагам.
7. Комментарий-блоки = заполненные абзацы с обоснованием why (dogfood-наблюдение inline).
8. Subject: `fusefs: <Imperative summary>` ≤67 (цель ~50), без точки, blank line, body ≤72 col.
9. Body самодостаточен: что+почему+числа наблюдения+ограничения; ссылки с сабжектами.
10. Футеры (наши черновики): `PR: <bugzilla>`, `Reported by:`, `Signed-off-by:` (DCO), `MFC after: 2 weeks` (если уместно); `Reviewed by:` НЕ ставим — это работа коммиттера; `Differential Revision:` — только если ходим через Phabricator, и тогда последняя строка.
11. Author = реальное имя + валидный email (e@4779.name), noreply запрещён; один логический коммит, fixup-ы сквошены.
12. ≤10 файлов / ≤200 строк на PR; больше — сплитить.
13. Тест: расширить tests/sys/fs/fusefs (шаблон interrupt.cc Intr/Nointr; для таймаута — новый сценарий с молчащим демоном), kyua green до/после.
14. Bugzilla: аттачмент `git diff` (новый предпочтительный формат) + репродюс + dtrace/control-run + related-номера + LLM-disclosure строка.
15. Ревью — asomers (MAINTAINERS:56); подготовить защиту предпосылки числами; пинг раз в неделю.

## Гэпы
1. git-история sys/fs/fuse недоступна (/usr/src без .git) → префикс subject ("fusefs:" vs "fuse:"), тон и типичные Reviewed by: последних коммитов не сняты. Канал: `gh api repos/freebsd/freebsd-src/commits?path=sys/fs/fuse` отдельным веб-прогоном.
2. Механизм «демон молчит N секунд» в mockfs.cc не верифицирован — тест таймаута требует прототипа (ближайший шаблон: fork+signal в interrupt.cc).
3. Текущий main мог уйти от Jun 12 (fuse_io.c/fuse_ipc.c) — перебазировка и свежий git log обязательны перед сабмитом.
4. ~/kn/pages не существует — wiki-контекст пуст; capture идёт через pi-topics владельца (DoD bcf019).
5. aiguide.md — черновик-снапшот (не приземлён, D54817 стагнирует) — чек перед PR.
