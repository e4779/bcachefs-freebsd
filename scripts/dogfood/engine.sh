#!/bin/sh
# engine.sh — Ф2 dogfood phase rotator.
#
# ONE rotation = corpus-gen → fio write+verify → churn → read-phase
#   (corpus-verify + fio randread) → dbench → fsx → chaos drill (one of a/b/c),
#   ALL inside a SINGLE stage-session.sh invocation (wrapper supplies mount,
#   canary, RSS sampling, umount, fsck verdict). Telemetry per rotation:
#   daemon op census (from BCACHEFS_FUSE_LOG, debug level) + churn TSV
#   percentiles (p50/p95/p99 per op class) → <session>/engine.log.
#   Any verify failure ⇒ nonzero exit.
#
# usage (outer — starts the wrapped rotation):
#   engine.sh <image> <mnt> [--mode dry|full] [--drill a|b|c|none] [--skip p,p,...]
#     <image>  file image or raw device (staging zvol) — absolute paths
#     --mode   dry: ~1.6-2G corpus, 60 s jobs, one drill (default: full)
#     --drill  chaos drill for this rotation (default b)
#     --skip   comma list from: corpus-gen,fio-write,churn,read-phase,dbench,fsx,chaos
# inner (invoked BY stage-session.sh — do not call by hand):
#   engine.sh _inner <mnt> <mode> <drill> <skip-csv>
# env: FIO_IODEPTH  fio queue depth, ≤16 (fuser max_background=16), default 4
# exit: 0 rotation green | 1 failure (newest tmp/stage-sessions/*/engine.log has details)
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DOGFOOD=$ROOT/scripts/dogfood

