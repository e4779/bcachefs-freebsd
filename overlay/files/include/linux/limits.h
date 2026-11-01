/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_LIMITS_SHADOW_H
#define _FREEBSD_LINUX_LIMITS_SHADOW_H
/*
 * Linux UAPI linux/limits.h, plus the max-value family the kernel's
 * internal linux/limits.h carries (shim headers such as overflow.h and
 * generic-radix-tree.h expect both). Everything guarded: host <limits.h>
 * may already have defined some of these with the same values.
 */
#ifndef PATH_MAX
#define PATH_MAX	4096	/* # chars in a path name including nul */
#endif
#define NAME_MAX	255	/* # chars in a file name */
#define NGROUPS_MAX	65536	/* max # of supplementary groups for users */
#define ARG_MAX		131072	/* base value for stack limit */
#define LINK_MAX	127	/* # links a file may have */
#define MAX_CANON	255	/* size of the canonical input queue */
#define MAX_INPUT	255	/* size of the type-ahead buffer */
#define PIPE_BUF	4096	/* # bytes in atomic write to a pipe */
#define XATTR_NAME_MAX	255	/* # chars in an extended attribute name */
#define XATTR_SIZE_MAX	65536	/* size of an extended attribute value (64k) */
#define XATTR_LIST_MAX	65536	/* size of list of extended attribute names (64k) */
#define RTSIG_MAX	32

#ifndef U8_MAX
#define U8_MAX		((unsigned char)~0U)
#endif
#ifndef S8_MAX
#define S8_MAX		((signed char)(U8_MAX ^ ~0U))
#endif
#ifndef S8_MIN
#define S8_MIN		((signed char)(-S8_MAX - 1))
#endif
#ifndef U16_MAX
#define U16_MAX		((unsigned short)~0U)
#endif
#ifndef S16_MAX
#define S16_MAX		((short)(U16_MAX ^ ~0U))
#endif
#ifndef S16_MIN
#define S16_MIN		((short)(-S16_MAX - 1))
#endif
#ifndef U32_MAX
#define U32_MAX		((unsigned int)~0U)
#endif
#ifndef S32_MAX
#define S32_MAX		((int)(U32_MAX ^ ~0U))
#endif
#ifndef S32_MIN
#define S32_MIN		((int)(-S32_MAX - 1))
#endif
#ifndef U64_MAX
#define U64_MAX		((unsigned long long)~0ULL)
#endif
#ifndef S64_MAX
#define S64_MAX		((long long)(U64_MAX ^ ~0ULL))
#endif
#ifndef S64_MIN
#define S64_MIN		((long long)(-S64_MAX - 1))
#endif
#ifndef UINT_MAX
#define UINT_MAX	U32_MAX
#endif
#ifndef INT_MAX
#define INT_MAX		S32_MAX
#endif
#ifndef INT_MIN
#define INT_MIN		S32_MIN
#endif
#ifndef ULONG_MAX
#define ULONG_MAX	((unsigned long)~0UL)
#endif
#ifndef LONG_MAX
#define LONG_MAX	((long)(ULONG_MAX ^ ~0UL))
#endif
#ifndef LONG_MIN
#define LONG_MIN	((long)(-LONG_MAX - 1))
#endif
#ifndef LLONG_MAX
#define LLONG_MAX	S64_MAX
#endif
#ifndef LLONG_MIN
#define LLONG_MIN	S64_MIN
#endif
#ifndef USHRT_MAX
#define USHRT_MAX	U16_MAX
#endif
#ifndef SHRT_MAX
#define SHRT_MAX	S16_MAX
#endif
#ifndef SHRT_MIN
#define SHRT_MIN	S16_MIN
#endif
#ifndef SIZE_MAX
#define SIZE_MAX	(~(size_t)0)
#endif
#endif
