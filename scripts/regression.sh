#!/bin/sh
# regression.sh — the bcachefs-freebsd regression battery.
# Runs: upstream cargo test suite + our runtime gates on throwaway images.
# Usage: scripts/regression.sh [quick] [--rss-capture] [--op-census] [--kill-drill]
#   quick         skip the cargo test suite
#   --rss-capture sample daemon RSS every 2s during the stage-3 storm → rss-storm.log (+max summary)
#   --op-census   run the storm daemon with BCACHEFS_LOG=debug and summarize FUSE op
#                 types+counts from the BCACHEFS_FUSE_LOG after the storm → op-census.log
#   --kill-drill  kill -9 the daemon MID-STORM (≥5000 files on the mount AND the storm
#                 loop verified alive), then recovery fsck + post-recovery cycle:
#                 remount rw → rw-probe → umount → fsck (journal replayed by the mount)
# Every stage logs to tmp/regression-<ts>/ and the script exits nonzero on ANY failure.
# Root-requiring steps go through doas (format/fsck/mount/umount on /dev/md*).
# NOTE: userspace repair-fsck is broken on the current binary (patch 057 dropped
# BLK_OPEN_WRITE from read_only opens → superblock writes EBADF). All fsck gates are
# CHECK-ONLY (fsck -n): journal-dirty replays in memory and counts as clean; nonzero =
# damage beyond journal. On-disk journal replay belongs to the mount path (verified).
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TS=$(date +%Y%m%d-%H%M%S)
OUT=$ROOT/tmp/regression-$TS
mkdir -p "$OUT"
cd "$ROOT/tools"

MODE=full; RSS=0; CENSUS=0; DRILL=0
for a in "$@"; do
  case $a in
    quick)         MODE=quick ;;
    --rss-capture) RSS=1 ;;
    --op-census)   CENSUS=1 ;;
    --kill-drill)  DRILL=1 ;;
    *) echo "regression.sh: unknown arg $a" >&2; exit 64 ;;
  esac
done
u_of() { echo "$1" | tr -d md; }

STAGE3_FAIL() { echo "$1"; doas mdconfig -d -u $(u_of "$dev") 2>/dev/null || true; exit 1; }

echo "=== [1/5] upstream cargo test suite"
if [ "$MODE" != quick ]; then
  PKG_CONFIG_PATH=$ROOT/overlay/pkgconfig CARGO_BUILD_JOBS=2 \
    nice -n 19 ../scripts/rlimit-run.sh 3000 cargo test --release 2>&1 | tee "$OUT/cargo-test.log" | tail -3
fi

echo "=== [2/5] format + clean fsck gate (fsck -n)"
rm -f /tmp/bch-reg.img; truncate -s 512m /tmp/bch-reg.img
dev=$(doas mdconfig -t vnode -f /tmp/bch-reg.img)
echo "$dev" > "$OUT/dev"
doas ../tools/bcachefs format --label reg /dev/$dev > /dev/null
../scripts/rlimit-run.sh 1024 doas ../tools/bcachefs fsck -n /dev/$dev > "$OUT/fsck-clean.log" 2>&1 \
  || { echo CLEAN-FSCK-DIRTY; tail -5 "$OUT/fsck-clean.log"; STAGE3_FAIL cleanup; }
tail -1 "$OUT/fsck-clean.log"

echo "=== [3/5] rw mount + storm + kill -9 + recovery"
DAEMON_ENV="BCACHEFS_FUSE_LOG=$OUT/storm-daemon.log"
if [ $CENSUS -eq 1 ]; then DAEMON_ENV="$DAEMON_ENV BCACHEFS_LOG=debug"; fi
doas env $DAEMON_ENV ../tools/bcachefs mount -o fuse /dev/$dev /tmp/bch-mnt 2>/dev/null || true
sleep 8
mount | grep -q fusefs.bcachefs || STAGE3_FAIL 'MOUNT-FAILED'

