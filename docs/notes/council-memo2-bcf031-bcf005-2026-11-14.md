# Council memo #2 — bcf031: reworked bcf005 artifacts review (final)

2026-11-14 · roster: council-style, council-skeptic, council-maintainer
· passes: 2 (pass 1 on the implemented rework; pass 2 cross-exam with
the skeptic/maintainer/style triangle + orchestrator empirical
receipts) · baseline memo: council-memo-bcf013-kernel-2026-11-14.md.

## Question

Is the IMPLEMENTED rework (inverse fuse_io patch regenerated vs main
12a57b07 + fusefs_timeout tests + commit drafts) ready for
submission to freebsd-src?

## Verdicts

### fuse_io-etimedout-fail-fast.patch → NOT submit-ready: append-lane
### hunk reshape (2-line form, converged)

STICKY DEFECT (maintainer escalated, skeptic confirmed with traces):
the strategy lane never clears `b_error` on success (fuse_io.c:823-884
clears flags only; bufwrite returns retval without writing b_error;
nothing clears it), so after one timeout episode + recovery every
OTHER discontiguous append on that buffer returns a spurious
ETIMEDOUT for a successful flush — a persistently broken errno
contract on exactly the workload class the PR motivates (piece
writers). asomers reads errno contracts precisely → instant reject.

FIX (converged: skeptic specified + traced both lanes, maintainer
verified the form): the append lane consumes `bwrite(9)`'s retval
instead of re-reading `b_error` after brelse:
`err = bwrite(bp); if (err == EINTR || err == ETIMEDOUT) break;`
Race-free (retval is what the sync consumer actually got; brelse
drops the lock before the read). Strategy-branch comment unchanged
(persistence attributed to fsync's scan); + half-sentence: the write
path consumes bwrite(9)'s retval, not b_error.

### fusefs-tests-etimedout.patch → NOT submit-ready: bounded silence
### rework + new case

1. Bounded silence: silent-window COUNTING HANDLER in the test body
   (N=20 windows, then success; NOT Times(N) — cardinality coupling
   breaks patched-run teardown, style S2). Unpatched: flush completes
   at window 21 → clean assert-fail (no runner hang — the
   uninterruptible-biowr kyua-kill hole is closed); patched: ETIMEDOUT
   at window 1.
2. NEW test `Timeout.append_after_recovery`: silence → pwrite@1024 →
   assert ETIMEDOUT; mock recovers → repeat pwrite@1024 → assert
   SUCCESS. Fails on the unfixed patch (spurious ETIMEDOUT), passes
   with the retval fix. fdatasync_etimedout does NOT cover this (its
   recovery rides vn_fsync_buf/loop1, which heals before the flush).
3. Wall-clock asserts ≤2.0s → ≤3.0s (3× the 1s window; flake margin).
4. Copyright line → the real author identity matching Signed-off-by
   (DCO consistency).
5. Comment updates: soften "exceeds the harness timeout" → "blocks
   until externally killed on unpatched kernels; the bound makes it
   fail cleanly".

### COMMIT-DRAFTS-bcf005.md → not sendable verbatim: use the style
### corrected body (delivered in pass-2 report §(a), verbatim)

B1: the fsync sentence ("already reports ETIMEDOUT") is FALSE for
stock — code-anchored replacement (vfs_vnops.c:3245-3312:
maxretry=10000 grind → EAGAIN; patched = one-pass ETIMEDOUT via the
final b_error scan; style report has the receipts). B2: append-lane
sentence folded into the body. New: three-lane precise inventory
(IO_SYNC = the only true EINTR→ETIMEDOUT inversion; append lane =
wedge→ETIMEDOUT, stock never returned; fsync = EAGAIN-after-grind →
one-pass ETIMEDOUT; RMW reads already ETIMEDOUT pre-patch).
Footer order PR → MFC after → Signed-off-by (guide.md:2406-2435).
Conditional dtrace sentence: append ONLY after the transit-probe run
supports it; prefer PR text over commit body. qbittorrent mention:
dropped (softened mechanism-premise sentence is the replacement).
`Relnotes: yes` — candidate for the committer, left out (memo did
not mandate).

## Converged facts (three-lane inventory, all seats + code anchors)

- IO_SYNC writes: stock EINTR → patched ETIMEDOUT. The only true
  errno inversion; intentional, stated.
- Discontiguous appends: stock = eternal `goto again` wedge (the
  OBSERVED failure mode); patched = ETIMEDOUT after one window.
- fsync(2): stock = grind maxretry=10000 × window → EAGAIN;
  patched = one-pass ETIMEDOUT (b_error recorded after loop1's
  scrub, read by the final scan).
- RMW reads: already returned ETIMEDOUT pre-patch (fuse_io.c:598-604)
  — unaffected; verified on the main clone.
- The stale-b_error append-lane defect is INTRODUCED by the rework
  (not present in stock) and is fixed by the retval form.

## Gates before submission (owner-ordered)

1. Implementer re-pass: append-lane retval reshape + test edits
   (bounded silence, append_after_recovery, copyright, 3.0s) +
   regenerate both patches on a pristine worktree.
2. work-verifier re-pass: apply-check both patches on a pristine
   clone; the 12-point checklist re-run on the final diff.
3. Build receipts: compile main+patches; kyua fusefs_timeout green
   on the patched module (build = orchestrator slot; module load
   test on a TEST image — the installed module stays until reboot).
4. Transit-probe receipt (dtrace arg0==3) — before PR text.
5. Real name/email into drafts; owner go; submit.

## Residual

- Unbound spawn/exit cycle: retirement proven (45→33 threads) but
  the synthetic burst did not drive events_unbound specifically;
  runtime unbound-path evidence deferred to the prod deploy window.
- 15.1↔main drift: anchors on both trees verified; re-check after
  rebase.
- The 77GB core + /tmp clones: retention decisions pending owner.

## Independent triangulation (PASS-3, post-memo)

The FIRST council's maintainer (b4273bcf, revived with a context
correction after a wrong-id resume) read the reworked artifacts
cold and independently converged: fsync lane correct as-is
(b_error-keying right for bawrite/epilogue); append lane needs the
two-line retval fix (two false-errno windows S1/S2); test patch =
hard blocker (fusefs_timeout.cc does not compile against STOCK —
m_daemon_timeout is main-only plumbing). Attachment:
council-memo2-attach-pass3-independent-confirmation.md. Three-way
triangulation of the verdicts complete.
