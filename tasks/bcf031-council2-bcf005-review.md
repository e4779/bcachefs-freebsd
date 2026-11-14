---
id: "bcf031"
title: "Council #2: review the reworked bcf005 artifacts (inverse fuse_io + tests) before submission"
status: completed
priority: high
effort: medium
dependencies: []
tags: ["review", "council", "kernel"]
created_at: 2026-11-14
completed_at: 2026-11-14
---

# Council #2: review the reworked bcf005 artifacts (inverse fuse_io + tests) before submission

## Objective

Fresh-eyes council on the IMPLEMENTED rework (the bcf013 council
verdicts specified it; script-kiddie implemented; work-verifier
confirmed the spec-match — but nobody has read the result as a
reviewer). Gate: no submission to freebsd-src until this council
accepts.

## Artifacts under review

- overlay/patches/kernel/fuse_io-etimedout-fail-fast.patch
  (inverse version vs main 12a57b07: B_EINTR dropped from the
  ETIMEDOUT lane, append-lane check EINTR||ETIMEDOUT with
  err=b_error, true-contract comment)
- overlay/patches/kernel/fusefs-tests-etimedout.patch
  (fusefs_timeout.cc 200 lines + Makefile GTESTS; NEVER EXECUTED —
  compile-syntax only)
- overlay/patches/kernel/COMMIT-DRAFTS-bcf005.md (commit draft +
  fuse_ipc DEMOTED note)
- council memo baseline: docs/notes/council-memo-bcf013-kernel-2026-11-14.md

## Tasks

- [ ] Seat pass 1 (independent): does the rework implement the memo
      verdicts correctly; fresh-eyes on the inverse semantics
      (sync-lane callers now see ETIMEDOUT — ABI-visible change);
      test design review (will Timeout.fdatasync_etimedout /
      append_lane_etimedout actually pass on main? mockfs patterns
      correct?); framing and drafts honesty.
- [ ] Claim matrix: agreements / disputes / gaps vs the memo.
- [ ] Pass 2 cross-exam on disputes (resume, curated relay).
- [ ] Memo #2: submit-ready verdict per artifact (submit / fix /
      hold), gaps that remain open (kyua run, placeholders).

## Acceptance Criteria

- [ ] Memo #2 persisted in docs/notes/ and committed; verdict per
      artifact recorded.
- [ ] bcf005 unblocked for submission only on a submit-ready
      verdict; otherwise fix-loop back to the implementer.
