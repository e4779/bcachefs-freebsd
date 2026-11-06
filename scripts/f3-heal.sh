#!/bin/sh
# f3-heal.sh — supervised recovery: полный bounce стека при стойком wedge/смерти демона.
# Триггеры: демон мёртв, ИЛИ wedge держится > STALL_MIN минут.
# Sunset (совет P2): 2 недели без срабатываний = пересмотр.
: ${ROOT:=/home/e4779/projects/bcachefs-freebsd}
: ${STALL_MIN:=5}
LOG=$ROOT/tmp/f3-heal.log

echo "$(date '+%m-%d %H:%M:%S') heal-supervisor start (stall=$STALL_MIN min)" >> $LOG
SEEN_WEDGE=0
while :; do
    DPID=$(ps axo pid,comm | awk '$2=="bcachefs"{print $1; exit}')
    WEDGED=$(doas procstat -kk -a 2>/dev/null | grep -c fdisp_wait_answ)
    if [ -z "$DPID" ]; then
        echo "$(date '+%m-%d %H:%M:%S') DAEMON DEAD -> heal" >> $LOG
        ACTION=heal
    elif [ "$WEDGED" -gt 0 ]; then
        SEEN_WEDGE=$((SEEN_WEDGE+1))
        [ $SEEN_WEDGE -ge $STALL_MIN ] && { echo "$(date '+%m-%d %H:%M:%S') WEDGE PERSISTED ${SEEN_WEDGE}min -> heal" >> $LOG; ACTION=heal; }
    else
        SEEN_WEDGE=0
    fi
    if [ "$ACTION" = heal ]; then
        ACTION=
        SEEN_WEDGE=0
        echo "$(date '+%m-%d %H:%M:%S') bouncing stack..." >> $LOG
        for s in amutorrent qbittorrent stash amuled; do doas service $s onestop >/dev/null 2>&1; done
        doas pkill -9 -f qbittorrent-nox 2>/dev/null; doas pkill -9 amuled 2>/dev/null
        sleep 3
        doas rm -f /var/run/qbittorrent.pid /var/run/amuled.pid /srv/homelab/amule/muleLock
        doas umount -f /mnt/pool 2>/dev/null
        sleep 3
        doas service poolfuse onestart >> $LOG 2>&1
        for s in amuled stash qbittorrent amutorrent; do doas service $s onestart >/dev/null 2>&1; done
        echo "$(date '+%m-%d %H:%M:%S') bounce done" >> $LOG
    fi
    sleep 60
done
