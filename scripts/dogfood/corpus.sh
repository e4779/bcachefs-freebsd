#!/bin/sh
# corpus.sh — deterministic, self-verifiable corpus for the dogfood engine (Ф2).
#
# Content invariant: content(file) == sha256("<relpath>||<epoch>") tiled — the
# 32-byte digest repeated and truncated to the file size. Zero stored hashes:
# verification recomputes the digest from (relpath, epoch) and compares.
#
# usage: corpus.sh gen|verify|epoch-bump <root> [epoch]
#   gen         create/refresh the corpus under <root> (writes .epoch)
#   verify      walk <root>; every file must match plan+invariant (0=ok, 1=drift)
#   epoch-bump  rewrite all content with epoch+1 (or [epoch]) — mass-rewrite churn
#
# Profiles (dirs under <root>), sizes mix 4k/64k/1M/64M (+2G big files full-only):
#   torrent/ — many small files + a few huge ones
#   library/ — deep & wide trees (d/i/d/ij/d/ijk/f files)
#   farm/    — farm/src/f* + 5 hardlinks each in farm/lk/; nlink==6 on verify
#   db/      — log files built through append/truncate/overwrite cycles (every
#              write stays digest-tiled, so mutation never breaks the invariant)
#
# env: CORPUS_SIZE=full|small     small ≈ 1.6-2 GiB (dry-run), default full
#      CORPUS_PROFILE=a,b,...     subset, default torrent,library,farm,db
#      CORPUS_SUBSET=N            verify only first N files per profile (0=all)
#      CORPUS_DB_ROUNDS=N         db mutation rounds during gen (default 3)
# exit: 0 ok | 1 drift/missing | 2 usage/environment error
set -u
MODE=${1:?usage: corpus.sh gen|verify|epoch-bump <root> [epoch]}
ROOT=${2:?corpus root}
EPOCH_ARG=${3:-}
PY=$(command -v python3) || { echo "corpus: python3 required" >&2; exit 2; }

case "$MODE" in
  gen|verify|epoch-bump) ;;
  *) echo "corpus: unknown mode $MODE" >&2; exit 2 ;;
esac
if [ "$MODE" != gen ] && [ ! -d "$ROOT" ]; then
  echo "corpus: root $ROOT missing" >&2; exit 1
fi
exec "$PY" - "$MODE" "$ROOT" "$EPOCH_ARG" <<'PYEOF'
import hashlib, os, random, sys, time

mode, root, epoch_arg = sys.argv[1], sys.argv[2], sys.argv[3]
size_mode = os.environ.get("CORPUS_SIZE", "full")
profiles = [p for p in os.environ.get("CORPUS_PROFILE", "torrent,library,farm,db").split(",") if p]
subset = int(os.environ.get("CORPUS_SUBSET", "0"))
db_rounds = int(os.environ.get("CORPUS_DB_ROUNDS", "3"))

K, CH, MB = 1024, 4096, 1024 * 1024
BLK = 32

def plan():
    """Single source of truth: [(relpath, size, profile)] — pure function of
    (CORPUS_SIZE, CORPUS_PROFILE), same enumeration in gen and verify."""
    small = size_mode == "small"
    files = []
    if "torrent" in profiles:
        n = 600 if small else 6000
        for i in range(n):
            files.append((f"torrent/t{i:05d}", (CH, 64 * K, MB)[i % 3], "torrent"))
        for j in range(2 if small else 4):
            files.append((f"torrent/big{j:02d}", 64 * MB if small else 2 * 1024 * MB, "torrent"))
    if "library" in profiles:
        a, per = (3, 12) if small else (4, 16)
        cyc = (CH, 64 * K, MB, 64 * K, CH)
        k = 0
        for i1 in range(a):
            for i2 in range(a):
                for i3 in range(a):
                    d = f"library/d{i1}/d{i1}{i2}/d{i1}{i2}{i3}"
                    for _ in range(per):
                        files.append((f"{d}/f{k:05d}", cyc[k % 5], "library")); k += 1
        for j in range(4 if small else 16):
            files.append((f"library/top{j:02d}", 64 * MB, "library"))
    if "farm" in profiles:
        for i in range(120 if small else 500):
            files.append((f"farm/src/f{i:05d}", MB, "farm"))
    if "db" in profiles:
        n, s = (20, 32 * MB) if small else (64, 64 * MB)
        for i in range(n):
            files.append((f"db/log{i:03d}", s, "db"))
    return files

def digest(rel, epoch):
    return hashlib.sha256(f"{rel}||{epoch}".encode()).digest()

