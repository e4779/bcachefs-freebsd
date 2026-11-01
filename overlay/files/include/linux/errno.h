/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_ERRNO_SHADOW_H
#define _FREEBSD_LINUX_ERRNO_SHADOW_H
/*
 * glibc's <linux/errno.h>/<asm/errno.h> carry the kernel-only errno names
 * on top of the shared ones. The shared names keep host values (they cross
 * host syscalls); the Linux-only names take their Linux numbers - they are
 * only compared within this program (bch error mapping).
 */
#include <errno.h>

/* Linux-only errno names FreeBSD lacks (values as on Linux; these never
 * cross a host syscall - they feed bch's own error mapping). */
#ifndef ENONET
#define ENONET		64	/* Machine is not on the network */
#endif
#ifndef ENODATA
#define ENODATA		61	/* No data available */
#endif
#ifndef ENOATTR
#define ENOATTR		ENODATA	/* Attribute not found (BSD name for it) */
#endif
#ifndef ENOSR
#define ENOSR		63	/* Out of streams resources */
#endif
#ifndef ENOSTR
#define ENOSTR		64	/* Device not a stream */
#endif
#ifndef ETIME
#define ETIME		62	/* Timer expired */
#endif
#ifndef ETOOMANYREFS
#define ETOOMANYREFS	109	/* Too many references: cannot splice */
#endif
#ifndef ENOKEY
#define ENOKEY		126	/* Required key not available */
#endif
#ifndef EKEYEXPIRED
#define EKEYEXPIRED	127	/* Key has expired */
#endif
#ifndef EKEYREVOKED
#define EKEYREVOKED	128	/* Key has been revoked */
#endif
#ifndef EKEYREJECTED
#define EKEYREJECTED	129	/* Key was rejected by service */
#endif

#endif
