---
title: "同步原语与锁"
date: 2024-08-26T10:48:24+08:00
draft: false  # Is this a draft? true/false！！！
author: ["Yeelight"]
math: false
toc: true
comments: true
---

# **基本原语**

在 Go 语言中除了自带的Groutine、channel等，其实在 sync 包中也提供了用于同步的一些基本原语，包括常见的 `sync.Mutex`、`sync.RWMutex`、`sync.WaitGroup`、`sync.Once` 、 `sync.Pool` 和 `sync.Cond` ，需要对其中的底层来分析其使用方法。

# Mutex

Go 语言的 `sync.Mutex` 由两个字段 `state` 和 `sema` 组成。其中 `state` 表示当前互斥锁的状态，而 `sema` 是用于控制锁状态的信号量。

```go
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
//
// In the terminology of [the Go memory model],
// the n'th call to [Mutex.Unlock] “synchronizes before” the m'th call to [Mutex.Lock]
// for any n < m.
// A successful call to [Mutex.TryLock] is equivalent to a call to Lock.
// A failed call to TryLock does not establish any “synchronizes before”
// relation at all.
type Mutex struct {
 state int32
 sema  uint32
}
```

`Mutex` 可以说是在Go中作一个**可携带的对象**具体说就是每个协程在处理时都需要看看有没有`mutex`，随后就依据`mutex`的状态携带着使用，但是mutex也有显示goroutinr的

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/1659dc07-004d-4382-bdb0-efbda5b634dd/image.png)

## 状态

mutex的状态在go中是一个十分复杂和有趣的，下面是Go中定义的

看上去是蛮复杂的，其实可以分为两个部分，第一部分是`mutex`的定义的状态位，是用在`mutex`的`state`字段，第二部分是对`mutex`的具体状态的实现**normal and starvation**

先来看看mutex中的状态位

- `mutexLocked` — 表示互斥锁的锁定状态；
- `mutexWoken` — 表示从正常模式被从唤醒；
- `mutexStarving` — 当前的互斥锁进入饥饿状态；
- `waitersCount` — 当前互斥锁上等待的 Goroutine 个数；

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/07ddfaeb-f1ea-4b98-ad30-66734fc233fd/274e35e4-b55f-4344-b601-c3dddce1d1fb/image.png)

再来看看`mutex`的具体状态的实现

## **正常模式和饥饿模式**

### 正常模式 (Normal Mode)

1. 新到达的`goroutine`会尝试立即获取锁，如果获取不到则加入等待队列。
2. 当锁被释放时，会唤醒队列中的第一个等待者。但是被唤醒的`goroutine`不会直接获得锁，而是需要与新到达的`goroutine`竞争。
3. 新到达的`goroutine`往往有优势(因为它们已经在CPU上运行),所以被唤醒的`goroutine`可能会再次失败并被放到队列前端。
4. 这种模式下吞吐量较高,因为一个`goroutine`可能连续多次获得锁。

### 饥饿模式 (Starvation Mode)

1. 如果一个等待者等待时间超过**1ms**,`mutex`会切换到饥饿模式。
2. 在饥饿模式下,`mutex`的所有权会直接从解锁的`goroutine`移交给队列头部的等待者。
3. 新到达的`goroutine`不会尝试获取锁,即使看起来锁是未被持有的。它们会直接进入等待队列尾部。
4. 如果一个等待者获得锁后发现自己是最后一个等待者,或者它的等待时间小于1ms,会将`mutex`切换回正常模式。
5. 这种模式可以防止尾部延迟的极端情况,保证公平性,但overall吞吐量会降低。

这两种模式的切换是自动的,旨在平衡公平性和性能。正常模式favors性能,而饥饿模式确保了公平性,防止goroutine被长时间"饿死"。

## 使用

再使用过程中，互斥锁就只有两个接口方法，说说互斥锁的加锁和解锁过程

```go
// A Locker represents an object that can be locked and unlocked.
type Locker interface {
 Lock()
 Unlock()
}
```

