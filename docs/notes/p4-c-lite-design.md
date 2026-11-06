# C-lite — restricted FUSE_IOCTL for freebsd-src (upstream gift design)

**Status: DESIGN, council Ф3** (plan-of-record, `docs/f3-runbook.org` P4):
a separate upstream track, NOT the telemetry deliverable. The council's
marshaling counter-fact (§3) means C-lite cannot carry QUERY_ACCOUNTING —
telemetry is served by A+ (snapshot ring); B-lite is the frozen fallback.

Evidence base: `tmp/p4/{ioctl,gate}.md` recon (2026-11) + live /usr/src read
(fusefs(4) as shipped on hlab). All file:line verified against the tree.

## 1. The TODO site

`fuse_vnop_ioctl()` — /usr/src/sys/fs/fuse/fuse_vnops.c:1309 (registered
`:201`) — returns ENOTTY for everything except FIOSEEKDATA/FIOSEEKHOLE:

```c
default:
    /* TODO: implement FUSE_IOCTL */   /* :1340 */
    err = ENOTTY;
```

The wire ABI already knows the opcode: FUSE_IOCTL = 39
(/usr/src/sys/fs/fuse/fuse_kernel.h:518) and its flags (`:433-440`:
COMPAT, UNRESTRICTED, RETRY, 32BIT, DIR, COMPAT_X32). No `fuse_ioctl.c`
exists (Linux `fs/fuse/ioctl.c` has no counterpart); fusefs(4) man page has
zero occurrences of "ioctl". Implementing it is a genuine upstream gift —
the TODO is theirs, in-tree.

## 2. Scope: fixed-_IOC_SIZE commands ONLY

Restricted mode only (kernel marshals cmd + fixed buffer in/out; daemon
returns ≤ out_size bytes). No RETRY, no UNRESTRICTED — that is C-full
(Ф4, explicit re-decision: owns the RETRY/UNRESTRICTED security tension,
scope 3-5x by council estimate).

## 3. The marshaling counter-fact (why scope is fixed-only)

_IOC_SIZE(cmd) carries ONLY the fixed header: 32 B for
BCH_IOCTL_QUERY_ACCOUNTING v1, 160 B for v2 (`tools/include/asm/ioctl.h:39`
_IOC layout; computed 0x4020BC15 / 0x40A0BC25, `tmp/p4/ioctl.md` §1b).
The actual metrics ride a flex array AFTER the header
(`accounting: [BkeyI<Accounting>; 0]`, `tools/fs/bcachefs_ioctl.rs:743`),
sized by the caller (`accounting_u64s`, buffer grown 1 KiB → 1 GiB,
`tools/src/wrappers/accounting.rs:48-64`). Restricted marshaling copies
exactly _IOC_SIZE(cmd) bytes each way — the flex array can NEVER round-trip.
A v2 request that "succeeds" would deliver the 160-byte header with empty/
stale metrics: **the CLI would silently show no data**. This is why the
council capped C-lite at fixed-size commands and kept the telemetry goal
on A+/B-lite. Fixed-size victims that DO fit: BCH_IOCTL_QUERY_UUID
(0x8010BC01, 16 B) and similar probe-class commands; READ_SUPER's header
is fixed (32 B) but its `sb` field is a caller pointer — restricted
marshaling cannot dereference it either, so READ_SUPER is out too.

Number-format footnote (verified, `tmp/p4/ioctl.md` §4): FreeBSD
sys/ioccom.h uses the same bit layout (dir<<30 | size<<16 | group<<8 |
nr; IOCPARM_MAX 0x1fff ≥ 160), so Linux-encoded 0xbc-group cmds arrive
unchanged; only the direction-bit naming differs (Linux _IOW=1 vs
FreeBSD IOC_IN=2) — never validate direction bits.

## 4. Kernel design

Mirror the FUSE_LSEEK precedent in the same function:

1. `fsess_maybe_impl(mp, FUSE_IOCTL)` → build `fuse_ioctl_in`
   (cmd, flags=0 restricted, in_size=_IOC_SIZE(cmd), out_size) + in_data
   copied from ap->a_data; fdisp to the daemon; copy min(reply_len,
   out_size) back to a_data.
2. ENOSYS reply → `fsess_set_not_impl(mp, FUSE_IOCTL)` (same as LSEEK
   at fuse_vnops.c:410-415 region) → every later call short-circuits to
   ENOTTY with zero round trips.
3. **Non-declaring daemons stay byte-identical**: stock daemons answer
   ENOSYS once (libfuse default for unknown op), callers keep getting
   ENOTTY exactly as today — no ABI break, no negotiation change. This
   is the argument that makes it mergable.