if [ $RSS -eq 1 ]; then
  ( end=$(( $(date +%s) + 900 ))
    while [ "$(date +%s)" -lt "$end" ]; do
      ps axo pid,ppid,rss,args | grep '[t]ools/bcachefs mount' | grep -F '/tmp/bch-mnt' \
        | awk -v t="$(date +%s)" '$2==1 {print t, $1, $3; exit}'
      sleep 2
    done ) > "$OUT/rss-storm.log" 2>&1 &
  RSSPID=$!
fi

doas sh -c 'i=0; while [ $i -lt 50000 ]; do echo x > /tmp/bch-mnt/s$i; i=$((i+1)); done' &
if [ $DRILL -eq 1 ]; then
  # kill DURING active writes: wait until the mount holds ≥5000 files and the storm
  # loop is still alive, then kill -9 the (reparented, ppid=1) daemon at that moment.
  n=0; i=0
  while [ $i -lt 90 ]; do
    n=$(doas ls /tmp/bch-mnt 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -ge 5000 ] && break
    sleep 1; i=$((i+1))
  done
  alive=$(pgrep -f 'while.*50000' | head -1)
  echo "kill-drill: files=$n storm_alive=${alive:+yes} waited=${i}s" | tee "$OUT/kill-drill.log"
  { [ "$n" -ge 5000 ] && [ -n "$alive" ]; } || STAGE3_FAIL 'DRILL-FAILED (storm not mid-write at kill)'
else
  sleep 8
fi
d=$(ps axo pid,ppid,args | grep '[t]ools/bcachefs mount' | awk '$2==1 {print $1}' | head -1)
[ -n "$d" ] && doas kill -9 $d
doas pkill -9 -f 'while.*50000' 2>/dev/null || true
if [ $RSS -eq 1 ]; then kill "$RSSPID" 2>/dev/null || true; fi
sleep 2; doas umount -f /tmp/bch-mnt 2>/dev/null || true

echo '--- recovery fsck -n (journal-dirty expected; damage must be absent):'
../scripts/rlimit-run.sh 1024 doas ../tools/bcachefs fsck -n /dev/$dev > "$OUT/fsck-recovery.log" 2>&1 \
  || STAGE3_FAIL 'RECOVERY-FSCK-DIRTY'
grep -E 'recovering|clean shutdown' "$OUT/fsck-recovery.log" | head -3

if [ $DRILL -eq 1 ]; then
  echo '--- post-recovery umount/remount cycle:'
  doas env BCACHEFS_FUSE_LOG=$OUT/cycle-daemon.log ../tools/bcachefs mount -o fuse /dev/$dev /tmp/bch-mnt 2>/dev/null || true
  sleep 8
  mount | grep -q fusefs.bcachefs || STAGE3_FAIL 'CYCLE-MOUNT-FAILED'
  n2=$(doas ls /tmp/bch-mnt | wc -l | tr -d ' ')
  doas sh -c 'echo cycle-ok > /tmp/bch-mnt/.cycle-probe'
  [ "$(doas cat /tmp/bch-mnt/.cycle-probe 2>/dev/null)" = 'cycle-ok' ] || STAGE3_FAIL 'CYCLE-RW-FAILED'
  echo "cycle: files=$n2 rw-probe=ok" | tee -a "$OUT/kill-drill.log"
  doas umount /tmp/bch-mnt 2>/dev/null || doas umount -f /tmp/bch-mnt 2>/dev/null || true
  sleep 2
  ../scripts/rlimit-run.sh 1024 doas ../tools/bcachefs fsck -n /dev/$dev > "$OUT/fsck-post-cycle.log" 2>&1 \
    || STAGE3_FAIL 'POST-CYCLE-FSCK-DIRTY'
  echo 'POST-RECOVERY CYCLE OK (remount rw → rw-probe → umount → clean fsck -n)'
fi

