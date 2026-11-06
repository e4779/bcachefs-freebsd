#!/bin/sh
# wedge-catcher.sh — авто-поимка FUSE wedge (поток клиента в fdisp_wait_answ)
# При детекции (>= threshold подряд проверок) снимает форензику:
#   стеки клиента и демона (procstat -kk), wchan-адреса (procstat -t),
#   mount-таблицу, dmesg-хвост — в tmp/fuse-wedge-<ts>/
# Гипотеза-подсказка: wchan ждущих потоков демона = адрес userspace-мьютекса;
# владелец ищется по стекам остальных потоков (umtx-адрес в аргументе).

: ${ROOT:=/home/e4779/projects/bcachefs-freebsd}
: ${THRESHOLD:=3}
: ${INTERVAL:=60}

STATE=$ROOT/tmp/wedge-catcher.state
LOG=$ROOT/tmp/wedge-catcher.log

wedge_count() {
    # client pids with a thread stuck in fdisp_wait_answ
    doas procstat -kk -a 2>/dev/null | awk '/fdisp_wait_answ/ {print $1}' | sort -u
}

echo "$(date '+%m-%d %H:%M:%S') wedge-catcher start (interval=$INTERVAL threshold=$THRESHOLD)" >> $LOG
n=0
while :; do
    WEDGED=$(wedge_count)
    if [ -z "$WEDGED" ]; then
        [ $n -gt 0 ] && echo "$(date '+%m-%d %H:%M:%S') wedge cleared after $n checks" >> $LOG
        n=0
    else
        n=$((n+1))
        echo "$(date '+%m-%d %H:%M:%S') wedge detected: pids=$WEDGED (count=$n/$THRESHOLD)" >> $LOG
        if [ $n -ge $THRESHOLD ]; then
            TS=$(date +%Y%m%d-%H%M%S)
            D=$ROOT/tmp/fuse-wedge-$TS
            mkdir -p $D
            echo "$(date '+%m-%d %H:%M:%S') CAPTURING evidence -> $D" >> $LOG
            DPID=$(ps axo pid,comm | awk '$2=="bcachefs"{print $1; exit}')
            for P in $WEDGED; do
                doas procstat -kk $P > $D/client-$P-stacks.txt 2>&1
                doas procstat -t $P > $D/client-$P-threads.txt 2>&1
            done
            if [ -n "$DPID" ]; then
                doas procstat -kk $DPID > $D/daemon-stacks.txt 2>&1
                doas procstat -t $DPID > $D/daemon-threads-wchan.txt 2>&1
            fi
            mount > $D/mounts.txt 2>&1
            dmesg | tail -50 > $D/dmesg-tail.txt 2>&1
            cp /var/log/bcachefs-fuse.log $D/ 2>/dev/null
            echo "$(date '+%m-%d %H:%M:%S') evidence captured: $(ls $D | wc -l) files" >> $LOG
            # one-shot per wedge episode: stop after capture
            break
        fi
    fi
    sleep $INTERVAL
done
