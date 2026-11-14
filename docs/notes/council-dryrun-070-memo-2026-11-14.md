# Council dry-run memo — patch 070 readiness (bcf020 pilot)

2026-11-14 · roster: council-style, council-skeptic, council-maintainer
(council-ops not seated — no live-pool decision involved) · passes: 2
(pass 1 independent reports; pass 2 = resume cross-exam with curated
relay; no fallbacks) · evidence ground: corpus
`docs/notes/upstream-corpus-2026-11-13/`, working tree, /usr/src.

## Question

Is patch 070 (SIGURG reader-kick, commit b1a110f) ready to submit as
a PR to koverstreet/fuser, and in what framing?

## Recommendation

**Approaching ready — one blocker.** Fix P2 (SIGURG disposition
hygiene), apply the one-line mid-dispatch amend, run the mechanical
gates, use the framing kit. Then submit to koverstreet/fuser ONLY
(cberner is out — stickiness argument below).

## Converged findings (pass-2 consensus)

1. **Framing (converged, skeptic conceded):** 070 is a bugfix on
   Kent's OWN destroy-before-reply arm (8fc86cf, pinned @8819589;
   skeptic verified and withdrew his P4 entanglement claim). Caveat
   kept: cberner rejected the ordering (c0420fc); koverstreet/fuser
   has zero external PRs ever and is 80 behind — the real question
   is "grow the carrier or not", answered by minimal diff + existing
   rebase discipline.
2. **Merge precondition (maintainer spec, skeptic concurs on
   construction):** one-line amend — top-of-loop
   `session_dead` check (Acquire) in `receive_session_aware` before
   `receive` (channel.rs:66-67 insert). Flag is monotonic
   (Release-store before the kill) = source of truth; SIGURG only
   wakes readers already in read(2); single fire sufficient. Commit
   message must state this invariant explicitly.
3. **Sole remaining blocker — P2 SIGURG disposition:** the handler
   is installed process-wide and unconditional (session.rs:297,
   522-530). Required: cfg(freebsd) gate + oldact save/verify
   (warn on foreign handler) or Config opt-in. Newly named
   assumption: process-wide SIGURG disposition ownership for the
   session lifetime — a foreign SA_RESTART handler silently
   restores the hang.
4. **Evidence language:** cite POSIX sigaction semantics (no
   SA_RESTART ⇒ interrupted read(2) returns EINTR) as the mechanism
   basis; the n=1 live fire (≤4s) is confirmation, not proof.
5. **Test story (honest partition):** in-CI Linux `/dev/fuse` unit
   for the flag/EINTR logic (drop_waits_for_destroy harness
   pattern; full hang path cannot run on Linux by construction);
   out-of-CI scripted FreeBSD interleaving repro (magic-path
   slow-dispatch race, n≥3 + idle control arm, skeptic's outcome
   table) — stated as CI-infeasible, never overclaimed.
6. **#757 policy:** one neutral technical cross-reference + the
   "does not change reply ordering" disclaimer, Kent audience only;
   grievance phrasing and momentum claims banned from PR text;
   optional ungated cross-comment on the issue.
7. **Mechanical gates before submit:** cargo fmt --check + clippy;
   pin b1a110f hash in corpus and PR text (absent from corpus —
   fixed); name the fork rev targeted (8819589 or HEAD); strip
   non-070 items from the diff (writev-retry channel.rs:117-145,
   SessionACL::to_mount_option, n_threads lift).

## Accepted / rejected feedback

- Accepted: skeptic P1 (one-shot edge, mid-dispatch hole), P2
  (disposition blocker), #757 framing policy, mechanical gates,
  corpus stat erratum.
- Accepted: maintainer one-line fix spec (over skeptic's
  "documented limitation" disposition — rejected on review-burden
  grounds), Acquire over Relaxed (ordering argument), framing kit.
- Rejected: skeptic's pass-1 P4 entanglement claim (withdrawn after
  8fc86cf verification).

## Owner decisions open

- None blocking the dry-run. bcf014 PR preparation now carries the
  findings above (registered in the task body).

## Evidence

Reports: subagent artifacts (council-style ac532e59, council-skeptic
c41fc05a + pass-2 3fe2f313, council-maintainer cc3594b1 + pass-2
bc744f03). Corpus: CORPUS.md, LIVE-ADDENDUM-2026-11-14.md, raw/
(incl. fuser757.json). Trust note: skeptic found a corpus-internal
stat discrepancy (6/29 vs 11/29 = 38%) — corrected in the
maintainer-tone topic; the 38% figure is authoritative.

## Confidence and what would change it

High that the framing and fix spec are correct (two independent
seats converged with receipts). Would change the decision: a
demonstrated hang even WITH the pre-read check (falsifies the
monotonic-flag mechanism → revisit signal delivery, P2 territory);
a live fuser upstream release absorbing destroy-before-reply (then
070 re-targets the release, not the fork).
