#!/bin/sh
# chaos.sh — chaos drills for the dogfood engine (Ф2). Runs INSIDE a live
# stage-session (the wrapper's canary + RSS sampling stay active throughout).
#
# usage: chaos.sh <mnt> <session-dir> <drill:a|b|c> <corpus-root>
#   a  kill -9 the FUSE daemon mid-churn → umount -f → recovery fsck -n →
#      remount (wrapper's own recipe, rctl-capped) → corpus verify subset
#   b  SIGSTOP the daemon → wrapper canary must raise L0 within 15 s → SIGCONT →
#      wait CANARY RECOVERED → corpus verify subset
#   c  ENOSPC: fio fill_fs fills the fs → a fresh corpus write must FAIL (silent
#      success on a full fs would be a finding) → free the fill files → space
#      returns → corpus verify subset
#
# Rules: kill/STOP target ONLY the daemon serving THIS session's mount (ppid=1,
# args match "bcachefs mount" + the mountpoint). The daemon dying under drill is
# the plan; the daemon dying OUTSIDE a drill is a FINDING for the engine log.
# exit: 0 drill green | 1 drill failed (caller logs it as a FINDING)
set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DOGFOOD=$ROOT/scripts/dogfood
BIN=$ROOT/tools/bcachefs
RLIMIT=$ROOT/scripts/rlimit-run.sh
MNT=${1:?mnt}; SESS=${2:?session dir}; DRILL=${3:?a|b|c}; CORPUS=${4:?corpus root}
ELOG=$SESS/engine.log

