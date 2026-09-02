---
aliases:
  - /blog/note_class/mit6.s081_0/
  - /en/posts/note_class/mit6.S081_0/
  - /blog/note_class/mit6.S081_0/
title: "XV6 Source Code Walkthrough"
weight: 10
date: 2025-03-04T11:45:30+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Booting XV6
<!--more-->

When we run `make qemu`, xv6 initializes itself and executes the boot loader stored in read-only memory. The CPU starts at memory address `0x80000000` (the program's entry point):

```c
_entry:
    # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la sp, stack0
        li a0, 1024*4
    csrr a1, mhartid
        addi a1, a1, 1
        mul a0, a0, a1
        add sp, sp, a0
    # jump to start() in start.c
        call start
```

The `_entry` instructions set up a stack (`stack0`) so xv6 can run C code. Xv6 declares space for the initial stack `stack0` in `start.c`. Since the stack on RISC-V grows downward, `_entry` loads the stack top address `stack0+4096` into the stack pointer register `sp`. Now that the kernel has a stack, `_entry` calls the C function `start`. Within it, `csrr a1, mhartid` at address `0x8000000a` reads the control system register `mhartid` and loads the result into `a1`—I believe this is used to determine which CPU core is setting up its stack.

In `entry.S` there is no paging, no interrupts, no isolation—everything is utterly "raw". Inside `start()`, basic configuration happens in M-mode (machine mode): it switches the previous privilege mode to supervisor mode in register `mstatus`, sets the return address to `main` by writing `main()`'s address into register `mepc`, disables virtual address translation in supervisor mode by writing 0 to the page table register `satp`, and delegates all interrupts and exceptions to supervisor mode.

```c
void
start()
{
  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);
  // set M Exception Program Counter to main, for mret.
  // requires gcc -mcmodel=medany
  w_mepc((uint64)main);
  // disable paging for now.
  w_satp(0);
  ......
  }
```

Finally, after all of this, `mret` returns to `main`, disables the timer interrupt, and sets PC to `main`. Inside `main()`, a series of initializations runs:

```c
void
main()
{
  if(cpuid() == 0){
    consoleinit();  // initialize console
    printfinit();
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("\n");
    kinit();         // physical page allocator
    kvminit();       // kernel page table
    kvminithart();   // enable paging
    procinit();      // process table init
    trapinit();      // trap vector table init
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC about device interrupts
    binit();         // buffer cache
    iinit();         // inode table
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    ...
    }
    ...
}
```

> Does the order of initialization calls matter?
> Yes—some functions depend on others having run first.

## Launching the First Process

Let's zoom in on `userinit()`. It leverages `initcode.S` to call `exec(init, argv)`, creating a user process:

```
# exec(init, argv)
.globl start
start:
        la a0, init        # first argument
        la a1, argv        # second argument
        li a7, SYS_exec
        ecall              # hand off to the OS
```

Then we enter `syscall()`:

```c
void
syscall(void)
{
  int num;
  struct proc *p = myproc();
  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    p->trapframe->a0 = syscalls[num]();
    if (p->mask & (1 << (uint32)num)) {
        printf("%d: syscall %s -> %d\n", p->pid, sys_name[num], p->trapframe->a0);
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
```

`syscalls[num]()` is an array of function pointers. It looks up `exec`'s system function `sys_exec`, which enters the `init` function. `init` sets up user memory—console, stdin, stdout—and spawns a child process to open `sh`. And that's it—we're up.
