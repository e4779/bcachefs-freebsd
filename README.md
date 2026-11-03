# bcachefs-freebsd

Native userspace access to [bcachefs](https://bcachefs.org/) filesystems on FreeBSD: a port of [bcachefs-tools](https://github.com/koverstreet/bcachefs-tools) with its FUSE frontend, built and running on FreeBSD 15.x.

## Status (2026-11-03)

**Sprint A complete — all acceptance gates passed:**

- **G0**: the `bcachefs` binary builds and runs on FreeBSD (`v1.39.7-1539-gd48ba1a7a1d0-dirty`)
- **G1**: `format` + full offline `fsck` clean on test images
- **G2**: pjdfstest: **0 failed / 380 passed / 10 expected failures** (chflags — no file-flags in the FUSE protocol) / 125 skipped; fsck clean after the suite
- **G3**: metadata performance vs an NFS-exported-Linux-VM bridge: `create+close` 0.01 ms/file, `rename` 0.19 ms/file (bridge baseline: 12.8 ms/file sync-create)
- Dirty-filesystem ro-mount experiment: honest `EROFS` refusal (no journal replay attempts) on a read-only backend, zero device writes, superblocks bit-exact

**Known open issues:** daemon died silently once mid-write-storm (cause under investigation — stderr logging patch 056 added); single-threaded FUSE session (n_threads=1); no chflags/xattr-over-FUSE; snapshots not exercised.

## Upstream pins

- bcachefs-tools: **d48ba1a7a1d03afed5a20d1cce8189e9ae9a848d** (koverstreet/bcachefs-tools)
- fuser: **koverstreet/fuser@8819589** (branch `destroy-before-reply`, via `[patch.crates-io]`)

## Build

```sh
pkg install pkgconf liburcu libuuid liblz4 fusefs-libs3 pjdfstest gmake rust
# Rust >= 1.85 (rustup or lang/rust); bindgen via cargo
git clone https://github.com/koverstreet/bcachefs-tools tools
git -C tools checkout d48ba1a
./overlay/apply.sh
cd tools && gmake -j2
```

All FreeBSD changes live in `overlay/` (56 patches, applied by the stamp-idempotent `apply.sh`); `tools/` stays a pristine clone. Mount: `doas ./tools/bcachefs mount -o fuse /dev/mdN /mnt`.

## Layout

- `overlay/` — patches + shim files over the pristine upstream clone
- `scripts/` — test/bench/control helpers (incl. `rlimit-run.sh`, an rctl memory-cap wrapper)
- `bench/` — metadata benchmarks + pjdfstest config with expected-failures
- `docs/` — engineering notes: full build chronicle (04a/05a), G2 root-cause analyses (11a), council decisions

## Caveats

This is a port in progress. Do not trust it with data you care about: the on-disk format is irreversible (1.39 incompat bits), fsck exists here and on Linux only, and crash recovery is not yet hardened. The upstream tools carry GPL-2.0; so do the patches here.
