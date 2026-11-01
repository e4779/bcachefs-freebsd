/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_FS_SHADOW_H
#define _FREEBSD_LINUX_FS_SHADOW_H
/*
 * glibc's <linux/fs.h> is kernel UAPI; the userspace build uses it for the
 * block-device ioctls. The FreeBSD geom(4) DIOCG* ioctls cover the same
 * ground with matching argument shapes (pointer to 64-bit / unsigned).
 *
 * The numbers are spelled out, not derived: <sys/disk.h> drags
 * sys/kerneldump.h -> sys/conf.h (2-arg LIST_HEAD vs the tree's linux
 * list.h), and _IOR() itself must stay the Linux encoding for bcachefs's
 * own ioctl ABI - see include/asm/ioctl.h. Values verified against
 * sys/disk.h on FreeBSD 15.1 amd64:
 *
 *	DIOCGMEDIASIZE	_IOR('d', 129, off_t)  = 0x40086481
 *	DIOCGSECTORSIZE	_IOR('d', 128, u_int)  = 0x40046480
 */
#define BLKGETSIZE64	0x40086481U		/* u64* <- off_t* bytes */
#define BLKSSZGET	0x40046480U		/* int*  <- u_int* */
#define BLKPBSZGET	0x40046480U		/* approximation: no PBSZ ioctl */

#define BLKROTATIONAL	0x1280	/* Linux _IO(0x12,128); answers ENOTTY here */

#endif
