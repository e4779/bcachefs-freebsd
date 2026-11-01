#!/bin/sh
# rlimit-run MEM_MB command [args...] — run command under an rctl memory cap.
# rctl rule is PID-scoped, survives exec and fork (children inherit); it disappears when the process tree dies.
# Requires doas NOPASSWD (rctl needs root). Usage: scripts/rlimit-run.sh 2048 cargo build -j 2
[ $# -ge 2 ] || { echo "usage: $0 MEM_MB command [args...]" >&2; exit 64; }
MB="$1"; shift
if ! doas rctl -a "process:$$:memoryuse=${MB}m:deny" 2>/dev/null; then
  echo "rlimit-run: cannot add rctl rule (rctl enabled? doas?)" >&2
  exit 77
fi
exec "$@"
