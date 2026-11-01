/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _BCACHEFS_TOOLS_FREEBSD_COMPAT_H
#define _BCACHEFS_TOOLS_FREEBSD_COMPAT_H
/*
 * FreeBSD userspace shims for the glibc-isms of the C sources.
 * Force-included from c_src/autoconf.h (overlay/patches/002), so every
 * translation unit - and bindgen, which force-includes autoconf.h too -
 * sees the same mapping.
 */
#include <sys/types.h>		/* makedev(): on Linux via <sys/sysmacros.h> */

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
 * discard is advisory. Implemented via fcntl(F_FRESP); other modes
 * report EOPNOTSUPP. (fs/vfs/io.c also references FALLOC_FL_* flags, but
 * that file compiles out under NO_BCACHEFS_FS.)
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
