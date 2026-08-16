---
aliases:
  - /blog/note_class/mit6.s081_7/
title: "Locks and Parallelism in XV6"
date: 2025-03-04T11:42:43+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

> Fast performance → Slow performance

<!--more-->

## Hardware Advancements

By the early 2000s, single-core CPU performance had hit a bottleneck. A single CPU could no longer meet demand—computer scientists needed to find a way to break through. What did we want? Faster performance and more compute power. Here's a comparison: if you push a single CPU harder for performance, its power consumption rises dramatically. But adding another CPU not only boosts performance—the power increase stays acceptable. Thus, the multi-core era arrived.

## Why Use Locks?

First, why do we need locks in multi-core systems? What even is a lock? It starts with applications wanting to use multiple CPU cores. We know that using multiple cores improves performance. If an application runs on multiple CPU cores and makes system calls, the kernel must handle **parallel** system calls. When system calls run in **parallel** across multiple cores, they may **concurrently** access shared data structures or data in the kernel. When accessing data structures in parallel—say, one core reads while another writes—we need locks to **coordinate updates to shared data** and ensure data **consistency**. So, we need locks to control and guarantee that shared data is correct.

But reality is somewhat disappointing. We want parallelism for high performance—we want system calls to execute in parallel on different CPU cores. But if those system calls touch shared data, we need locks, and locks force serial execution. So in the end, locks limit the very performance we sought.

We find ourselves in a contradiction: for correctness we need locks, but for performance locks are terrible. This is what I mean by `fast performance → slow performance`.

First, let's understand where locks are used. Earlier I said a lock is a *token* that **controls and ensures shared data**. What is this data? In truth, a lock is less like a token and more like a warehouse keeper—whenever someone wants to modify what's in the warehouse, the keeper steps in to manage the process and prevent problems.

Let's look at `kfree()` in xv6:

```c
acquire(&kmem.lock)
r->next = kmem.freelist;
kmem.freelist = r;
release(&kmem.lock)
```

The code between `acquire` and `release` is commonly called the **critical section**. That's the data we need to manage.

To ensure data correctness, we use locks to manage the **critical section**. When shared data is read and written simultaneously without a lock, a **race condition** may occur, causing the program to malfunction. For example: in `r->next = kmem.freelist;`, if CPU0 and CPU1 both execute this at the same time, `r->next` might point to CPU0's data or CPU1's data—a catastrophic error we really don't want to see.

**Race conditions** are particularly annoying. Notably, they can manifest in different ways and they might or might not happen. We'd rather they never happen.

Let's get more concrete about locks. A lock is an object, just like other objects in the kernel. There's a struct called `lock` containing fields that maintain the lock's state. Locks have a very intuitive API:

- **acquire** takes a pointer to a lock. acquire ensures that at any given time, only one process can successfully grab the lock.
- **release** also takes a pointer to a lock. Other processes trying to acquire the lock must wait until the holding process calls release.

So, locks prevent **race conditions** on data structures and protect resources.

## When to Use Locks

Before using locks, we need to understand one **mechanism** — the atomic operation.
Simply put, `i += 1` in a program involves three actions:

```asm
ld  t0, 0(a0)
addi t0, t0, 1
sd  t0, 0(a0)
```

An atomic operation turns these three into a single operation.

The protected **data** is called a **critical section** because shared data updates are typically performed atomically here. Basically, if there are multiple instructions between `acquire` and `release`, they either all execute together or none of them execute at all. So the CPU can never peek into the middle of a **critical section**—unlike a **race condition**, where multiple CPUs interleave their execution within the critical section. This avoids race conditions.

Modern programs typically have many locks. In fact, XV6 has plenty of locks. Why so many? Because locks serialize code execution. If two processors want to enter the same **critical section**, only one succeeds at a time; the other waits until the first exits. So execution here is entirely serial—no parallelism whatsoever.

Imagine the kernel had just one **big lock**—let's call it the **big kernel lock**. Virtually all system calls would be protected and serialized by this big lock. System calls would follow this flow: one acquires the big kernel lock, does its work, releases it, returns to user space—only then can the next system call proceed. If an application makes parallel system calls, they'd execute serially because we only have one lock. So typically, operating systems like XV6 have multiple locks to achieve some degree of concurrency. If two system calls use two different locks, they can run fully in parallel.

