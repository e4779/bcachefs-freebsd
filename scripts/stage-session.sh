#!/bin/sh
# stage-session.sh — Ф0 session wrapper: the ONLY sanctioned way to run a stage session.
# Flow: fresh mdconfig + rw FUSE mount → run command (or interactive marker) →
#       daemon RSS sampled every 10s → canary watcher → umount → fsck → verdict.
# usage: scripts/stage-session.sh <image> <stage-dir> [command...]
#   <image> is a regular file (mdconfig vnode bridge) OR a raw device node such
#   as the staging zvol /dev/zvol/zdata/stage-pool (mounted directly, no md layer;
#   <session>/dev then holds the full device path).
#   command '-' (or none) → interactive marker mode: wrapper prints the marker file
#   and waits until <session-dir>/done appears (write "fail" into it to flag failure).
# env knobs:
#   STAGE_RCTL_MB      daemon rctl memoryuse cap (default 2048; 0 disables) — stop-layer L1
#   STAGE_CANARY_OPTS  extra args for stage-canary.sh (e.g. "--auto-stop" on prod-tiers)
#   STAGE_LOG_LEVEL    BCACHEFS_LOG for the daemon (e.g. debug → per-op trace for census)
# The image must be bcachefs-formatted already (mk-test-fs.sh / regression.sh format).
# Session dir: tmp/stage-sessions/<ts>/ {session.env,dev,mount.log,daemon.log,command.log,
#   rss.log,canary.log,fsck.log,verdict}. Exit: 0 clean | 1 mount fail | 2 fsck dirty | 3 command fail.
# Verdict fsck is CHECK-ONLY (fsck -n) on the backing image file: a journal-dirty image
# counts as clean (journal replay belongs to the mount path — verified 2026-11-03);
# nonzero = damage beyond journal replay. Repair-fsck (write path) is broken on the
# current binary by patch 057 (read_only opens lost BLK_OPEN_WRITE → superblock EBADF);
# see docs/notes/17a-frame-zero.md.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BIN=$ROOT/tools/bcachefs
CANARY=$ROOT/scripts/stage-canary.sh
RLIMIT=$ROOT/scripts/rlimit-run.sh
IMAGE=${1:?usage: stage-session.sh <image> <stage-dir> [command...]}; shift
MNT=${1:?stage-dir = mountpoint}; shift
# normalize to absolute paths: every mount-table grep below matches the kernel's
# absolutized entries — a relative arg would silently skip umount/detach and leak
# a live daemon (measured 2026-11-04)
case "$IMAGE" in /*) ;; *) IMAGE="$PWD/$IMAGE" ;; esac
case "$MNT" in /*) ;; *) MNT="$PWD/$MNT" ;; esac
[ -f "$IMAGE" ] || [ -c "$IMAGE" ] || { echo "stage-session: no image $IMAGE (regular file or device)" >&2; exit 1; }
[ -x "$BIN" ]  || { echo "stage-session: no binary $BIN" >&2; exit 1; }
[ -x "$CANARY" ] || { echo "stage-session: no $CANARY" >&2; exit 1; }

TS=$(date +%Y%m%d-%H%M%S)
SESS=$ROOT/tmp/stage-sessions/$TS
mkdir -p "$SESS" "$MNT" || exit 1
cat > "$SESS/session.env" <<EOF
ts=$TS
image=$IMAGE
mnt=$MNT
rctl_mb=${STAGE_RCTL_MB:-2048}
canary_opts=${STAGE_CANARY_OPTS:-}
cmd=$*
EOF
CAP=${STAGE_RCTL_MB:-2048}

dev=""; canary_pid=""; rss_pid=""
cleanup() {
  [ -n "$canary_pid" ] && kill "$canary_pid" 2>/dev/null
  [ -n "$rss_pid" ] && kill "$rss_pid" 2>/dev/null
  if mount | grep -q "on $MNT ("; then
    doas umount "$MNT" 2>/dev/null || doas umount -f "$MNT" 2>/dev/null || true
  fi
  detach_md
  return 0
}
mounted_bcachefs() { mount | grep " on $MNT (" | grep -q bcachefs; }
# md release with retry: the daemon may hold the device open for a few seconds after umount
detach_md() {
  [ -n "$dev" ] || return 0
  case "$dev" in
    md*) i=0
         while [ $i -lt 10 ]; do
           doas mdconfig -d -u "${dev#md}" 2>/dev/null && { dev=""; return 0; }
           sleep 1; i=$((i+1))
         done
         echo "stage-session: WARNING md unit $dev still attached (device busy?)" >&2
         return 1 ;;
    *)  dev=""; return 0 ;;   # raw device (zvol): nothing to detach
  esac
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

echo "=== stage-session $TS"
echo "image=$IMAGE mnt=$MNT session=$SESS"
case "$IMAGE" in
  /dev/*) dev=$IMAGE ;;   # raw device (zvol): use it as-is
  *)      dev=$(doas mdconfig -t vnode -f "$IMAGE") || { echo "MOUNT-FAILED: mdconfig"; exit 1; } ;;
esac
echo "$dev" > "$SESS/dev"
case "$dev" in /*) DEVSRC=$dev ;; *) DEVSRC=/dev/$dev ;; esac
DAEMON_ENV="BCACHEFS_FUSE_LOG=$SESS/daemon.log"
[ -n "${STAGE_LOG_LEVEL:-}" ] && DAEMON_ENV="$DAEMON_ENV BCACHEFS_LOG=$STAGE_LOG_LEVEL"
MOUNTOPTS="fuse,allow_other"   # allow_other + default_permissions: the port's own
                                # everyone-can-access philosophy; perms stay kernel-enforced
if [ "$CAP" != "0" ]; then
  doas env $DAEMON_ENV "$RLIMIT" "$CAP" "$BIN" mount -o "$MOUNTOPTS" "$DEVSRC" "$MNT" \
    > "$SESS/mount.log" 2>&1 || true
else
  doas env $DAEMON_ENV "$BIN" mount -o "$MOUNTOPTS" "$DEVSRC" "$MNT" \
    > "$SESS/mount.log" 2>&1 || true
fi
i=0; up=0
while [ $i -lt 30 ]; do
  if mounted_bcachefs; then up=1; break; fi
  sleep 1; i=$((i+1))
done
if [ "$up" != "1" ]; then
  echo "MOUNT-FAILED (no fusefs at $MNT after ${i}s; see $SESS/mount.log)"
  exit 1
fi
echo "mount: $DEVSRC on $MNT (rw, $MOUNTOPTS, cap=${CAP}MB)"
# user-writable workspace inside the root-owned fs (fs perms enforced by default_permissions)
doas mkdir -p "$MNT/.stage"
doas chown "$(id -u):$(id -g)" "$MNT/.stage"

# RSS sampler: daemon matched by (bcachefs mount + this mountpoint + ppid 1), 10s cadence
(
  while :; do
    ps axo pid,ppid,rss,args | grep '[b]cachefs mount' | grep -F -- "$MNT" \
      | awk -v t="$(date +%s)" '$2==1 {print t, $1, $3; exit}'
    sleep 10
  done
) >> "$SESS/rss.log" 2>&1 &
rss_pid=$!

# canary watcher (L0); probes write inside .stage so they exercise the FUSE write path as this user
# shellcheck disable=SC2086
"$CANARY" "$MNT" "$SESS/canary.log" --probe-dir "$MNT/.stage" ${STAGE_CANARY_OPTS:-} &
canary_pid=$!

export STAGE_MNT="$MNT"
export STAGE_WORK="$MNT/.stage"
rc=0
if [ $# -eq 0 ] || [ "$1" = "-" ]; then
  cat > "$SESS/interactive.marker" <<EOF
session:    $SESS
image:      $IMAGE
device:     /dev/$dev
mount:      $MNT (rw, fuse)
daemon-log: $SESS/daemon.log
canary:     pid $canary_pid (log $SESS/canary.log)
finish:     echo done > $SESS/done        (echo fail > $SESS/done to flag failure)
EOF
  echo "STAGE READY (interactive): $SESS/interactive.marker"
  while [ ! -f "$SESS/done" ]; do
    sleep 2
    kill -0 "$canary_pid" 2>/dev/null || break   # canary died (auto-stop/exit)
  done
  if [ -f "$SESS/done" ] && grep -q fail "$SESS/done"; then rc=1; fi
  rm -f "$SESS/done"
else
  echo "command: $*"
  "$@" > "$SESS/command.log" 2>&1
  rc=$?
fi
echo "command rc=$rc"

kill "$canary_pid" 2>/dev/null
wait "$canary_pid" 2>/dev/null; echo "canary_exit=$?" >> "$SESS/canary.log"
kill "$rss_pid" 2>/dev/null; wait "$rss_pid" 2>/dev/null

echo '--- umount'
if mount | grep -q "on $MNT ("; then
  doas umount "$MNT" 2>/dev/null || doas umount -f "$MNT" 2>/dev/null || true
fi
i=0; while [ $i -lt 15 ]; do
  mount | grep -q "on $MNT (" || break
  sleep 1; i=$((i+1))
done
if mount | grep -q "on $MNT ("; then doas umount -f "$MNT" 2>/dev/null || true; fi

echo '--- md release + fsck -n (check-only on image, rctl cap 1024 MB)'
detach_md
if [ -c "$IMAGE" ]; then
  # device images (zvols) are root:operator — the invoking user cannot open them
  "$RLIMIT" 1024 doas "$BIN" fsck -n "$IMAGE" > "$SESS/fsck.log" 2>&1
else
  "$RLIMIT" 1024 "$BIN" fsck -n "$IMAGE" > "$SESS/fsck.log" 2>&1
fi
fsck_rc=$?
tail -2 "$SESS/fsck.log"

rss_max=$(awk '{print $3}' "$SESS/rss.log" 2>/dev/null | sort -n | tail -1)
echo "daemon rss max: ${rss_max:-n/a} kB (samples: $(wc -l < "$SESS/rss.log" 2>/dev/null | tr -d ' '))"

if   [ "$fsck_rc" -ne 0 ]; then verdict=2; why="fsck dirty (rc=$fsck_rc)"
elif [ "$rc" -ne 0 ];        then verdict=3; why="command failed (rc=$rc)"
else                               verdict=0; why="clean"
fi
echo "VERDICT: $verdict — $why" | tee "$SESS/verdict"
exit "$verdict"
