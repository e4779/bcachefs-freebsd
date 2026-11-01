# 05a — Rust-layer FreeBSD compat (Run 19d errors)

Date: 2026-11-02 · agent: rust-compat (synchronous, no builds — patches authored
against the pristine clone via /tmp diff workflow, dry-run verified only)
Scope: the 72 non-fusemount errors of Run 19d's 93 (src/commands/fusemount.rs
= 21 errors is fuser-porter's). Full extraction: tmp/build-19.log lines
23086+.

## Root cause classes

1. **rustix Linux-only APIs** (cfg linux_kernel): xattr fns, statx/StatxFlags/
   XattrFlags, rustix::mount, AtFlags::NO_AUTOMOUNT, OFlags::NOATIME,
   RenameFlags::RENAME_* (fusemount only), Errno::NODATA (FreeBSD has
   ENOATTR=87), syncfs.
2. **libc Linux-only items**: `Ioctl` type, `sysinfo`, `statx`, MS_* flags,
   SYS_fsopen/fsconfig/fsmount/move_mount, MOVE_MOUNT_F_EMPTY_PATH, O_NOATIME,
   XATTR_REPLACE (fusemount).
3. **libc ABI diffs**: mount(2) is 4-arg on FreeBSD (type, dir, flags, data);
   mode_t is u16 (Linux u32) → the u32&u16 mismatched-type errors.
4. **std Linux-only**: std::os::linux::net abstract sockets (plymouth).

## Design rule (mirrors c_src/freebsd_compat.h)

The crate keeps **Linux vocabulary internally** — MS_* flag numbers, ioctl
request as c_ulong, xattr names with "user." prefixes — and translates to the
native BSD API **only at the syscall edge** in cfg(freebsd) arms. Parsing,
masking and tests stay byte-identical to upstream.

## Mechanism

- `overlay/files/src/bsd_compat.rs` — new module (self-contained):
  - Linux MS_* consts (uapi values); `ms_to_mnt()` → MNT_* (drops DIRSYNC/
    MANDLOCK/RELATIME/STRICTATIME/NODIRATIME — no BSD equivalent, commented);
  - `IoctlRequest` = c_ulong (libc crate names it `Ioctl` only on Linux);
  - xattr→extattr(2) helpers: "user.X" ↔ EXTATTR_NAMESPACE_USER with the
    prefix stripped; anything else (bcachefs uses namespace-less
    "bcachefs.*" names) stored verbatim in the user namespace — extattr
    names accept dots. `llistxattr` rewrites the BSD length-prefixed list
    format to NUL-separated "user."-prefixed names so copy_fs's
    bch_xattr_type::from_name parsing is unchanged.
  - Patch 010 declares the module (cfg-gated) in src/bcachefs.rs.
- Patches 011–019 per-file, each with inline BSD-decision comments.

## Per-file approach (error count → fix)

| File | n | Approach |
|---|---|---|
| wrappers/ioctl.rs, bdev.rs, handle.rs | 6+2+4 | `libc::Ioctl` → `IoctlRequest` alias (011) |
| commands/attr.rs | 6 | imports split by cfg; mount detection statx(MNT_ID) → fstat/fstatat st_dev compare (same boundary); set/get/removexattr → bsd_compat extattr; ENOATTR≡NODATA arm (012) |
| plymouth.rs | 2 | connect() → ENOENT on BSD (no abstract sockets, no plymouth port); callers already treat Err as "no splash" (013) |
| commands/format_util.rs | 2 | sysinfo(2) → sysctlbyname("hw.physmem") (014) |
| commands/migrate.rs | 1 | drop O_NOATIME custom flag (per-mount MNT_NOATIME on BSD; hint only) (015) |
| fs_context.rs | 17 | MS_* shim imports; SYS_*-and-MOVE_MOUNT placeholders = -1/0 with comment: syscall(-1)→ENOSYS→FsContext::open() takes its designed Ok(None) fallback → callers use mount(2). Zero behavior invention (016) |
| commands/mount.rs | 19 | MS_* shim; mount(2) call gets a 4-arg MNT_* arm (ms_to_mnt). Kernel bcachefs can't exist on FreeBSD → honest runtime ENODEV; fuse path is the real route (017) |
| copy_fs.rs | 11 | llistxattr/lgetxattr → bsd_compat; mode_t u16 casts (as u32, no-ops on Linux); OFlags::NOATIME dropped; syncfs→fsync (no fd-scoped sync on BSD) (018) |
| util.rs | 2 | path_subvol → None on BSD (STATX_SUBVOL is a bcachefs statx(2) patch; no call, no extension); subvol_root() therefore errs "not on a bcachefs filesystem" — honest limitation under FUSE (019) |
| commands/fusemount.rs | 21 | NOT MINE — fuser-porter (T09) |