if [ "${1:-}" = _inner ]; then
  # ======================= inner: runs INSIDE the wrapper ==================
  MNT=${2:?mnt}; MODE=${3:-dry}; DRILL=${4:-b}; SKIP=${5:-none}
  : "${STAGE_WORK:?inner must run under stage-session.sh (no STAGE_WORK)}"
  SESS=$(ls -1d "$ROOT"/tmp/stage-sessions/*/ | tail -1); SESS=${SESS%/}
  ELOG=$SESS/engine.log
  TSV=$SESS/churn.tsv
  WORK=$STAGE_WORK
  CORPUS=$WORK/corpus
  RLIMIT=$ROOT/scripts/rlimit-run.sh

  if [ "$MODE" = dry ]; then
    CSIZE=small;  WRT=60;  RRT=60;  NRFILES=8;  FILESIZE=64m
    CR=8;  CB=50;  CMAX=90;   DBN=4; DBT=60;   FSXOPS=20000;  FSXFLEN=67108864
  else
    CSIZE=full;   WRT=300; RRT=180; NRFILES=64; FILESIZE=256m
    CR=40; CB=100; CMAX=300;  DBN=8; DBT=120;  FSXOPS=200000; FSXFLEN=268435456
  fi
  IODEPTH=${FIO_IODEPTH:-4}
export CORPUS_SIZE=$CSIZE

  log() { echo "$(date -u +%H:%M:%SZ) $*" >> "$ELOG"; echo "engine: $*" >&2; }
  fail() { log "FAIL: $*"; log "ENGINE RESULT: FAIL ($*)"; exit 1; }
  skip() { case ",$SKIP," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
  free_mb() { echo $(( $(sysctl -n vm.stats.vm.v_free_count) * 4096 / 1048576 )); }
  memgate() {  # ≥1 GiB free before heavy phases (AGENTS resource rule), wait ≤600 s
    i=0; while [ "$(free_mb)" -lt 1024 ] && [ $i -lt 60 ]; do sleep 10; i=$((i+1)); done
    [ "$(free_mb)" -ge 1024 ] || log "WARN: free mem $(free_mb) MiB after 600s — proceeding (rctl caps on)"
  }
  pct() {  # pct <op> — p50/p95/p99 ms of one op class from the churn TSV
    f=$SESS/.pct.$1
    awk -F'\t' -v op="$1" '$2==op {print $3}' "$TSV" | sort -n > "$f"
    n=$(wc -l < "$f" | tr -d ' ')
    [ "$n" -gt 0 ] || { log "  $1: n=0"; rm -f "$f"; return; }
    p() { awk -v i=$(( (n * $1 + 99) / 100 )) -v n=$n 'i>n{i=n} NR==i{print; exit}' "$f"; }
    log "  $1: n=$n p50=$(p 50)ms p95=$(p 95)ms p99=$(p 99)ms"
    rm -f "$f"
  }

  log "ENGINE start mode=$MODE drill=${DRILL} skip=$SKIP"
  log "sess=$SESS work=$WORK iodepth=$IODEPTH"
  log "fs: $(df -h "$MNT" | tail -1)"

  # ---- phase 1: corpus ---------------------------------------------------
  if ! skip corpus-gen; then
    memgate; t0=$(date +%s)
    CORPUS_SIZE=$CSIZE sh "$DOGFOOD/corpus.sh" gen "$CORPUS" 1 >> "$ELOG" 2>&1 \
      || fail "corpus gen"
    log "phase corpus-gen ok ($(( $(date +%s) - t0 ))s)"
  else log "skip corpus-gen (corpus state as-is)"; fi

  # ---- phase 2: fio raw write + inline verify ----------------------------
  if ! skip fio-write; then
    memgate; mkdir -p "$WORK/fio"
    sed -e "s|__DIR__|$WORK/fio|" -e "s|__RUNTIME__|$WRT|" -e "s|__IODEPTH__|$IODEPTH|" \
        -e "s|__NRFILES__|$NRFILES|" -e "s|__FILESIZE__|$FILESIZE|" \
        "$DOGFOOD/fio-jobs/write-verify.fio" > "$SESS/write-verify.run.fio"
    log "phase fio-write-verify: runtime=${WRT}s iodepth=$IODEPTH nrfiles=$NRFILES x $FILESIZE"
    t0=$(date +%s)
    "$RLIMIT" 3000 fio "$SESS/write-verify.run.fio" > "$SESS/fio-write.log" 2>&1 \
      || { grep -E 'err=|verify|ERROR|FAIL' "$SESS/fio-write.log" | tail -10 >> "$ELOG"; fail "fio write-verify"; }
    grep -E 'err= [1-9]|verify.*error|VERIFY' "$SESS/fio-write.log" | head -5 >> "$ELOG" || true
    log "phase fio-write-verify ok ($(( $(date +%s) - t0 ))s): $(grep -oE 'WRITE: [^|]*bw=[^ ]*' "$SESS/fio-write.log" | tail -1)"
  fi

  # ---- phase 3: churn (metadata storm) -----------------------------------
  if ! skip churn; then
    memgate
    log "phase churn: rounds=$CR batch=$CB (walkroot=$CORPUS/library)"
    t0=$(date +%s)
    CHURN_MAX_SECONDS=$CMAX "$RLIMIT" 1024 sh "$DOGFOOD/churn.sh" "$WORK" "$CR" "$CB" "$TSV" \
      > "$SESS/churn.out" 2>&1 || { tail -5 "$SESS/churn.out" >> "$ELOG"; fail "churn"; }
    log "phase churn ok ($(( $(date +%s) - t0 ))s) — per-op percentiles:"
    for op in create rename hardlink unlink readdir-deep stat; do pct $op; done
  fi

  # ---- phase 4: read-phase (corpus verify + fio randread) ----------------
  if ! skip read-phase; then
    memgate; t0=$(date +%s)
    CORPUS_SIZE=$CSIZE sh "$DOGFOOD/corpus.sh" verify "$CORPUS" >> "$ELOG" 2>&1 \
      || fail "corpus verify (read-phase)"
    log "phase corpus-verify ok ($(( $(date +%s) - t0 ))s)"
    sed -e "s|__DIR__|$WORK/fio|" -e "s|__RUNTIME__|$RRT|" -e "s|__IODEPTH__|$IODEPTH|" \
        -e "s|__NRFILES__|$NRFILES|" -e "s|__FILESIZE__|$FILESIZE|" \
        "$DOGFOOD/fio-jobs/read.fio" > "$SESS/read.run.fio"
    t0=$(date +%s)
    "$RLIMIT" 3000 fio "$SESS/read.run.fio" > "$SESS/fio-read.log" 2>&1 \
      || { tail -10 "$SESS/fio-read.log" >> "$ELOG"; fail "fio read"; }
    log "phase fio-read ok ($(( $(date +%s) - t0 ))s): $(grep -oE 'READ: [^|]*bw=[^ ]*' "$SESS/fio-read.log" | tail -1)"
  fi

  # ---- phase 5: dbench (SMB profile — xattr findings!) -------------------
  if ! skip dbench; then
    memgate; mkdir -p "$WORK/dbench"
    log "phase dbench: clients=$DBN t=${DBT}s (xattr/flock through FUSE = dogfood finding territory)"
    t0=$(date +%s)
    "$RLIMIT" 1024 dbench "$DBN" -c /usr/local/share/dbench/client.txt -t "$DBT" -D "$WORK/dbench" \
      > "$SESS/dbench.log" 2>&1 || { tail -10 "$SESS/dbench.log" >> "$ELOG"; fail "dbench rc"; }
    xatt=$(grep -icE 'xattr|extattr|not supported|operation not supported' "$SESS/dbench.log" || true)
    [ "${xatt:-0}" -gt 0 ] && log "FINDING: dbench xattr/extattr mentions: $xatt — $(grep -iE 'xattr|extattr|not supported' "$SESS/dbench.log" | head -3)"
    log "phase dbench ok ($(( $(date +%s) - t0 ))s): $(grep -E 'Throughput|ops/s' "$SESS/dbench.log" | tail -2 | tr '\n' ' ')"
  fi

  # ---- phase 6: fsx (single big file, adversarial, seed logged) ----------
  if ! skip fsx; then
    memgate; mkdir -p "$WORK/fsx"
    SEED=$(( $(date +%s) % 1000000 ))
    cat > "$SESS/fsx.toml" <<TOML
flen = $FSXFLEN
[opsize]
max = 65536
min = 0
align = 1
[weights]
close_open = 1
read = 10
write = 10
mapread = 10
mapwrite = 10
invalidate = 1
truncate = 1
fsync = 1
fdatasync = 1
TOML
    log "phase fsx: ops=$FSXOPS seed=$SEED flen=$(( FSXFLEN / 1048576 ))MiB"
    t0=$(date +%s)
    "$RLIMIT" 1024 fsx -N "$FSXOPS" -S "$SEED" -f "$SESS/fsx.toml" -P "$WORK/fsx" \
      "$WORK/fsx/fsx.test" > "$SESS/fsx.log" 2>&1 \
      || { tail -15 "$SESS/fsx.log" >> "$ELOG"; fail "fsx (seed=$SEED)"; }
    log "phase fsx ok ($(( $(date +%s) - t0 ))s, seed=$SEED)"
  fi

  # ---- phase 7: chaos drill (one per rotation) ---------------------------
  if [ "$DRILL" != none ] && ! skip chaos; then
    memgate
    sh "$DOGFOOD/chaos.sh" "$MNT" "$SESS" "$DRILL" "$CORPUS" >> "$ELOG" 2>&1 \
      || fail "chaos drill $DRILL"
  else log "skip chaos (drill=$DRILL)"; fi

  # ---- telemetry: daemon op census ---------------------------------------
  for f in daemon.log daemon-recovery.log; do
    [ -f "$SESS/$f" ] && sed -n -E 's/^\[[^]]+\] FUSE\([0-9 ]+\) ino 0x[0-9a-f]+ ([A-Za-z_]+).*/\1/p' "$SESS/$f"
  done | sort | uniq -c | sort -rn > "$SESS/op-census.log"
  n_types=$(wc -l < "$SESS/op-census.log" | tr -d ' ')
  n_ops=$(awk '{s+=$1} END{print s+0}' "$SESS/op-census.log")
  log "op census: $n_types types, $n_ops ops"
  head -12 "$SESS/op-census.log" >> "$ELOG"

  log "ENGINE RESULT: PASS (mode=$MODE drill=$DRILL)"
  exit 0
fi

# ============================ outer: start the rotation ======================
IMAGE=${1:?usage: engine.sh <image> <mnt> [options]}; shift
MNT=${1:?mountpoint}; shift
MODE=full; DRILL=b; SKIP=none
while [ $# -gt 0 ]; do
  case $1 in
    --mode)  MODE=${2:?}; shift 2 ;;
    --drill) DRILL=${2:?}; shift 2 ;;
    --skip)  SKIP=${2:?}; shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "engine: unknown arg $1" >&2; exit 64 ;;
  esac
