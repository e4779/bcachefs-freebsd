/* SPDX-License-Identifier: GPL-2.0 */
#include <errno.h>
#include <fcntl.h>
#include <stddef.h>

#include "freebsd_compat.h"

/*
 * REQ_OP_DISCARD (PUNCH_HOLE|KEEP_SIZE) maps to fspacectl(2)'s
 * SPACECTL_DEALLOC: zero the range and give the space back, size
 * unchanged - the same contract Linux's fallocate() gives for that
 * mode pair. The result is advisory, as discards are.
 */
int bch_fallocate_freebsd(int fd, int mode, off_t offset, off_t len)
{
	if (mode == (FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE)) {
		struct spacectl_range r = {
			.r_offset	= offset,
			.r_len		= len,
		};
		return fspacectl(fd, SPACECTL_DEALLOC, &r, 0, NULL);
	}

	errno = EOPNOTSUPP;
	return -1;
}
