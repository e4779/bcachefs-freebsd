#!/bin/sh
# Apply the FreeBSD overlay onto tools/ (idempotent, reproducible).
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$root/tools/Makefile" ] || { echo "overlay/apply.sh: $root/tools/Makefile not found (clone first)" >&2; exit 1; }

# 1. files: copy overlay/files/** into tools/, overwriting.
( cd "$root/overlay/files" && find . -type f | while read -r f; do
	dest="$root/tools/$f"
	mkdir -p "$(dirname "$dest")"
	cp "$f" "$dest"
done )

# 2. patches: --forward never reverses (a plain --batch patch would "assume -R"
# on an already-patched file and silently un-apply). A skipped-already-applied
# patch exits nonzero and is detected by the reverse dry-run.
for p in "$root"/overlay/patches/*.patch; do
	[ -e "$p" ] || continue
	if patch -d "$root/tools" -p1 --forward --batch --silent < "$p" >/dev/null 2>&1; then
		echo "APPLIED: $(basename "$p")"
	elif patch -d "$root/tools" -R -p1 --dry-run --silent < "$p" >/dev/null 2>&1; then
		echo "SKIP (already applied): $(basename "$p")"
	else
		echo "FAILED: $p" >&2
		patch -d "$root/tools" -p1 --forward --batch < "$p" || true
		exit 1
	fi
done
echo "overlay applied."
