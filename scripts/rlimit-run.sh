#!/bin/sh
# rlimit-run MEM_MB command [args...] — run command under an rctl memory cap.
# rctl rule is PID-scoped, survives exec and fork (children inherit); it disappears when the process tree dies.
# Root-aware: uses rctl directly when root (doas denies root->root in rc.d context).
# Requires doas NOPASSWD for non-root callers (rctl needs root). Usage: scripts/rlimit-run.sh 2048 cargo build -j 2
[ $# -ge 2 ] || { echo "usage: $0 MEM_MB command [args...]" >&2; exit 64; }
MB="$1"; shift
RCTL=rctl
[ "$(id -u)" -ne 0 ] && RCTL="doas rctl"
if ! $RCTL -a "process:$$:memoryuse:deny=${MB}m" 2>/dev/null; then
    echo "rlimit-run: cannot add rctl rule (rctl enabled? doas?)" >&2
    exit 77
fi
exec "$@"
