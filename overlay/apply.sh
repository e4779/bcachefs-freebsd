#!/bin/sh
# Apply the FreeBSD overlay onto tools/ (idempotent, reproducible).
# Stamps in tools/.overlay-stamps/ record applied patches; chained patches
# (whose context later patches modify) can never be reverse-detected, so
# stamps are the primary skip mechanism. Fresh clone = full forward chain.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
# Bootstrap: clone the pinned upstream if tools/ is absent (see overlay/README.md).
BCACHEFS_TOOLS_URL=https://github.com/koverstreet/bcachefs-tools.git
BCACHEFS_TOOLS_REF=d48ba1a7a1d03afed5a20d1cce8189e9ae9a8486
if [ ! -f "$root/tools/Makefile" ]; then
	if command -v git >/dev/null 2>&1; then
		echo "overlay/apply.sh: tools/ missing - cloning upstream at $BCACHEFS_TOOLS_REF"
		git clone "$BCACHEFS_TOOLS_URL" "$root/tools" || exit 1
		git -C "$root/tools" checkout "$BCACHEFS_TOOLS_REF" || {
			echo "overlay/apply.sh: pinned ref $BCACHEFS_TOOLS_REF not found - update the pin (see overlay/README.md)" >&2
			exit 1
		}
	else
		echo "overlay/apply.sh: $root/tools/Makefile not found and git(1) unavailable to clone" >&2
		exit 1
	fi
fi

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
