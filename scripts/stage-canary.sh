#!/bin/sh
# stage-canary.sh — Ф0 stop-layer L0: stall watcher for a live stage mount.
# Probes statfs (df) + a canary-file touch on the mount every --interval seconds;
# if the pair exceeds --threshold (or times out), that is a stall:
#   1st consecutive stall  → CANARY L0 ALERT  (alert only, logged)
#   2nd+ consecutive stall → CANARY L1 STALL  (report; with --auto-stop: doas umount -f)
# A healthy probe resets the consecutive counter (CANARY RECOVERED is logged).
# usage: scripts/stage-canary.sh <mount> <session-log> [--auto-stop]
#          [--threshold secs=10] [--timeout secs=12] [--interval secs=1]
# exit: 0 mount-gone/terminated | 42 L1 auto-stop executed | 64 usage
# Note: the probe pair shares ONE timeout envelope so the first alert lands at
# ~timeout seconds even if both df and touch hang (alert budget = timeout + interval).
set -u
MNT=${1:?usage: stage-canary.sh <mount> <session-log> [options]}
LOG=${2:?session-log path}
shift 2
AUTO=0; THRESH=10; KILLT=12; INTERVAL=1; PDIR=""
while [ $# -gt 0 ]; do
  case $1 in
    --auto-stop) AUTO=1 ;;
    --probe-dir) PDIR=${2:?}; shift ;;
    --threshold) THRESH=${2:?}; shift ;;
    --timeout)   KILLT=${2:?}; shift ;;
    --interval)  INTERVAL=${2:?}; shift ;;
    *) echo "stage-canary: unknown option $1" >&2; exit 64 ;;
  esac
  shift
done
[ -d "$MNT" ] || { echo "stage-canary: no mount dir $MNT" >&2; exit 64; }

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" >> "$LOG"; }

mounted() { mount | grep -q "on $MNT ("; }
trap 'log "CANARY EXIT terminated"; exit 0' TERM INT

PROBE="${PDIR:-$MNT}/.canary.$$"
log "CANARY START mount=$MNT threshold=${THRESH}s timeout=${KILLT}s auto-stop=$AUTO pid=$$"
stalls=0; first=1
while :; do
  if ! mounted; then log "CANARY EXIT mount-gone"; exit 0; fi
  t0=$(date +%s)
  timeout "$KILLT" sh -c "df '$MNT' >/dev/null 2>&1 && touch '$PROBE'"
  rc=$?
  t1=$(date +%s); dt=$((t1 - t0))
  if [ "$rc" -eq 124 ] || [ "$dt" -ge "$THRESH" ]; then
    stalls=$((stalls + 1))
    if [ "$stalls" -ge 2 ]; then
      log "CANARY L1 STALL dt=${dt}s rc=$rc consecutive=$stalls — repeated stall on $MNT"
      if [ "$AUTO" -eq 1 ]; then
        log "CANARY L1 AUTO-STOP: umount -f $MNT"
        doas umount -f "$MNT" >/dev/null 2>&1
        log "CANARY EXIT auto-stopped (L1 enforced)"
        exit 42
      fi
    else
      log "CANARY L0 ALERT dt=${dt}s rc=$rc (statfs+touch over ${THRESH}s on $MNT)"
    fi
  else
    if [ "$first" -eq 1 ]; then log "CANARY PROBE ok dt=${dt}s (baseline healthy)"; first=0; fi
    if [ "$stalls" -gt 0 ]; then log "CANARY RECOVERED (stall run was $stalls)"; fi
    stalls=0
  fi
  sleep "$INTERVAL"
done
