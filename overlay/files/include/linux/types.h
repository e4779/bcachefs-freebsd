/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_TYPES_SHADOW_H
#define _FREEBSD_LINUX_TYPES_SHADOW_H
/*
 * Linux UAPI linux/types.h as glibc ships it: pulls the fixed-width set
 * from <asm/types.h> and adds the endian-annotated aliases. Sparse's
 * __bitwise does not exist in plain userspace compilation - on glibc it
 * expands to nothing unless sparse (__CHECKER__) runs.
 */
#include <asm/types.h>

#ifndef __ASSEMBLY__

#ifdef __CHECKER__
#define __bitwise	__attribute__((bitwise))
#else
#define __bitwise
#endif

typedef __u16 __bitwise __le16;
typedef __u16 __bitwise __be16;
typedef __u32 __bitwise __le32;
typedef __u32 __bitwise __be32;
typedef __u64 __bitwise __le64;
typedef __u64 __bitwise __be64;

typedef __u16 __bitwise __sum16;
typedef __u32 __bitwise __wsum;

#define __aligned_u64	__u64 __attribute__((aligned(8)))
#define __aligned_be64	__be64 __attribute__((aligned(8)))
#define __aligned_le64	__le64 __attribute__((aligned(8)))

#endif /* __ASSEMBLY__ */
#endif
