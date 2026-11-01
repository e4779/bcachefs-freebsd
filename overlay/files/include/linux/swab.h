/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_SWAB_SHADOW_H
#define _FREEBSD_LINUX_SWAB_SHADOW_H
/*
 * Linux UAPI linux/swab.h, host-compiler edition: the kernel's
 * __builtin_constant_p() branching collapses to the same code after
 * optimization, so only the plain helpers are spelled out.
 */
#include <linux/types.h>

#define ___constant_swab16(x) ((__u16)( \
	(((__u16)(x) & (__u16)0x00ffU) << 8) | \
	(((__u16)(x) & (__u16)0xff00U) >> 8)))

#define ___constant_swab32(x) ((__u32)( \
	(((__u32)(x) & (__u32)0x000000ffUL) << 24) | \
	(((__u32)(x) & (__u32)0x0000ff00UL) <<  8) | \
	(((__u32)(x) & (__u32)0x00ff0000UL) >>  8) | \
	(((__u32)(x) & (__u32)0xff000000UL) >> 24)))

#define ___constant_swab64(x) ((__u64)( \
	(((__u64)(x) & (__u64)0x00000000000000ffULL) << 56) | \
	(((__u64)(x) & (__u64)0x000000000000ff00ULL) << 40) | \
	(((__u64)(x) & (__u64)0x0000000000ff0000ULL) << 24) | \
	(((__u64)(x) & (__u64)0x00000000ff000000ULL) <<  8) | \
	(((__u64)(x) & (__u64)0x000000ff00000000ULL) >>  8) | \
	(((__u64)(x) & (__u64)0x0000ff0000000000ULL) >> 24) | \
	(((__u64)(x) & (__u64)0x00ff000000000000ULL) >> 40) | \
	(((__u64)(x) & (__u64)0xff00000000000000ULL) >> 56)))

/* swap halves of each 16-bit pair */
#define ___constant_swahw32(x) ((__u32)( \
	(((__u32)(x) & (__u32)0x0000ffffUL) << 16) | \
	(((__u32)(x) & (__u32)0xffff0000UL) >> 16)))

/* swap bytes within each 16-bit half */
#define ___constant_swahb32(x) ((__u32)( \
	(((__u32)(x) & (__u32)0x00ff00ffUL) << 8) | \
	(((__u32)(x) & (__u32)0xff00ff00UL) >> 8)))

static inline __u16 __fswab16(__u16 val) { return ___constant_swab16(val); }
static inline __u32 __fswab32(__u32 val) { return ___constant_swab32(val); }
static inline __u64 __fswab64(__u64 val) { return ___constant_swab64(val); }
static inline __u32 __fswahw32(__u32 val) { return ___constant_swahw32(val); }
static inline __u32 __fswahb32(__u32 val) { return ___constant_swahb32(val); }

static inline void __fswab16s(__u16 *p) { *p = __fswab16(*p); }
static inline void __fswab32s(__u32 *p) { *p = __fswab32(*p); }
static inline void __fswab64s(__u64 *p) { *p = __fswab64(*p); }

#define __swab16(x)	__fswab16(x)
#define __swab32(x)	__fswab32(x)
#define __swab64(x)	__fswab64(x)
#define __swahw32(x)	__fswahw32(x)
#define __swahb32(x)	__fswahb32(x)
#define __swab16s(x)	__fswab16s(x)
#define __swab32s(x)	__fswab32s(x)
#define __swab64s(x)	__fswab64s(x)
#define __swahw32s(x)	do { *(x) = __fswahw32(*(x)); } while (0)
#define __swahb32s(x)	do { *(x) = __fswahb32(*(x)); } while (0)

#endif
