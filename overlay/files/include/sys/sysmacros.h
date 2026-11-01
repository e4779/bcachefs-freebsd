/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_SYS_SYSMACROS_SHADOW_H
#define _FREEBSD_SYS_SYSMACROS_SHADOW_H
/*
 * <sys/sysmacros.h> is glibc-only (major()/minor()/makedev()); on FreeBSD
 * those live in <sys/types.h>. This file shadows the include for sources
 * that include it unconditionally (linux/blkdev.c, c_src/tools-util.c).
 */
#include <sys/types.h>
#endif
