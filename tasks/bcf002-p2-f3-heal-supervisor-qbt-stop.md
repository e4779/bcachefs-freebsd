---
id: "bcf002"
title: "P2: f3-heal супервизор на посту; qbt стоп до atomic-фикса"
status: blocked
priority: medium
effort: medium
type: improvement
tags: [ops]
created_at: 2026-11-13
context: [docs/f3-runbook.org, scripts/f3-heal.sh]
---

# P2: f3-heal супервизор на посту; qbt стоп до atomic-фикса

2026-11-06 вечер: qbt — единственный стабильный триггер livelock (init-бёрст); остановлен до atomic-фикса, enable=NO в rc.conf. Восстановить: qbittorrent_enable=YES + onestart. Троица stash/amut/amuled служит.
Триггеры супервизора: демон мёртв ИЛИ wedge >5 мин → полный bounce стека (включая qbt — с retry-фиксом бёрст-триггер должен уйти; если флапает — sunset-пересмотр).
Только mount -u timeout=30 → supervised рестарт ДЕМОНА (не клиентов! рестарт qbt = 3/3 триггер).
Sunset 2 недели без wedge. Тройка приёмки: KPI + expiry + письменно предзаписанный rollback-триггер.
Статус по журналу 2026-11-07: f3-heal v2.1 на посту (rc.d f3heal, daemon(8)), валидирован первым живым огнём; qbt-разблокировка остаётся открытой частью.

## Source

docs/f3-runbook.org:32 — org-заголовок «WAITING P2: f3-heal.sh супервизор на посту; qbt остановлен на ночь» (мигрировано 2026-11-13).
