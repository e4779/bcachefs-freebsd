# bcf005 — commit-message drafts (kernel patches, post-council-#2 fix pass)

2026-11-14 · regenerated after council memo #2 fix pass (append-lane
retval reshape + bounded-silence test rework) against freebsd-src main
HEAD 12a57b078972c4f2778dfaa2faa96a4c64f59dc6 (2026-11-13, shallow
clone /tmp/bcf005-src). Council memo #2 + style pass-2 report are the
source of truth: docs/notes/council-memo2-bcf031-bcf005-2026-11-14.md.

Patches (re-verified this pass on a FRESH LOCAL CLONE of HEAD
12a57b07: `git apply --check` standalone AND combined, both clean;
applied clone is byte-identical to the working tree, `diff --git a/ b/`
format):
- overlay/patches/kernel/fuse_io-etimedout-fail-fast.patch
  (sys/fs/fuse/fuse_io.c: ETIMEDOUT branch @ :902-927, append-lane
  retval form @ :669-672; checkstyle9.pl: 0 errors, 0 warnings)
- overlay/patches/kernel/fusefs-tests-etimedout.patch
  (tests/sys/fs/fusefs/: Makefile + fusefs_timeout.cc, new file,
  3 tests; checkstyle9 hits are C++-idiom noise also present on stock
  suite files — 12 hits here vs 11 on stock cache.cc, 60 on stock
  interrupt.cc; 0 length/whitespace issues in added lines)

## 1. fuse_io-etimedout-fail-fast — commit message (style pass-2 corrected body, VERBATIM)

Subject: 59 chars, imperative, `fusefs:` prefix (verifier-corrected,
still accurate under the three-lane inventory). Body = the three-lane
precise inventory (IO_SYNC = the only true EINTR→ETIMEDOUT inversion;
append lane = wedge→ETIMEDOUT, stock never returned; fsync =
EAGAIN-after-grind → one-pass ETIMEDOUT; RMW reads already ETIMEDOUT
pre-patch). Footers in order PR → MFC after → Signed-off-by
(guide.md:2406-2435) and use LITERAL TABS in the actual commit
message (guide.md §9.14).

```
fusefs: report daemon timeouts to sync writers as ETIMEDOUT

When the FUSE daemon misses a full timeout window, fuse_io_strategy
redirties the buffer and sets B_EINTR, so bufwait(9) reports EINTR
to synchronous writers, masking the real errno (B_EINTR is checked
before BIO_ERROR).

Keep the dirty data and record the failure with BIO_ERROR and
b_error = ETIMEDOUT, without B_EINTR.  Effects by I/O path:

- IO_SYNC writes: synchronous bwrite(9) callers now get ETIMEDOUT
  instead of a bogus EINTR after one timeout window.  This is the
  only errno inversion.
- Discontiguous appends: fuse_write_biobackend previously flushed
  through a goto again loop that never observed the timeout (no
  b_error was recorded on the buffer) and the write never returned;
  it now breaks out and returns ETIMEDOUT to the writer after one
  window.
- fsync(2): vn_fsync_buf previously re-flushed until maxretry
  (10000) flush passes were exhausted, each pass delayed a full
  timeout window, and finally returned EAGAIN; it now reports
  ETIMEDOUT after a single pass, because the final scan reads the
  recorded b_error of the still-dirty buffer, which brelse(9)'s
  redirty scrub leaves intact.

Reads that require read-modify-write already returned ETIMEDOUT
before this change and are unaffected.  Async buffers are redirtied
and retried by the flusher as before.  A writer whose daemon stays
unresponsive now observes the timeout instead of hanging in the
flush path.

This intentionally changes the errno seen by synchronous IO_SYNC
writers on daemon timeout from EINTR to ETIMEDOUT.

PR:		<NNNNNN>
MFC after:	2 weeks
Signed-off-by:	<Real Name> <e@4779.name>
```

### Conditional dtrace paragraph — DO NOT SEND YET

