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
| `include/linux/fiemap.h`, `ktime.h`, `capability.h`, `numa.h`, `dynamic_debug.h`, `futex.h`, … | file | Linux UAPI/glibc headers the sources include but never use on the userspace path — presence stubs |
| `patches/001-makefile-freebsd.patch` | patch | drop libkeyutils from PKGCONFIG_LIBS; udevdir fallback; drop -lrt -lkeyutils -laio -ldl |
| `patches/002-autoconf-freebsd-compat.patch` | patch | force-include freebsd_compat.h from c_src/autoconf.h (C and bindgen see the same mapping) |
| `patches/007-blkdev-alloca-freebsd.patch` | patch | blkdev.c: alloca.h is glibc-only; FreeBSD takes alloca(3) from stdlib.h |
| `patches/008-gettid-thr-self-freebsd.patch` | patch | kthread.c/sched.c: syscall(SYS_gettid) → bch_gettid() (thr_self(2); pid feeds only backtraces/debug) |
| `patches/009-shrinker-listhead-freebsd.patch` | patch | shrinker.c: CDS_LIST_HEAD — sidesteps the LIST_HEAD(name,type) redefinition from sys/queue.h |

## Runtime semantics notes

- **libaio**: blkdev.c's aio fops are first in `fops_list`, but `aio_init()`
  calls `io_setup()` and falls back to the sync fops on `-ENOSYS` — upstream
  already designed the fallback; the stub just selects it. All IO is
  synchronous preadv/pwritev (acceptable for format/fsck tools; documented
  in docs/notes/04a-build-c.md).
- **keyutils**: `bch2_add_key()` dies on failure — only reachable for
  encrypted filesystems, which the test-FS plan does not use.
