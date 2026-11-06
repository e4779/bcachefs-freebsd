#!/bin/sh
# wedge-catcher v3 — БЕЗ truss (v2 убивал демона SIGTRAP'ом при detach!)
# Вместо truss: деликатный снимок стеков. Кор-дампы добываются отдельно (deliberate SIGTRAP),
# только если оператор подтвердил жертву: kill -5 <daemon> -> core -> lldb offline.
: ${ROOT:=/home/e4779/projects/bcachefs-freebsd}
: ${THRESHOLD:=3}
: ${INTERVAL:=60}
LOG=$ROOT/tmp/wedge-catcher.log
wedge_count() {
    doas procstat -kk -a 2>/dev/null | awk '/fdisp_wait_answ/ {print $1}' | sort -u
}
echo "$(date '+%m-%d %H:%M:%S') catcher-v3 start" >> $LOG
n=0
while :; do
    WEDGED=$(wedge_count)
    if [ -z "$WEDGED" ]; then
        [ $n -gt 0 ] && echo "$(date '+%m-%d %H:%M:%S') cleared after $n" >> $LOG
        n=0
    else
        n=$((n+1))
        echo "$(date '+%m-%d %H:%M:%S') wedge: $WEDGED ($n/$THRESHOLD)" >> $LOG
        if [ $n -ge $THRESHOLD ]; then
            TS=$(date +%Y%m%d-%H%M%S)
            D=$ROOT/tmp/fuse-wedge-$TS
            mkdir -p $D
            DPID=$(ps axo pid,comm | awk '$2=="bcachefs"{print $1; exit}')
            for P in $WEDGED; do
                doas procstat -kk $P > $D/client-$P-stacks.txt 2>&1
            done
            if [ -n "$DPID" ]; then
                doas procstat -kk $DPID > $D/daemon-stacks.txt 2>&1
                doas procstat -t $DPID > $D/daemon-threads-wchan.txt 2>&1
            fi
            mount > $D/mounts.txt 2>&1
            dmesg | tail -30 > $D/dmesg-tail.txt 2>&1
            echo "$(date '+%m-%d %H:%M:%S') captured $D (hint: core via kill -5 $DPID if operator approves)" >> $LOG
            break
        fi
    fi
    sleep $INTERVAL
done
