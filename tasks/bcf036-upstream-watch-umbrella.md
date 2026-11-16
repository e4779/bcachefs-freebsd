---
title: "Upstream watch: umbrella over all open upstream artifacts (attention-driven)"
id: "bcf036"
status: pending
priority: medium
type: chore
tags: [upstream, watch, coordination]
created_at: "2026-11-16"
dependencies: ["bcf005", "bcf015", "bcf016", "bcf032"]
effort: small
context: [tasks/bcf034-kent-loop-watch-1234.md, tasks/bcf005-p5-kernel-patches-upstream-freebsd.md, tasks/bcf015-freebsd-pr-redirty-no-redrive.md, tasks/bcf016-freebsd-forum-thread.md, tasks/bcf032-fuser-070-kent-arm.md, docs/notes/upstream-corpus-2026-11-13/CORPUS.md]
---

# Upstream watch: umbrella over all open upstream artifacts (attention-driven)

## Objective

One living deliverable: this single card is the observation ledger for EVERY upstream
artifact the project has created and is waiting on (at writing time 2026-11-16: five
trackers, six target lines). One umbrella card, NOT a group of per-target cards; the
goal checklist below is append-only.

The card logs outcomes and routes responses; it is an observation ledger, not a work
queue — engineering work triggered by an outcome is routed to the owning task named
per goal, and this card only records the receipt.

**Attention-driven activation (anti-degradation, bcf035 pattern).** No cron, no review
schedule, no deadlines, no expiry: nothing in this card rots while it sleeps. A check
happens when owner attention lands on upstream — a notification, a maintainer reply, a
manual sweep, or a known window opening (rmacklem's "end of Nov" on 300130 is such a
window, and it is open as of writing).

**Tracker-truth rule.** A target's status is read from its tracker at check time and
copied into the card; the card's cached snapshot is provenance only and is never the
source of truth. Every check re-fetches before writing anything down.

## Tasks

Goal checklist — append-only: any new upstream artifact of this project (bugzilla PR,
GitHub issue/PR, forum thread, mailing-list post) gets a line here the day it is
created, with its link plus an outcome/routing one-liner. The card closes only when
zero goals remain open.

- [ ] **300785** — fusefs ETIMEDOUT redirty-no-redrive (our inverse fuse_io fix travels
      here as attachment 277313, tests as 277314). From the bcf005/bcf015 chain, filed
      2026-11-15. Snapshot (provenance, 2026-11-16): New, no activity.
      Check: `curl -s 'https://bugs.freebsd.org/bugzilla/rest/bug/300785?include_fields=status,resolution,is_open,last_change_time,summary' | jq '.bugs[0]'`
      plus comments: `curl -s 'https://bugs.freebsd.org/bugzilla/rest/bug/300785/comment' | jq '.bugs["300785"][-3:][] | {creation_time, text}'`
      Outcomes: maintainer triage / needs-changes / merge-commit / close.
      Routing: needs-changes → rework the fix in the bcf005 chain (not in this card);
      merge → mark this goal resolved (commit hash logged verbatim); close without
      merge → log the verdict verbatim.
- [ ] **#1234 (THIN REF)** — koverstreet/bcachefs-tools#1234 (070 reader-kick heads-up
      to Kent). The outcome is OWNED BY bcf034 (Kent loop, gate for bcf033): we do NOT
      run duplicate observation here. This line is open/closed exactly when bcf034
      logs its outcome; during a sweep, read bcf034's logged state and move on.
