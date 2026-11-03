#!/bin/sh
# churn.sh — metadata storm for the dogfood engine (Ф2): N rounds of
#   create / rename (incl. rename-over-existing) / hardlink / unlink /
#   readdir-deep / stat-walk, every op individually timed (ms) into a TSV
#   (round<TAB>op<TAB>dt_ms) for p50/p95/p99 per op class.
#
# usage: churn.sh <work-dir> <rounds> <batch> <tsv-file>
# env: CHURN_MAX_SECONDS=S   stop STARTING new rounds after S wall-seconds (0=off)
#      CHURN_TOLERANT=1      absorb per-op I/O errors (chaos drills kill the daemon
#                            under the storm — those errors are the point, not bugs;
#                            50 consecutive errors still abort as "tolerated")
#      CHURN_WALK_ROOT=DIR   deep tree for readdir/stat walks (default: corpus library)
# files land under <work-dir>/churn/ ; tree growth is bounded (r-files of the
# last 2 rounds + current c/h files survive any single round).
# exit: 0 ok or tolerated-abort | 1 hard failure (non-tolerant mode)
set -u
WORK=${1:?work dir}; ROUNDS=${2:?rounds}; BATCH=${3:?batch}; TSV=${4:?tsv out}
PY=$(command -v python3) || { echo "churn: python3 required" >&2; exit 1; }
exec "$PY" - "$WORK" "$ROUNDS" "$BATCH" "$TSV" <<'PYEOF'
import os, sys, time

work, rounds, batch, tsv = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
max_s = float(os.environ.get("CHURN_MAX_SECONDS", "0"))
tolerant = os.environ.get("CHURN_TOLERANT", "") == "1"
churn = os.path.join(work, "churn")
os.makedirs(churn, exist_ok=True)
libroot = os.environ.get("CHURN_WALK_ROOT") or os.path.join(work, "corpus", "library")
if not os.path.isdir(libroot):
    libroot = churn

out = open(tsv, "w", buffering=1)
rnd = 0
err_streak = 0

def timed(op, fn):
    """time one op; on OSError record op-err line, honor tolerance"""
    global err_streak
    t0 = time.perf_counter()
    try:
        r = fn()
        out.write(f"{rnd}\t{op}\t{(time.perf_counter() - t0) * 1000:.3f}\n")
        err_streak = 0
        return r
    except OSError as e:
        out.write(f"{rnd}\t{op}-err\t{(time.perf_counter() - t0) * 1000:.3f}\n")
        print(f"churn: op {op} error: {e}", file=sys.stderr, flush=True)
        if not tolerant:
            out.close(); sys.exit(1)
        err_streak += 1
        if err_streak >= 50:
            print("churn: tolerated-abort (50 consecutive op errors)", flush=True)
            out.close(); sys.exit(0)
        return None

def walk_deep(root):
    n, stack = 0, [root]
    while stack:
        d = stack.pop()
        try:
            with os.scandir(d) as it:
                for e in it:
                    n += 1
                    try:
                        if e.is_dir(follow_symlinks=False):
                            stack.append(e.path)
                    except OSError:
                        pass
        except OSError:
            continue
    return n

libfiles = []
def refresh_lib():
    global libfiles
    libfiles = []
    for dp, dn, fn in os.walk(libroot):
        dn.sort()
        for f in sorted(fn):
            libfiles.append(os.path.join(dp, f))
            if len(libfiles) >= 5000:
                return

print(f"churn: rounds={rounds} batch={batch} walkroot={libroot} tolerant={tolerant} max_s={max_s}", flush=True)
t_start = time.perf_counter()
done = 0
for rnd in range(rounds):
    if max_s and (time.perf_counter() - t_start) > max_s:
        print(f"churn: time cap hit before round {rnd}", flush=True)
        break
    names = [f"c{rnd}_{i}" for i in range(batch)]
    for n in names:
        timed("create", lambda n=n: open(os.path.join(churn, n), "wb").write(b"x" * 4096))
    for i, n in enumerate(names):
        tgt = f"r{rnd}_{i}"
        if rnd % 3 == 0 and rnd > 0 and i % 2 == 0:
            tgt = f"r{rnd - 1}_{i}"     # rename OVER an existing file (replace)
        timed("rename", lambda n=n, t=tgt: os.rename(os.path.join(churn, n), os.path.join(churn, t)))
    for i in range(batch // 2):
        src = f"r{rnd}_{i}"
        if not os.path.lexists(os.path.join(churn, src)):
            src = f"c{rnd}_{i}"
        if os.path.lexists(os.path.join(churn, src)):
            timed("hardlink", lambda s=src, i=i: os.link(os.path.join(churn, s), os.path.join(churn, f"h{rnd}_{i}")))
    for i in range(batch // 2):
        hp = os.path.join(churn, f"h{rnd}_{i}")
        if os.path.lexists(hp):
            timed("unlink", lambda p=hp: os.unlink(p))
    if rnd >= 2:
        for i in range(batch):
            p = os.path.join(churn, f"r{rnd - 2}_{i}")
            if os.path.lexists(p):
                timed("unlink", lambda p=p: os.unlink(p))
    timed("readdir-deep", lambda: walk_deep(libroot))
    refresh_lib()
    if libfiles:
        for k in range(batch * 10):
            timed("stat", lambda p=libfiles[(k * 7 + rnd) % len(libfiles)]: os.lstat(p))
    done = rnd + 1
    out.flush()

out.close()
elapsed = time.perf_counter() - t_start
print(f"churn: done rounds={done} elapsed={elapsed:.1f}s tsv={tsv}", flush=True)
sys.exit(0)
PYEOF
