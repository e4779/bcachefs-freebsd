// SPDX-License-Identifier: GPL-2.0
//! FreeBSD shims for the Linux-shaped pieces of the Rust layer.
//!
//! Same rule the C overlay follows (c_src/freebsd_compat.h): the crate's
//! internal vocabulary stays Linux — MS_* mount-flag numbers, the shape of
//! ioctl(2)'s request argument, xattr names — and this module is where those
//! names exist on FreeBSD. Translation to the native API happens only at the
//! syscall edge, in the cfg(freebsd) branches of the call sites.
//!
//! The xattr helpers are here rather than inlined because extattr(2) differs
//! structurally from xattr(2), not just in naming: namespaces are syscall
//! arguments instead of name prefixes, and list output is length-prefixed
//! instead of NUL-separated.

use std::ffi::CStr;
use std::io;
use std::os::unix::ffi::OsStrExt;
use std::path::Path;

/// Linux MS_* mount flags (uapi/linux/mount.h values). Options are parsed
/// and carried in this namespace throughout the crate; they are translated
/// to FreeBSD MNT_* by [ms_to_mnt] only where mount(2) is actually called.
pub const MS_RDONLY: libc::c_ulong = 1;
pub const MS_NOSUID: libc::c_ulong = 2;
pub const MS_NODEV: libc::c_ulong = 4;
pub const MS_NOEXEC: libc::c_ulong = 8;
pub const MS_SYNCHRONOUS: libc::c_ulong = 16;
pub const MS_REMOUNT: libc::c_ulong = 32;
pub const MS_MANDLOCK: libc::c_ulong = 64;
pub const MS_DIRSYNC: libc::c_ulong = 128;
pub const MS_NOATIME: libc::c_ulong = 1024;
pub const MS_NODIRATIME: libc::c_ulong = 2048;
pub const MS_RELATIME: libc::c_ulong = 1 << 21;
pub const MS_STRICTATIME: libc::c_ulong = 1 << 24;

/// The request-argument type of ioctl(2). The Linux libc crate names it
/// `Ioctl`; FreeBSD's ioctl(2) takes the same unsigned long.
pub type IoctlRequest = libc::c_ulong;

/// XATTR_REPLACE (uapi/linux/xattr.h): the flag value libbcachefs's
/// bch2_xattr_set() interprets on the fuse xattr path (removing an xattr is
/// a set with a null value and XATTR_REPLACE, so a missing one is ENODATA).
/// The libc crate exports it only for linux_like targets; the value carried
/// here is the Linux ABI, which is the point.
pub const XATTR_REPLACE: libc::c_int = 2;

/// MNT_NODEV — in sys/mount.h but missing from the libc crate's FreeBSD
/// module (checked libc 0.2.186).
const MNT_NODEV: libc::c_int = 0x00000010;

/// Translate Linux MS_* mount flags to FreeBSD MNT_*.
///
/// Deliberately dropped, with reasons: MS_DIRSYNC (no per-dir sync),
/// MS_MANDLOCK (mandatory locking does not exist), MS_RELATIME /
/// MS_STRICTATIME / MS_NODIRATIME (FreeBSD atime policy is a single
/// MNT_NOATIME bit — set means never, unset means always).
pub fn ms_to_mnt(ms: libc::c_ulong) -> libc::c_int {
    let mut mnt: libc::c_int = 0;
    if ms & MS_RDONLY != 0 { mnt |= libc::MNT_RDONLY; }
    if ms & MS_NOSUID != 0 { mnt |= libc::MNT_NOSUID; }
    if ms & MS_NODEV != 0 { mnt |= MNT_NODEV; }
    if ms & MS_NOEXEC != 0 { mnt |= libc::MNT_NOEXEC; }
    if ms & MS_SYNCHRONOUS != 0 { mnt |= libc::MNT_SYNCHRONOUS; }
    if ms & MS_NOATIME != 0 { mnt |= libc::MNT_NOATIME; }
    mnt
}

// ---- xattr(2) -> extattr(2) --------------------------------------------
//
// Linux xattr names are "namespace.name"; FreeBSD extattr passes the
// namespace as a syscall argument and the name is bare. Mapping used here:
// "user.X" lives in EXTATTR_NAMESPACE_USER as "X"; any other name (bcachefs
// tools use namespace-less "bcachefs.*" names) is stored verbatim in the
// user namespace — extattr names accept dots.
//
// XattrFlags CREATE/REPLACE distinctions do not exist in extattr: set always
// creates or replaces, which is the behaviour of XattrFlags::empty().

