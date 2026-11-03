#!/bin/sh
# stage-sentinel.sh — Ф0 stop-layer L2: stratified sha256 sentinel set over a mounted fs.
# build  : sample 64 files stratified by find depth — 8 top / 24 mid / 32 deep —
#          deterministic: files sorted by (depth, path), strata cut by rank thirds,
#          even stride inside each stratum (clamped to availability).
# verify : re-hash every recorded file; drift = MISSING or CHANGED content.
#          New files are NOT drift (the sentinel is a fixed sample).
# usage: scripts/stage-sentinel.sh build  <mount> <sentinels-file>
#        scripts/stage-sentinel.sh verify <mount> <sentinels-file>
# file format: <sha256>\t<depth>\t<relpath>  (tab-separated; paths with tabs unsupported)
# exit: 0 clean | 1 drift (verify) or nothing to sample (build) | 64 usage
set -u
MODE=${1:?build|verify}; MNT=${2:?mount}; OUT=${3:?sentinels-file}
[ -d "$MNT" ] || { echo "stage-sentinel: no mount dir $MNT" >&2; exit 64; }
TAB=$(printf '\t')

case $MODE in
build)
  TMP=$(mktemp -d) || exit 1
  # depth = number of path components of the relpath (root file = 1)
  find "$MNT" -type f | sed "s|^$MNT/||" | awk -F/ '{print NF $TAB $0}' \
    | LC_ALL=C sort -k1,1n -k2,2 > "$TMP/index"
  total=$(wc -l < "$TMP/index" | tr -d ' ')
  [ "$total" -ge 1 ] || { echo "stage-sentinel: no files under $MNT" >&2; rm -rf "$TMP"; exit 1; }
  awk -F'\t' -v TAB="$TAB" '
    { d[NR] = $1; p[NR] = $2 }
    END {
      t1 = int(NR / 3); t2 = int(2 * NR / 3)
      split("8 24 32", q, " ")
      for (s = 1; s <= 3; s++) {
        n    = (s == 1 ? t1 : (s == 2 ? t2 - t1 : NR - t2))
        base = (s == 1 ? 1    : (s == 2 ? t1 + 1     : t2 + 1))
        if (n < 1) continue
        for (k = 0; k < q[s] && k < n; k++)
          sel[++m] = base + (q[s] <= 1 || n <= 1 ? 0 : int(k * (n - 1) / (q[s] - 1)))
      }
      for (i = 1; i <= m; i++) print d[sel[i]] TAB p[sel[i]]
    }' "$TMP/index" > "$TMP/selected"
  : > "$OUT"
  while IFS="$TAB" read -r depth rel; do
    [ -n "$rel" ] || continue
    h=$(sha256sum "$MNT/$rel" 2>/dev/null | awk '{print $1}') || continue
    [ -n "$h" ] || continue
    printf '%s%s%s%s%s\n' "$h" "$TAB" "$depth" "$TAB" "$rel" >> "$OUT"
  done < "$TMP/selected"
  n_out=$(wc -l < "$OUT" | tr -d ' ')
  dmin=$(awk -F'\t' 'NR==1{print $1}' "$OUT"); dmax=$(awk -F'\t' 'END{print $1}' "$OUT")
  echo "sentinels: $n_out/$total files (quota 8/24/32 by depth-rank thirds; depth $dmin..$dmax) -> $OUT"
  rm -rf "$TMP"
  [ "$n_out" -ge 1 ] || exit 1
  ;;
verify)
  [ -f "$OUT" ] || { echo "stage-sentinel: no file $OUT" >&2; exit 64; }
  ok=0; miss=0; chg=0
  : > "$OUT.drift"
  while IFS="$TAB" read -r h depth rel; do
    [ -n "$rel" ] || continue
    f="$MNT/$rel"
    if [ ! -f "$f" ]; then echo "MISSING d=$depth $rel" >> "$OUT.drift"; miss=$((miss+1)); continue; fi
    h2=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    if [ "$h" != "$h2" ]; then echo "CHANGED d=$depth $rel ($h -> $h2)" >> "$OUT.drift"; chg=$((chg+1)); continue; fi
    ok=$((ok+1))
  done < "$OUT"
  echo "sentinel verify: ok=$ok missing=$miss changed=$chg (sample $((ok+miss+chg)))"
  if [ $((miss + chg)) -eq 0 ]; then echo "SENTINELS CLEAN"; else
    echo "SENTINEL DRIFT:"; cat "$OUT.drift"; exit 1
  fi
  ;;
*) echo "stage-sentinel: mode must be build|verify" >&2; exit 64 ;;
esac
