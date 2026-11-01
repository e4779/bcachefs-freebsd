# overlay/ — FreeBSD build overlay for tools/ (bcachefs-tools @ d48ba1a)

The clone in `tools/` is pristine upstream (gitignored). All FreeBSD
changes live here and are applied onto the clone by `apply.sh` — the
clone is never hand-edited, so `rm -rf tools && git clone && ./overlay/apply.sh`
reproduces the build tree exactly.

## Mechanism

```
overlay/files/**    -> copied into tools/ verbatim (cp, overwrite)
overlay/patches/*   -> applied inside tools/ with patch -p1
```

```sh
./overlay/apply.sh          # idempotent: re-copy + skip applied patches
```

## Why files vs patches

New headers and stub .c files are *copies* (they shadow/add paths that the
Linux build takes from glibc/UAPI); modifications of upstream files are
*patches*, so the diff against upstream stays reviewable.

## Inventory (first pass, more added as the build iterates)

| Path in tools/ | Kind | Purpose |
|---|---|---|
| `c_src/freebsd_compat.h` | file | pwritev2/preadv2→pwritev/preadv, FALLOC_FL_*, fallocate→F_FRESP, bch_gettid()=thr_self(2), MAP_NORESERVE=0; force-included from autoconf.h (patch 002) |
| `c_src/freebsd_compat.c` | file | bch_fallocate_freebsd() |
| `c_src/keyutils_stub.c` + `include/keyutils.h` | file | libkeyutils stub (no FreeBSD port; keyring only used for encrypted-FS key mgmt — returns -ENOSYS) |
| `c_src/libaio_stub.c` + `include/libaio.h` | file | Linux AIO stub: io_setup()→-ENOSYS routes blkdev.c to its own sync preadv/pwritev fallback (fops_list[1]) |
| `include/sys/sysmacros.h` | file | glibc-only header; makedev lives in sys/types.h on BSD |
| `include/asm/types.h`, `include/linux/types.h`, `const.h`, `limits.h`, `errno.h` | file | glibc UAPI headers absent on FreeBSD; keystone pair everything else chains through |
| `include/linux/fs.h` | file | BLKGETSIZE64/BLKSSZGET→DIOCGMEDIASIZE/DIOCGSECTORSIZE, BLKPBSZGET/BLKROTATIONAL constants |
| `include/linux/fiemap.h`, `ktime.h`, `capability.h`, `numa.h`, `dynamic_debug.h`, … | file | Linux UAPI/glibc headers the sources include but never use on the userspace path — presence stubs |
| `include/linux/futex.h` | file | FUNCTIONAL shim, not a stub: futex() → _umtx_op(2); timeout ADDRESS goes in uaddr2 with the struct SIZE in uaddr (backwards = kernel copyins from address 24 → EFAULT, shrinker thread busy-spin); FUTEX_WAIT_BITSET → _umtx_time{UMTX_ABSTIME,CLOCK_MONOTONIC} |
| `patches/001-makefile-freebsd.patch` | patch | drop libkeyutils from PKGCONFIG_LIBS; udevdir fallback; drop -lrt -lkeyutils -laio -ldl |
| `patches/002-autoconf-freebsd-compat.patch` | patch | force-include freebsd_compat.h from c_src/autoconf.h (C and bindgen see the same mapping) |
| `patches/007-blkdev-alloca-freebsd.patch` | patch | blkdev.c: alloca.h is glibc-only; FreeBSD takes alloca(3) from stdlib.h |
| `patches/008-gettid-thr-self-freebsd.patch` | patch | kthread.c/sched.c: syscall(SYS_gettid) → bch_gettid() (thr_self(2); pid feeds only backtraces/debug) |
| `patches/009-shrinker-listhead-freebsd.patch` | patch | shrinker.c: CDS_LIST_HEAD — sidesteps the LIST_HEAD(name,type) redefinition from sys/queue.h |
| `patches/010-cargo-fuser-libfuse3-freebsd.patch` | patch | Cargo.toml: fuser dep +libfuse3 feature — mounting via fusefs-libs3/mount_fusefs(8); FreeBSD has no fusermount(8), so fuser's pure-rust backend can't mount |
| `patches/011-fusemount-single-thread-freebsd.patch` | patch | fusemount.rs: n_threads=1, clone_fd=false on FreeBSD — fuser rejects n_threads!=1 off Linux; FUSE_DEV_IOC_CLONE fd cloning is Linux-only |
| `patches/012-fusemount-fuseblk-freebsd.patch` | patch | fusemount.rs: FreeBSD has no fuseblk — device mounts go through fuser's libfuse3 path like image mounts; O_EXCL claims on ALL devices (no kernel claim); MS_* flag shim; getmntinfo() replaces /proc/self/mountinfo |

## Runtime semantics notes

- **libaio**: blkdev.c's aio fops are first in `fops_list`, but `aio_init()`
  calls `io_setup()` and falls back to the sync fops on `-ENOSYS` — upstream
  already designed the fallback; the stub just selects it. All IO is
  synchronous preadv/pwritev (acceptable for format/fsck tools; documented
  in docs/notes/04a-build-c.md).
