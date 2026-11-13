---
id: "bcf021"
title: "Мониторинг здоровья пула: ландшафт утилит и что портировать"
status: pending
priority: medium
effort: large
dependencies: []
tags: ["telemetry", "research"]
created_at: 2026-11-13
---

# Мониторинг здоровья пула: ландшафт утилит и что портировать

## Objective

Общая задача «на подумать»: как ПРАВИЛЬНО мониторить здоровье bcachefs-пула в
нашем контуре. Не код — инвентаризация и вердикт.

Контекст: hmlb-007 (homelab) отменён — legacy-hlmon (Rust-дашборд Debian-эпохи,
исходники на thinkpad, описание в homelab `docs/debian/23-hlmon.md`) написан под
Linux sysfs (`/sys/fs/bcachefs/`: reconcile_blocked, copygc_waiting_for_bytes,
reconcile_target_pending_bytes), которого на FreeBSD host-FUSE линии не
существует, а прод-плоскость пула с 2026-11-10 — именно host-FUSE. Generic
дашборды (netdata/beszel/node_exporter) sysfs bcachefs не парсят — это и было
мотивацией hlmon.

## Tasks

- [ ] Инвентаризация: что наблюдаемо на каждой плоскости — host-FUSE (fuser-форк,
      kit 066 reconcile-visibility, f3-heal v2.1 ring-staleness), VM-appliance
      (Alpine гость: Linux sysfs существует, когда пул смонтирован), generic
      FreeBSD (gstat/iostat — что дают, чего не дают)
- [ ] Разбор наследства hlmon: какие метрики были ценными, что переносимо на
      fuser-форк (эквиваленты reconcile_blocked/copygc_waiting в daemon-side
      счётчиках), что выбросить вместе с docker/bollard частью
- [ ] Ландшафт утилит: что есть в экосистеме bcachefs-tools (Linux) для
      health/fsck-статусов и что из этого имеет смысл портировать или
      реимплементировать поверх fuser
- [ ] Пороги и алерты: существующие триггеры f3-heal (ring staleness) —
      расширяемый ли каркас, чего не хватает (drift, perr, wedge-предвестники)
- [ ] Вердикт: минимально достаточный монитор для прод (host-FUSE) + список
      портов с оценкой усилий; отдельное решение — нужно ли что-то внутри
      appliance на случай её возврата

## Acceptance Criteria

- [ ] Вердикт-документ в docs/ (или pi-topic): метрики по плоскостям, выбранный
      минимальный монитор, список портов с effort-оценкой
- [ ] Каждое утверждение про «утилита X умеет Y» проверено (ман/исходники), а не
      взято из памяти
- [ ] Решение зафиксировано (консилиум, если спорно); в коде ничего не меняется —
      реализация будет отдельными тасками
