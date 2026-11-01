#!/bin/sh
# T06: create a bcachefs test filesystem image using OUR FreeBSD build.
# NEVER run against pool devices — test image only (AGENTS.md constant).
# usage: scripts/mk-test-fs.sh [size-MiB] ; prints /dev/mdN
set -e
SIZE=${1:-2048}
IMG=${TMPDIR:-/tmp}/bcachefs-test.img
BIN=$(dirname "$0")/../tools/bcachefs
[ -x "$BIN" ] || { echo "no $BIN (build first)" >&2; exit 1; }
[ -f "$IMG" ] || truncate -s "${SIZE}m" "$IMG"
dev=$(doas mdconfig -t vnode -f "$IMG")
echo "image: $IMG -> $dev"
doas "$BIN" format --label test --fs_size=$((SIZE*1024*1024)) "$dev"
echo "TEST FS READY: $dev (bcachefs format OK = half of gate G1; fsck next: $BIN fsck $dev)"
# note: mdconfig+format need root on FreeBSD; md release: doas mdconfig -d -u ${dev#md}
