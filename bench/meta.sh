#!/bin/sh
# metadata benchmark: sync-create / rename-storm / deep-readdir / stat-walk
# usage: bench/meta.sh MOUNTPOINT [ITERATIONS]
MP="${1:?mountpoint required}"; N="${2:-1000}"
echo "# meta bench on $MP, N=$N, $(date)"
# 1) sync-create (the bridge pain: 12.8 ms/file target to beat)
T=$MP/bench-create.$$; mkdir -p $T
START=$(date +%s%N)
i=0; while [ $i -lt $N ]; do echo x > "$T/f$i"; i=$((i+1)); done
END=$(date +%s%N)
echo "sync-create: $(( (END-START)/1000000/N )) ms/file ($N files)"
rm -rf $T
# 2) rename-storm (ed2k-farm pattern)
T=$MP/bench-rename.$$; mkdir -p $T
i=0; while [ $i -lt $N ]; do echo x > "$T/f$i"; i=$((i+1)); done
START=$(date +%s%N)
i=0; while [ $i -lt $N ]; do mv "$T/f$i" "$T/r$i"; i=$((i+1)); done
END=$(date +%s%N)
echo "rename: $(( (END-START)/1000000/N )) ms/file"
rm -rf $T
# 3) deep-readdir
T=$MP/bench-readdir.$$; mkdir -p $T
i=0; while [ $i -lt $N ]; do echo x > "$T/f$i"; i=$((i+1)); done
START=$(date +%s%N); ls -f $T > /dev/null; END=$(date +%s%N)
echo "readdir($N): $(( (END-START)/1000000 )) ms"
# 4) stat-walk
START=$(date +%s%N); find $T -maxdepth 1 -exec stat -t %s {} \; > /dev/null 2>&1; END=$(date +%s%N)
echo "stat-walk($N): $(( (END-START)/1000000 )) ms"
rm -rf $T