/// Map a Linux-style attribute name to its EXTATTR_NAMESPACE_USER name.
fn user_ns_name(name: &CStr) -> &CStr {
    match name.to_bytes().strip_prefix(b"user.") {
        // SAFETY: rest borrows the same NUL-terminated buffer and excludes
        // only bytes before the terminator, so it is still NUL-terminated.
        Some(rest) => unsafe {
            CStr::from_bytes_with_nul_unchecked(std::slice::from_raw_parts(
                rest.as_ptr(),
                rest.len() + 1,
            ))
        },
        None => name,
    }
}

fn ssize(r: libc::ssize_t) -> io::Result<usize> {
    if r < 0 { Err(io::Error::last_os_error()) } else { Ok(r as usize) }
}

fn zero(r: libc::c_int) -> io::Result<()> {
    if r != 0 { Err(io::Error::last_os_error()) } else { Ok(()) }
}

/// getxattr(3) on a path, following symlinks. An empty @buf returns the
/// attribute's size, as on Linux.
pub fn getxattr(path: &Path, name: &str, buf: &mut [u8]) -> io::Result<usize> {
    let path = std::ffi::CString::new(path.as_os_str().as_bytes())?;
    let name = std::ffi::CString::new(name)?;
    ssize(unsafe {
        libc::extattr_get_file(path.as_ptr(), libc::EXTATTR_NAMESPACE_USER,
                               user_ns_name(&name).as_ptr(),
                               buf.as_mut_ptr().cast(), buf.len())
    })
}

/// setxattr(3) on a path, following symlinks. extattr_set_file(2)
/// returns the bytes written (>= 0), not 0.
pub fn setxattr(path: &Path, name: &str, value: &[u8]) -> io::Result<()> {
    let path = std::ffi::CString::new(path.as_os_str().as_bytes())?;
    let name = std::ffi::CString::new(name)?;
    ssize(unsafe {
        libc::extattr_set_file(path.as_ptr(), libc::EXTATTR_NAMESPACE_USER,
                               user_ns_name(&name).as_ptr(),
                               value.as_ptr().cast(), value.len())
    })
    .map(|_| ())
}

/// removexattr(3) on a path; ENOATTR when absent (Linux ENODATA).
pub fn removexattr(path: &Path, name: &str) -> io::Result<()> {
    let path = std::ffi::CString::new(path.as_os_str().as_bytes())?;
    let name = std::ffi::CString::new(name)?;
    zero(unsafe {
        libc::extattr_delete_file(path.as_ptr(), libc::EXTATTR_NAMESPACE_USER,
                                  user_ns_name(&name).as_ptr())
    })
}

/// lgetxattr(3): @name on @path without following a final symlink.
pub fn lgetxattr(path: &CStr, name: &CStr, buf: &mut [u8]) -> io::Result<usize> {
    ssize(unsafe {
        libc::extattr_get_link(path.as_ptr(), libc::EXTATTR_NAMESPACE_USER,
                               user_ns_name(name).as_ptr(),
                               buf.as_mut_ptr().cast(), buf.len())
    })
}

/// llistxattr(3) equivalent: the user-namespace attribute names of @path
/// (not following a final symlink), NUL-separated and each prefixed
/// "user.", so Linux-shaped consumers (bch_xattr_type::from_name) parse
/// them unchanged. ERANGE when @buf is too small, as on Linux.
pub fn llistxattr(path: &CStr, buf: &mut [u8]) -> io::Result<usize> {
    // extattr_list_link answers in its own format: one length byte followed
    // by that many name bytes, repeated. Names can't contain NULs, so the
    // rewrite to the Linux format is unambiguous.
    let mut raw = vec![0u8; buf.len()];
    let n = ssize(unsafe {
        libc::extattr_list_link(path.as_ptr(), libc::EXTATTR_NAMESPACE_USER,
                                raw.as_mut_ptr().cast(), raw.len())
    })?;

    let mut total = 0usize;
    let mut pos = 0usize;
    while pos < n {
        let len = raw[pos] as usize;
        pos += 1;
        let name = &raw[pos..pos + len];
        pos += len;

        let entry = b"user.".len() + name.len() + 1;
        if total + entry > buf.len() {
            return Err(io::Error::from_raw_os_error(libc::ERANGE));
        }
        buf[total..total + b"user.".len()].copy_from_slice(b"user.");
        total += b"user.".len();
        buf[total..total + name.len()].copy_from_slice(name);
        total += name.len();
        buf[total] = 0;
        total += 1;
    }
    Ok(total)
}
