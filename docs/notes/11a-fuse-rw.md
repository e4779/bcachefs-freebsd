# 11a — pjdfstest on the FUSE mount: bisect + root cause (T11)

Agent: bisect-fuse. Status: **root cause found, fix patched (045), awaiting
orchestrator rebuild + rerun.**

## Symptom

pjdfstest 0.2.2 (Rust runner) panics with exit 101 on the bcachefs FUSE mount;
buffered stdout is lost (the runner aggregates it), stderr empty, backtrace
frames `<unknown>` (stripped binary). On ZFS the same binary: 515 total,
390 passed / 125 skipped (root), 0 failed.

## Bisect table (per-group, root, on /tmp/bch-mnt)

Non-root runs die earlier: EACCES on the runner's temp dir (FUSE mount owner
is root; only the mounter may walk it) — the runner MUST run under doas.

| group | exit | verdict |
|---|---|---|
| all 20 groups (rename nfsv4acl chmod link chflags mknod unlink open chown symlink rmdir utimensat mkfifo mkdir truncate enotdir_component eexist_file_exists ftruncate posix_fallocate unlink_err) | 101 | identical failure in shared setup, before any test line is printed |

Every group dies at the runner's per-test setup: mkdir tempdir → mkdir subdir →
fchmodat(subdir, 0755) → ENOENT → panic. Group-level bisection saturates;
the killer is the setup gate itself.

## Evidence chain

1. truss of `pjdfstest -p /tmp/bch-mnt mkdir`: mkdir ok → **fchmodat ERR#2
   ENOENT** → fstatat ok but `mode=-rwxr-xr-x` (**regular file**, not dir) →
   openat(O_DIRECTORY) ENOTDIR → runner unlinks it **as a file** (succeeds!)
   → panic exit 101.
2. Shell repro (see below) reproduces both ENOENT and the type morph; a control
   mkdir without chmod stays a directory — **chmod is the trigger**.
3. ktrace(GENIO) on the daemon pid: daemon stderr is /dev/null in daemon mode,
   but eprintln per-op trace + raw /dev/fuse protocol both land in the ktrace.
   Daemon log: mkdir(mode=0o40777) correct, chmod's LOOKUP ok, then SETATTR.
   Protocol decode: SETATTR request `valid=FATTR_MODE, mode=0o755` (perm bits
   only); reply `error=0` with attr `mode=0o100755` — S_IFREG|0755. Kernel
   immediately sends FUSE_FORGET(node, nlookup=2) and fchmodat returns ENOENT.
4. On-disk proof: after unmount, fsck reports `dirent_d_type_wrong`; a fresh
   mount stats the victim as Regular File (not kernel cache). Orphaned dirs of
   earlier runs show up as lost+found `inode_unreachable` (the 2147483659
   from the first panic; 3746/3748/3754 from this bisect).

## Root cause

`fuse_setattr()` (fusemount.rs) did `inode_u.bi_mode = mode` with FUSE_SETATTR's
mode, which per protocol carries chmod(2)'s **permission bits only**. The file
type bits (S_IFMT) were overwritten to zero:

- `mode_to_filetype()` maps a typeless mode to RegularFile → attrs reply flips
  the vnode type;
- FreeBSD fusefs(4) `fuse_internal_setattr` (fuse_internal.c:939-941) returns
  **ENOENT** when a server flips a live vnode's type mid-setattr — the chmod
  error;
- the transaction already committed, so the inode is corrupted **on disk**:
  a directory with a regular-file mode (fsck: dirent_d_type_wrong; children
  unreachable → lost+found), and post-mortem lookups legitimately see a file
  (ENOTDIR for O_DIRECTORY, unlink-as-file succeeds).

One bug explains every symptom: the runner-wide setup panic, the ENOENT, the
type morph, the fsck orphans.

## Minimal repro (pre-fix)

```sh
doas sh -c 'cd /tmp/bch-mnt && umask 0
mkdir d && mkdir d/c && chmod 0755 d/c'   # chmod: d/c: No such file or directory
doas stat -f '%HT %Sp' /tmp/bch-mnt/d/c   # Regular File -rwxr-xr-x
```

## Fix

Patch **045-fuse-setattr-preserve-file-type-freebsd.patch** (applied):
merge permission bits, keep the type:

```rust
inode_u.bi_mode = (inode_u.bi_mode & !0o7777) | (mode & 0o7777);
```

(!0o7777 on u16 == S_IFMT.) Not cfg'd: the bug is protocol-level, OS-agnostic.

## Not yet reached (masked by the setup gate)

Group bisection could not see past the shared setup, so these remain untested
until the rerun: mknod/symlink EOPNOTSUPP paths, xattr/extattr (fusefs(4)
lacks extattr vnops), rename RENAME_* flags (patch 033), flock/fcntl,
posix_fallocate, utimensat. Cleared: the forget/evict path — the observed
FUSE_FORGET was the kernel reacting to our type flip, not a lifetime bug.

## Secondary observations (no action)

- `TTL = Duration::MAX`: infinite entry/attr validity means the kernel never
  re-fetches; any future attrs bug persists until vnode recycling. Consider a
  finite TTL later (bench first).
- Daemon stderr → /dev/null (since 8d2ea5aef1); the per-op eprintln trace is
  excellent but needs `--foreground` (hardcoded off) or ktrace(GENIO) to see.
  ktrace(GENIO) on the daemon pid is a zero-rebuild wire tap — remember to
  detach (`ktrace -c -p PID`); a left-on trace grew to 4.5 GB in ~10 min.
