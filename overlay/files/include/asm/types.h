/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_ASM_TYPES_SHADOW_H
#define _FREEBSD_ASM_TYPES_SHADOW_H
/*
 * Linux UAPI asm/types.h (asm-generic/int-ll64.h): the fixed-width
 * integer typedefs everything in the tree chains through via
 * <linux/types.h>. The LL64 model is what the UAPI guarantees on every
 * architecture - and what bindgen sees on Linux.
 */
#ifndef __ASSEMBLY__

typedef unsigned char	__u8;
typedef signed char	__s8;

typedef unsigned short	__u16;
typedef signed short	__s16;

typedef unsigned int	__u32;
typedef signed int	__s32;

typedef unsigned long long	__u64;
typedef signed long long	__s64;

#endif /* __ASSEMBLY__ */
#endif
