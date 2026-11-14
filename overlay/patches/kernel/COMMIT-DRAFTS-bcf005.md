# bcf005 — commit-message drafts (kernel patches, post-council rework)

2026-11-14 · regenerated against fresh freebsd-src main HEAD
12a57b078972c4f2778dfaa2faa96a4c64f59dc6 (2026-11-13, shallow clone,
/tmp/bcf005-src). Council verdict + style pass-2 are the source of
truth: docs/notes/council-memo-bcf013-kernel-2026-11-14.md.

Patches (both verified `git apply --check` standalone against stock
HEAD, `diff --git a/ b/` format):
- overlay/patches/kernel/fuse_io-etimedout-fail-fast.patch
  (sys/fs/fuse/fuse_io.c: branch split @ :896-904, append lane @ :670-673)
- overlay/patches/kernel/fusefs-tests-etimedout.patch
  (tests/sys/fs/fusefs/: Makefile + fusefs_timeout.cc, new file)

## 1. fuse_io-etimedout-fail-fast — commit message (style pass-2, VERBATIM)

Subject: 60 chars. Intentional EINTR→ETIMEDOUT ABI-visible change is
stated in the body. `MFC after: 2 weeks` per council.

```
fusefs: report daemon timeouts to sync writers as ETIMEDOUT

When the daemon misses a full timeout window, fuse_io_strategy
redirties the buffer and sets B_EINTR, so bufwait(9) reports EINTR
to synchronous writers, masking the real errno (B_EINTR is checked
before BIO_ERROR).  A client whose daemon stays unresponsive never
observes ETIMEDOUT and stays wedged (observed with a bcachefs FUSE
mount under qbittorrent load; dtrace counts in the PR).

Keep the dirty data and set BIO_ERROR with b_error = ETIMEDOUT
without B_EINTR.  Synchronous bwrite(9) callers now see the real
ETIMEDOUT; fsync(2) already reports ETIMEDOUT because vn_fsync_buf's
final scan reads b_error of still-dirty buffers, and brelse(9)
clears BIO_ERROR but not b_error when redirtying a failed write.
Async buffers are redirtied and retried by the flusher as before.
This intentionally changes the errno seen by synchronous writers on
daemon timeout from EINTR to ETIMEDOUT.

PR:             <NNNNNN>
Signed-off-by:  <Name> <e@4779.name>
MFC after:      2 weeks
```

### Packaging notes (non-verbatim, submitter checklist)

- Fill `<Name>` and `<NNNNNN>` (bugzilla PR number) before sending;
  DCO requires a real email — noreply addresses are a committer red
  flag (corpus guide.md).
- The regenerated diff also extends the discontiguous-append lane
  check in fuse_write_biobackend (`EINTR || ETIMEDOUT`, main :670-673)
  and carries the companion test patch
  (fusefs-tests-etimedout.patch: Timeout.fdatasync_etimedout,
  Timeout.append_lane_etimedout).  The verbatim draft above predates
  the append-lane edit — before sending, add one sentence covering it,
  e.g.: "The discontiguous-append lane in fuse_write_biobackend
  propagates the timeout to the writer instead of retrying forever."
  Keep everything else byte-identical to the draft.
- Gates before submission: checkstyle9.pl = 0 on both files
  (verified locally for the new diff hunks: 0 trailing whitespace,
  0 lines >80 col in added lines); anchors re-checked on main
  (branch @ :896-927, append lane @ :669-675); dogfooding numbers for
  the "observed" sentence must come from the dtrace
  `sdt:fusefs:::ipc-trace /arg0==3/` probe run on a test mount before
  any PR text that claims production validation.
- Known limitation to note in the PR text (council residual risk):
  a stale b_error can persist on a buffer rewritten before the fsync
  scan; pre-existing buf-API pattern.

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
