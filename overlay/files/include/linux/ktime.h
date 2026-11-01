/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_KTIME_SHADOW_H
#define _FREEBSD_LINUX_KTIME_SHADOW_H
/* Minimal kernel ktime surface (fs/util/eytzinger.c includes the header;
 * the userspace build only needs the type). */
#include <linux/types.h>

typedef __u64 ktime_t;

#define KTIME_MAX			((s64)~0ULL >> 1)
#define KTIME_SEC_MAX			(KTIME_MAX / NSEC_PER_SEC)

#endif