Clearly, locks limit concurrency and limit performance. There's no perfect rule for when to use locks. The rule of thumb: *if two processes access a shared data structure and one updates it, you need a lock on that structure.* The contradiction is that sometimes this rule is too strict, and sometimes it's too lax. Beyond shared data, locks are needed in other contexts too—for example, with `printf`: if we pass it a string, XV6 tries to output the entire string atomically rather than interleaving output with another process's `printf`. Even though there's no shared data structure here, a lock is still useful because we want `printf` output to be serialized.

Therefore, locks should be associated with **operations** rather than data—linked to the order of operations.

## Lock Properties and Deadlock

- *Locks prevent lost updates*. Recall our earlier `kfree` example in `kalloc.c`: a lost update means we lost an update to a memory page in `kfree`. Without a lock, during a race condition, a memory page might never be added to the freelist. With a lock, we don't lose that update.
- *Locks make operations atomic*. We've covered that the region between lock/unlock is the critical section, and all operations within it execute as one atomic operation.
- *Locks maintain the **invariant** of shared data structures*. A shared data structure remains unchanged if no process modifies it. If a process acquires a lock and performs updates, the data invariant is temporarily broken, but after releasing the lock, the invariant is restored.

> A data structure's **invariant** is relative across different CPUs: for example, CPU0 changes the data structure—it sees a change—but CPU1 sees it as unchanged.

**Deadlock** is something you frequently encounter when using locks. The simplest deadlock scenario: first `acquire` a lock, enter the **critical section**; inside the critical section, `acquire` the same lock again; the second `acquire` must wait for the first lock to be `release`d before it can proceed, but without proceeding you can never reach the first `release`—so the program is stuck forever. That's a deadlock. It reminds me of the famous **Dining Philosophers Problem**. A real-world analogy: gridlock in traffic.

The solution to deadlock: if you have multiple locks, order them. All operations must acquire locks in the same order. Then release them in the same order.

## Locks and Performance

We want better performance, so we want more locks—but that introduces a lot of work.

The typical development flow is:

- Start with a **coarse-grained lock** (big lock).
- Test the program to see whether it can use multiple cores.
- If it can, you're done—your lock design is good enough. If not, it means there's lock contention: multiple processes are trying to grab the same lock, causing serialized execution and poor performance. Then you need to refactor.

In this flow, the testing phase is important. It's possible that a module uses a coarse-grained lock but isn't called in parallel very often—in that case there's no need to refactor, because refactoring involves significant work and adds complexity to the code. If it's not necessary, don't refactor.

## Implementing Locks

I have detailed notes [here]().

Key things to keep in mind:
!!! *Don't turn the lock itself into a critical section* !!!
!!! *Don't turn the lock itself into a critical section* !!!
!!! *Don't turn the lock itself into a critical section* !!!

So spinlocks need to handle two kinds of concurrency: concurrency between different CPUs, and concurrency between interrupts and normal code on the same CPU. We need to disable interrupts inside `acquire`.

## Sleep & Wakeup

The last thing `sleep` does is re-acquire the condition lock.

## Summary

The hardware performance bottleneck means that when a single CPU core can no longer meet application demands, computer scientists must find ways to break through. In multi-core systems, locks control and ensure shared data updates to maintain data consistency. However, locks also limit performance by serializing system calls. To address this, we can consider using more locks to achieve some degree of concurrent execution. But this introduces significant work, requiring careful design and consideration of lock usage.

In practice, we can test the program to determine whether lock design needs refactoring. If the program can execute in parallel, the lock design may be good enough; if not, refactoring is needed to improve concurrency performance.

In summary, hardware performance bottlenecks drove computer scientists to find breakthroughs, and locks are one approach to resolving shared data races. However, locks also limit performance, so careful design and consideration are essential.

Reasons to use locks:

1. **Ensure resource sharing correctness**: When multiple threads access shared resources simultaneously, locks ensure that only one thread accesses the resource at a time, preventing desynchronization and errors.
2. **Prevent resource contention**: When multiple threads access shared resources simultaneously, contention may lead to unexpected results. Locks prevent resource contention and ensure correct resource usage.
3. **Improve code reusability**: Locks can encapsulate multi-threaded access code into thread-safe units, improving code reusability.
4. **Reduce development difficulty**: Locks simplify what developers need to worry about, lowering development difficulty.
5. **Ensure thread safety**: Locks guarantee thread safety in programs, preventing errors and exceptions caused by thread-unsafe behavior.
