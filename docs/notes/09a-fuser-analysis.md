# 09a — fuser fork analysis for T09 (koverstreet/fuser, branch destroy-before-reply)

Date: 2026-11-02 · analyst: fuser-analyst (synchronous, read-only; no builds, no fs mounts)
Scope: de-risk T09 (port Kent's fuser fork to FreeBSD) BEFORE the C build finishes.
All `file:line` refer to the fork @ 8819589 unless prefixed `up/master` or `tools/`.

## 1. Clones & refs (Q1)

- Fork cloned to `/tmp/fuser-fork`, branch `destroy-before-reply` @ **88195892644d78da0f90c84ad52fbe916cbd1886** ("Handle FUSE_SYNCFS", 2026-10-03, Kent Overstreet).
- Upstream remote `up` = cberner/fuser master @ `c0420fc` (shallow fetch, depth 400).
- **merge-base** `16e20c12522cd628917526fc27b689de32753e00`; fork is **3 ahead / 80 behind**. Fork declares `version = "0.17.0"` (Cargo.toml:17); upstream master is 0.18.0-dev.
- bcachefs-tools pins EXACTLY this fork: tools/Cargo.toml:66-68 `[patch.crates-io] fuser = { git = "https://github.com/koverstreet/fuser", branch = "destroy-before-reply" }`, dep at :44 `fuser = { version = "0.17", optional = true }`; tools/Cargo.lock:575-577 resolves to git rev `8819589…` (== fork HEAD).
- The comment above the patch (tools/Cargo.toml:63-65): *"fuser replies to FUSE_DESTROY before calling destroy(), so a fuseblk unmount returns while the filesystem is still shutting down. Fixed on this branch (from v0.17.0); sent upstream - drop this once a release has it."*

## 2. Q2 — libfuse feature: INTACT (and restructured vs 0.16)

- Cargo.toml:57-59: `libfuse = []`, `libfuse2 = ["libfuse"]`, `libfuse3 = ["libfuse"]`. Default features = none.
- build.rs picks a `fuser_mount_impl` cfg:
  - build.rs:10-16: `linux|freebsd|dragonfly|openbsd|netbsd` **without** the libfuse feature → **pure-rust** (FreeBSD default is pure-rust, NOT libfuse!).
  - build.rs:28-31: `libfuse3` → pkg-config `fuse3` ≥3.0.0 → `libfuse3`; `libfuse2` → `fuse` ≥2.6.0.
  - build.rs:33-44: other targets fall back fuse3 → fuse2 → panic.
- Module split src/mnt/mod.rs:10-15: `fuse3.rs`+`fuse3_sys.rs` compile only under libfuse3; `fuse_pure.rs` only under pure-rust. `Mount::new` dispatches (mod.rs:99-127).
- libfuse3 is used for **mount plumbing only**: fuse3.rs:37-70 — `fuse_session_new` with an **empty** `fuse_lowlevel_ops` (fuse3.rs:45-51), `fuse_session_mount` (:61), `fuse_session_fd` → dup → `DevFuse` (:65-70). fuser runs its **own** event loop on that fd. lib.rs:4 states exactly this design.
- On FreeBSD this is the fuse-ufs recipe: pkg-config fuse3 → `/usr/local/lib/libfuse3.so` (port **fusefs-libs3**) → `/sbin/mount_fusefs`. hlab probe (2026-11-02): fusefs-libs3-3.18.3 installed, `fuse3.pc` = 3.18.3, `/sbin/mount_fusefs` present, no fusermount/fusermount3 binaries. ✅

## 3. Q3 — What Kent changed (3 commits, all protocol/dispatch level)

1. **8fc86cf "Call destroy() before replying to FUSE_DESTROY"** — the branch's namesake.
   - Rationale (commit msg): the kernel sends FUSE_DESTROY **synchronously** (fuseblk, virtiofs): `fuse_conn_destroy()` waits for the reply. Upstream fuser replied first and ran `destroy()` only when the holder dropped → umount(2) returned while destroy() was still running; a subsequent fsck/remount raced the shutdown. libfuse's `do_destroy()` calls destroy, then replies.
   - Mechanics: `FilesystemHolder.fs: Option<FS>` → `RwLock<Option<FS>>` (session.rs:85-93); requests take the **read** lock while dispatched (request.rs:100-101); `destroy()` takes the **write** lock → waits out in-flight requests, idempotent via `.take()` (session.rs:95-99, Drop :102-107). Event loop on FUSE_DESTROY: `self.filesystem.destroy(); req.reply::<ReplyEmpty>(); return` (session.rs:533-544). `run()` end still destroys sessions that ended without FUSE_DESTROY (session.rs:327-329).
   - Naming inversion: the branch name describes the FIX; the bcachefs-tools comment describes upstream's BUG. Same thing.
   - **Upstream status: NOT merged** as of up/master c0420fc — upstream session.rs:583-585 still replies first (`req.reply…ok(); return`). Upstream instead added "Wait for the session to end when dropping BackgroundSession" (bceb68b) + test `drop_waits_for_destroy` (up/master session.rs:1562-1588) — a different, weaker mitigation. Keep the fork.
2. **792855c "Reply with a node ID that isn't attr.ino"** — adds `ReplyEntry::entry_with_nodeid()` / `ReplyCreate::created_with_nodeid()` (reply.rs:223-246, 449-478; ll/reply.rs:203-213). Node ID ≠ inode number — needed because bcachefs subvolumes share inode numbers (fusemount.rs:29-33 "NodeMap"). Additive API.
3. **8819589 "Handle FUSE_SYNCFS"** — opcode 50 (fuse_abi.rs:164), `fuse_syncfs_in` (:735-740), parse (ll/request.rs:1866-1870), `Filesystem::syncfs()` defaulting ENOSYS (lib.rs:776-783). Upstream independently landed "Add Filesystem::syncfs()" (2c3b9b5); bcachefs implements it (fusemount.rs:1536).

All three commits touch request dispatch/session only — **100% mount-impl-agnostic**.

## 4. Q4 — Linux-isms in the mount path (exact port surface)

### 4a. WITH libfuse3 ON (the FreeBSD recipe) — what remains inside fuser

| Linux-ism | Where | Status on FreeBSD w/ libfuse3 |
|---|---|---|
| `/dev/fuse` open (`DevFuse::PATH`) | dev_fuse.rs:25-33 | not used for mount; fd comes from `fuse_session_fd` (fuse3.rs:65) ✅ |
| fusermount/fusermount3 spawn, `_FUSE_COMMFD`, SCM_RIGHTS | fuse_pure.rs:47-49, 143, 158-183, 186-235, 257 | pure-rust module, **compiled out** (mnt/mod.rs:15 gates on pure-rust) ✅ |
| direct mount(2) fstype "fuse", `fd=,rootmode=,user_id=,group_id=` opts, `MS_*` | fuse_pure.rs:379-505 (format! :407, flags :426-448, mount :477-487) | compiled out ✅ |
| `umount2(MNT_DETACH)` / `unmount(MNT_FORCE)` | fuse_pure.rs:129-139 | compiled out ✅ |
| `FUSE_DEV_IOC_CLONE` fd clone | channel.rs:59-88 | already `#[cfg(target_os="linux")]` → out ✅ |
| `libc_umount` | mnt/mod.rs:169-190 | has explicit BSD branch (`nix::mount::unmount`, empty flags) ✅ |
| fuse3 umount EPERM→`fuse_session_unmount/destroy` | fuse3.rs:78-92 | `#[cfg(linux)]`; on FreeBSD root, unmount(2) succeeds directly. Note: `fuse_session_destroy` never called on success path → minor C-side leak, harmless |
| option strings (`fsname=`, `subtype=`, `default_permissions`, CUSTOM passthrough) | mount_options.rs:145+ via `with_fuse_args` (mnt/mod.rs:31-56) | go to libfuse3 → mount_fusefs; BSD equivalents exist — **smoke-test** `subtype=bcachefs` (CUSTOM), `dev`/`suid` pushed by bcachefs (fusemount.rs:1824-1828) |
| `/proc`, `/sys` reads | — | **none in src/** ✅ |
| splice syscalls | — | none (only protocol flag constants ll/flags/init_flags.rs:23-26) ✅ |
| **n_threads gate** | **session.rs:261-268** | **`!linux && n_threads != 1` → Err("n_threads != 1 is only supported on Linux")** — TODO comment: "check whether it works on macOS/FreeBSD". THE functional gate; see Q5 |

### 4b. WITHOUT libfuse (pure-rust, the FreeBSD *default* build!) — dead end

- fuse_pure.rs:103-127: BSDs have NO direct-mount path — fuse_pure.rs:114-115 "Other supported Unix targets (such as the BSDs) rely on the setuid mount helper", stub `fuse_mount_sys` returns `Ok(None)` (fuse_pure.rs:499-507) → always `fuse_mount_fusermount` (fuse_pure.rs:257) → needs fusermount3 binary → **absent on FreeBSD** → mount fails at runtime.
- Everything in the table above marked "compiled out" is live here.
- => T09 MUST build fuser with `libfuse3`; the default feature-less build is unusable on FreeBSD.

### 4c. bcachefs-tools side (src/commands/fusemount.rs — port surface independent of fuser)

- :1989-2017 `mount_fuseblk()`: opens `/dev/fuse`, builds `fd=…,rootmode=…,user_id=…,group_id=…,blksize=…,subtype=bcachefs,allow_other,default_permissions`, `rustix::mount::mount(source, mp, "fuseblk", flags, data)` — Linux-only (fstype fuseblk; rustix mount).
- :2024-2034 `fuse_claim()`: the fuseblk mount is what makes the kernel claim the source device exclusively (keeps kernel bcachefs/fsck off our device, EBUSY either direction); :2037-2041 `fuse_unclaim()` = `unmount(DETACH)`.
- :2044-2059 `fuse_serve()`: device mounts = `Session::from_fd(fs, fd, acl, config).spawn()` (fork session.rs:202); image mounts = `fuser::mount2` (:2051).
- :557-564, :1815: mount(8) flag parsing into `MS_NOATIME|MS_STRICTATIME|MS_NODIRATIME|MS_RDONLY`.
- :2207-2221: `config.n_threads = Some(available_parallelism()…min(16))` → **trips fuser's non-Linux gate** (4a last row).
- :1834-1960: transient systemd scope via `dlopen("libsystemd.so.0")` + sd-bus — runtime-guarded by `/run/systemd/system` existence (:1850) → clean no-op on FreeBSD, no patch needed.

## 5. Q5 — Verdict for T09

**(a) YES — use the fork WITH the libfuse3 feature, near-as-is (fuse-ufs recipe, upgraded).**
pkg-config `fuse3` → libfuse3.so from port fusefs-libs3 → mount_fusefs; all pieces already on hlab (fuse3.pc 3.18.3). The crate is *closer* to FreeBSD-ready than fuser 0.16 was for fuse-ufs: build.rs knows freebsd (build.rs:10-16), `libc_umount` has a BSD branch (mnt/mod.rs:169-190), `FUSE_DEV_IOC_CLONE` is already cfg-gated (channel.rs:59). Every API bcachefs-tools uses (Filesystem trait incl. syncfs/destroy, `mount2`, `Session::from_fd`, `spawn`, Config, MountOption, KernelConfig) exists in the fork. Rust 1.98 ≥ MSRV 1.85 (edition 2024). 
**(b) NO bypass — destroy-before-reply is NOT routed through libfuse.** It lives in fuser's own event loop + RwLock holder (session.rs:95-107, 533-544); libfuse3 is called with EMPTY ops only for mount/umount (fuse3.rs:45-51); fuser never calls `fuse_session_loop`. The fork's semantics are identical under any mount impl.

### Required patches
1. **tools/Cargo.toml:44** — `fuser = { version = "0.17", optional = true, features = ["libfuse3"] }` (without it build.rs selects pure-rust on FreeBSD → runtime mount failure). 1 line.
2. **fuser session.rs:263** — lift the non-Linux `n_threads != 1` gate for FreeBSD (channels then share one fd via `Arc<DevFuse>` clones, session.rs:276-291 — the same single-fd model libfuse3's `loop_mt` uses on BSD), or short-term set `n_threads = Some(1)` on BSD in fusemount.rs. 1-5 lines + runtime probe. Metadata throughput is the project's core metric → prefer lifting the gate.
3. **fusemount.rs BSD branch** for `mount_fuseblk`/`fuse_claim`/`fuse_unclaim` (:1989-2041): FreeBSD has no fuseblk. Either (i) route device mounts through fuser `Session::new` (libfuse3/mount_fusefs) and rely on bcachefs's own `lock_devices` for exclusivity, or (ii) `nmount("fusefs", "fd=N,allow_other,default_permissions")` keeping a claim-before-start ordering. ~40-80 lines + MS_*→MNT_* flag mapping ~20 lines.
4. **fusemount.rs:557-564, :1815** — BSD atime/rdonly flag mapping. ~15 lines.

Rough total: fuser crate ≤5 lines; bcachefs-tools ~100-150 lines behind `cfg(target_os)` gates. **T09 risk concentrates in bcachefs's own fuseblk mount path, not in fuser.**

### Smoke-test items (first vn-backed test FS mount)
- mount_fusefs acceptance of `subtype=bcachefs`, `dev`, `suid` options (drop on BSD if rejected);
- `FUSE_EXPORT_SUPPORT` capability negotiation (fusemount.rs:918) — kernel ignores unknown bits;
- FUSE_SYNCFS: FreeBSD fuse(4) may never send it — default ENOSYS is safe;
- concurrent read(2) on one shared /dev/fuse fd with n_threads>1 (gate #2);
- unmount path: fuse3.rs never calls fuse_session_destroy on success — verify no fd lifecycle surprises.

### Disproven-if
- `cargo build --features libfuse3` fails to link libfuse3 on FreeBSD, or mount_fusefs rejects the option set → verdict (a) weakens; first probe = fuser `examples`/simple mount on a vn-backed test FS.
- Concurrent reads on one /dev/fuse fd corrupt/stall on FreeBSD → multi-thread lift reverts to n_threads=1 (big metadata perf cost — would need its own answer).

## Sources
- /tmp/fuser-fork @ 8819589 (clone, branch destroy-before-reply; remotes origin=koverstreet, up=cberner)
- tools/ @ bcachefs-tools clone (Cargo.toml/Cargo.lock fuser pin; src/commands/fusemount.rs)
- hlab probes: `pkg info | rg fuse`, `pkg-config --modversion fuse3`, `which mount_fusefs fusermount3`
- Upstream comparison: `git log up/master..HEAD`, `git show up/master:src/session.rs`
