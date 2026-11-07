# Core 83736 - SIGSEGV in waitqueue wake (btree write endio), 2026-11-07 11:27

Daemon 83736 (067 deploy, rc.d mount attempt 1) segfaulted during
JOURNAL REPLAY at mount (dirty journal: the 066 daemon was umount -f'd).
Crash chain: bch2_journal_replay_key(reflink) -> btree node fill ->
trans_unlock -> btree node WRITE submit -> btree_node_write_endio ->
wake_up_bit -> SEGV in __wake_up_common (shim wait.c:49) walking the
wait queue. Completion-thread wake racing a waiter - same class as the
P0 spinlock-semantics fix, now in the waitqueue shim itself.

Repro precondition: dirty journal (force-umount) + concurrent btree
writes at replay. Second mount attempt (85165) replayed clean - flaky
race, keep this core for the waitqueue-shim audit task.

backtrace.txt = full lldb bt (49 frames). bcachefs.core = 9GB raw.
Binary: tools/target/release/bcachefs @ commit e2552b6 (debuginfo on).
