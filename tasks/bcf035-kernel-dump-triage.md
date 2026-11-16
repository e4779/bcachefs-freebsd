---
title: "Kernel crash dump triage: panic path + subsystem verdict (event-driven)"
id: "bcf035"
status: pending
priority: medium
type: chore
tags: [evidence, kernel, ops]
created_at: "2026-11-16"
dependencies: []
effort: medium
context: [tasks/bcf005-p5-kernel-patches-upstream-freebsd.md, tasks/bcf032-fuser-070-kent-arm.md, tasks/bcf034-kent-loop-watch-1234.md, docs/f3-runbook.org]
---

# Kernel crash dump triage: panic path + subsystem verdict (event-driven)

## Objective

One deliverable: a triage report (written into this card) that pins the panic path from a
real kernel crash dump on the prod host and closes with a subsystem verdict plus a routing
decision.

**Event-driven activation.** This task sleeps until a crash dump appears in `/var/crash/`
on the prod host (`vmcore.N` + `info.N` + `core.txt.N`, written by savecore; rc.conf already
carries `dumpdev="AUTO"`). The trigger is the dump's existence — the owner notices it, or a
savecore line shows up in logs/dmesg after a panic. No cron, no review schedule, no expiry:
nothing in this card rots while it sleeps.

Why it matters: the prod kernel carries our experimental inverse fuse_io patch (bcf005
chain, deployed into /boot/kernel). A panic under it is currently diagnosed blind — no
dumpdev existed at task-writing time (zvol swap rejected via DIOCSKERNELDUMP; file-system
dumps impossible per dumpon(8); no free real partitions; RAM 31GB ⇒ full dump ≥31GB). A dump
on disk therefore implies the owner has since provisioned a real dumpdev (dedicated ≥32GB
stick or a carved partition — owner's separate hardware track, OUTSIDE this store and this
task's scope). The card works regardless of which provisioning path was taken, including
compressed dumps (`dumpon -Z`).

**Panic-time truth comes from the dump, not from this card.** Derive the kernel version,
module identity, and build ids from `info.N` / `core.txt.N` and the kgdb banner. Snapshot at
writing time (2026-11-16, provenance only — may be stale by activation): kernel
15.1-RELEASE-p6; inverse fuse_io sha c23977d4 deployed 2026-11-14. Experimental sides that
could own a panic: kernel-side bcf005 (fuse_io/fuse_ipc), userland FUSE daemon side
bcf032/bcf034 (070 SIGURG reader-kick).

## Tasks

- [ ] Provenance + integrity: list `/var/crash/`; record the `vmcore.N` / `info.N` /
      `core.txt.N` triple with sizes and mtimes; cross-check the expected dump size from
      `info.N` against the actual `vmcore.N` size — flag any mismatch as a truncated dump
      (valid outcome, see AC note).
- [ ] Panic-time revision: extract the kernel version string and panic message from
      `info.N`/`core.txt.N`; verify the available debug kernel
      (`/usr/lib/debug/boot/kernel/kernel.debug`, built for the CURRENTLY installed kernel)
      matches the panic-time build. Mismatch trap: if freebsd-update (or a manual install)
      replaced the kernel between panic and analysis, recover the matching `kernel.debug`
      or mark symbolization degraded in the report. Same check for our deployed module(s):
      `/boot/kernel/` + `/usr/lib/debug/boot/kernel/*.ko.debug` (our module may be built
      from main while the kernel is 15.1-RELEASE — version skew is expected, state it).
- [ ] kgdb session: `kgdb /usr/lib/debug/boot/kernel/kernel.debug /var/crash/vmcore.N`;
      confirm the banner version matches `info.N`; capture the panic context: `ps`, `bt`
      (full backtrace of the panic thread), `frame` / `info locals` on the top interesting
      frames; walk the stack for our paths (fuse_io / fuse_ipc / bcachefs-FUSE) vs foreign
      subsystems.
- [ ] Verdict, exactly one: `ours` (inverse fuse_io / bcachefs-FUSE stack), `other:
      <subsystem>` (named — e.g. zfs, vm, tty), or `indeterminate: <gap>` (name the
      specific gap: truncated dump, missing debug symbols, unwalkable stack).
- [ ] Routing per verdict: `ours` → open/prepare the upstream bug report (FreeBSD
      bugzilla, per the bcf015 precedent) with the evidence pack (panic string, backtrace
      excerpt, panic-time versions, module sha) and record the permanent receipt in this
      card; `other` → documentation-only, no upstream action; `indeterminate` → no upstream
      action, gap documented.
- [ ] Close the loop: paste verdict + routing receipt into this card; record the ops
      journal entry: `git commit --allow-empty -m "ops(f3): bcf035 dump triage verdict - <X>"`
      with body trailers `Context:` (1 line) and `Refs: bcf035`.

## Acceptance Criteria

- [ ] The triage report exists in this card and contains all four mandatory elements: dump
      provenance (file triple + sizes + truncation status), the panic string, the
      panic-thread backtrace, and the revision-match statement (which `kernel.debug` /
      module symbols were used vs the panic-time build; explicit degraded-symbolization
      flag if not exact).
- [ ] The report ends with exactly one verdict — `ours`, `other: <subsystem>`, or
      `indeterminate: <gap>` — and a routing entry consistent with it (ours ⇒ upstream
      receipt present; other / indeterminate ⇒ documentation-only note; no verdict without
      its routing counterpart).
- [ ] The ops journal commit recording the verdict exists in first-parent git history with
      the `Refs: bcf035` trailer.

A truncated or corrupt dump is a VALID outcome, not a failure: the ACs are satisfied when
the report documents the corruption, its effect on confidence, and routes to
documentation-only / indeterminate. The ACs FAIL on: a verdict without the revision-match
statement, a verdict without a backtrace, or a routing claim without a receipt.

## Source

Owner brief 2026-11-16: dumpdev structural impossibility verified live 2026-11-16
(dumpon(8) man-check + DIOCSKERNELDUMP refusal on the zvol swap; gpart shows no free real
partitions). Motivation: experimental inverse fuse_io (bcf005, deployed 2026-11-14, sha
c23977d4) leaves panics undiagnosable without a dump; 2026-11-14 power loss was hardware,
not a panic — the "panic from our module" class is real and evidence-uncovered.
Event-driven shape precedent: bcf034. Host facts: prod runs 15.1-RELEASE-p6; kgdb,
savecore, `/usr/lib/debug/boot/kernel/` and `/var/crash/` present.