def write_file(path, rel, epoch, sz):
    dig = digest(rel, epoch)
    buf = dig * (4 * MB // BLK)                     # 4 MiB tiled buffer
    with open(path, "wb") as f:                     # truncates in place: hardlinks keep nlink
        left = sz
        while left > 0:
            n = min(left, len(buf)); f.write(buf[:n]); left -= n
        os.fsync(f.fileno())

def db_mutate(root, rel, epoch, sz):
    """append/truncate/overwrite cycles — all writes digest-tiled, sizes and
    offsets 32-byte aligned, so the content invariant survives every step."""
    dig = digest(rel, epoch)
    path = os.path.join(root, rel)
    rng = random.Random(rel + "|" + str(epoch))
    step = MB // BLK
    with open(path, "r+b") as f:
        for _ in range(db_rounds):
            f.truncate(sz * 3 // 4)                 # shrink (multiple of 32)
            f.seek(sz * 3 // 4)                     # NB: truncate() does NOT move the position
            while f.tell() < sz:                     # re-extend by appending
                f.write((dig * step)[: min(MB, sz - f.tell())])
            for _ in range(8):                       # in-place overwrites (same content)
                off = rng.randrange(0, sz // CH - 1) * CH
                f.seek(off); f.write(dig * (CH // BLK))
        os.fsync(f.fileno())
        f.truncate(sz)

def read_epoch():
    p = os.path.join(root, ".epoch")
    return int(open(p).read().strip()) if os.path.exists(p) else 1

def cmd_gen(epoch):
    files = plan()
    dirs = {os.path.dirname(r) for r, _, _ in files} | {"farm/lk"}
    for d in sorted(dirs):
        os.makedirs(os.path.join(root, d), exist_ok=True)
    t0, tot = time.time(), 0
    cnt = {}
    for i, (rel, sz, p) in enumerate(files):
        write_file(os.path.join(root, rel), rel, epoch, sz)
        tot += sz; cnt[p] = cnt.get(p, 0) + 1
        if (i + 1) % 500 == 0:
            print(f"  gen {i+1}/{len(files)} ({tot/MB:.0f} MiB)", flush=True)
    if "farm" in profiles:
        for rel, sz, p in files:
            if p != "farm":
                continue
            for k in range(5):
                lp = os.path.join(root, f"farm/lk/l{rel.split('f')[-1]}_{k}")
                if not os.path.lexists(lp):
                    os.link(os.path.join(root, rel), lp)
    if "db" in profiles:
        for rel, sz, p in files:
            if p == "db":
                db_mutate(root, rel, epoch, sz)
    open(os.path.join(root, ".epoch"), "w").write(f"{epoch}\n")
    dt = time.time() - t0
    print(f"gen: {len(files)} files, {tot/MB:.0f} MiB, epoch={epoch}, {dt:.1f}s ({tot/MB/max(dt,0.001):.0f} MiB/s)")
    for p in sorted(cnt):
        print(f"  {p}: {cnt[p]} files")

def verify_file(path, rel, epoch, sz):
    dig = digest(rel, epoch)
    if os.stat(path).st_size != sz:
        return f"size {os.stat(path).st_size} != {sz}"
    with open(path, "rb") as f:
        off = 0
        while True:
            b = f.read(4 * MB)
            if not b:
                break
            exp = (dig * (len(b) // BLK + 1))[: len(b)]
            if b != exp:
                return f"content@{off}"
            off += len(b)
    return None

def cmd_verify(epoch):
    files = plan()
    plan_set = {r for r, _, _ in files}
    for r, _, p in files:                           # farm links are plan members too
        if p == "farm":
            for k in range(5):
                plan_set.add(f"farm/lk/l{r.split('f')[-1]}_{k}")
    by_profile = {}
    for rel, sz, p in files:
        by_profile.setdefault(p, []).append((rel, sz))
    drift, ok, checked = [], 0, 0
    t0 = time.time()
    for p in sorted(by_profile):
        sel = by_profile[p] if subset == 0 else by_profile[p][:subset]
        for rel, sz in sel:
            path = os.path.join(root, rel)
            if not os.path.exists(path):
                drift.append(f"MISSING {rel}"); continue
            err = verify_file(path, rel, epoch, sz)
            if err:
                drift.append(f"CHANGED {rel} ({err})")
            else:
                ok += 1
                if p == "farm":
                    nl = os.stat(path).st_nlink
                    if nl != 6:
                        drift.append(f"NLINK {rel} nlink={nl} != 6")
            checked += 1
    if subset == 0:  # only a full walk may judge extras (partials elsewhere are chaos state)
        actual = []
        for dp, dn, fn in os.walk(root):
            dn.sort()
            if dp == root:
                fn = [x for x in fn if x != ".epoch"]
            for f in sorted(fn):
                actual.append(os.path.relpath(os.path.join(dp, f), root))
        extras = [r for r in actual if r not in plan_set]
        for r in extras[:20]:
            drift.append(f"UNEXPECTED {r}")
        if len(extras) > 20:
            drift.append(f"UNEXPECTED ... and {len(extras) - 20} more")
    print(f"verify: checked={checked} ok={ok} drift={len(drift)} epoch={epoch} "
          f"subset={'all' if subset == 0 else subset} ({time.time() - t0:.1f}s)")
    for d in drift[:20]:
        print("  " + d)
    sys.exit(1 if drift else 0)

def cmd_bump(new_epoch):
    files = plan()
    t0, tot = time.time(), 0
    for rel, sz, p in files:  # farm srcs rewritten in place → links follow the same inode
        write_file(os.path.join(root, rel), rel, new_epoch, sz)
        tot += sz
    open(os.path.join(root, ".epoch"), "w").write(f"{new_epoch}\n")
    print(f"epoch-bump: {len(files)} files, {tot/MB:.0f} MiB rewritten, epoch={new_epoch}, {time.time() - t0:.1f}s")

if mode == "gen":
    cmd_gen(int(epoch_arg) if epoch_arg else read_epoch())
elif mode == "verify":
    cmd_verify(int(epoch_arg) if epoch_arg else read_epoch())
elif mode == "epoch-bump":
    cmd_bump(int(epoch_arg) if epoch_arg else read_epoch() + 1)
PYEOF
