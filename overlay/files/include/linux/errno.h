/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_ERRNO_SHADOW_H
#define _FREEBSD_LINUX_ERRNO_SHADOW_H
/*
 * glibc's <linux/errno.h> is a thin include of <errno.h>; on the userspace
 * build path the codes are compared as host errno values, which is what we
 * want on FreeBSD too.
 */
#include <errno.h>
#endif
