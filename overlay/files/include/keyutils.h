/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _FREEBSD_KEYUTILS_STUB_H
#define _FREEBSD_KEYUTILS_STUB_H
/*
 * Minimal libkeyutils replacement (no FreeBSD port exists). Constants and
 * prototypes mirror libkeyutils/keyutils.h; implementations in
 * c_src/keyutils_stub.c return -1/ENOSYS - see the header of that file for
 * why that is acceptable (keyring is only used for encrypted-FS key
 * management).
 */
#include <sys/types.h>

typedef int32_t key_serial_t;
typedef uint32_t key_perm_t;

/* special keyring IDs */
#define KEY_SPEC_THREAD_KEYRING		-1
#define KEY_SPEC_PROCESS_KEYRING	-2
#define KEY_SPEC_SESSION_KEYRING	-3
#define KEY_SPEC_USER_KEYRING		-4
#define KEY_SPEC_USER_SESSION_KEYRING	-5
#define KEY_SPEC_GROUP_KEYRING		-6
#define KEY_SPEC_REQKEY_AUTH_KEY	-7
#define KEY_SPEC_POSSESSION_KEYRING	-8

/* keyctl() command numbers (subset; values as on Linux) */
#define KEYCTL_GET_KEYRING_ID		0
#define KEYCTL_JOIN_SESSION_KEYRING	1
#define KEYCTL_UPDATE			2
#define KEYCTL_REVOKE			3
#define KEYCTL_CHOWN			4
#define KEYCTL_SETPERM			5
#define KEYCTL_DESCRIBE			6
#define KEYCTL_CLEAR			7
#define KEYCTL_LINK			8
#define KEYCTL_UNLINK			9
#define KEYCTL_SEARCH			10
#define KEYCTL_READ			11
#define KEYCTL_INSTANTIATE		12
#define KEYCTL_INSTANTIATE_IOV		13
#define KEYCTL_NEGATE			14
#define KEYCTL_SET_REQKEY_KEYRING	15
#define KEYCTL_SET_TIMEOUT		16
#define KEYCTL_ASSUME_AUTHORITY		17

key_serial_t add_key(const char *type, const char *description,
		     const void *payload, size_t plen, key_serial_t ring);
key_serial_t request_key(const char *type, const char *description,
			 const char *callout_info, key_serial_t dest);
long keyctl(int cmd, ...);
key_serial_t keyctl_search(key_serial_t ring, const char *type,
			   const char *description, key_serial_t dest);
long keyctl_read(key_serial_t id, void *buf, size_t buflen);
long keyctl_update(key_serial_t id, const void *payload, size_t plen);
long keyctl_revoke(key_serial_t id);
long keyctl_unlink(key_serial_t id, key_serial_t ring);
long keyctl_link(key_serial_t id, key_serial_t ring);
long keyctl_clear(key_serial_t ring);
long keyctl_instantiate(key_serial_t id, const void *payload, size_t plen,
			key_serial_t ring);

#endif /* _FREEBSD_KEYUTILS_STUB_H */
