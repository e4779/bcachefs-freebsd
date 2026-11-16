All evidence gathered. Assembling the artifact and digest.

---

## Дайджест (≤15 строк)

1. **rw_pend дренируется ТОЛЬКО через pending-фазы passes, а они исполняются лишь при живом cookie pending-скана** (work.rs:871-874 `phase.is_pending() && p.pending.is_none() → skip`). Сам pending-скан ключей не читает (scan.rs:245-246 — пустая ветка) — он только ставит `p.pending` (work.rs:682-690) и анпаркует стрипы. Cookie запрашивают: dev add (dev.c:1206/1310), state→rw (dev.c:866/897), offline (dev.c:1424), resize (dev.c:1487/1551), label (change.rs:76), durability↑ (change.rs:59, wakeup=false), sysfs (sysfs.rs:127), SIGUSR1 (telemetry.rs:356). **Freespace recovery (copygc) pending-скан НЕ запрашивает** — ENOSPC-park копится бесконечно, пока не меняется топология/конфиг.
2. **Нить спит часами легитимно**: `wait()` (work.rs:902-927) ставит дедлайн `now + capacity>>6` = 1/64 ёмкости меньшего RW-диска в WRITE-секторах (для 4 ТБ ≈ 128 GiB записи!). WRITE-часы тикают только из write.c:2739, interior.c:569, io_misc.rs:121 — read-only нагрузка часы не двигает, kick нет → `io_clock::wait_until` (clock.rs:146) спит неограниченно. `io wait remaining` (work.rs:1038) — оставшийся объём записи до пробуждения. Copygc спит так же (copygc.rs:676-682, 741-778; no-op эвакуации не считаются работой → backoff capacity>>6).
3. **`check_reconcile_pending_err` НЕ СУЩЕСТВУЕТ** — только упоминание в комментарии plan.rs:315 («nothing retries the pending list»). fsck `check_reconcile_work` (check.rs:537-546) правит лишь биты work-btree, pending не перепланирует; записи, создавшие работу, reconcile не кикают (trigger.rs киков нет). Часть авто-retry всё же есть: pending-бит сбрасывается при сузившемся need_rb / новом hipri (needs_reconcile.rs:180-187), стрипы анпаркятся на moved-секторах/copygc-run (work.rs:800-806, 861-867).

**Вывод для bcf012**: очередь копится = (a) parks_on/Plan::Park/сбой EC-аллокации кладут ключи в reconcile_pending, (b) дренаж заблокирован отсутствием pending-scan cookie при отсутствии device/config событий, (c) idle-ожидание на WRITE-часах маскирует накопление часами. Быстрый рычаг — SIGUSR1/sysfs `trigger_reconcile_pending_wakeup`; системный фикс — kick pending-скана при freed-space/удалении данных или ретраить ENOSPC-park отдельно от конфигурационных park'ов.

---