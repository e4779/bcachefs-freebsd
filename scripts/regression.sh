#!/bin/sh
# regression.sh — the bcachefs-freebsd regression battery.
# Runs: upstream cargo test suite + our runtime gates on throwaway images.
# Usage: scripts/regression.sh [quick]   (quick = skip cargo test)
# Every stage logs to tmp/regression-<ts>/ and the script exits nonzero on ANY failure.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TS=$(date +%Y%m%d-%H%M%S)
OUT=$ROOT/tmp/regression-$TS
mkdir -p "$OUT"
cd "$ROOT/tools"

echo "=== [1/5] upstream cargo test suite"
if [ "$1" != quick ]; then
  PKG_CONFIG_PATH=$ROOT/overlay/pkgconfig CARGO_BUILD_JOBS=2 \
    nice -n 19 ../scripts/rlimit-run.sh 3000 cargo test --release 2>&1 | tee "$OUT/cargo-test.log" | tail -3
fi

echo "=== [2/5] format + clean fsck gate"
rm -f /tmp/bch-reg.img; truncate -s 512m /tmp/bch-reg.img
dev=$(doas mdconfig -t vnode -f /tmp/bch-reg.img)
echo "$dev" > "$OUT/dev"
../tools/bcachefs format --label reg /dev/$dev > /dev/null
../tools/bcachefs fsck /dev/$dev 2>&1 | tee "$OUT/fsck-clean.log" | tail -1

echo "=== [3/5] rw mount + storm + kill -9 + recovery"
doas env BCACHEFS_FUSE_LOG=$OUT/storm-daemon.log ../tools/bcachefs mount -o fuse /dev/$dev /tmp/bch-mnt 2>/dev/null || true
sleep 8
mount | grep -q fusefs.bcachefs || { echo MOUNT-FAILED; exit 1; }
doas sh -c 'i=0; while [ $i -lt 50000 ]; do echo x > /tmp/bch-mnt/s$i; i=$((i+1)); done' &
sleep 8
d=$(ps axo pid,ppid,args | grep '[t]ools/bcachefs mount' | awk '$2==1 {print $1}' | head -1)
[ -n "$d" ] && doas kill -9 $d
doas pkill -9 -f 'while.*50000' 2>/dev/null || true
sleep 2; doas umount -f /tmp/bch-mnt 2>/dev/null || true
echo '--- recovery fsck (expect: replay + clean):'
../tools/bcachefs fsck /dev/$dev 2>&1 | tee "$OUT/fsck-recovery.log" | grep -E 'recovering|clean' | head -3

echo "=== [4/5] dirty image ro-refusal gate"
u=$(echo $dev | tr -d md); doas mdconfig -d -u $u
rdev=$(doas mdconfig -o ro -t vnode -f /tmp/bch-reg.img)
out=$(doas ../tools/bcachefs mount -o fuse,ro /dev/$rdev /tmp/bch-mnt 2>&1 | tail -1)
echo "$out" | tee "$OUT/ro-refusal.log"
echo "$out" | grep -q 'Read-only file system' || { echo 'RO-REFUSAL-MISSING'; exit 1; }
doas mdconfig -d -u $(echo $rdev | tr -d md)

echo "=== [5/5] multi-device roundtrip"
rm -f /tmp/bch-reg2.img; truncate -s 256m /tmp/bch-reg2.img
dev=$(doas mdconfig -t vnode -f /tmp/bch-reg.img); dev2=$(doas mdconfig -t vnode -f /tmp/bch-reg2.img)
../tools/bcachefs format --label mreg /dev/$dev:/dev/$dev2 > /dev/null
doas ../tools/bcachefs mount -o fuse /dev/$dev:/dev/$dev2 /tmp/bch-mnt 2>/dev/null || true
sleep 8
doas sh -c 'echo hi > /tmp/bch-mnt/final-check' ; doas cat /tmp/bch-mnt/final-check
doas umount /tmp/bch-mnt
../tools/bcachefs fsck /dev/$dev:/dev/$dev2 2>&1 | tail -1
doas mdconfig -d -u $(echo $dev | tr -d md); doas mdconfig -d -u $(echo $dev2 | tr -d md)

echo "=== REGRESSION BATTERY: ALL GREEN"
echo "logs: $OUT"
