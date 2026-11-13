---
id: "bcf010"
title: "Fix B: wedge-catcher — сторож владельца umtx при зависании"
status: completed
priority: high
effort: medium
type: bug
tags: [port, wedge]
created_at: 2026-11-13
context: [docs/f3-runbook.org, scripts/wedge-catcher.sh]
---

# Fix B: wedge-catcher — сторож владельца umtx при зависании

org-id: 2a93749a-d986-11f1-a363-9c6b00bdbaa5

Доказанный механизм wedge: fdisp_wait_answ таймаутит (60с) → fuse_io_strategy редиртит буфер (fuse_io.c:896-902) + biobackend goto again (:602-607) → вечный цикл, очередь ms_head растёт. Триггер в демоне: event-loop застревает в umtx (инцидент #1: ни один поток в read(/dev/fuse)).
Инструмент: скрипт-сторож (стеки демона через procstat -kk при обнаружении потока клиента в fdisp_wait_answ >N мин + sndump/поиск владельца мьютекса), деплой в scripts/ (scripts/wedge-catcher.sh).
Завершено: валидирован боем 2026-11-06 09:11 — инцидент #3 снят автоматически; оба случая инцидента #4 сняты автоматически (журнал Ф3 в runbook).

## Source

docs/f3-runbook.org (журнал миграции org→taskmd; история: git log --grep 'Refs: bcf[0-9]+').
