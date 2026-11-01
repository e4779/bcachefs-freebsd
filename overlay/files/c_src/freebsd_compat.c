/* SPDX-License-Identifier: GPL-2.0 */
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>

#include "freebsd_compat.h"

int bch_fallocate_freebsd(int fd, int mode, off_t offset, off_t len)
{
	if (mode == (FALLOC_FL_PUNCH_HOLE | FALLOC_FL_KEEP_SIZE)) {
		struct flock fl = {
			.l_whence	= SEEK_SET,
			.l_start	= offset,
			.l_len		= len,
		};
		return fcntl(fd, F_FRESP, &fl);
	}

	errno = EOPNOTSUPP;
	return -1;
}
