#!/bin/sh
# T07: fsck roundtrip on the test image.
#  clean mode (pre-FUSE): fsck a freshly formatted image — expect exit 0, zero errors.
#  fill mode (post-T10):  mount via FUSE at $2, write N files+fsync, unmount, fsck, read back, verify.
# usage: scripts/fsck-roundtrip.sh clean DEV | fill DEV MNT [N]
set -e
BIN=$(dirname "$0")/../tools/bcachefs
mode=${1:?clean|fill}; dev=${2:?device}
case "$mode" in
clean)
  "$BIN" fsck "$dev"
  echo "CLEAN FSCK PASSED: $dev"
  ;;
fill)
  mnt=${3:?mountpoint}; n=${4:-500}
  i=0; while [ $i -lt $n ]; do echo "payload-$i" > "$mnt/file-$i"; i=$((i+1)); done
  sync
  umount "$mnt" || fusermount3 -u "$mnt"
  "$BIN" fsck "$dev"
  mkdir -p "$mnt"
  "$BIN" mount -o fuse,ro "$dev" "$mnt"   # re-mount read-only for readback
  fail=0; i=0
  while [ $i -lt $n ]; do
    [ "$(cat "$mnt/file-$i" 2>/dev/null)" = "payload-$i" ] || { echo "MISMATCH file-$i"; fail=$((fail+1)); }
    i=$((i+1))
  done
  umount "$mnt" || fusermount3 -u "$mnt"
  [ $fail -eq 0 ] && echo "FILL ROUNDTRIP PASSED: $n files verified" || { echo "FAILURES: $fail"; exit 1; }
  ;;
esac
