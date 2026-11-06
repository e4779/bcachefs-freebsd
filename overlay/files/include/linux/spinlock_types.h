#ifndef __TOOLS_LINUX_SPINLOCK_H
#define __TOOLS_LINUX_SPINLOCK_H

#include <linux/atomic.h>
#include <linux/bug.h>
#include <pthread.h>

/*
 * Kernel raw spinlocks NEVER sleep: all ported code relies on that invariant
 * (short, non-sleeping critical sections). The first port revision used a
 * non-recursive pthread_mutex here, which turned any circular wait involving
 * e.g. six_lock wait_lock (fastpath wakeup vs slowpath holder) into a
 * permanent deadlock — the single FUSE reader wedged forever in
 * six_unlock_ip -> six_lock_wakeup (core dump 2026-11-06). A true spinlock
 * restores the kernel contract: waiters spin briefly instead of sleeping,
 * so would-be deadlocks degenerate into bounded contention. A zero value is
 * a valid unlocked FreeBSD pthread_spinlock (no INITIALIZER macro exists).
 */
typedef struct {
	pthread_spinlock_t lock;
} raw_spinlock_t;

#define __RAW_SPIN_LOCK_UNLOCKED(name)	(raw_spinlock_t) { .lock = { 0 } }

static inline void raw_spin_lock_init(raw_spinlock_t *lock)
{
	pthread_spin_init(&lock->lock, PTHREAD_PROCESS_PRIVATE);
}

static inline bool raw_spin_trylock(raw_spinlock_t *lock)
{
	return !pthread_spin_trylock(&lock->lock);
}

static inline void raw_spin_lock(raw_spinlock_t *lock)
{
	pthread_spin_lock(&lock->lock);
}

static inline void raw_spin_unlock(raw_spinlock_t *lock)
{
	pthread_spin_unlock(&lock->lock);
}

#define raw_spin_lock_irq(lock)		raw_spin_lock(lock)
#define raw_spin_unlock_irq(lock)	raw_spin_unlock(lock)

#define raw_spin_lock_irqsave(lock, flags)		\
do {						\
	flags = 0;					\
	raw_spin_lock(lock);				\
} while (0)

#define raw_spin_unlock_irqrestore(lock, flags) raw_spin_unlock(lock)

typedef raw_spinlock_t spinlock_t;

#define __SPIN_LOCK_UNLOCKED(name)	__RAW_SPIN_LOCK_UNLOCKED(name)

#define DEFINE_SPINLOCK(x)	spinlock_t x = __SPIN_LOCK_UNLOCKED(x)

#define spin_lock_init(lock)		raw_spin_lock_init(lock)
#define spin_lock(lock)			raw_spin_lock(lock)
#define spin_unlock(lock)		raw_spin_unlock(lock)

#define spin_lock_nested(lock, n)	spin_lock(lock)

#define spin_lock_bh(lock)		raw_spin_lock(lock)
#define spin_unlock_bh(lock)	raw_spin_unlock(lock)

#define spin_lock_irq(lock)		raw_spin_lock(lock)
#define spin_unlock_irq(lock)	raw_spin_unlock(lock)

#define spin_lock_irqsave(lock, flags)	raw_spin_lock_irqsave(lock, flags)
#define spin_unlock_irqrestore(lock, flags) raw_spin_unlock_irqrestore(lock, flags)
#define spin_trylock(lock)		raw_spin_trylock(lock)

#endif /* __TOOLS_LINUX_SPINLOCK_H */
