# 11a — pjdfstest on the FUSE mount: bisect + root cause (T11)

Agent: bisect-fuse. Status: **root cause found, fix patched (045), awaiting
orchestrator rebuild + rerun.** T11-final (errno-round) below: 045 held,
the 15 errno-family failures root-caused and patched (046/047), project
pjdfstest config added — same gate: orchestrator rebuilds and reruns.

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

## T11 final — the 25 failures of the G2 full run (errno-round)

G2 full run (/tmp/pjdf-final.log): 365 passed / 25 failed / 125 skipped /
515 total, fsck clean after. 10 of the 25 are `chflags::*` — inherent to
the FUSE protocol (no chflags request exists, so flags are neither
enforced nor reported and ctime around chflags is unverifiable). They are
listed as expected failures in the project config
**bench/pjdfstest-bcachefs.toml** (`doas pjdfstest -c bench/pjdfstest-bcachefs.toml
-p /tmp/bch-mnt`; no file_flags feature — with it the chflags family fails
even on ZFS). Note the runner's semantics: a test in expected_failures
that *passes* is reported FAILED ("PASSED UNEXPECTEDLY") — the list is a
contract, not a suppression.

The other 15 were two real bugs, both in the daemon, both patched.

### 046 — rmdir/rename of a non-empty directory answered EDESTADDRREQ

7× `rmdir::eexist_enotempty_non_empty_dir::*` and 7×
`rename::eexist_enotempty_to_non_empty::*` failed because the daemon
replied errno 39: Linux's ENOTEMPTY. `bch_err()` passed `e.errno()` to
fuser's `Errno::from_i32()` raw — but the errcode table roots every
BCH_ERR_* in an errno numbered by linux-raw-sys (fs/errcode.rs's class
module; `errno()` walks the chain to that root), while fuser's Errno is
the raw *host* errno. The kernels disagree past errno 34: ENOTEMPTY is
39 on Linux, 66 on FreeBSD — so the kernel read 39 = EDESTADDRREQ,
which matches neither EEXIST nor ENOTEMPTY.

The FS itself was already right: namei.rs `unlink_trans()`/`rename_trans()`
call `dirent::empty_dir_trans()`, which returns
BCH_ERR_ENOTEMPTY_dir_not_empty — only the numbering at the daemon
boundary was wrong. Of the errnos the FS can emit, exactly two roots
diverge (verified against fs/errcode_types.rs): ENOTEMPTY 39→66 and
EOPNOTSUPP 95→45; everything else (EEXIST 17, EINVAL 22, ENOSPC 28,
…) coincides, and plain errnos from the C build already carry host
numbering. Patch 046 translates those two by chain root in `bch_err()`
and routes `err()` (the C-return-value twin) through it. No cfg: on
Linux the table is the identity. POSIX allows EEXIST or ENOTEMPTY here;
we answer ENOTEMPTY. (The EEXIST at fusemount.rs:1342 is the
Linux-only RENAME_NOREPLACE arm — unrelated.)

### 047 — rename(dir, path-inside-it) returned Ok(())

