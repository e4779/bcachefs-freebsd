#!/bin/sh
# f3-heal v2.1 — supervised recovery for the bcachefs FUSE pool (Ф3).
#
# v2 (2026-11-07): first aid = bounce ONLY the daemon (umount -f +
#   poolfuse onestart, ~1 min; clients ride through via kernel fail-fast
#   + libtorrent retries). Full-stack bounce is the escalation.
#   Triggers: A) daemon dead >= DEAD_N checks (1/min);
#   B) ring gen stale > STALE_MIN min while daemon alive (with timeout=0
#   fdisp counts are meaningless; frozen telemetry = daemon sick-alive).
# v2.1 (2026-11-07 evening): PATH fix — daemon(8) runs with a minimal env
#   where /usr/local/bin (jq!) is absent, so ring_gen always failed, so
#   verification always failed, so first aid ALWAYS escalated (first live
#   fire killed the client stack for nothing). Also: bounces now enforce
#   the single-daemon invariant (kill all mount daemons before onestart).
# Runs as root (rc.d f3heal, daemon(8)) — no doas inside.
# MAINTENANCE: service f3heal onestop before deliberate poolfuse stops.
# Sunset (P2 council): 2 weeks without a heal = retire.

: "${ROOT:=/home/e4779/projects/bcachefs-freebsd}"
: "${UUIDFILE:=/tmp/bcf-uuid}"
: "${DEAD_N:=2}"
: "${STALE_MIN:=5}"
: "${VERIFY_MIN:=3}"
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
export PATH
LOG=$ROOT/tmp/f3-heal.log
RINGBASE=/var/run/bcachefs-fuse

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
    logger -t f3-heal -p daemon.warning "$*" 2>/dev/null
}

ring_gen() {
    u=$(cat "$UUIDFILE" 2>/dev/null) || return 1
    jq -r '.gen' "$RINGBASE/$u/accounting.json" 2>/dev/null
}

daemon_pid() { pgrep -f '^\./tools/bcachefs mount' | head -1; }

kill_all_daemons() {
    for p in $(pgrep -f '^\./tools/bcachefs mount'); do
        log "killing daemon $p"
        kill -9 "$p" 2>/dev/null
    done
}

bounce_daemon() {
    log "first aid: bounce daemon only"
    umount -f /mnt/pool 2>>"$LOG"
    sleep 2
    kill_all_daemons
    service poolfuse onestart >> "$LOG" 2>&1
}

bounce_stack() {
    log "ESCALATION: full stack bounce (first aid failed)"
    for s in amutorrent qbittorrent stash amuled; do service "$s" onestop >/dev/null 2>&1; done
    pkill -9 -f qbittorrent-nox 2>/dev/null; pkill -9 amuled 2>/dev/null
    sleep 3
    rm -f /var/run/qbittorrent.pid /var/run/amuled.pid /srv/homelab/amule/muleLock
    umount -f /mnt/pool 2>>"$LOG"
    sleep 2
    kill_all_daemons
    service poolfuse onestart >> "$LOG" 2>&1
    for s in amuled stash qbittorrent amutorrent; do service "$s" onestart >/dev/null 2>&1; done
}

log "f3-heal v2.1 start (dead_n=$DEAD_N stale=$STALE_MIN verify=$VERIFY_MIN)"
DEAD=0; STALE=0; LAST_GEN=""
while :; do
    ACTION=
    if [ -z "$(daemon_pid)" ]; then
        DEAD=$((DEAD + 1))
        [ "$DEAD" -ge "$DEAD_N" ] && ACTION=heal
    else
        DEAD=0
    fi

    G=$(ring_gen)
    if [ -n "$(daemon_pid)" ] && [ -n "$G" ] && [ "$G" = "$LAST_GEN" ]; then
        STALE=$((STALE + 1))
        [ "$STALE" -ge "$STALE_MIN" ] && ACTION=heal
    else
        STALE=0
    fi
    LAST_GEN=$G

    if [ "$ACTION" = heal ]; then
        DEAD=0; STALE=0; LAST_GEN=""
        bounce_daemon
        G0=$(ring_gen); ok=0; G=$G0
        i=0
        while [ $i -lt "$VERIFY_MIN" ]; do
            sleep 60
            G=$(ring_gen)
            if [ -n "$G" ] && [ "$G" != "$G0" ]; then ok=1; break; fi
            i=$((i + 1))
        done
        if [ "$ok" = 1 ]; then
            log "heal ok: ring gen advancing ($G0 -> $G)"
        else
            bounce_stack
            log "escalation done; verify manually if this repeats"
        fi
        continue
    fi
    sleep 60
done
