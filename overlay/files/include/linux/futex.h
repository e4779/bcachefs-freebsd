/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_FUTEX_SHADOW_H
#define _FREEBSD_LINUX_FUTEX_SHADOW_H
/*
 * glibc (2.39+) exposes futex()/FUTEX_* directly; FreeBSD's equivalent is
 * _umtx_op(2). include/linux/bit_spinlock.h waits/wakes 32-bit words -
 * UMTX_OP_WAIT_UINT/WAKE with the same semantics, and the PRIVATE variants
 * map 1:1 (the locks in question are process-private by construction).
 */
#include <errno.h>
#include <stdint.h>
#include <time.h>
#include <sys/types.h>
#include <sys/umtx.h>

#define FUTEX_WAIT		0
#define FUTEX_WAKE		1
#define FUTEX_PRIVATE_FLAG	128
#define FUTEX_WAIT_PRIVATE	(FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
#define FUTEX_WAKE_PRIVATE	(FUTEX_WAKE | FUTEX_PRIVATE_FLAG)

static inline int futex(uint32_t *uaddr, int op, uint32_t val,
			const struct timespec *timeout, uint32_t *uaddr2,
			uint32_t val3)
{
	int umtx_op;

	switch (op & ~FUTEX_PRIVATE_FLAG) {
	case FUTEX_WAIT:
		umtx_op = (op & FUTEX_PRIVATE_FLAG)
			? UMTX_OP_WAIT_UINT_PRIVATE : UMTX_OP_WAIT_UINT;
		return _umtx_op(uaddr, umtx_op, val,
				(void *)(uintptr_t)timeout, NULL);
	case FUTEX_WAKE:
		umtx_op = (op & FUTEX_PRIVATE_FLAG)
			? UMTX_OP_WAKE_PRIVATE : UMTX_OP_WAKE;
		return _umtx_op(uaddr, umtx_op, val, NULL, NULL);
	default:
		return -ENOSYS;
	}
}

#endif