`rename::einval_parent_from_subdir_to` renamed d1 into d1/d2 and
succeeded — the bi_depth wrapping in rename_trans() is the only guard,
i.e. silent-corruption territory. The Linux VFS rejects the prefix case
in may_move() before the FS is called; FreeBSD's fusefs(4) forwards the
request, so the daemon must check. Patch 047 walks dst_dir's dirent
backpointers (bi_dir/bi_dir_offset — a directory has exactly one name)
up toward the root and answers EINVAL on meeting the renamed directory.
This mirrors namei.rs's own `inum_to_path_up()`/`parent_inum()` walk
(root / no-backpointer termination, subvol crossing via
bi_parent_subvol). O(depth), capped at 512 (PATH_MAX/2 — deeper is a
corrupt backpointer loop, which must not spin the daemon; past the cap
rename_trans()'s own checks govern). EINVAL precedes the target checks,
as may_move() orders it. Unlocked reads are safe: the daemon is
single-threaded on FreeBSD (patch 011).

Both patches are uncfg'd generic POSIX semantics. NOT re-run: the
orchestrator rebuilds (045+046+047), re-formats /tmp/bch-file.img,
reruns with the project config. Expectation: 380 passed / 10 expected
failures / 125 skipped / 0 failed, fsck clean.

## Dirty-ro эксперимент — PASS (детали)


## Dirty-ro: ФИНАЛ (2026-11-03, чистый прогон)

**Phase 1 (настоящий краш):** демон-ребёнок (ppid=1 после setsid) убит kill -9 посреди шторма на 417,597 файлах. Мёртвый fuse-маунт корректно БЛОКИРУЕТ IO (ядерная защита — записи в голый каталог не просачиваются); umount -f освобождает. Урок пидоспекции: убивать надо ребёнка с ppid=1, не родителя-mount.

**Phase 2 (ro-backend):** mdconfig -o ro → демон ЗАПРОСИЛ read-write для replay → получил EROFS → **честный отказ без единой попытки записи**. Truss: 0 pwrites. dump-super: БИТ-БИТ.

**Вердикт Q1-эксперимента: PASS** (канал записи через journal-replay на ro-backend закрыт доказуемо).

**Тихая смерть РАЗРЕШЕНА:** воспроизведения нет (180с/732k файлов — жив; контролируемый килл — по плану). Первоначальная интерпретация — артефакт kill-команд с кривым паттерном pid. Единичная аномалия "Failed to send FUSE reply: EINVAL" — класс прерванных запросов, логируется, нефатально.

**Логирование (056) работает в бою:** BCACHEFS_FUSE_LOG захватывает ops-трейс и последние слова демона (readdir на момент килла).

# ОКНО: ro-маунт живого пула — 2026-11-03/04, ВЫПОЛНЕНО

**Вердикт: УСПЕХ.** Прод-пул (1.1T NVMe nda0p3 + 3.6T HDD ada1, формат 1.39, External UUID 0ec475a1-…) примонтирован read-only на FreeBSD нашей сборкой; 27/27 sha256 манифеста совпали; НОЛЬ записей в пул от нас (supers неизменны с момента чистого shutdown VM; ada1 — ни одного I/O; Clean:1 сохранён). Прод восстановлен через 45с.

**Хронология:** стоп 6 потребителей + poolmount → чистый poweroff гостя (ssh) → Clean:1 на обоих членах → ro-маунт (fd-проверка truss: все mount-time open O_RDONLY; fusefs-модуль потерян ребутом — kldload) → визит (обход + sha256) → umount -f по kill-протоколу (см. ниже) → bit-compare → rollback.

**Активированный kill-протокол (ложная, но правильная тревога):** iostat показал 80 МБ/с записей на nda0 + procstat вскрыл fd 10 с rw-флагом на nda0p3 у демона → немедленный umount по протоколу. Разбор: записи шли в zroot (p2, системные), seq суперблоков пула НЕ ДВИНУЛСЯ с shutdown-значения — визит чист. Ложность тревоги не отменяет правильности реакции.

**Находки (в работу):**
1. fd 10 (rw на nda0p3) — ленивый путь открывает устройство RW даже на ro-маунте; записей не было, но гарантия дырява → патч-кандидат 057: форсировать O_RDONLY на ВСЕХ открытиях при ro.
2. Baseline протокола брать ПОСЛЕ shutdown VM (наш pre-shutdown baseline создал ложное DIFFERENT).
3. Часы гостя убегают вперёд ~6ч20м (Nov 4 03:44 при хостовом Nov 3 21:25) — заметка владельцу.
4. fusefs-модуль не переживает ребут — добавить kldload в протокол шагом 0.

## fd 10 — root cause и фикс (2026-11-04, патч 057)

**Механизм (по /var/log/window-truss.log, pid 8662, mount-кластер):**

| fd | flags | кто | судьба |
|---|---|---|---|
| 6, 7 | O_RDONLY\|O_DIRECT | scan_sbs → read_super_silent (nochanges) | живут в демоне |
| 4, 5 | O_RDONLY\|O_CLOEXEC | lock_devices | до destroy |
| **10, 11** | **O_RDWR\|O_EXCL\|O_DIRECT** | **bch2_read_super ← bch2_fs_open ← Fs::open (fusemount)** | **весь маунт** |

Это НЕ ленивый open — он в mount-кластере truss (строки 1308/1317), procstat просто вскрыл его позже. `read_super_and_backups` (fs/sb/io.rs) добавляет `BLK_OPEN_WRITE` всем вызывающим без `nochanges`; маунт `-o fuse,ro` ставит `read_only=1`, но НЕ `nochanges` → персистентные sb-fd демона на ОБОИХ членах пула — rw на всё время маунта. O_EXCL в флагах подтверждает путь: geom-провайдеры на FreeBSD — S_IFCHR, fusemount не распознал блочность → ветка Fuse (не Fuseblk с noexcl) → mode = READ|WRITE|EXCL.

**Почему апстрим так делает:** rw-open при чтении суперблоков позволяет recovery и `rewrite_primary_super` чинить суперблок даже под `-o ro`; на Linux ro-гейт ядра под маунтом держит защиту. В порту fd сам и есть write-capability — структурная дыра в протоколе «ноль write-способности на живом пуле». Побочное подтверждение: dirty-ro фаза 2 — демон «requested read-write, got EROFS» — это ровно этот fd, открывшийся rw на ro-backend и честно упёршийся в backend, а не в нас.

**Фикс (057):** fs/sb/io.rs — `if !opts.nochanges_or_default() && !opts.read_only_or_default() { mode |= BLK_OPEN_WRITE }` + инвариант комментарием. Аудит всех вызывающих read_super: единственная комбинация read_only=1 && nochanges=0 — это ro-маунт (mount/fusemount/degraded; все остальные read_only-вызовы — fsck/list/dump/super/journal_rewind/kill_btree/kvdb/migrate — ставят nochanges тоже). Поведение меняется только у ro-маунта: открытие O_RDONLY|O_EXCL|O_DIRECT; `rewrite_primary_super` под ro больше не сработает (и не должен — визит требует bit-exact); EACCES-fallback остаётся для rw.

**Попутно починено:** overlay/apply.sh — `mkdir -p "$(dirname "$$dest")"` раскрывал `$$` в PID; копирование files/ работало только потому, что целевые каталоги уже существовали в клоне. На свежем клоне (worktree-верификация 057) cp падал. `$$dest` → `$dest`.

**Верификация 057 (без сборки):** свежий shared-clone tools @ d48ba1a в worktree, полный forward-цеп 001→057 (50 патчей = 50 штампов), hunk лёг на 1377. Поведенческая проверка ro-открытия — на следующей тестовой ФС (fsck-roundtrip), не на живом пуле.