Daemon side in our fuser fork already exists end-to-end for restricted
mode: request parse (`src/ll/request.rs:1822-1826)), unrestricted→ENOSYS
gate (`src/request.rs:430-432`), trait method with ENOSYS default
(`src/lib.rs:923-940`), reply (`src/reply.rs:609` → `src/ll/reply.rs:256-275`).
The bcachefs daemon must still override `fn ioctl` and bridge to
`fs_file_ioctl` (`tools/fs/vfs/ioctl.rs:162`) — fusemount.rs:1020 has no
override today (gap 1 in `tmp/p4/ioctl.md` §5).

## 5. Deadlock rule: vn_lock and handler purity

The LSEEK branch wraps its FUSE round trip in `vn_lock(vp, LK_SHARED |
LK_RETRY)` (fuse_vnops.c:1331) — kernel sleeps in fdisp_wait_answ holding
the vnode lock. If the daemon's handler ever re-enters the mount through
syscalls (path lookup needs LK_EXCLUSIVE) the daemon deadlocks against
its own reply. Rules for the ioctl branch:

- Prefer NO vn_lock at all: fixed-size pure queries read daemon-internal
  state, they need no vnode consistency.
- If a lock is ever added: LK_SHARED only, and handler purity becomes a
  hard requirement — the daemon answers from in-memory state (bch_fs is
  internally locked, fusemount.rs:886-887) and never issues syscalls on
  the mount.

## 6. Security model

- **Default-deny cmd allowlist at kernel AND daemon.** Kernel: forward
  only commands on an explicit per-session allowlist (opt-in via FUSE_INIT
  extension or dev-adjacent knob; no wildcard). Daemon: its own opcode
  whitelist — the bcachefs rust-kernel dispatch is already default-deny
  (`tools/fs/init/chardev.rs:77-145`, `_ => ENOTTY` at :144).
- **Uid gate via a_cred.** The caller's credentials are ap->a_cred
  (fuse_vnop_ioctl localizes it already); the FUSE request header carries
  the caller uid — the daemon MUST authorize on that, never on its own
  process privileges: capable()-style checks in the daemon context are
  always-true/meaningless (the daemon is not the caller).
- Buffer bounds: in_size/out_size clamped to _IOC_SIZE(cmd) ≤ IOCPARM_MAX;
  reply_len > out_size → truncate-to-protocol + log, never over-copy.

## 7. Deadline-cap coupling (from day one)

FUSE_IOCTL requests sleep in fdisp_wait_answ — exactly the path where
periodic signals used to restart msleep with a fresh window forever
(form-4 wedge, bcachefs dogfood 2026-11; our fix: `overlay/patches/kernel/
fuse_ipc-deadline-cap.patch`, fuse_ipc.c:411+ — one daemon_timeout window
per request, hard). The C-lite series MUST ship with the deadline cap
(or build on a tree that has it): a wedged daemon must yield ETIMEDOUT
to ioctl callers within daemon_timeout, not hold them indefinitely.
Stock-tree behavior without the cap is a known wedge amplifier.

## 8. Test plan (staging guest, no prod exposure)

- Environment: staging mdconfig image via `scripts/stage-session.sh`
  (docs/notes/17a-frame-zero.md) on a guest; custom fusefs.ko built from
  patched /usr/src; verify load with `kldstat -v` / `kldload -v`, confirm
  module path so the stock module is not silently serving.
- Positive: fixed-size cmd (QUERY_UUID) round-trips value-correct bytes
  vs the same query offline.
- Negative (each must FAIL CLOSED, not degrade):
  - non-declaring daemon (stock libfuse hello) → first call ENOSYS
    negotiated, then ENOTTY, zero extra round trips; daemon log clean;
  - flex-array cmd (QUERY_ACCOUNTING v1/v2) → allowlist rejects with
    ENOTTY — never a truncated "success" (the §3 counter-fact);
  - cmd with _IOC_SIZE > IOCPARM_MAX / bogus direction bits → ENOTTY/EINVAL;
  - daemon SIGSTOP'd mid-request → ETIMEDOUT within daemon_timeout
    (proves §7), caller thread unwinds, no wedge;
  - kill -9 daemon mid-request → mount-dead semantics per existing paths.
- Regression: pjdfstest quick battery green after kldload (per AGENTS).

## 9. Upstream checklist

1. reviews.freebsd.org FIRST — search existing reviews + bugs.freebsd.org
   for FUSE_IOCTL/ENOTTY/ioctl passthrough; dedup before writing (runbook
   P5 rule; also check git log of sys/fs/fuse for WIP branches).
2. Align byte-for-byte with Linux `fs/fuse/ioctl.c` restricted path and
   the existing fuse_kernel.h definitions (:518, :433-440) — no ABI changes.
3. Include: patch + test methodology + the deadlock note (§5) + deadline-cap
   dependency (§7, our patch is a candidate companion PR — P5 track).
4. man4 fusefs(4): document the ioctl passthrough + negotiation.
5. Text per opensource-contribution skill: evidence-first, no AI-slop;
   PR target github.com/freebsd/freebsd-src or reviews.freebsd.org.

## 10. Evidence index

- Recon: `tmp/p4/ioctl.md` (verdict, structs, fuser plumbing, kernel),
  `tmp/p4/gate.md` (ENOTTY gate table for the CLI today).
- Kernel: /usr/src/sys/fs/fuse/fuse_vnops.c:201,1309,1318-1343 (TODO :1340,
  LSEEK precedent :1321-1335, vn_lock :1331) · fuse_kernel.h:518,433-440 ·
  fuse_ipc.c:411+ (deadline-cap site).
- fuser fork: `overlay/files/fuser-vendored/src/{lib.rs:923-940,
  request.rs:425-443, reply.rs:609, ll/request.rs:1822-1826,
  ll/fuse_abi.rs:155, ll/reply.rs:256-275}`.
- tools: `fs/bcachefs_ioctl.rs` (cmd table :53-93, structs :732-802) ·
  `fs/init/chardev.rs:71-144` · `src/wrappers/accounting.rs:36-91`.
