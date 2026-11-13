---
id: "bcf008"
title: "NFS-мост (poolmount + VM diod) на пенсию: FUSE-порт = единственный прод-путь"
status: cancelled
priority: low
effort: small
type: chore
tags: [migration, someday]
created_at: 2026-11-13
context: [docs/f3-runbook.org, bench]
cancelled_at: 2026-11-13
---

# NFS-мост (poolmount + VM diod) на пенсию: FUSE-порт = единственный прод-путь

ОТМЕНЕНО 2026-11-13 (решение владельца): вердикт «FUSE-порт = единственный прод-путь» зафиксирован (прод-стек stash/qbittorrent/amuled/amutorrent на /mnt/pool с 2026-11-06), мост выведен из ротации — но физический разбор сейчас = churn без выгоды: если appliance-линия вернётся в прод (возврат hmlb-005), мост возвращается вместе с ней. Замеры моста против порта остаются в bench/ как базовая линия. Ревизия решения — при следующем архитектурном ревью.

## Source

docs/f3-runbook.org:68 — org-заголовок «SOMEDAY NFS-мост (poolmount + VM diod) на пенсию…» (мигрировано 2026-11-13).