done
case "$IMAGE" in /*) ;; *) IMAGE=$PWD/$IMAGE ;; esac
case "$MNT" in /*) ;; *) MNT=$PWD/$MNT ;; esac
mkdir -p "$MNT"

echo "engine: rotation start image=$IMAGE mnt=$MNT mode=$MODE drill=$DRILL skip=$SKIP"
STAGE_LOG_LEVEL=debug sh "$ROOT/scripts/stage-session.sh" "$IMAGE" "$MNT" \
  sh "$0" _inner "$MNT" "$MODE" "$DRILL" "$SKIP"
rc=$?
SESS=$(ls -1d "$ROOT"/tmp/stage-sessions/*/ | tail -1); SESS=${SESS%/}
echo "engine: session $SESS"
cat "$SESS/verdict" 2>/dev/null
if [ $rc -ne 0 ]; then
  echo "engine: ROTATION FAILED (wrapper exit $rc) — see $SESS/engine.log"
  tail -20 "$SESS/engine.log" 2>/dev/null
  exit 1
fi
if ! grep -q 'ENGINE RESULT: PASS' "$SESS/engine.log" 2>/dev/null; then
  echo "engine: ROTATION FAILED (engine inner did not pass) — see $SESS/engine.log"
  tail -20 "$SESS/engine.log" 2>/dev/null
  exit 1
fi
echo "engine: ROTATION GREEN — report: $SESS/engine.log"
exit 0
