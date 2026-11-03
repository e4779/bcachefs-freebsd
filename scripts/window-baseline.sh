#!/bin/sh
# window-baseline.sh — pre-window baseline of the LIVE pool (READ-ONLY probing).
# Saves dump-super of both pool members + device identity for the post-window bit-compare.
# NEVER writes to the pool. Run before scheduling the window.
set -e
OUT=${1:-/tmp/pool-baseline}
BIN=$(dirname "$0")/../tools/bcachefs
mkdir -p "$OUT"
for dev in /dev/nda0p3 /dev/ada0; do
  [ -e "$dev" ] || { echo "missing $dev — check device names first!"; exit 1; }
  name=$(basename "$dev" | tr '/' '_')
  doas camcontrol identify "$dev" 2>/dev/null | grep -i serial > "$OUT/$name.serial" || true
  doas "$BIN" dump-super "$dev" > "$OUT/$name.super" 2>&1 || { echo "dump-super FAILED on $dev — DO NOT proceed"; exit 1; }
  echo "baseline saved: $dev -> $OUT/$name.super"
done
echo "BASELINE COMPLETE: $OUT (bit-compare after the window: diff must be empty)"