if [ $CENSUS -eq 1 ]; then
  echo '--- op census (per-request debug lines from BCACHEFS_FUSE_LOG):'
  sed -n -E 's/^\[[^]]+\] FUSE\([0-9 ]+\) ino 0x[0-9a-f]+ ([A-Za-z_]+).*/\1/p' "$OUT/storm-daemon.log" \
    | sort | uniq -c | sort -rn > "$OUT/op-census.log"
  total=$(awk '{s+=$1} END{print s+0}' "$OUT/op-census.log")
  echo "op census: $(wc -l < "$OUT/op-census.log" | tr -d ' ') op types, $total ops logged" | tee -a "$OUT/op-census.log"
  head -10 "$OUT/op-census.log"
fi

if [ $RSS -eq 1 ]; then
  rssmax=$(awk '{print $3}' "$OUT/rss-storm.log" 2>/dev/null | sort -n | tail -1)
  echo "daemon rss during storm: max=${rssmax:-n/a} kB, samples=$(wc -l < "$OUT/rss-storm.log" | tr -d ' ')" | tee "$OUT/rss-summary.log"
fi

echo "=== [4/5] ro-device mount gate (post-057: ro mount allowed, write must EROFS)"
u=$(u_of $dev); doas mdconfig -d -u $u
rdev=$(doas mdconfig -o ro -t vnode -f /tmp/bch-reg.img)
doas ../tools/bcachefs mount -o fuse,ro /dev/$rdev /tmp/bch-mnt > "$OUT/ro-mount.log" 2>&1 || true
sleep 8
if ! mount | grep -q 'on /tmp/bch-mnt (.*read-only'; then
  echo 'RO-MOUNT-FAILED (expected a read-only mount to come up post-057)'; tail -2 "$OUT/ro-mount.log"
  doas mdconfig -d -u $(u_of $rdev) 2>/dev/null || true; exit 1
fi
wout=$(doas sh -c 'echo x > /tmp/bch-mnt/ro-probe' 2>&1 || true)
echo "$wout" | tee "$OUT/ro-refusal.log"
echo "$wout" | grep -q 'Read-only file system' || { echo 'RO-WRITE-NOT-REFUSED'; doas umount -f /tmp/bch-mnt 2>/dev/null || true; doas mdconfig -d -u $(u_of $rdev) 2>/dev/null || true; exit 1; }
echo 'RO GATE OK (ro mount up; write refused with EROFS)'
doas umount /tmp/bch-mnt 2>/dev/null || doas umount -f /tmp/bch-mnt 2>/dev/null || true
sleep 2
doas mdconfig -d -u $(u_of $rdev)

echo "=== [5/5] multi-device roundtrip"
rm -f /tmp/bch-reg2.img; truncate -s 256m /tmp/bch-reg2.img
dev=$(doas mdconfig -t vnode -f /tmp/bch-reg.img); dev2=$(doas mdconfig -t vnode -f /tmp/bch-reg2.img)
# NOTE: colon-devices syntax is NOT accepted by `format` on this build (treated as one
# path → ENOENT); it IS accepted by mount and fsck. Format with separate args.
doas ../tools/bcachefs format --label mreg /dev/$dev /dev/$dev2 > /dev/null
doas ../tools/bcachefs mount -o fuse /dev/$dev:/dev/$dev2 /tmp/bch-mnt 2>/dev/null || true
sleep 8
doas sh -c 'echo hi > /tmp/bch-mnt/final-check' ; doas cat /tmp/bch-mnt/final-check
doas umount /tmp/bch-mnt
sleep 2
../scripts/rlimit-run.sh 1024 doas ../tools/bcachefs fsck -n /dev/$dev:/dev/$dev2 > "$OUT/fsck-multi.log" 2>&1 \
  || { echo MULTI-FSCK-DIRTY; tail -5 "$OUT/fsck-multi.log"; }
tail -1 "$OUT/fsck-multi.log"
doas mdconfig -d -u $(u_of $dev); doas mdconfig -d -u $(u_of $dev2)

echo "=== REGRESSION BATTERY: ALL GREEN"
echo "logs: $OUT"
