#!/bin/sh
# bench/run-all.sh MOUNTPOINT — full suite, 5 iterations, medians in report
MP="${1:?mountpoint required}"
for i in 1 2 3 4 5; do
  echo "--- iteration $i"
  sh "$(dirname "$0")/meta.sh" "$MP" 500
done | tee tmp/bench-run-$(date +%H%M%S).log
sh "$(dirname "$0")/seqrw.sh" "$MP" 512 | tee -a tmp/bench-run-*.log
echo "baselines: bridge NFS 12.8 ms/file sync-create; sshfs-fuse 1.2 ms (runbook 02)"
