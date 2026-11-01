#!/bin/sh
# sequential r/w: bench/seqrw.sh MOUNTPOINT [MiB]
MP="${1:?mountpoint required}"; MIB="${2:-1024}"
echo "# seq bench on $MP, $MIB MiB, $(date)"
dd if=/dev/zero of=$MP/bench.dd bs=1m count=$MIB conv=fsync 2>&1 | tail -1
dd if=$MP/bench.dd of=/dev/null bs=1m 2>&1 | tail -1
rm -f $MP/bench.dd
