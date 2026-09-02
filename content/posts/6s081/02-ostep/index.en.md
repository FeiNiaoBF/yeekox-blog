---
title: "Learning Operating Systems through XV6 (OSTEP)"
weight: 20
date: 2025-03-04T10:58:48+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

These notes follow OSTEP as the primary text.

Operating systems revolve around four major themes (from OSTEP). I'll work through them one by one.

<!--more-->


- CPU Virtualization
- Memory Virtualization
- Concurrency
- Persistence

## CPU Virtualization

## What Is a Process?

Informally (in my view), a `Process` is a program currently executing on the CPU, along with the resources it needs: memory, stack, data being read/written, and so on.

> Why do we need processes?

People often want a computer to run multiple programs at once. When using a computer or laptop, we simultaneously run a browser, email, games, a music player, and more. In reality, a typical system may have hundreds of processes running concurrently. If we can build such a system, users don't have to think about which CPU is available—it just works. So the question becomes: how do we achieve concurrent execution?

### Common Process Functions

[[fork() function]]

## OS Mechanisms

A mechanism is a low-level method or protocol inside the OS that provides some required capability—for example, **context switching**, which is a time-sharing mechanism.

On the other hand, a **policy** is a higher-level intelligent algorithm that makes decisions within the OS.

## Process Loading

In early (or simple) operating systems, loading was done eagerly—everything was loaded before running the program. Modern operating systems do this lazily: they only load code or data fragments when they are actually needed during execution.

## Process States

- **Running**: The process is executing on a processor—it is actively running instructions.
- **Ready**: The process is ready to run, but the OS has chosen not to run it at this moment for some reason.
- **Blocked**: The process has performed some operation and will not be ready to run until another event occurs. A common example: when a process issues an I/O request to a disk, it blocks so that other processes can use the processor.

![process](https://s2.loli.net/2023/07/09/auLEzkS2MKBCmp4.png)

## Process API

Modern operating systems provide the following five categories of API for developers and users:

- **Create**: The OS must include some way to create new processes. Typing a command in a shell or double-clicking an application icon calls the OS to create a new process and run the specified program.
- **Destroy**: Since there is an interface for creation, the system also provides one to forcibly destroy a process. Many processes exit on their own when done, of course, but if they don't, users may want to terminate them—so an interface to stop runaway processes is very useful.
- **Wait**: Sometimes it is useful to wait for a process to stop running, so some kind of wait interface is often provided.
- **Miscellaneous Control**: Beyond killing or waiting, other controls may exist. For example, most OSes provide a way to suspend a process (pause it for a while) and then resume it (let it continue running).
- **Status**: There are usually interfaces to obtain status information about a process—how long it has run, what state it is currently in, and so on.

## OS Isolation

1. A process is not the CPU itself, but it corresponds to a CPU—it lets you run computational tasks on the CPU. So, **applications cannot interact directly with the CPU; they can only interact with processes**.

> A CPU core runs one process for a while, then switches to another process and runs it for a while.

2. `exec` abstracts memory, allowing applications to run in a bounded, "enclosed" space.

3. Files essentially abstract the disk—using the File data structure to perform read/write operations on disk blocks.

> Q: When switching privileges, the instruction that sets that bit must be a privileged instruction. Since applications shouldn't be able to set that bit to kernel mode (i.e., '0'), applications cannot run privileged instructions. So that bit is protected.
> My question: when an application is running in user mode and control must switch from user mode to kernel mode, who flips the bit to 0 (kernel mode)?
> A: I think the control switch from user mode to kernel mode is managed by the CPU's internal privilege-level mechanism (machine mode? BIOS?).

![Hi](https://s2.loli.net/2023/12/02/t3qMXbhoLym165E.png)
> For example, whether it's a shell or another application, when it executes `fork` in user space, it doesn't directly call the corresponding OS function. Instead, it invokes the `ECALL` instruction and passes the number for `fork` as a parameter. ECALL then jumps into the kernel.

```
user.fork() --->> ECALL syscall() --->> kernel.fork()
```

> Q: Does `root` in Linux have full privileges?
> A: No—only specific privileges, more than a regular user.

### User/Kernel Mode Switching

We can think of user/kernel mode as the boundary separating user space from kernel space. Programs running in user space execute in user mode; programs in kernel space execute in kernel mode. The operating system resides in kernel space.

## Scheduling Algorithms
>
> You can't have your cake and eat it too.

In our daily work, we often have to carry out **reasonable allocation** of resources and time. This is a common management pattern in real life. For the operating system, the primary goal is managing CPU resource allocation.

We've learned about the role of **context**: when switching the process running on the CPU, we must first save the current process's state from registers (memory, registers, instruction pointer, PC, etc.) into main memory, then load the next process's state back into the CPU, placing its execution context into the registers.

### FIFO

First-in, first-out. This model has a premise: "processes arrive at the same time and have the same run time."

### SJF

### STCF

### Round Robin (RR)

### Multi-Level Feedback Queue (MLFQ)

[What's the difference between batch processing and stream processing?](https://www.zhihu.com/question/313869609)

[[Concurrency and Parallelism]]

# Memory Virtualization
>
> They are "invisible."

## Address Space

### Memory API
>
> Some common APIs in C.

- `malloc(size_t)`
- `free(void*)`
- `calloc()`
- `realloc()`

***Forgetting to free memory***
This is a very bad situation.

***Using your own memory incorrectly***

### Segmentation
>
> How do we support large address spaces?

## Thread Virtualization

Concurrency means multiple tasks execute alternately within the same time period—there may be temporal overlap, but they are not necessarily executing simultaneously. In concurrency, tasks may alternate through time-slicing or event-driven approaches.

Parallelism means multiple tasks execute at the exact same moment, typically requiring multiple processing units (such as multi-core processors or multiple compute nodes). In parallelism, multiple tasks can proceed simultaneously without temporal overlap.

### Threads

The difference between one worker doing all the work and two (or more) workers doing all the work. Scheduling shifts, working in rotation.

#### Critical Section

```asm
    11dd:   8b 05 31 2e 00 00       mov    0x2e31(%rip),%eax
    11e3:   83 c0 01                add    $0x1,%eax
    11e6:   89 05 28 2e 00 00       mov    %eax,0x2e28(%rip)
```

#### Atomicity
