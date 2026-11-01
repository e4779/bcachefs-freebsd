/* SPDX-License-Identifier: GPL-2.0 */
/*
 * libkeyutils stub (see include/keyutils.h). The kernel keyring does not
 * exist on FreeBSD; the only C consumer is bch2_add_key() in c_src/crypto.c
 * (encrypted-filesystem key management), which dies on the -ENOSYS return -
 * acceptable: encrypted FSes are out of scope for the test-mount plan.
 */
#include <errno.h>
#include <sys/types.h>

#include <keyutils.h>

static key_serial_t keyutils_enosys(void)
{
	errno = ENOSYS;
	return -1;
}

key_serial_t add_key(const char *type, const char *description,
		     const void *payload, size_t plen, key_serial_t ring)
{
	(void)type; (void)description; (void)payload; (void)plen; (void)ring;
	return keyutils_enosys();
}

key_serial_t keyctl_search(key_serial_t ring, const char *type,
			   const char *description, key_serial_t dest)
{
	(void)ring; (void)type; (void)description; (void)dest;
	return keyutils_enosys();
}

long keyctl(int cmd, ...)
{
	(void)cmd;
	return keyutils_enosys();
}

long keyctl_read(key_serial_t id, void *buf, size_t buflen)
{
	(void)id; (void)buf; (void)buflen;
	return keyutils_enosys();
}

long keyctl_update(key_serial_t id, const void *payload, size_t plen)
{
	(void)id; (void)payload; (void)plen;
	return keyutils_enosys();
}

long keyctl_revoke(key_serial_t id) { (void)id; return keyutils_enosys(); }
long keyctl_unlink(key_serial_t id, key_serial_t ring)
{
	(void)id; (void)ring;
	return keyutils_enosys();
}
long keyctl_link(key_serial_t id, key_serial_t ring)
{
	(void)id; (void)ring;
	return keyutils_enosys();
}
long keyctl_clear(key_serial_t ring) { (void)ring; return keyutils_enosys(); }
long keyctl_instantiate(key_serial_t id, const void *payload, size_t plen,
			key_serial_t ring)
{
	(void)id; (void)payload; (void)plen; (void)ring;
	return keyutils_enosys();
}
