# bcachefs-freebsd

Нативный userspace-доступ к bcachefs на FreeBSD: порт bcachefs-tools (FUSE-фронтенд) по лекалу [fuse-ufs](https://github.com/realchonk/fuse-ufs).

**Статус:** pre-sprint (ожидаем go). Решение и план — homelab `docs/freebsd/18-bcachefs-native-research.md` §8: A = прототип-спринт, D (ВМ+NFS-мост) остаётся продом до полной приёмки, E (ZFS) — аудит-день.

**Цель приёмки:** xfstests-сабсет зелёный на тестовой ФС; метаданные лучше 12.8 мс/файл NFS-моста; ноль артефактов корректности на ro-чтении чистого пула. Kill-критерии — в runbook 18 §8.

**Намерение:** опубликовать (форк + PR'ы апстриму), чтобы у FreeBSD появился не один пользователь.
