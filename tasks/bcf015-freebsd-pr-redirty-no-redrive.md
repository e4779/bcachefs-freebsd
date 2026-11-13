---
id: "bcf015"
title: "FreeBSD PR (баг-репорт): redirty-no-redrive — ядро вечно ретраит ETIMEDOUT-запись"
status: blocked
priority: medium
effort: medium
type: bug
tags: [upstream, kernel]
dependencies: ["bcf023", "bcf013"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches/kernel/, tasks/bcf001-p1-mt-fix-wedge-daemon-alive.md]
---

# FreeBSD PR (баг-репорт): kernel redirty-no-redrive

Баг-репорт в FreeBSD (bugs.freebsd.org или freebsd-src): fuse(4) при ETIMEDOUT на записи молча перезакладывает dirty-буфер (redirty) без redrive — запись не доезжает до демона вечно, wedge без вины демона. Дополняет наш патч fuse_io-etimedout-fail-fast (bcf005): патч = фикс, репорт = признание класса.

## Блокер (evidence)

Ждём дискриминатор daemon-alive (bcf023): при следующем wedge доказать, что демон служит (жив, отвечает), а остаток — ядро. Без кита/стека с этим доказательством репорт = голословие; апстрим его не примет.

## Шаги

1. Дубли: поиск по bugs.freebsd.org (fuse EINTR/wedge/timeout — bcf005 уже заказывал такую проверку, объединить находки).
2. Репродюс минимальный (не только наш прод-кит): сценарий + ktrace/стеки.
3. Текст по скиллу opensource-contribution: evidence-first, форма-4 диагноз, стеки из китов.
4. **Ссылка на проект** https://github.com/e4779/bcachefs-freebsd + наш fail-fast патч как возможный фикс.

## Definition of done

- Репорт отправлен, номер/ссылка записаны в задачу; связка с bcf005 PR указана.

## Source

tasks/bcf001 «FreeBSD PR материал» (kernel redirty-no-redrive); решение владельца 2026-11-13 (трек публикации).
