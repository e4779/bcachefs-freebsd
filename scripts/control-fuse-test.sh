#!/bin/sh
# T08 control test: prove the FreeBSD kernel FUSE layer works WITHOUT our code.
# Uses the fusefs-ufs port (realchonk/fuse-ufs) to mount a tiny UFSv2 image read-only.
# PREREQ (not yet installed, needs owner approval): doas pkg install fusefs-ufs
set -e
IMG=${TMPDIR:-/tmp}/ufs-control.img
MNT=${TMPDIR:-/tmp}/ufs-control.mnt

echo "== kernel module:"
kldstat -m fusefs >/dev/null 2>&1 || doas kldload fusefs
sysctl vfs.fusefs.kernelabi_major vfs.fusefs.kernelabi_minor

echo "== image:"
[ -f "$IMG" ] || truncate -s 64M "$IMG"
dev=$(mdconfig -t vnode -f "$IMG")
if ! dumpfs "$dev" >/dev/null 2>&1; then
  newfs -O2 "$dev" >/dev/null
  mount "/dev/$dev" /mnt >/dev/null 2>&1 && { echo hello > /mnt/probe.txt; umount /mnt; } || true
fi

echo "== mount via fuse-ufs (FUSE):"
mkdir -p "$MNT"
fuse-ufs -o ro "$dev" "$MNT"
cat "$MNT/probe.txt" 2>/dev/null || echo "(fresh image, no probe file — mount itself is the proof)"
fstat "$MNT" | head -5

echo "== cleanup:"
umount "$MNT" || true
mdconfig -d -u "${dev#md}"
echo "CONTROL TEST PASSED: kernel fusefs + libfuse3 path alive"
