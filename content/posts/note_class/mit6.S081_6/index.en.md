---
aliases:
  - /blog/note_class/mit6.s081_6/
title: "XV6 Processes and Threads"
date: 2025-03-04T11:41:37+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

> Shadow Clone Jutsu!

I'm writing about processes and threads together because they're essentially *cousins*. These two have always been hard for me to distinguish. I once tried using AI to understand them --- [[Process and Thread]] --- but it was too vague, so now I want to grasp them through XV6 itself.

<!--more-->

## Processes

A process is an object representing a program running on a computer. It includes copies of the program's code, data, execution state, and system resources such as memory space and files.

The operating system manages processes to concretely schedule programs. Processes also help isolate User Space from Kernel Space — for example, through memory virtualization: each process has its own page table. If we think of the CPU as a massive factory, a process is like a complete production line for a specific product, with its own workers, raw materials, assembly lines, packaging, and so on. And it has nothing to do with other products (at least not directly).

![process](https://s2.loli.net/2024/01/06/Oe53hsV6zDS9mqR.png)
The space a process needs

To the operating system, a process is just a data structure. Let's look at `proc.h` in XV6:

```c
// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID
  // wait_lock must be held when using this:
  struct proc *parent;         // Parent process
  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
};
```

Quite complex — in a real system it would be far more intricate and diverse.

Among these, `enum procstate state;` represents the process state (some of these also apply to threads):

```c
enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
```

In simple terms, there are a few key states:

- **RUNNING**: The process is currently executing on a processor. It is actively running instructions.
- **RUNNABLE (ready)**: The process is ready to run, but for some reason the OS has chosen not to run it at this moment.
- **SLEEPING (blocked)**: The process has performed some operation and won't be ready to run until some other event occurs. A common example: when a process issues an I/O request to disk, it blocks so other processes can use the processor.
- **ZOMBIE**: A special state. A "zombie process" is one that has finished executing, but its parent process hasn't yet cleaned it up, so it still occupies an entry in the process table. It no longer executes any instructions, but its process table entry still consumes system resources. Normally, the parent should call `wait()` or `waitpid()` to reap the zombie and release its resources.

```c
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID
```

These are all process attributes.

```c
  struct proc *parent;         // Parent process
```

A process may have a parent through `fork()`. The `init` process is the parent of all processes.

```c
  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char name[16];               // Process name (debugging)
```

These are the concrete *raw materials and assembly lines* that determine how the *product* is made in the system.

But we don't run a single process on the CPU forever — processes need to switch between each other, and **switching between processes is essentially switching between threads**.

## Threads

A thread can be thought of as an abstraction that simplifies programming when there are multiple tasks. A thread is a unit of serial code execution. If you write a program that just executes code in order, you can consider it a single-threaded program — that's a loose definition of a thread. While people have many different definitions of threads, here we'll treat a thread as a single serial execution unit: it occupies exactly one CPU and executes instructions one after another in the ordinary way.

Back to my factory analogy: if a process is a complete production line, then a thread is the smallest unit on that line — the work of a single pipeline — with its own corresponding attributes. I'm actually borrowing the pipeline concept from RISC-V here: imagine a pipeline stage with one thread running on it, hence I call it "pipeline work."

Notably, we can save a thread's attributes at any time and pause its execution, then later restore its attributes to resume running. A thread's attributes consist of three parts:

- **Program Counter (PC)**: indicates where the current thread is executing instructions.
- The **registers** that hold variables.
- The program's **Stack**. Typically each thread has its own stack, which records the function call history and reflects the thread's current execution point.

Threads are the concrete mechanism for achieving parallel execution of multiple processes. To improve throughput, we keep processes in constant motion, so we use threads to implement **time-sharing**: when one process pauses, we switch to another.

There are two main strategies for running threads in parallel:

- **Strategy one**: use multiple CPUs on a multi-core processor, with each CPU running one thread. If you have 4 CPUs, each can run a thread. Each thread automatically gets its own PC and registers based on the CPU it's on. But if you have only 4 CPUs and thousands of threads, assigning one thread per CPU obviously won't solve the problem.
- **Strategy two**: have a single CPU rapidly switch between multiple threads. Suppose I have one CPU and 1000 threads. Run thread one, save its state, switch to thread two, then thread three, and so on until each thread has run for a bit, then cycle back to thread one.

![](https://s2.loli.net/2024/01/02/uUzkxQeG4bOfFnJ.png)
> My CPU has only 8 cores but over six thousand Threads.

So here's a question: how many threads can a process have?

![](https://s2.loli.net/2024/01/06/iPcdKyCYz1Su8lf.png)

In XV6, each process has two threads:

1. **User Thread**:
  Every user process has its own independent memory address space and contains one thread that controls the execution of the user process's code instructions.
2. **Kernel Thread**:
  For each user process, there is a kernel thread that executes system calls coming from that user process. All kernel threads share kernel memory, so XV6's kernel threads do indeed share memory.

If the XV6 kernel decides to switch from one user process to another, first the kernel thread of the first process switches to the kernel thread of the second process within the kernel. Then, from within the second process's kernel thread, execution returns to the second process's user space — this return is also accomplished by restoring the user process state saved in the trapframe.

The core point here is that in XV6, at any time you must go through:

1. To switch from one user process to another, you must first enter the kernel from the first user process, save the user process state, and run the first process's kernel thread.
2. Then switch from the first process's kernel thread to the second process's kernel thread.
3. After that, the second process's kernel thread pauses itself and restores the second user process's registers.
4. Finally, return to the second user process to continue execution.

We usually say we're "switching from one thread to another" because during the switch, you first save the previous thread's registers, then restore the last-saved registers of the next thread.

### Thread States

- **RUNNING**: the thread is currently running on some CPU
- **RUNNABLE**: the thread isn't yet running on any CPU, but can run as soon as a CPU becomes idle
- **SLEEPING**: this state means the thread is waiting for some I/O event and will only run after that I/O event occurs

> Different threads are distinguished by their state, but in reality a thread's complete state is far more complex.

## XV6 Thread Switching

The actual thread-switching sequence looks more like this:

1. A process wants to enter sleep for some reason — say, yielding the CPU or waiting for data. It first acquires its own lock.
2. Then the process changes its state from RUNNING to RUNNABLE.
3. The process then calls the `switch` function — actually it calls `sched`, which in turn calls `switch`.
4. `switch` switches the current thread to the scheduler thread.
5. The scheduler thread had previously called `switch` too, and now resumes execution, returning from its own `switch` call.
6. After returning, the scheduler thread releases the lock of the process that just yielded the CPU.

Now let's understand thread switching with the CPU as our reference point, guided by a few questions:

- Why do threads switch?
- How do threads switch?
- What must be saved during a thread switch?

### Let's Begin

Suppose we have two CPUs — CPU0 and CPU1. CPU0 is running a process — **shell** — and when this **user program** runs, it's actually its **user thread** that's running. Now I want to run another process — **ls**. CPU0 enters a **trap** — via a system call, timer interrupt, or I/O interrupt — and the kernel thread belonging to this user program is activated. CPU0 uses the **stack** from the kernel thread. And now, if the XV6 kernel decides to switch from one user process to another, first within the kernel, the first process's kernel thread is switched to the second process's kernel thread.

In xv6's code implementation (using a timer interrupt as an example), we enter the `yield()` function, which gives up the current CPU:

```c
// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}
```

Inside `yield()`, we acquire the current process's lock — that is, **shell**'s lock — and change its state to **RUNNABLE**. Here's a curious thing: aren't we changing a thread's state? Why are we changing the process's state? My personal take is that in xv6, each process has only one user thread, so the thread's state is placed inside the process struct. Then the most important part — thread scheduling — arrives.

`sched()` is essentially the function that transitions a **RUNNING** thread into a **RUNNABLE** thread. So for every **RUNNABLE thread**, when we transition it from RUNNING to RUNNABLE, we need to copy the information that was on CPU0 — namely the **PC** and **registers** — to some location in memory. Note: this is not copying from somewhere in memory, but copying *from* the CPU's registers.

```c
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}
```

As you can see, `sched` only performs some sanity checks and calls `panic` if anything is wrong. Let's go straight to the `swtch` function at the bottom. **This function is the core of thread scheduling.**

`swtch` takes two arguments: one is the address where the current **PC** and **callee registers** will be saved, and the other is the address from which the new **PC** and **callee registers** will be restored.

```c
swtch:
        sd ra, 0(a0)
        sd sp, 8(a0)
        sd s0, 16(a0)
        sd s1, 24(a0)
        sd s2, 32(a0)
        sd s3, 40(a0)
        sd s4, 48(a0)
        sd s5, 56(a0)
        sd s6, 64(a0)
        sd s7, 72(a0)
        sd s8, 80(a0)
        sd s9, 88(a0)
        sd s10, 96(a0)
        sd s11, 104(a0)

        ld ra, 0(a1)
        ld sp, 8(a1)
        ld s0, 16(a1)
        ld s1, 24(a1)
        ld s2, 32(a1)
        ld s3, 40(a1)
        ld s4, 48(a1)
        ld s5, 56(a1)
        ld s6, 64(a1)
        ld s7, 72(a1)
        ld s8, 80(a1)
        ld s9, 88(a1)
        ld s10, 96(a1)
        ld s11, 104(a1)

        ret
```

You might notice there's no PC here. Did I get it wrong? Wait — this is where the real magic happens. Let's think about what the PC does in the CPU pipeline. Yes, it's just a pointer: wherever the PC points, the CPU executes whatever is at that address. Registers are truly "dumb" — if I change the PC value, the CPU "dumbly" goes and executes it, regardless of whether it's related to what came before. And didn't we just *call* the `swtch` function? That means `PC → swtch`'s address, so `RA ← PC + 4`. The **ra register** holds the return address of `swtch`, which is the next instruction: `mycpu()->intena = intena;`. This is the register I save. And the **RA** in the restored registers — isn't that just another **PC**? After I return from `swtch`, the PC value updates to the restored RA value from `0(a1)`. I have to admire the genius who discovered this.

> Q: Why does RISC-V have 32 registers, but `swtch` only saves and restores 14 (callee) registers?
> A: Because `swtch` is called as an ordinary function. For some registers, the caller of `swtch` (`sched`) assumes `swtch` will modify them, so the caller has already saved those registers on its own stack. When the function returns, those registers are automatically restored. Therefore `swtch` only needs to save the Callee-Saved Registers.

Finally, the sp (Stack Pointer) register. It's actually the kernel stack address of the current process, mapped at a high address by the virtual memory system.

> Q: Why do we restore from the CPU scheduler thread's context object `&mycpu()->context`?
> A: Because earlier, the kernel registers corresponding to the `ls` program's kernel thread were also saved in the corresponding context object — that is, the context in CPU0.

Once `swtch` returns, the **PC** now points to the `scheduler` function, since we've restored the scheduler thread's context object.

The scheduler thread's `scheduler` function: the per-CPU process scheduler. After each CPU sets itself up, it must call `scheduler()`. This is the process of transitioning a **RUNNABLE** thread into a **RUNNING** thread.

```C
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}
```

You can probably guess where my PC points now — yes, to `c->proc = 0;`, setting that no process is currently running on CPU0. Earlier in the `yield` function we acquired the process's lock, because `yield` didn't want any other CPU core's scheduler thread to see this process and run it before it fully enters the Sleep state. And now that we're done, we can release the lock (pretty far away from where we acquired it). OK, now CPU0 is free and can look for other **RUNNABLE** processes. Remember at the beginning we had two CPUs? We haven't used CPU1 at all. Now you should know what it's been doing — it's been looping in `scheduler` looking for a suitable process. You see, we earlier made the **shell** process RUNNABLE, so CPU1 can go execute it. And my CPU0 might go execute **ls**.

![](https://s2.loli.net/2024/01/06/W98BHw1uIjkaQAq.png)

> Q: If the switch wasn't triggered by a timer interrupt, could we expect the ra register to point somewhere else, like the `sleep` function?
> A (Prof. Robert): Yes. We saw earlier that the code path here could involve some system-call-related functions. You basically answered your own question. If we stopped executing the current process for reasons other than a timer interrupt, `switch` would return into some system-call code, not to the `sched` function we see here. I recall that `sleep` also calls `sched` in the end — the backtrace might look different, but it still includes `sched`. So I've only introduced one method of process switching here, namely switching due to a timer interrupt. But there are other possible triggers for a process switch, such as waiting for I/O or waiting for another process to write data to a pipe.

Beyond registers, a thread has a lot of other state — variables, heap data, etc. — but all of this data resides in memory and remains unchanged. We haven't modified any of the thread's stack or heap data. So during a thread switch, the registers inside the processor are the only volatile state that needs to be saved and restored. All other data in memory stays as-is, so there's no need to explicitly save and restore it. We only save and restore the processor's registers because we want to use the same set of registers in the new thread. I believe other state isn't changed because kernel threads share memory among themselves.
