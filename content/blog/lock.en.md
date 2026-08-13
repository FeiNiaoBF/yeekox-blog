---
title: "Sync Primitives and Locks"
date: 2024-08-26T10:48:24+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - Golang
  - Concurrency
  - Locks
---

# **Basic Primitives**

In Go, beyond built-in goroutines and channels, the `sync` package also provides basic synchronization primitives, including `sync.Mutex`, `sync.RWMutex`, `sync.WaitGroup`, `sync.Once`, `sync.Pool`, and `sync.Cond`. We need to analyze their underlying implementation to understand how they work.

# Mutex

Go's `sync.Mutex` consists of two fields: `state` and `sema`. `state` represents the current state of the mutex, while `sema` is a semaphore used to control the lock state.

```go
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
//
// In the terminology of [the Go memory model],
// the n'th call to [Mutex.Unlock] "synchronizes before" the m'th call to [Mutex.Lock]
// for any n < m.
// A successful call to [Mutex.TryLock] is equivalent to a call to Lock.
// A failed call to TryLock does not establish any "synchronizes before"
// relation at all.
type Mutex struct {
	state int32
	sema  uint32
}
```

`Mutex` can be thought of as a **carryable object** in Go — specifically, each goroutine checks whether there's a `mutex` and carries it based on its state. However, mutex also exposes goroutine-related behavior.

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/1659dc07-004d-4382-bdb0-efbda5b634dd/image.png)

## State

The mutex state in Go is quite complex and interesting. Here's how Go defines it:

While it looks complex, it can be divided into two parts: the first is the state bits defined in the `mutex`'s `state` field; the second is the implementation of specific mutex states — **normal and starvation**.

Let's first look at the mutex state bits:

- `mutexLocked` — indicates the mutex is locked;
- `mutexWoken` — indicates being woken from normal mode;
- `mutexStarving` — the mutex has entered starvation mode;
- `waitersCount` — number of goroutines waiting on the mutex;

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/274e35e4-b55f-4344-b601-c3dddce1d1fb/image.png)

Now let's look at the specific state implementations:

## **Normal Mode and Starvation Mode**

### Normal Mode

