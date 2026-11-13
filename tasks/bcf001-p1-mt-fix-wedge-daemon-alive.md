---
id: "bcf001"
title: "P1-финал: MT-фикс wedge (8 потоков), дискриминатор daemon-alive при wedge"
status: blocked
priority: high
effort: large
type: bug
tags: [port, wedge]
created_at: 2026-11-13
context: [docs/f3-runbook.org, docs/evidence]
---

# P1-финал: MT-фикс wedge (8 потоков), дискриминатор daemon-alive при wedge

Core#2 (MT-билд, kill -5) показал fuser-0 в preadv на HDD (sync disk IO inline) => MT-фикс (8 потоков, gate снят).
Acid test 2026-11-07 11:0x: qbt init ВСЁ ЕЩЁ 1 wedged.
Дискриминатор следующий: daemon-alive тест при wedge — если демон служит, остаток = kernel redirty-no-redrive (FreeBSD PR материал; wedge не лечится на нашей стороне).
Сборка: fuser-vendored (writev bounded retry 5×10ms, EAGAIN/EWOULDBLOCK/EINTR/ENOMEM) + Cargo.toml path-dep. Deadline-слой (watchdog/heartbeat) — после оценки эффекта retry на живом.
C+B: destroy-before-reply семантика (fuser#757, форк koverstreet) + writev-retry + reply-registry/watchdog/reader-heartbeat; сверить escape-коды с fuse_io.c. Это root-cause фикс Shape-1 (детерминированный close-шторм → reply-path failure → брошенный мьютекс → смерть ридера).

## Source

docs/f3-runbook.org:29 — org-заголовок «WAITING P1-финал: MT-фикс wedge (8 потоков)…» (мигрировано в tasks/ 2026-11-13).