再操作系统中lock的使用一般是原子的，自旋的，这是对lock的基本使用，而在go中的mutex也是用这样的形式作lock

### **加锁**

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

`Lock()` 方法首先尝试通过原子操作快速获取锁。如果失败,则进入慢速路径 `lockSlow()`。

### **解锁**

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

这里有一个我好奇的问题，为什么有 `_ = m.state`？

我发现，对于这一行是一个没有具体使用的代码，给我的感觉是可有可无的代码，但我觉得既然出现这个代码，就一定有自己的存在的意义，先来看看`Unlocak`的具体代码逻辑:

1. race detection 竞态检测：在该逻辑判断中竞态检测器是一个动态分析工具，用于在运行时检测数据竞争。它可以跟踪所有**内存访问**和**同步事件**（如锁的获取和释放）。
2. 寻找`m.state` ：`_ = m.state`
3. `race.Release` 函数的作用：这个函数告诉竞态检测器，当前 goroutine 正在释放对特定内存位置的独占访问，使用`unsafe.Pointer(m)`可以将 mutex 的地址转换为一个不安全指针，允许竞态检测器识别具体的内存位置。
4. 使用快速路径尝试通过原子操作解锁 mutex，`-mutexLocked`。
5. 如果 `new != 0`，说明可能有等待的 goroutine 或者 mutex 处于特殊状态（如饥饿模式），需要进入慢速路径。

`_ = m.state` 这行代码看起来没有实际作用，但实际上它在启用了竞态检测器（race detector）的情况下扮演着重要角色。

1. `_ = m.state` 的目的：
    - 这行代码的主要目的是告诉竞态检测器，我们正在"读取" `m.state`。虽然我们实际上并没有使用这个值（因为我们将其赋给了空白标识符 `_`），但对竞态检测器来说，这被视为对 `m.state` 的一次**读操作**。
2. 为什么这样做：
    - 在 Unlock 操作中，我们实际上是要修改 `m.state`（通过后面的 `atomic.AddInt32` 操作）。通过先"读取" `m.state`，我们确保竞态检测器能够正确地追踪到这个变量的所有访问，包括即将进行的写操作。这有助于检测到可能的竞态条件，例如在一个 goroutine 解锁的同时，另一个 goroutine 正在读取或修改 mutex 的状态。
3. `race.Release` 调用：
    - 这个调用进一步通知竞态检测器，我们正在释放对 mutex 的独占访问。

`_ = m.state` 这行代码是一个巧妙的技巧，用于确保竞态检测器能够全面地监控 mutex 状态的所有访问。它不影响实际的程序逻辑，但在启用竞态检测时提供了额外的安全检查。

其中，主要说一下 `lockSlow()`和`unlockSlow(new)` ，因为这个是自旋的主要实现

该方法的主体是一个非常大 for 循环，这里将它分成几个部分介绍获取锁的过程：

1. 判断当前 Goroutine 能否进入自旋；
2. 通过自旋等待互斥锁的释放；
3. 计算互斥锁的最新状态；
4. 更新互斥锁的状态并获取锁；

在`lockSlow()`

- 如果是正常模式下，这段代码会设置唤醒和饥饿标记、重置迭代次数并重新执行获取锁的循环；
- 如果是饥饿模式下，当前 Goroutine 会获得互斥锁，如果等待队列中只存在当前 Goroutine，互斥锁还会从饥饿模式中退出；

在`unlockSlow(new)`

- 在正常模式下，上面的函数会使用如下所示的处理过程：
  - 如果互斥锁不存在等待者或者互斥锁的 `mutexLocked`、`mutexStarving`、`mutexWoken` 状态不都为 0，那么当前方法可以直接返回，不需要唤醒其他等待者；
  - 如果互斥锁存在等待者，会通过 `sync.runtime_Semrelease` 唤醒等待者并移交锁的所有权；
- 在饥饿模式下，上述代码会直接调用 `sync.runtime_Semrelease` 将当前锁交给下一个正在尝试获取锁的等待者，等待者被唤醒后会得到锁，在这时互斥锁还不会退出饥饿状态；

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