## bch_bindgen panic (Run 19c) — diagnosis

NOT a bindgen/stub issue. build.rs:286:
`pkg_config::probe_library("libkeyutils").expect("Failed to find keyutils lib")`
— pkg-config couldn't find libkeyutils.pc (FreeBSD has no port; overlay ships a
stub .a/.h). Run 19d supplied a keyutils .pc and bch_bindgen then compiled
cleanly (log: "Compiling bch_bindgen" with no following error; the 19d
failure set is purely the bin crate's 93 E-errors). The keyutils_wrapper.h
bindgen pass ran fine against our stub — its prototypes (add_key, request_key,
keyctl_search, KEY_SPEC_*) are present in overlay/files/include/keyutils.h, so
nothing further needed there. The stub .pc approach stands; orchestrator
should keep PKG_CONFIG_PATH pointing at it in future runs.

## Verification done (builds are the orchestrator's slot)

- `patch -p1 --dry-run` of all 10 patches against a pristine tree: clean.
- Each patched hunk re-read after generation; token-scan confirms no
  residual `libc::MS_`/`libc::SYS_` references in mount.rs/fs_context.rs.
- libc 0.2.186 FreeBSD module probed for every symbol used:
  mount(4-arg)/nmount/unmount/MNT_*/extattr_*/sysctlbyname/ENOATTR/
  EXTATTR_NAMESPACE_USER ✓ (MNT_NODEV missing from libc crate — defined
  locally in bsd_compat with the sys/mount.h value).
- rustix 1.1.4 probed: Errno::NOATTR exists (libc backend); fstatat/fstat/
  fsync exist on FreeBSD backend.

## Open risks / next-build watchlist

1. **rustix::fs::Dir/FileType on FreeBSD** — compiles (no 19d errors), but
   entry.file_type() mapping is untested at runtime.
2. **attr.rs fstatat st_dev mount detection** — st_dev granularity on
   FreeBSD (ufsdev vs dev_t of underlying) may differ from Linux stx_mnt_id;
   verify the propagate walk stops at the right boundary on a test FS.
3. **extattr on FUSE** — FreeBSD fuse(4) does not implement extattr vnops:
   set/get-file-option will report EOPNOTSUPP (read path treats it as
   "unset", which is correct). If per-file options must work under FUSE,
   they need a bcachefs ioctl route instead — future work, not a regression.
4. **copy_fs ACLs** — POSIX ACLs don't surface as system.posix_acl_* xattrs
   on BSD; acl_from_xattr path is dead code there (matches "skip silently").
5. **mount_legacy BSD arm** — ENODEV expected for kernel mounts; make sure
   the fuse path intercepts before mount() ever gets there (fuser-porter's
   fusemount.rs gate).
6. **fs_context placeholders** — if any caller skips FsContext::open() and
   calls move_mount/fsmount directly, syscall(-1) → ENOSYS errors surface;
   mount.rs goes through open() (checked), fusemount.rs is fuser-porter's.
