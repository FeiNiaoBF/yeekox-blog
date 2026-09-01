---
aliases:
  - /blog/note_class/mit6.s081_5/
  - /en/posts/note_class/mit6.S081_5/
title: "Traps in XV6"
weight: 60
date: 2025-03-04T11:38:58+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

> Failure is the mother of success.

## Trap Instructions and System Calls

During execution, the CPU forcefully transfers control to special kernel code called a **trap**. Three scenarios trigger traps:

<!--more-->

1. **System call**: `ecall` (RISC-V), `int` (x86)
2. **Exception**: division by zero, etc.
3. **Interrupt**: timer interrupt, device interrupt

Below is an overview showing which paths each type of trap takes through the kernel:

$$
\text{Shell } \Rightarrow \text{user space} \xRightarrow{write()} \text{usys.S} \to \text{uservec in trap.c} \xRightarrow{usertrap()} \text{usertrapret()} \to \text{kernetrap vec}
$$

> Note: `write()` is a user-space library function, not a system call—it escapes to the kernel via the system call function `ecall`.

In RISC-V, a hardware thread (hart) invokes the `ecall` instruction as a system call through `ecall`:

```
.global fork
fork:
 li a7, SYS_fork
 ecall
 ret
```

`ecall` elevates the privilege level from user mode to supervisor mode, and PC jumps to the instruction at `0x3ffffff000` (in some xv6 versions this is the `uservec` address—so the address includes both `uservec` and `usertrap`). Actually, `ecall` does **three** things:

1. Switches from user mode to supervisor mode
2. Saves PC into `SEPC`
3. Jumps to `STVEC` (the trap vector, which points to `uservec` or `kerneltrap`)

The LV6 book states that the RISC-V CPU's `ecall` instruction stores the return-PC in `SEPC` and jumps to `STVEC`, which stores the kernel-side handler address under lockdown. The lock stores the address to prevent malicious program intervention. The kernel's first step is to **save registers** (32 general-purpose registers).

> A trap from user space undergoes `uservec` (trampoline.S) → `usertrap` (trap.c) → `usertrapret` (trap.c) → `userret` (trampoline.S). A trap from kernel space goes through **`kernelvec`** (kernelvec.S) → **`kerneltrap`** (trap.c) → returns to kernel space.

## Summary of the Entire Process

To handle traps, we need paging hardware and a `trapframe` to handle trap in/out. Below is an overview of each component involved in handling traps from user space:

- **STVEC**: stores the address where the trap handler function resides; RISC-V jumps here to handle the trap.
- **SEPC**: when handling a trap, RISC-V saves the PC value here (`sret` will later copy SEPC back to PC).
- **SSRATCH**: holds a pointer to the `trapframe` page.
- **Scause**:
    - `scause` = 8 → syscall
- **STVAL**
- **SSTATUS**:
    - **SIE**: controls whether interrupts are enabled. SIE=0, disabled (SIE=0 when running in kernel).
    - **SPP**: indicates whether the trap came from user mode (SPP=0) or supervisor mode (SPP=1).

## Basic Trap Handling Code in Xv6

```c
// trap.c
void usertrap(void) {
    // ...
    if (r_scause() == 8) {
        // system call
        if (p->killed) exit(-1);
        // sepc points to the ecall instruction—
        // that's where we want to return to
        p->trapframe->epc += 4;
        // an interrupt will change sepc, so change sstatus to prevent it
        intr_on();
        syscall();
    } else {
        // handle other types of traps
    }
    // ...
}

void usertrapret(void) {
    // ...
    // set up the trap vector for the next user trap
    w_stvec(TRAMPOLINE + (uservec - trampoline));
    // set user page table
    p->trapframe->kernel_satp = r_satp();
    // set sepc to the user program counter
    w_sepc(p->trapframe->epc);
    // call userret (trampoline.S)
    extern char trampoline[], uservec[], userret[];
    uint64 fn = TRAMPOLINE + (userret - trampoline);
    ((void (*)(uint64, uint64))fn)(TRAPFRAME, p->trapframe->kernel_satp);
}
```

## Registers involved in RISC-V Trap Handling

| Register | Description |
|---|---|
| `stvec` | The register where the kernel writes the address of its trap handler; RISC-V jumps here for traps. |
| `sepc` | When a trap occurs, RISC-V saves the program counter here (because PC gets overwritten with stvec). `sret` copies sepc back to PC. |
| `scause` | A number describing the reason for the trap. |
| `sscratch` | The kernel places a value here that comes in handy early in a trap handler. |
| `sstatus` | **SIE** controls whether device interrupts are enabled. If SIE is cleared, RISC-V defers device interrupts until it is set. **SPP** indicates whether the trap came from user mode or supervisor mode, and controls which mode sret returns to. |

## The SSTATUS Register

| Bits | Field Name | Description |
|---|---|---|
|   | SIE | 0 → disabled, 1 → enabled |
|   | SPIE | Stores the previous value of SIE |

Note: SPIE differs between `usertrap` and `kerneltrap`:

|      | user mode trap   | kernel mode trap    |
|------|------------------|---------------------|
| SIE  | leaves interrupts on | disables interrupts |
| SPIE | interrupts on    | disables interrupts    |

Set `epc->sepc` to the value of the user PC.

Generate the parameters and address for the `userret` function.

**fn**: trampoline base address + offset
**a0**: trapframe base address
**a1**: user page table base address

## The USERRET Function

Returns to user-space assembly code.

1. Switch to the user page table.
Pass parameter `a1` to `satp`. (This works because the trap mappings are identical.)

2. Restore registers from `trapframe` (parameter a0). Pass `trapframe` to `t0`, then to `sscratch`.

3. Pass `a0` from `trapframe` (which holds the system call return value) into the `a0` register.
4. **sret**
Switch back to **user mode**, copy SEPC to PC (previously PC+4), re-enable interrupts.

Summary:
The trap mechanism for system calls is quite complex—all in the name of maintaining isolation. Some operations even resort to assembly language for finer control.