- [ ] **forums.freebsd.org thread .104370** — project announcement (Storage; fresh
      account → premoderation). From bcf016, posted 2026-11-16. Snapshot (provenance):
      awaiting moderation.
      Check (logged-out curl distinguishes visible vs not visible; telling
      premoderation from removal requires the owner's logged-in session):
      `curl -sL -A 'Mozilla/5.0' 'https://forums.freebsd.org/threads/running-a-bcachefs-pool-on-freebsd-a-vm-bridge-and-a-fuse-daemon-port.104370/' | grep -icE 'awaiting (approval|moderation)|message-body'`
      Outcomes: approved / questions / moderation-refusal.
      Routing: questions → answer substantively; refusal → move the announcement to
      another venue (owner chooses; e.g. mailing lists).
- [ ] **300130** — nfscl verifier-bump churn (bcachefs-box era report; our fix as the
      attachment evolution 276998→277008→277145/277146). Snapshot (provenance,
      2026-11-16): Open, confirmed; rmacklem c17 (2026-11-10): "I'll have time to look
      at this around the end of Nov" — that window is NOW as of writing.
      Check: the same two REST fetches with bug id 300130.
      Outcomes: reply / merge / silence-past-window.
      Routing: reply/merge → log verbatim; silence through and past end-of-Nov → log
      a "silence signal" entry; any ping is OWNER JUDGMENT (no auto-ping, no deadline —
      a single polite ping after the window is the owner's call, per corpus tone
      rules).
- [ ] **300475 + 300480** — bhyve uart EOF spin (attachments 276939/276940) and bhyve
      AMD QoS CPUID boot-loop (attachment 276942), both filed 2026-11-03. Snapshot
      (provenance, 2026-11-16): both New, silence; a 300475 follow-up draft exists,
      NOT sent (homelab docs — outside this store).
      Check: the same two REST fetches for 300475 and for 300480.
      Outcomes (per bug): reply / merge / close.
      Routing: reply → answer substantively; merge → log commit hash; close → log
      verdict verbatim. Sending the drafted 300475 follow-up is OWNER JUDGMENT, not a
      scheduled obligation.

## Acceptance Criteria

- [ ] Every checklist target line carries, at any moment, EITHER a final logged outcome
      (date + verbatim tracker evidence + routing receipt) OR a current legitimate-open
      note ("checked YYYY-MM-DD: <live tracker status>"). A line with neither FAILS.
- [ ] Every logged outcome cites tracker evidence fetched at check time (REST/gh/HTML
      output pasted verbatim, with URL and date). An outcome recorded from the card's
      cached snapshot or from memory FAILS. Routing receipts name the owning task for
      any engineering response (e.g. 300785 rework → bcf005 chain); this card never
      hosts fixes or announcements itself.
- [ ] Closure gate: this card reaches `completed` only when zero checklist goals are
      open; closing with any open goal FAILS. A goal open for months is a legitimate
      pending state, not a failure — the ACs fail only on an unlogged outcome, an
      outcome without tracker evidence, or a closure with open goals.

## Source

- Owner brief 2026-11-16: single umbrella observation card, not a group of five cards;
  explicit requirement that provenance threads land as dependency edges ("the card must
  visibly receive the threads from the tasks that created the upstream artifacts");
  anti-degradation identical to bcf035 (no cron, no deadlines — tracker checks happen on
  owner attention; the tracker is the source of truth, never this card).
- Provenance threads: dependencies bcf005, bcf015, bcf016, bcf032 are ALL completed, so
  these edges are satisfied instantly and gate nothing — they are provenance threads
  converging in the graph (which task spawned which artifact): bcf005+bcf015 → bug
  300785 (bcf015 recorded the filing receipt, bcf005 is the patch chain the fix belongs
  to); bcf032 → bcachefs-tools#1234; bcf016 → forum thread .104370. The nfscl/bhyve
  trio (300130, 300475, 300480) predates this store (bcachefs-box era; receipts in
  docs/notes/upstream-corpus-2026-11-13/raw/); bcf005 cites the 300130 pattern as its
  precedent, hence those targets hang off the bcf005 thread.
- Tooling receipts: Bugzilla REST bypasses Anubis (CORPUS.md, snapshots 2026-11-05/13);
  `gh api` covers GitHub artifacts added later; forums = plain curl, where the
  logged-out view only distinguishes visible vs not visible. Graph rendering: the
  provenance threads draw as converging edges under `taskmd graph --all` (the default
  view hides completed nodes and therefore hides the threads).
