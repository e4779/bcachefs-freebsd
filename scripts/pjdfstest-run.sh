#!/bin/sh
# T10/T11: run pjdfstest against a mountpoint, log TAP summary.
# usage: scripts/pjdfstest-run.sh MOUNTPOINT [tests-root-group]
set -e
MP=${1:?mountpoint}
ROOT=/usr/local/share/pjdfstest
[ -d "$ROOT" ] || { echo "pjdfstest not found at $ROOT (pkg install pjdfstest)" >&2; exit 1; }
cd "$ROOT"
LOG=$(dirname "$0")/../tmp/pjdfstest-$(date +%Y%m%d-%H%M%S).tap
prove -e "sh -x" "$ROOT/tests/${2:-.}" 2>&1 | tee "$LOG" | tail -5
echo "full log: $LOG"
