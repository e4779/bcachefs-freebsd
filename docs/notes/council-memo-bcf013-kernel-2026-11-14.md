# Council memo — bcf013 gate: kernel patches review (final)

2026-11-14 · roster: council-style, council-skeptic, council-maintainer
(council-ops not seated) · passes: 2 (pass 1 independent; pass 2
resume cross-exam with empirical receipts from the orchestrator and
curated relays) · artifacts: pass-1/pass-2 reports in subagent
artifacts; this memo is the gate verdict.

## Question

Are the two kernel patches (fuse_io-etimedout-fail-fast,
fuse_ipc-deadline-cap) ready to submit to freebsd-src (fusefs(4),
maintainer asomers), and in what shape?

## Verdicts

### fuse_io-etimedout-fail-fast → REWORK (3 edits), then SUBMIT

The committed patch is TWO-LANE (skeptic pass-2 self-correction,
maintainer-verified): sync lane inert (B_EINTR masks b_error in
bufwait, vfs_bio.c:4588-4591), fsync lane ALIVE (b_error=ETIMEDOUT
survives brelse — the scrub clears only BIO_ERROR, vfs_bio.c:2772-
2774 — and vn_fsync_buf's scan breaks on it: one pass instead of a
10000×60s ≈ 6.9-day grind). The patch DOES fix the observed wedge —
with a false comment and dishonest sync errno.

Rework (3 edits): (1) drop the B_EINTR line from the ETIMEDOUT
branch; (2) CRITICAL: extend fuse_io.c:669-672 check to
`EINTR || ETIMEDOUT` or the discontiguous-append lane keeps grinding
(TEST3 covers it); (3) rewrite the comment to the true contract
(style's draft in pass-2 report: b_error → fsync epilogue; bufwait
B_EINTR ordering explanation; brelse clears BIO_ERROR but not
b_error). Keep explicit bdirty (do not rely on brelse auto-redirty:
ENXIO trap).

Commit draft delivered by style (subject 60 chars: "fusefs: report
daemon timeouts to sync writers as ETIMEDOUT", intentional
EINTR→ETIMEDOUT ABI-visible change stated, MFC after: 2 weeks).

### fuse_ipc-deadline-cap → NOT SENDABLE as-is; demoted from bcf005

Converged facts: (1) the cap is a NO-OP for no-intr mounts (SIGFILLSET,
fuse_ipc.c:421-426) — poolfuse mounts WITHOUT intr, so the
qbittorrent story does not fall under it (probable misattribution);
(2) old code already converges ≤2×daemon_timeout per interrupted
attempt (latch, fuse_ipc.c:507-515) — "wedged forever" per call is
dead; (3) BLOCKER: daemon_timeout=0 is legal (fuse.h:66) and the cap
kills it (slptime≤0 on first pass → instant ETIMEDOUT on every op).
Survival path if pursued: reframe as "intr-only: bound one
interrupted wait to one window" + daemon_timeout≠0 guard + dtrace
trace of an intr-scenario + receipts that qbittorrent sat on an
intr mount. Otherwise: keep as receipts, out of bcf005.

### Cross-cutting

- PR-disposition: TWO PRs (separate files/mechanisms/tests),
  cross-linked; both ≤10 files/≤200 lines.
- Packaging: regenerate from a fresh main worktree as git diffs
  (current diffs are /root-backup GNU-diffs — won't apply); DCO
  Signed-off-by (real email); checkstyle9.pl = 0 explicit gate;
  anchors re-verified on 15.1-RELEASE, re-check after rebase to main.
- Tests: TEST2 fsync ETIMEDOUT ≤2s vs grind-kill (fails on unpatched
  = failing-then-passing); TEST3 append-lane (new); TEST1 cap
  (weakest — asomers may call 2→1 windows not-a-bug); mount-option
  plumbing in the harness needed.
- dogfooding honesty: production "validation" claims about the cap
  are UNSUBSTANTIATED (see provenance below) — do not put them in
  PR text.

## Live-mine escalation (owner decision, OUT of council scope)

/boot/kernel/fusefs.ko (built Nov 6 11:16, after both patches)
contains the UNGUARDED cap; poolfuse rc passes timeout=0. The loaded
in-memory module predates the rebuild (cannot unload under a live
mount, EBUSY at 107k vnodes) — that is why prod is alive. The NEXT
reboot/kldload arms an instant-ETIMEDOUT storm on every operation =
pool outage. Options: (1) build+install a guarded module; (2) sysrc
poolfuse_timeout_s≥1; (3) conscious deferral with the risk recorded.

## Provenance resolution (skeptic pass 2)

Leading explanation: `timeout=0` never reaches daemon_timeout — it
is lost in transit (mount.rs demux → fs_opts; mount_fusefs.c option
table does not know it; static trace: mount.rs:485-591,
fusemount.rs:1979-1980, mount_fusefs.c:66-105). The kernel has been
running on the default 60s all along; the "timeout=0 architecture"
(runbook 12:5x) does not exist in the kernel. Discriminator: one
dtrace command on a test mount (`sdt:fusefs:::ipc-trace /arg0==3/`),
no rebuild — mandatory before any PR text that claims production
validation.

## Residual risks

- 15.1 ↔ main drift: anchors verified on 15.1-RELEASE only; re-diff
  against fresh main mandatory.
- B_PAGING/VMIO subcases of the ETIMEDOUT branch untraced.
- sys/fs/fuse commit-tone unresolved (no git history locally).
- stale-b_error race on buffers rewritten before the fsync scan
  (pre-existing buf-API pattern; note as known limitation in PR).
