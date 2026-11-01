/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_FIEMAP_SHADOW_H
#define _FREEBSD_LINUX_FIEMAP_SHADOW_H
/*
 * Linux UAPI linux/fiemap.h: needed by c_src/rust_shims.h, which exports
 * FS_IOC_FIEMAP to Rust as a compiler-evaluated constant. The structs are
 * ABI-relevant only if a FIEMAP ioctl is ever issued - on FreeBSD it will
 * answer ENOTTY; the FUSE code paths use bcachefs's own extent walking.
 */
#include <linux/types.h>
#include <sys/ioctl.h>

struct fiemap_extent {
	__u64 fe_logical;	/* logical offset in bytes for the start */
	__u64 fe_physical;	/* physical offset in bytes for the start */
	__u64 fe_length;	/* length in bytes for this extent */
	__u64 fe_reserved64[2];
	__u32 fe_flags;		/* FIEMAP_EXTENT_* flags for this extent */
	__u32 fe_reserved32[2];
};

struct fiemap {
	__u64 fm_start;		/* logical offset (inclusive) at which to start */
	__u64 fm_length;	/* logical length of the boom which to map */
	__u32 fm_flags;		/* FIEMAP_FLAG_* */
	__u32 fm_mapped_extents;/* number of extents that were mapped */
	__u32 fm_extent_count;	/* size of fm_extents array */
	__u32 fm_reserved;
	struct fiemap_extent fm_extents[]; /* array of mapped extents */
};

#define FIEMAP_MAX_OFFSET	(~0ULL)

#define FIEMAP_FLAG_SYNC	0x0001 /* sync file data before map */
#define FIEMAP_FLAG_XATTR	0x0002 /* map extended attribute tree */
#define FIEMAP_FLAG_CACHE	0x0004 /* request caching of the extents */

#define FIEMAP_EXTENT_LAST		0x0001 /* last extent in the file */
#define FIEMAP_EXTENT_UNKNOWN		0x0002 /* extent location unknown */
#define FIEMAP_EXTENT_DELALLOC		0x0004 /* extent is delayed allocation */
#define FIEMAP_EXTENT_ENCODED		0x0008 /* encoded extent */
#define FIEMAP_EXTENT_DATA_ENCRYPTED	0x0010
#define FIEMAP_EXTENT_NOT_ALIGNED	0x0020
#define FIEMAP_EXTENT_DATA_INLINE	0x0040
#define FIEMAP_EXTENT_DATA_TAIL		0x0080
#define FIEMAP_EXTENT_UNWRITTEN		0x0100
#define FIEMAP_EXTENT_MERGED		0x0200
#define FIEMAP_EXTENT_SHARED		0x0400

#define FS_IOC_FIEMAP	_IOWR('f', 11, struct fiemap)

#endif