1. Newly arrived goroutines attempt to acquire the lock immediately. If they can't get it, they join the wait queue.
2. When the lock is released, the first waiter in the queue is woken up. However, the woken goroutine doesn't directly get the lock — it must compete with newly arriving goroutines.
3. Newly arriving goroutines often have an advantage (since they're already running on the CPU), so the woken goroutine may fail again and be placed at the front of the queue.
4. This mode achieves higher throughput, as one goroutine can acquire the lock multiple times in succession.

### Starvation Mode

1. If a waiter has been waiting for more than **1ms**, the mutex switches to starvation mode.
2. In starvation mode, ownership of the mutex is directly handed from the unlocking goroutine to the waiter at the front of the queue.
3. Newly arriving goroutines don't attempt to acquire the lock, even if it appears unlocked. Instead, they go directly to the tail of the wait queue.
4. If a waiter acquiring the lock finds it's the last waiter, or its wait time is less than 1ms, it switches the mutex back to normal mode.
5. This mode prevents pathological tail latency, ensuring fairness, though overall throughput decreases.

The switch between these two modes is automatic, designed to balance fairness and performance. Normal mode favors performance, while starvation mode ensures fairness and prevents goroutines from being "starved" for long periods.

## Usage

In practice, the mutex exposes only two interface methods. Let's discuss the locking and unlocking process:

```go
// A Locker represents an object that can be locked and unlocked.
type Locker interface {
	Lock()
	Unlock()
}
```

In operating systems, lock usage is generally atomic and spin-based — this is the basic approach to locking. Go's mutex also uses this pattern for locking.

### **Lock**

```go
// Lock locks m.
// If the lock is already in use, the calling goroutine
// blocks until the mutex is available.
func (m *Mutex) Lock() {
	// Fast path: grab unlocked mutex.
	if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
		if race.Enabled {
			race.Acquire(unsafe.Pointer(m))
		}
		return
	}
	// Slow path (outlined so that the fast path can be inlined)
	m.lockSlow()
}
```

`Lock()` first attempts to acquire the lock quickly via an atomic operation. If that fails, it enters the slow path `lockSlow()`.

### **Unlock**

```go
// Unlock unlocks m.
// It is a run-time error if m is not locked on entry to Unlock.
//
// A locked [Mutex] is not associated with a particular goroutine.
// It is allowed for one goroutine to lock a Mutex and then
// arrange for another goroutine to unlock it.
func (m *Mutex) Unlock() {
	if race.Enabled {
		_ = m.state
		race.Release(unsafe.Pointer(m))
	}

	// Fast path: drop lock bit.
	new := atomic.AddInt32(&m.state, -mutexLocked)
	if new != 0 {
		// Outlined slow path to allow inlining the fast path.
		// To hide unlockSlow during tracing we skip one extra frame when tracing GoUnblock.
		m.unlockSlow(new)
	}
}
```

Here's a question I was curious about: why is there `_ = m.state`?

I found this line seems to be code without a concrete use — at first glance it feels like optional code. But since it exists, it must have a purpose. Let's first look at the `Unlock` logic:

1. Race detection: the race detector is a dynamic analysis tool for detecting data races at runtime. It tracks all **memory accesses** and **synchronization events** (such as lock acquisition and release).
2. Reading `m.state`: `_ = m.state`
3. The `race.Release` function: this tells the race detector that the current goroutine is releasing exclusive access to a specific memory location. Using `unsafe.Pointer(m)` converts the mutex address to an unsafe pointer, allowing the race detector to identify the specific memory location.
4. The fast path attempts to unlock the mutex via an atomic operation, using `-mutexLocked`.
5. If `new != 0`, it means there may be waiting goroutines or the mutex is in a special state (like starvation mode), requiring the slow path.

`_ = m.state` looks like it does nothing, but it actually plays an important role when the race detector is enabled.

1. The purpose of `_ = m.state`:
    - The main goal is to tell the race detector that we are "reading" `m.state`. Although we don't actually use this value (assigning it to the blank identifier `_`), the race detector treats this as a **read operation** on `m.state`.
2. Why do this:
    - In the Unlock operation, we're actually going to modify `m.state` (via the subsequent `atomic.AddInt32`). By "reading" `m.state` first, we ensure the race detector can correctly track all accesses to this variable, including the upcoming write. This helps detect potential race conditions, for example when one goroutine is unlocking while another is reading or modifying the mutex state.
3. The `race.Release` call:
    - This further notifies the race detector that we are releasing exclusive access to the mutex.

`_ = m.state` is a clever trick to ensure the race detector comprehensively monitors all accesses to the mutex state. It doesn't affect actual program logic, but provides additional safety checks when race detection is enabled.

Now, let's focus on `lockSlow()` and `unlockSlow(new)`, as these are where spin-based implementation primarily occurs.

This method's body is a very large for loop. Let's break it into parts describing the lock acquisition process:

1. Determine whether the current goroutine can enter spinning;
2. Wait for the mutex to be released via spinning;
3. Calculate the latest mutex state;
4. Update the mutex state and acquire the lock;

In `lockSlow()`:

- In normal mode, this code sets wakeup and starvation flags, resets the iteration count, and re-executes the lock acquisition loop;
- In starvation mode, the current goroutine acquires the mutex. If only the current goroutine exists in the wait queue, the mutex also exits starvation mode;

In `unlockSlow(new)`:

- In normal mode, the function above uses the following processing:
  - If the mutex has no waiters or the `mutexLocked`, `mutexStarving`, `mutexWoken` states are not all zero, the method can return directly without waking other waiters;
  - If the mutex has waiters, it calls `sync.runtime_Semrelease` to wake a waiter and transfer lock ownership;
- In starvation mode, the code directly calls `sync.runtime_Semrelease` to hand the current lock to the next waiter trying to acquire it. After the waiter is woken, it receives the lock, but the mutex doesn't exit starvation mode yet;

```go
const (
	mutexLocked = 1 << iota // mutex is locked
	mutexWoken
	mutexStarving
	mutexWaiterShift = iota

	// Mutex fairness.
	//
	// Mutex can be in 2 modes of operations: normal and starvation.
	// In normal mode waiters are queued in FIFO order, but a woken up waiter
	// does not own the mutex and competes with new arriving goroutines over
	// the ownership. New arriving goroutines have an advantage -- they are
	// already running on CPU and there can be lots of them, so a woken up
	// waiter has good chances of losing. In such case it is queued at front
	// of the wait queue. If a waiter fails to acquire the mutex for more than 1ms,
	// it switches mutex to the starvation mode.
	//
	// In starvation mode ownership of the mutex is directly handed off from
	// the unlocking goroutine to the waiter at the front of the queue.
	// New arriving goroutines don't try to acquire the mutex even if it appears
	// to be unlocked, and don't try to spin. Instead they queue themselves at
	// the tail of the wait queue.
	//
	// If a waiter receives ownership of the mutex and sees that either
	// (1) it is the last waiter in the queue, or (2) it waited for less than 1 m
	// it switches mutex back to normal operation mode.
	//
	// Normal mode has considerably better performance as a goroutine can acquire
	// a mutex several times in a row even if there are blocked waiters.
	// Starvation mode is important to prevent pathological cases of tail latency.
	starvationThresholdNs = 1e6
)
```