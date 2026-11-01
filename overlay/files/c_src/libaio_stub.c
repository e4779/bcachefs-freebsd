/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Linux AIO stub (see include/libaio.h). io_setup() returns -ENOSYS, which
 * linux/blkdev.c's aio_init() handles by io_fallback() to the synchronous
 * preadv/pwritev fops - upstream's own fallback path, exercised whenever
 * the kernel lacks AIO. Nothing else here should ever run.
 */
#include <errno.h>
#include <stddef.h>
#include <sys/types.h>

#include <libaio.h>

int io_setup(unsigned nr_events, io_context_t *ctx)
{
	(void)nr_events; (void)ctx;
	return -ENOSYS;
}

int io_destroy(io_context_t ctx) { (void)ctx; return -ENOSYS; }

int io_submit(io_context_t ctx, long nr, struct iocb *iocbs[])
{
	(void)ctx; (void)nr; (void)iocbs;
	return -ENOSYS;
}

int io_cancel(io_context_t ctx, struct iocb *iocb, struct io_event *evt)
{
	(void)ctx; (void)iocb; (void)evt;
	return -ENOSYS;
}

int io_getevents(io_context_t ctx, long min_nr, long nr,
		 struct io_event *events, struct timespec *timeout)
{
	(void)ctx; (void)min_nr; (void)nr; (void)events; (void)timeout;
	return -ENOSYS;
}
