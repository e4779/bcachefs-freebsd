/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_ASM_ERRNO_SHADOW_H
#define _FREEBSD_ASM_ERRNO_SHADOW_H
/* glibc's <asm/errno.h> is a redirect to <asm-generic/errno.h>, which adds
 * kernel-only errno numbers; the userspace build compares host errno
 * values, which <errno.h> already supplies on FreeBSD. */
#include <errno.h>
#endif