- **keyutils**: `bch2_add_key()` dies on failure — only reachable for
  encrypted filesystems, which the test-FS plan does not use.

| `src/bsd_compat.rs` | file | Rust-side FreeBSD shims: Linux MS_* flag values + ms_to_mnt(), IoctlRequest alias, xattr(2)→extattr(2) helpers (user-namespace mapping; list-format rewrite) |
| `patches/020-rust-bsd-compat-module.patch` | patch | declare mod bsd_compat in src/bcachefs.rs (cfg freebsd) |
| `patches/021-wrappers-ioctl-request-type.patch` | patch | wrappers: libc::Ioctl → IoctlRequest alias (libc crate has no Ioctl on FreeBSD) |
| `patches/022-attr-freebsd-xattr.patch` | patch | attr.rs: xattr→extattr, statx(MNT_ID)→fstat/st_dev mount check, ENOATTR arm |
| `patches/023-plymouth-freebsd-stub.patch` | patch | plymouth connect() → ENOENT (no abstract sockets / no plymouth on FreeBSD) |
| `patches/024-format-util-physmem.patch` | patch | sysinfo(2) → sysctl hw.physmem |
| `patches/025-migrate-noatime.patch` | patch | drop Linux-only O_NOATIME open flag |
| `patches/026-fs-context-freebsd.patch` | patch | fs_context: MS_* shims; SYS_fs*/MOVE_MOUNT placeholders — syscall(-1)→ENOSYS → designed Ok(None) fallback |
| `patches/027-mount-legacy-freebsd.patch` | patch | mount.rs: MS_* shims; 4-arg MNT_* mount(2) arm (kernel mount → honest ENODEV) |
| `patches/028-copy-fs-freebsd.patch` | patch | copy_fs: llistxattr/lgetxattr→extattr, mode_t u16 casts, no O_NOATIME, syncfs→fsync |
| `patches/029-util-statx-freebsd.patch` | patch | util.rs path_subvol → None (STATX_SUBVOL is a Linux statx extension) |
| `patches/030-attr-rustix-statat.patch` | patch | attr.rs: rustix::fs::fstatat → statat (fstatat is only a doc alias in rustix 1.1.4) |
| `patches/031-fusemount-xattr-replace-freebsd.patch` | patch | fusemount.rs: XATTR_REPLACE from bsd_compat (libc crate: linux_like only) |
| `patches/032-fusemount-mode-width-freebsd.patch` | patch | fusemount.rs: mode_t u16 — from_raw_mode shadow-cast, S_IFMT/S_IFDIR widened |
| `patches/033-fusemount-rename-flags-freebsd.patch` | patch | fusemount.rs: RENAME_WHITEOUT/EXCHANGE/NOREPLACE are fuser Linux-only cfg arms |
| `patches/034-fusemount-statfs-cchar-freebsd.patch` | patch | fusemount.rs: getmntinfo name() closure takes &[c_char] ([i8;N] fields) |
| `patches/035-migrate-openopts-shadow.patch` | patch | migrate.rs: rename local OpenOptions fs_opts→open_opts (shadowed the bch_opts param) |
| `patches/036-mount-dataptr-type-freebsd.patch` | patch | mount.rs: data_ptr gets explicit *const c_void (FreeBSD arm casts only) |
| `patches/037-fs-context-syscall-cint.patch` | patch | fs_context.rs: SYS_* placeholders c_long→c_int (FreeBSD libc::syscall takes c_int) |
| `patches/038-mount-unsafe-wrap.patch` | patch | mount.rs: wrap syscall/mount call in unsafe (Rust 2024 extern rules) |
| `patches/039-build-link-freebsd-libs.patch` | patch | build-link.rs: skip -lkeyutils/-laio on FreeBSD (stubbed in libbcachefs.a) |
| `patches/040-stdout-linkname-freebsd.patch` | patch | bcachefs.rs: extern stdout → FreeBSD __stdoutp link_name |
| `patches/041-page-h-freebsd-pagemask.patch` | patch | include/linux/page.h: #undef+force Linux PAGE_SIZE/PAGE_MASK/PAGE_SHIFT — machine/param.h (via sys/user.h) predefines PAGE_MASK=(PAGE_SIZE-1), the INVERSE offset mask; virt_to_page/offset_in_page swapped roles, 64-bit addr truncated into 32-bit bvec bv_offset → preadv/pwritev EFAULT on every IO |
| `patches/042-bdev-fstat-freebsd.patch` | patch | src/wrappers/bdev.rs: fd_metadata() /proc/self/fd/N → libc::fstat(2) (no /proc on FreeBSD); is_block_device() S_IFMT check; st_rdev/st_size/st_blksize fields |
| `patches/043-btree-cache-mmap-anon-fd-freebsd.patch` | patch | fs/btree/cache.c: userspace aux_data mmap passes fd 0 to MAP_ANONYMOUS — Linux ignores fd, FreeBSD requires -1 (EINVAL); the NULL aux_data surfaced as ENOMEM_fs_btree_cache_init on every fs start |