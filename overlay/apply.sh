#!/bin/sh
# Apply the FreeBSD overlay onto tools/ (idempotent, reproducible).
# Stamps in tools/.overlay-stamps/ record applied patches; chained patches
# (whose context later patches modify) can never be reverse-detected, so
# stamps are the primary skip mechanism. Fresh clone = full forward chain.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$root/tools/Makefile" ] || { echo "overlay/apply.sh: $root/tools/Makefile not found (clone first)" >&2; exit 1; }

# 1. files: copy overlay/files/** into tools/, overwriting (deterministic).
( cd "$root/overlay/files" && find . -type f | while read -r f; do
	dest="$root/tools/$f"
	mkdir -p "$(dirname "$dest")"
	cp "$f" "$dest"
done )

# 2. patches in numeric order; stamp = applied. A patch is retried only if
# unstamped; --forward never reverses (plain --batch would "assume -R" on an
# already-patched file and silently un-apply).
mkdir -p "$root/tools/.overlay-stamps"
for p in "$root"/overlay/patches/*.patch; do
	[ -e "$p" ] || continue
	stamp="$root/tools/.overlay-stamps/$(basename "$p")"
	if [ -e "$stamp" ]; then
		echo "SKIP (stamped): $(basename "$p")"
		continue
	fi
	if patch -d "$root/tools" -p1 --forward --batch < "$p"; then
		touch "$stamp"
		echo "APPLIED: $(basename "$p")"
	else
		echo "FAILED: $p" >&2
		exit 1
	fi
done
echo "overlay applied."
