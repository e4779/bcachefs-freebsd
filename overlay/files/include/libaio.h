/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LIBAIO_STUB_H
#define _FREEBSD_LIBAIO_STUB_H
/*
 * Linux libaio API subset used by linux/blkdev.c. Only the types and names
 * must satisfy compilation: io_setup() is stubbed to -ENOSYS (see
 * c_src/libaio_stub.c), which makes blkdev.c fall back to its synchronous
 * preadv/pwritev fops - no AIO request is ever built or submitted, so the
 * struct layout here never crosses into the kernel.
 */
#include <sys/types.h>
#include <sys/uio.h>

struct io_context;
typedef struct io_context *io_context_t;

struct io_event {
	void		*data;
	unsigned long	obj;
	long		res;
	long		res2;
};

struct io_iocb_common {
	char		*buf;
	unsigned	 nbytes;
	long long	 offset;
};

struct iocb {
	void		*data;		/* returned in io_event.data */
	short		 aio_lio_opcode;
	short		 aio_reqprio;
	int		 aio_fildes;
	unsigned	 aio_rw_flags;
	union {
		struct io_iocb_common	c;
	} u;
};

#define IO_CMD_PREAD	0
#define IO_CMD_PWRITE	1
#define IO_CMD_FSYNC	2
#define IO_CMD_FDSYNC	3
#define IO_CMD_POLL	5
#define IO_CMD_NOOP	6
#define IO_CMD_PREADV	7
#define IO_CMD_PWRITEV	8

int io_setup(unsigned nr_events, io_context_t *ctx);
int io_destroy(io_context_t ctx);
int io_submit(io_context_t ctx, long nr, struct iocb *iocbs[]);
int io_cancel(io_context_t ctx, struct iocb *iocb, struct io_event *evt);
int io_getevents(io_context_t ctx, long min_nr, long nr,
		 struct io_event *events, struct timespec *timeout);

#endif /* _FREEBSD_LIBAIO_STUB_H */