Append the paragraph below to the commit body ONLY after the
`sdt:fusefs:::ipc-trace /arg0==3/` transit-probe run supports it, and
prefer PR text over commit body (council memo #2, style pass-2):

```
Observed on a bcachefs FUSE mount: a synchronous writer wedged in
the unbounded flush retry while the daemon was unresponsive; dtrace
counts are in the PR.
```

### Append-lane retval form (maintainer F3 disclosure, fix pass 2)

The append lane in fuse_write_biobackend (:669-672) consumes
bwrite(9)'s return value, not b_error:

```c
err = bwrite(bp);
if (err == EINTR || err == ETIMEDOUT)
	break;
```

bwrite(9) is a static inline wrapper over bufwrite(9) whose retval is
bufwait(9)'s return: the correct errno in BOTH branches (EINTR via
B_EINTR, ETIMEDOUT via BIO_ERROR/b_error), so no stale-b_error window
exists.  This replaces the earlier b_error-after-brelse form: after a
timeout episode + recovery, b_error is never cleared on success by
this path (bufwrite returns retval without writing b_error; nothing
clears it), so every OTHER discontiguous append on that buffer would
have returned a spurious ETIMEDOUT for a successful flush.  The
strategy branch's ETIMEDOUT comment (:903-915) carries the matching
half-sentence ("The write path consumes bwrite(9)'s return value, not
b_error."); its persistence wording is unchanged (fsync's final scan).

### Packaging notes (non-verbatim, submitter checklist)

- Fill `<Real Name>` / `<NNNNNN>` before sending: the same identity in
  the Signed-off-by footer AND the new test file's copyright line
  (fusefs_timeout.cc currently carries the `<Real Name>` placeholder —
  DCO consistency, style MF-7).  DCO requires a real email; noreply
  addresses are a committer red flag (corpus guide.md).
- `Relnotes: yes` is a candidate footer for the committing committer
  (intentional errno inversion = compatibility break; guide.md:2425
  receipt) — deliberately left out of the draft, memo did not mandate.
- Companion test patch (fusefs-tests-etimedout.patch): Timeout.
  fdatasync_etimedout + Timeout.append_lane_etimedout + Timeout.
  append_after_recovery, bounded-silence counting handler (20 windows,
  then success — no Times(N) cardinality coupling), elapsed asserts
  bounded at 3.0 s, copyright placeholder.
- Regression test Timeout.append_after_recovery (fusefs_timeout.cc
  :234-313, verifier-gap fix pass 2026-11-14): seeds dirty [0, 512),
  silence → pwrite@1024 → ETIMEDOUT (≤3.0 s), then the mock recovers
  (silent_windows = 0) → repeat pwrite@1024 same range → SUCCESS.
  Fails on the stale-b_error append lane (spurious ETIMEDOUT for a
  successful flush), passes with the retval form;
  fdatasync_etimedout does not cover this lane (its recovery rides
  vn_fsync_buf's retry pass, which scrubs b_error before the flush
  sees it).
- Gates before submission: kernel+userspace builds and kyua
  fusefs_timeout run on the patched module (orchestrator slot);
  dtrace transit-probe receipt before any PR text claiming the
  "Observed" sentence; work-verifier re-pass (12-point checklist) on
  the final diff.

## 2. fuse_ipc-deadline-cap — DEMOTED (NOT in this PR set)

Council verdict 2026-11-14: **NOT SENDABLE as-is; demoted from
bcf005.** The patch file
overlay/patches/kernel/fuse_ipc-deadline-cap.patch stays in the tree
as receipts only — do not attach it to any PR.

Converged reasons (full detail: council memo §fuse_ipc):
1. The cap is a NO-OP for no-intr mounts (SIGFILLSET,
   fuse_ipc.c:421-426) — poolfuse mounts WITHOUT intr, so the
   qbittorrent story does not fall under it (probable misattribution).
2. Old code already converges to ≤2×daemon_timeout per interrupted
   attempt (latch, fuse_ipc.c:507-515) — "wedged forever" per call is
   dead.
3. BLOCKER: daemon_timeout=0 is legal (fuse.h:66) and the cap kills
   it (slptime<=0 on first pass → instant ETIMEDOUT on every op).

Survival path if ever pursued (separate later patch, NOT bcf005):
reframe as "intr-only: bound one interrupted wait to one window" +
daemon_timeout != 0 guard + dtrace trace of an intr scenario +
receipts that qbittorrent sat on an intr mount.  Until then:
receipts only.
