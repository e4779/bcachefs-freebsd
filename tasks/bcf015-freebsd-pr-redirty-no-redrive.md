---
id: "bcf015"
title: "FreeBSD PR (bug report): redirty-no-redrive — the kernel retries an ETIMEDOUT write forever"
status: blocked
priority: medium
effort: medium
type: bug
tags: [upstream, kernel]
dependencies: ["bcf023", "bcf013"]
created_at: 2026-11-13
context: [docs/f3-runbook.org, overlay/patches/kernel/, tasks/bcf001-p1a-mt-fix.md]
---

# FreeBSD PR (bug report): kernel redirty-no-redrive

A bug report to FreeBSD (bugs.freebsd.org or freebsd-src): fuse(4) on ETIMEDOUT on a write silently re-dirties the dirty buffer (redirty) without a redrive — the write never reaches the daemon, a wedge that is not the daemon's fault. Complements our fuse_io-etimedout-fail-fast patch (bcf005): the patch = the fix, the report = recognition of the class.

## Blocker (evidence)

We are waiting on the daemon-alive discriminator (bcf023): at the next wedge, prove that the daemon serves (alive, responsive) and the remainder is the kernel. Without a core/stack carrying this proof the report is hand-waving; upstream will not accept it.

## Steps

1. Duplicates: a search over bugs.freebsd.org (fuse EINTR/wedge/timeout — bcf005 already ordered such a check, merge the findings).
2. A minimal repro (not only our prod core): a scenario + ktrace/stacks.
3. The text per the opensource-contribution skill: evidence-first, the shape-4 diagnosis, stacks from cores.
4. **The project link** https://github.com/e4779/bcachefs-freebsd + our fail-fast patch as a possible fix.

## Definition of done

- The report sent, the number/link recorded into the task; the link-up with the bcf005 PR stated.

## Source

tasks/bcf023 daemon-alive discriminator (the evidence gate); owner decision 2026-11-13 (the publication track).
