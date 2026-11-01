/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_CONST_SHADOW_H
#define _FREEBSD_LINUX_CONST_SHADOW_H
/*
 * Linux UAPI linux/const.h: token-pasting helpers the shim headers use
 * (BIT(), _BITUL() etc. chain through here).
 */
#ifdef __ASSEMBLY__
#define _AC(X,Y)			X
#define _AC_C(X,Y)			X
#else
#define __AC(X,Y)			(X##Y)
#define __AC_C(X,Y)			(X##Y)
#define _AC(X,Y)			__AC(X,Y)
#define _AC_C(X,Y)			__AC_C(X,Y)
#endif

#define _AT(T,X)			((T)(X))

#define _BITUL(x)			(_AC(1,UL) << (x))
#define _BITULL(x)			(_AC(1,ULL) << (x))

#ifndef _UL
#define _UL(x)				(_AC(x, UL))
#define _ULL(x)				(_AC(x, ULL))
#endif

#define UL(x)				(_UL(x))
#define ULL(x)				(_ULL(x))

#endif
