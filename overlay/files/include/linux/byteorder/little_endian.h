/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_LINUX_BYTEORDER_LITTLE_ENDIAN_H
#define _FREEBSD_LINUX_BYTEORDER_LITTLE_ENDIAN_H
/*
 * Linux UAPI linux/byteorder/little_endian.h for a little-endian host:
 * le conversions are identity, be conversions are byte swaps. The
 * __force annotations are sparse-only and drop out in plain compilation.
 */
#include <linux/types.h>
#include <linux/swab.h>

static inline __le64 __cpu_to_le64(__u64 x) { return (__le64)x; }
static inline __u64 __le64_to_cpu(__le64 x) { return (__u64)x; }
static inline __be64 __cpu_to_be64(__u64 x) { return (__be64)__swab64(x); }
static inline __u64 __be64_to_cpu(__be64 x) { return __swab64((__u64)x); }

static inline __le32 __cpu_to_le32(__u32 x) { return (__le32)x; }
static inline __u32 __le32_to_cpu(__le32 x) { return (__u32)x; }
static inline __be32 __cpu_to_be32(__u32 x) { return (__be32)__swab32(x); }
static inline __u32 __be32_to_cpu(__be32 x) { return __swab32((__u32)x); }

static inline __le16 __cpu_to_le16(__u16 x) { return (__le16)x; }
static inline __u16 __le16_to_cpu(__le16 x) { return (__u16)x; }
static inline __be16 __cpu_to_be16(__u16 x) { return (__be16)__swab16(x); }
static inline __u16 __be16_to_cpu(__be16 x) { return __swab16((__u16)x); }

static inline __le64 __cpu_to_le64p(const __le64 *p) { return *p; }
static inline __le32 __cpu_to_le32p(const __le32 *p) { return *p; }
static inline __le16 __cpu_to_le16p(const __le16 *p) { return *p; }
static inline __be64 __cpu_to_be64p(const __be64 *p) { return __swab64((__u64)*p); }
static inline __be32 __cpu_to_be32p(const __be32 *p) { return __swab32((__u32)*p); }
static inline __be16 __cpu_to_be16p(const __be16 *p) { return __swab16((__u16)*p); }

static inline __u64 __le64_to_cpup(const __le64 *p) { return (__u64)*p; }
static inline __u32 __le32_to_cpup(const __le32 *p) { return (__u32)*p; }
static inline __u16 __le16_to_cpup(const __le16 *p) { return (__u16)*p; }
static inline __u64 __be64_to_cpup(const __be64 *p) { return __swab64((__u64)*p); }
static inline __u32 __be32_to_cpup(const __be32 *p) { return __swab32((__u32)*p); }
static inline __u16 __be16_to_cpup(const __be16 *p) { return __swab16((__u16)*p); }

/* little-endian in-place: no-ops */
static inline void __le16_to_cpus(__le16 *p) { (void)p; }
static inline void __le32_to_cpus(__le32 *p) { (void)p; }
static inline void __le64_to_cpus(__le64 *p) { (void)p; }
static inline void __cpu_to_le16s(__le16 *p) { (void)p; }
static inline void __cpu_to_le32s(__le32 *p) { (void)p; }
static inline void __cpu_to_le64s(__le64 *p) { (void)p; }

/* big-endian in-place: swaps */
static inline void __be16_to_cpus(__be16 *p) { __swab16s((__u16 *)p); }
static inline void __be32_to_cpus(__be32 *p) { __swab32s((__u32 *)p); }
static inline void __be64_to_cpus(__be64 *p) { __swab64s((__u64 *)p); }
static inline void __cpu_to_be16s(__be16 *p) { __swab16s((__u16 *)p); }
static inline void __cpu_to_be32s(__be32 *p) { __swab32s((__u32 *)p); }
static inline void __cpu_to_be64s(__be64 *p) { __swab64s((__u64 *)p); }

#endif
