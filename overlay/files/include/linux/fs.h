/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_FS_SHADOW_H
#define _FREEBSD_LINUX_FS_SHADOW_H
/*
 * glibc's <linux/fs.h> is kernel UAPI; the userspace build uses it for the
 * block-device ioctls. On FreeBSD the geom(4) DIOCG* ioctls cover the
 * same ground with argument shapes that match (pointer to 64-bit /
 * pointer to unsigned int), so the Linux names alias onto them.
 *
 * BLKPBSZGET has no direct FreeBSD equivalent (physical block size);
 * DIOCGSECTORSIZE is the sane approximation. BLKROTATIONAL has none at
 * all: keep the Linux x86-64 encoding so the constant exists for the Rust
 * export in c_src/rust_shims.h - the ioctl itself answers ENOTTY and the
 * caller must cope (probe falls back to "unknown").
 */
#include <sys/disk.h>		/* DIOCGMEDIASIZE, DIOCGSECTORSIZE */
#include <sys/ioctl.h>

#define BLKGETSIZE64	DIOCGMEDIASIZE		/* u64* <- off_t* (bytes) */
#define BLKSSZGET	DIOCGSECTORSIZE		/* int*  <- u_int* */
#define BLKPBSZGET	DIOCGSECTORSIZE		/* approximation */

#define BLKROTATIONAL	0x1280			/* _IO(0x12,128); ENOTTY here */

#endif
