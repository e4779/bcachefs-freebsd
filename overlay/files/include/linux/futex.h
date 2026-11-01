/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_FUTEX_SHADOW_H
#define _FREEBSD_LINUX_FUTEX_SHADOW_H
/*
 * glibc (2.39+) exposes futex()/FUTEX_* directly; FreeBSD's equivalent is
 * _umtx_op(2). include/linux/bit_spinlock.h waits/wakes 32-bit words -
 * UMTX_OP_WAIT_UINT/WAKE with the same semantics, and the PRIVATE variants
 * map 1:1 (the locks in question are process-private by construction).
 *
 * linux/shrinker.c additionally uses FUTEX_WAIT_BITSET: an absolute timeout
 * against CLOCK_MONOTONIC - struct _umtx_time with UMTX_ABSTIME expresses
 * exactly that (passing sizeof(struct _umtx_time) as uaddr2 tells the
 * kernel that uaddr1 points to a _umtx_time rather than a bare timespec).
 * The bit mask (val3) is not translated: the only caller waits with ~0, and
 * a plain FUTEX_WAKE wakes such a waiter; bitmask-granular waking is not
 * expressible in _umtx_op and nothing in tools would exercise it.
 */
#include <errno.h>
#include <stdint.h>
#include <time.h>
#include <sys/types.h>
#include <sys/umtx.h>

#define FUTEX_WAIT		0
#define FUTEX_WAKE		1
#define FUTEX_WAIT_BITSET	9	/* Linux UAPI number */
#define FUTEX_PRIVATE_FLAG	128
#define FUTEX_WAIT_PRIVATE	(FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
#define FUTEX_WAKE_PRIVATE	(FUTEX_WAKE | FUTEX_PRIVATE_FLAG)

/*
 * _umtx_op(2) returns the errno value directly; Linux futex(2) returns -1
 * and sets errno. Convert: shrinker.c's timeout loop reads errno
 * (ETIMEDOUT); every other caller (bit_spinlock.h, sched.c) ignores the
 * return value.
 */
static inline int futex(uint32_t *uaddr, int op, uint32_t val,
			const struct timespec *timeout, uint32_t *uaddr2,
			uint32_t val3)
{
	int umtx_op, ret;

	switch (op & ~FUTEX_PRIVATE_FLAG) {
	case FUTEX_WAIT:
		umtx_op = (op & FUTEX_PRIVATE_FLAG)
			? UMTX_OP_WAIT_UINT_PRIVATE : UMTX_OP_WAIT_UINT;
		ret = _umtx_op(uaddr, umtx_op, val,
			       (void *)(uintptr_t)timeout, NULL);
		break;
	case FUTEX_WAIT_BITSET: {
		struct _umtx_time umt = {
			._timeout	= *timeout,
			._flags		= UMTX_ABSTIME,
			._clockid	= CLOCK_MONOTONIC,
		};
		umtx_op = (op & FUTEX_PRIVATE_FLAG)
			? UMTX_OP_WAIT_UINT_PRIVATE : UMTX_OP_WAIT_UINT;
		ret = _umtx_op(uaddr, umtx_op, val, &umt,
			       (void *)(uintptr_t)sizeof(umt));
		break;
	}
	case FUTEX_WAKE:
		umtx_op = (op & FUTEX_PRIVATE_FLAG)
			? UMTX_OP_WAKE_PRIVATE : UMTX_OP_WAKE;
		ret = _umtx_op(uaddr, umtx_op, val, NULL, NULL);
		break;
	default:
		ret = ENOSYS;
		break;
	}

	if (ret) {
		errno = ret;
		return -1;
	}
	return 0;
}

#endif
