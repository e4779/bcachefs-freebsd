/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_ASM_IOCTL_SHADOW_H
#define _FREEBSD_ASM_IOCTL_SHADOW_H
/*
 * Linux UAPI asm-generic/ioctl.h, verbatim encodings. bcachefs's ioctl ABI
 * (and the Rust static asserts over it) requires these exact numbers; the
 * FreeBSD variants of the same macro names are kept out of the way (see
 * c_src/freebsd_compat.h).
 */
#define _IOC_NRBITS	8
#define _IOC_TYPEBITS	8
#define _IOC_SIZEBITS	14
#define _IOC_DIRBITS	2

#define _IOC_NRSHIFT	0
#define _IOC_TYPESHIFT	(_IOC_NRSHIFT + _IOC_NRBITS)
#define _IOC_SIZESHIFT	(_IOC_TYPESHIFT + _IOC_TYPEBITS)
#define _IOC_DIRSHIFT	(_IOC_SIZESHIFT + _IOC_SIZEBITS)

#define _IOC_NRMASK	((1 << _IOC_NRBITS) - 1)
#define _IOC_TYPEMASK	((1 << _IOC_TYPEBITS) - 1)
#define _IOC_SIZEMASK	((1 << _IOC_SIZEBITS) - 1)
#define _IOC_DIRMASK	((1 << _IOC_DIRBITS) - 1)

#define _IOC_NONE	0U
#define _IOC_WRITE	1U
#define _IOC_READ	2U

#define _IOC(dir, type, nr, size) \
	(((dir)  << _IOC_DIRSHIFT) | \
	 ((type) << _IOC_TYPESHIFT) | \
	 ((nr)   << _IOC_NRSHIFT) | \
	 ((size) << _IOC_SIZESHIFT))

extern unsigned int __invalid_size_argument_for_IOC;

#define _IO(type, nr)		_IOC(_IOC_NONE, (type), (nr), 0)
#define _IOR(type, nr, size)	_IOC(_IOC_READ, (type), (nr), sizeof(size))
#define _IOW(type, nr, size)	_IOC(_IOC_WRITE, (type), (nr), sizeof(size))
#define _IOWR(type, nr, size)	_IOC(_IOC_READ | _IOC_WRITE, (type), (nr), sizeof(size))

#define _IOC_DIR(nr)		(((nr) >> _IOC_DIRSHIFT) & _IOC_DIRMASK)
#define _IOC_TYPE(nr)		(((nr) >> _IOC_TYPESHIFT) & _IOC_TYPEMASK)
#define _IOC_NR(nr)		(((nr) >> _IOC_NRSHIFT) & _IOC_NRMASK)
#define _IOC_SIZE(nr)		(((nr) >> _IOC_SIZESHIFT) & _IOC_SIZEMASK)

#endif
