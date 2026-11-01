/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _BCACHEFS_TOOLS_FREEBSD_COMPAT_H
#define _BCACHEFS_TOOLS_FREEBSD_COMPAT_H
/*
 * FreeBSD userspace shims for the glibc-isms of the C sources.
 * Force-included from c_src/autoconf.h (overlay/patches/002), so every
 * translation unit - and bindgen, which force-includes autoconf.h too -
 * sees the same mapping.
 */
/*
 * Neutralize <sys/ioccom.h>: FreeBSD's _IOC/_IO/_IOR/_IOW share names with
 * Linux's but encode differently (dir bits swapped, 13- vs 14-bit size).
 * The bcachefs ioctl ABI must keep its Linux numbers (checked by static
 * asserts against Rust), and no BSD macro-encoded ioctl is used in the
 * compiled sources (the geom DIOCG* numbers are spelled out numerically in
 * include/linux/fs.h). Predefining the header's guard keeps it inert.
 */
#define _SYS_IOCCOM_H_

#include <sys/types.h>		/* makedev(): on Linux via <sys/sysmacros.h> */

/*
 * glibc's <sys/types.h> gives loff_t under _GNU_SOURCE; FreeBSD has no
 * loff_t at all. Same beast as off_t with _FILE_OFFSET_BITS=64.
 */
typedef off_t loff_t;

/*
 * Pull in <malloc_np.h> before the tree's linux/compiler.h defines its
 * __malloc annotation macro: the header declares real jemalloc-compat
 * symbols named __malloc/__free, which the macro would otherwise shred.
 * Including it early also arms the include guard for linux/slab.h's
 * later <malloc.h> (malloc_usable_size lives here on FreeBSD).
 */
#include <malloc_np.h>

/*
 * glibc's <sys/types.h> defines this on little-endian hosts; the
 * cstruct-generated headers use it to pick bitfield member order.
 */
#define __LITTLE_ENDIAN_BITFIELD	1

/*
 * glibc has preadv2/pwritev2 (Linux 4.6+); FreeBSD only preadv/pwritev.
 * linux/blkdev.c's sync fops pass RWF_SYNC for REQ_FUA writes and then
 * fdatasync() in sync_check() regardless - so dropping the flag is
 * semantically inert.
 */
#ifndef RWF_SYNC
#define RWF_SYNC 0
#endif
#define preadv2(fd, iov, iovcnt, offset, flags) \
	preadv(fd, iov, iovcnt, offset)
#define pwritev2(fd, iov, iovcnt, offset, flags) \
	pwritev(fd, iov, iovcnt, offset)

/*
 * No fallocate(2) on FreeBSD. The only userspace C caller is REQ_OP_DISCARD
 * in linux/blkdev.c (PUNCH_HOLE|KEEP_SIZE), whose result is ignored -
 * discard is advisory. Implemented via fspacectl(2) SPACECTL_DEALLOC; other
 * modes report EOPNOTSUPP. (fs/vfs/io.c also references FALLOC_FL_* flags,
 * but that file compiles out under NO_BCACHEFS_FS.)
 */
#define FALLOC_FL_KEEP_SIZE		0x01
#define FALLOC_FL_PUNCH_HOLE		0x02
#define FALLOC_FL_COLLAPSE_RANGE		0x08
#define FALLOC_FL_ZERO_RANGE		0x10
#define FALLOC_FL_INSERT_RANGE		0x20
#define FALLOC_FL_UNSHARE_RANGE		0x40
int bch_fallocate_freebsd(int fd, int mode, off_t offset, off_t len);
#define fallocate(fd, mode, offset, len) \
	bch_fallocate_freebsd(fd, mode, offset, len)

#endif /* _BCACHEFS_TOOLS_FREEBSD_COMPAT_H */