dev=$(cat "$SESS/dev")
case "$dev" in /*) DEV=$dev ;; *) DEV=/dev/$dev ;; esac
CAP=$(grep '^rctl_mb=' "$SESS/session.env" | cut -d= -f2)
[ -n "$CAP" ] || CAP=2048

log() { echo "$(date -u +%H:%M:%SZ) chaos[$DRILL]: $*" | tee -a "$ELOG" >&2; }
finding() { log "FINDING: $*"; }
fail() { log "DRILL $DRILL FAILED: $*"; exit 1; }

daemon_pid() {
  ps axo pid,ppid,args | grep '[b]cachefs mount' | grep -F -- "$MNT" \
    | awk -v mnt="x$MNT" '{args=$0; sub(/^[ ]*[0-9]+[ ]+[0-9]+[ ]+/, "", args)} $2==1 {print $1; exit}'
}

corpus_verify_subset() {
  n=${1:-40}
  CORPUS_SUBSET=$n sh "$DOGFOOD/corpus.sh" verify "$CORPUS" >> "$ELOG" 2>&1
}

wait_mounted() { # ≤30 s for the fuse mount to appear
  i=0; while [ $i -lt 30 ]; do
    mount | grep -q "on $MNT (" && return 0
    sleep 1; i=$((i+1))
  done
  return 1
}

case "$DRILL" in
a)
  # ---- kill -9 mid-churn → recovery path → verify -------------------------
  pid=$(daemon_pid); [ -n "$pid" ] || fail "no daemon found for $MNT"
  log "daemon pid=$pid; starting churn under the drill"
  CHURN_TOLERANT=1 sh "$DOGFOOD/churn.sh" "$MNT/.stage" 100000 50 "$SESS/churn-drill.tsv" \
    > "$SESS/churn-drill.out" 2>&1 &
  CPID=$!
  i=0; while [ $i -lt 30 ]; do
    [ "$(wc -l < "$SESS/churn-drill.tsv" 2>/dev/null | tr -d ' ')" -ge 30 ] && break
    sleep 1; i=$((i+1))
  done
  lines=$(wc -l < "$SESS/churn-drill.tsv" 2>/dev/null | tr -d ' ')
  [ "${lines:-0}" -ge 30 ] || fail "churn never reached mid-storm (tsv lines=${lines:-0})"
  log "mid-churn reached (tsv=$lines lines) — kill -9 daemon pid=$pid"
  doas kill -9 "$pid" || fail "kill -9 failed"
  i=0; while [ $i -lt 30 ]; do kill -0 "$CPID" 2>/dev/null || break; sleep 1; i=$((i+1)); done
  wait "$CPID" 2>/dev/null
  grep -q tolerated-abort "$SESS/churn-drill.out" && log "churn aborted under kill (expected)"
  sleep 2
  if mount | grep -q "on $MNT ("; then doas umount -f "$MNT" || true; fi
  log "recovery fsck -n on $DEV (journal-dirty ok, damage not ok)"
  t0=$(date +%s)
  "$RLIMIT" 1024 doas "$BIN" fsck -n "$DEV" > "$SESS/fsck-drill-a.log" 2>&1
  rc=$?
  log "recovery fsck rc=$rc ($(( $(date +%s) - t0 ))s): $(grep -E 'recovering|clean shutdown' "$SESS/fsck-drill-a.log" | tail -2 | tr '\n' ' | ')"
  [ $rc -eq 0 ] || fail "recovery fsck dirty (rc=$rc)"
  log "remounting $DEV (wrapper recipe, cap=${CAP}MB)"
  doas env BCACHEFS_FUSE_LOG="$SESS/daemon-recovery.log" "$RLIMIT" "$CAP" "$BIN" \
    mount -o fuse,allow_other "$DEV" "$MNT" > "$SESS/mount-recovery.log" 2>&1 || true
  wait_mounted || fail "recovery remount did not come up"
  echo chaos-a-ok > "$MNT/.stage/.chaos-a-probe" || fail "rw probe after recovery failed"
  log "rw probe ok — restarting a canary on the recovered mount (L0 coverage for later phases)"
  "$ROOT/scripts/stage-canary.sh" "$MNT" "$SESS/canary-recovery.log" --probe-dir "$MNT/.stage" &
  echo $! > "$SESS/canary-recovery.pid"
  corpus_verify_subset 40 || fail "corpus drift after kill-9 drill"
  log "DRILL a GREEN (kill -9 mid-churn → recovery → verify)"
  ;;
b)
  # ---- SIGSTOP → canary L0 ≤15 s → SIGCONT → RECOVERED → verify ------------
  pid=$(daemon_pid); [ -n "$pid" ] || fail "no daemon found for $MNT"
  CLOG=$SESS/canary.log
  [ -f "$CLOG" ] || fail "no canary log at $CLOG (wrapper canary dead?)"
  n0=$(wc -l < "$CLOG" | tr -d ' ')
  stop_t=$(date +%s)
  log "SIGSTOP daemon pid=$pid (canary lines before: $n0)"
  doas kill -STOP "$pid" || fail "SIGSTOP failed"
  l0_dt=-1
  i=0; while [ $i -lt 25 ]; do
    if tail -n +$((n0 + 1)) "$CLOG" 2>/dev/null | grep -q 'CANARY L0 ALERT'; then
      l0_line=$(tail -n +$((n0 + 1)) "$CLOG" | grep 'CANARY L0 ALERT' | head -1)
      l0_raw=$(echo "$l0_line" | cut -d' ' -f1)
      l0_ts=$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$l0_raw" +%s 2>/dev/null) || l0_ts=$((stop_t + 99))
      l0_dt=$(( l0_ts - stop_t ))
      break
    fi
    sleep 1; i=$((i+1))
  done
  if [ "$l0_dt" -lt 0 ]; then
    doas kill -CONT "$pid" 2>/dev/null
    finding "canary L0 never fired within 25 s of SIGSTOP"
    fail "no L0 ALERT"
  fi
  log "canary L0 fired dt=${l0_dt}s after SIGSTOP"
  [ "$l0_dt" -le 15 ] || { doas kill -CONT "$pid" 2>/dev/null; finding "L0 budget exceeded: ${l0_dt}s > 15s"; fail "L0 late (${l0_dt}s)"; }
  doas kill -CONT "$pid" || fail "SIGCONT failed"
  i=0; while [ $i -lt 30 ]; do
    tail -n +$((n0 + 1)) "$CLOG" | grep -q 'CANARY RECOVERED' && break
    sleep 1; i=$((i+1))
  done
  tail -n +$((n0 + 1)) "$CLOG" | grep -q 'CANARY RECOVERED' \
    || { finding "canary never logged RECOVERED after SIGCONT"; fail "no RECOVERED"; }
  log "canary RECOVERED — verifying corpus subset"
  corpus_verify_subset 40 || fail "corpus drift after SIGSTOP drill"
  log "DRILL b GREEN (SIGSTOP → L0=${l0_dt}s → CONT → RECOVERED → verify)"
  ;;
c)
  # ---- ENOSPC: fill → write must fail → free → verify ----------------------
  FILLDIR=$MNT/.stage/fio-fill
  mkdir -p "$FILLDIR"
  sed "s|__DIR__|$FILLDIR|" "$DOGFOOD/fio-jobs/fill.fio" > "$SESS/fill.run.fio"
  log "fio fill_fs on $FILLDIR (this writes until the fs is full — takes a while)"
  t0=$(date +%s)
  "$RLIMIT" 3000 fio "$SESS/fill.run.fio" > "$SESS/fio-fill.log" 2>&1
  rc=$?
  grep -qE 'ENOSPC|No space' "$SESS/fio-fill.log" \
    && log "fill ended ENOSPC as designed (rc=$rc, $(( $(date +%s) - t0 ))s)" \
    || { finding "fill_fs did not end ENOSPC (rc=$rc)"; fail "no ENOSPC"; }
  df -h "$MNT" | tail -1 | tee -a "$ELOG" >&2
  log "corpus write attempt on full fs (must FAIL)"
  if dd if=/dev/zero of="$MNT/.stage/enospc-probe" bs=1m count=64 conv=fsync 2>"$SESS/enospc-write.log"; then
    finding "write SUCCEEDED on a full filesystem (ENOSPC not propagated)"
    rm -f "$MNT/.stage/enospc-probe"
    fail "silent write on full fs"
  fi
  log "write failed as designed: $(tail -1 "$SESS/enospc-write.log")"
  log "freeing fill files"
  rm -rf "$FILLDIR"
  i=0; while [ $i -lt 120 ]; do
    avail=$(df -k "$MNT" | tail -1 | awk '{print $4}')
    [ "${avail:-0}" -gt 10485760 ] && break   # >10 GiB back
    sleep 2; i=$((i+1))
  done
  df -h "$MNT" | tail -1 | tee -a "$ELOG" >&2
  [ "${avail:-0}" -gt 10485760 ] || fail "space did not come back after rm fill"
  corpus_verify_subset 100 || fail "corpus drift after ENOSPC drill"
  log "DRILL c GREEN (fill → refused write → freed → verify)"
  ;;
*)
  echo "chaos: unknown drill $DRILL" >&2; exit 64 ;;
esac
exit 0
