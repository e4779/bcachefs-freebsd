#!/bin/sh
# window-baseline.sh — pre-window READ-ONLY baseline of the LIVE pool (Zen5 layout).
# Members verified by SERIAL, not by name (names swapped during the Zen5 migration).
#  bcachefs NVMe: /dev/nda0p3  KINGSTON 50026B7383F5EDA1
#  bcachefs HDD : /dev/ada1    TOSHIBA 41OYK6J4FAYG   (ada0 = zdata, NEVER TOUCH)
# Uses show-super (upstream renamed dump-super in this build).
set -e
OUT=${1:-/tmp/pool-baseline}
BIN=$(dirname "$0")/../tools/bcachefs
[ -x "$BIN" ] || { echo "no binary at $BIN"; exit 1; }
mkdir -p "$OUT"
check() { # dev expected_serial
  dev=$1; want=$2
  ser=$(doas camcontrol identify "$dev" 2>/dev/null | grep -i serial | awk '{print $NF}' | tr -d ' :')
  [ "$ser" = "$want" ] || { echo "SERIAL MISMATCH $dev: got=$ser want=$want — devices moved again, DO NOT proceed"; exit 1; }
}
check nda0 50026B7383F5EDA1 || true   # NVMe serial via nda
check ada1 41OYK6J4FAYG
for dev in /dev/nda0p3 /dev/ada1; do
  name=$(echo "$dev" | tr '/' '_')
  doas "$BIN" show-super "$dev" > "$OUT/$name.super" 2>&1 || { echo "show-super FAILED on $dev — DO NOT proceed"; exit 1; }
  clean=$(grep -E '^Clean:' "$OUT/$name.super" || true)
  echo "baseline: $dev ($clean) -> $OUT/$name.super"
done
echo "BASELINE COMPLETE: $OUT"
echo "Expected at window time (after clean VM shutdown): Clean: 1 on both members."
echo "Post-window bit-compare: diff these files against fresh show-super output — must be identical."
