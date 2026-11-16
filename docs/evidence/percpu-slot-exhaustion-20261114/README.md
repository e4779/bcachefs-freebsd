# Evidence dir notes

- `bcachefs.core` (72G, Nov 14 12:42) — the raw core dump of the prod daemon
  (SIGABRT, percpu slot exhaustion, bcf029). Moved here from the repo root
  (2026-11-16) after the diagnosis closed; the committed
  `lldb-thread-table.txt` transcript refers to it by its old path
  (`bcachefs.core` at the repo root). Deletion candidate after the
  retirement fix has proven stable (precedent: core 69055 - "deletable
  after acceptance").
