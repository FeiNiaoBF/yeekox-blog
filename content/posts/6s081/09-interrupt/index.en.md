---
title: "Interrupts in XV6"
weight: 90
date: 2025-03-04T11:43:27+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

> Where did `ls` go?

<!--more-->

## Interrupt Hardware

Interrupts arise from a simple scenario: hardware (peripherals) wants the operating system's attention. When a hardware device needs the processor's attention, it sends an interrupt signal. This causes the processor to pause its current task, save the current state, and begin executing a special program called an **interrupt handler**. The interrupt handler processes the interrupt event, then restores the previous task state so the processor can resume the interrupted task.

It's like a system call, but with several differences:

- **Asynchronous**: In a hardware interrupt, the interrupt handler does not run in a process context, so the CPU operates asynchronously.
- **Concurrency**: For interrupts, the CPU and the interrupting device run in parallel.
- **Program device**: You must program the hardware according to the relevant documentation.

Device Address Mapping in the Kernel:
![Platform Level Interrupt Control.webp](https://s2.loli.net/2024/03/10/Q6eEPwmoN7DHZGh.webp)

Devices are connected to the processor. The processor handles device interrupts through the **Platform Level Interrupt Control** (PLIC for short).
![Platform Level Interrupt Control.webp](https://s2.loli.net/2024/03/10/Q6eEPwmoN7DHZGh.webp)
The PLIC routes these interrupts (like a toll station), notifying the CPU of an interrupt. An available CPU core claims the interrupt, then receives and processes it, notifying the PLIC when done.

## Device Drivers

A device driver is software that allows the operating system to communicate and interact with computer hardware. Simply put: code that manages devices is called a driver, and all drivers reside in the kernel.

Most drivers are divided into two parts:

1. **Driver (bottom)**: The driver part is responsible for device control and management, including device initialization, data transmission, and status monitoring. Drivers are typically written in the kernel and run in kernel mode with higher privileges.
2. **Device program (top)**: The device configuration program is usually a user-space program used to configure and control the device. These programs typically do not run in kernel mode and have lower privileges. They interact with the driver through system calls to control and manage the device.

This layered structure provides isolation; the two interact through a *queue* between them.

How to program devices. Typically, programming is done through **memory-mapped I/O**. From the start, device addresses are mapped to specific physical address ranges. You can read and write device control registers using `load` / `store` instructions.

## An XV6 Interrupt Example

When XV6 boots, the Shell outputs the prompt `"$ "`. If we type `ls` on the keyboard, we eventually see `"$ ls"`. Let's trace through how the Console displays `"$ ls"` to see how device interrupts work.

Actually, `"$ "` and `"ls"` are different: `"$ "` is output from the Shell program, while `"ls"` is displayed after the user types it on the keyboard.

RISC-V has several interrupt-related registers:

- **SIE (Supervisor Interrupt Enable)** register. This register has a bit (E) specifically for external device interrupts such as UART; a bit (S) specifically for software interrupts, which may be triggered by one CPU core to another; and a bit (T) specifically for timer interrupts. This lesson focuses only on external device interrupts.

- **SSTATUS (Supervisor Status)** register. This register has a bit to enable or disable interrupts. Each CPU core has independent SIE and SSTATUS registers. Besides individually controlling specific interrupts through the SIE register, you can also control all interrupts through a single bit in the SSTATUS register.

- **SIP (Supervisor Interrupt Pending)** register. When an interrupt occurs, the processor can check this register to determine the type of interrupt.

- **SCAUSE** register, which we've seen many times before. It indicates that the cause of the current state is an interrupt.

- **STVEC** register, which saves the program counter of the user program the CPU was running when a trap, page fault, or interrupt occurred, so that program execution can be restored later.

![](https://s2.loli.net/2023/12/23/uAEnQoZ5sdzXICk.png)

First, a lock is initialized—we don't care about this lock right now. Then `uartinit` is called; the `uartinit` function is in `uart.c`. This function configures the UART chip so it can be used.

![](https://s2.loli.net/2023/12/23/4CsmZKpExjrnR2q.webp)
The flow here is: first disable interrupts, then set the baud rate, set character length to 8 bits, reset the FIFO, and finally re-enable interrupts.

Here, `WriteReg(IER, 0x00)` writes `0x00` to the IER register, and so on.

UART Registers:

![](https://s2.loli.net/2023/12/23/IdOHv6JsNlzQyRm.png)

![](https://s2.loli.net/2023/12/23/lDH3f7mJxdktWwq.png)

After this function runs, the UART is in principle capable of generating interrupts. But since we haven't programmed the PLIC yet, the CPU cannot perceive the interrupts. Eventually, in `main`, the `plicinit` function must be called.

```c
void
plicinit(void)
{
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;     // 0x0c000000L + 10*4
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;   // 0x0c000000L + 1*4
}
```

The first line sets the PLIC to receive interrupts from **UART**.
The second line sets the PLIC to receive interrupts from **VirtIO disk**.

In the `main` function, `plicinit` is followed by `plicinithart`. `plicinit` is run by CPU 0; after that, each CPU core must call `plicinithart` to indicate which peripheral interrupts it is interested in. So in `plicinithart`, each CPU core declares that it is interested in interrupts from UART and VIRTIO. Since we ignore interrupt priorities, we set the priority to 0.

```c
void
plicinithart(void)
{
  int hart = cpuid();
  // set uart's enable bit for this hart's S-mode.
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
}
```

So far, we have external devices that can generate interrupts, and we have a PLIC that can route interrupts to individual CPUs. But the CPU itself hasn't been set up to receive interrupts yet, because we haven't configured the SSTATUS register.
At the end of `main`, the program calls the `scheduler` function:

```c
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();                  //
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

## Output from the Shell Program

### (top part)

The `scheduler` function above is actually quite interesting. Its main function is to schedule processes for each CPU. It runs in an infinite loop, switching to the selected process via context switch: `swtch(&c->context, &p->context);`

In the operating system, after the kernel completes all initialization, it enters the first user process. This user process is typically started by the `init` process, which is the ancestor of all processes—it's the first user process automatically created at system startup. The init process has PID 1 and is responsible for starting and managing other user processes; it's the last process to terminate in the system.

XV6's **init** main function (`user/init.c : main`)

First, this process's main function creates a device representing the Console. Here, `mknod` creates the console device. Since this is the first opened file, the file descriptor here is 0. Then `dup` creates stdout and stderr. This effectively duplicates file descriptor 0 to get the other two file descriptors, 1 and 2. Ultimately, file descriptors 0, 1, and 2 all represent the Console.

```c
  dup(0);  // stdout        fd = 1
  dup(0);  // stderr        fd = 2
```

Then `fork()` creates a child process that runs `exec("sh", argv)`, arriving at `sh.c : main`. The Shell program first opens file descriptors 0, 1, and 2.

```c
main:
  // Ensure that three file descriptors are open.
  while((fd = open("console", O_RDWR)) >= 0){
    if(fd >= 3){
      close(fd);
      break;
    }
  }
```

Then the Shell prints the prompt `"$ "` to file descriptor 2.

```c
int
getcmd(char *buf, int nbuf)
{
  fprintf(2, "$ ");
  memset(buf, 0, nbuf);
  gets(buf, nbuf);
  if(buf[0] == 0) // EOF
    return -1;
  return 0;
}
```

It's worth noting: in Unix systems, devices are represented by files.
So the shell simply wrote `$ ` to the **file** at fd = 2. That is, the `fprintf()` function uses interrupts, specifically the `write()` system call. So every character output by the Shell triggers a `write` system call. This eventually reaches the `filewrite` function (`file.c`).

In `filewrite`, the file descriptor type is first checked. The file descriptor created by `mknod` is of device type (`FD_DEVICE = 3`), and for device-type file descriptors, we execute the device's corresponding write function. Since our current device is the Console, we know this will call the `consolewrite` function in `console.c`.

Here, the character is first copied in via `either_copyin`, then the `uartputc` function is called. `uartputc` writes the character to the UART device, so you can think of `consolewrite` as the top part of the UART driver. The `uartputc` function in `uart.c` actually prints the character.

```c
void
uartputc(int c)
{
  acquire(&uart_tx_lock);

  if(panicked){
    for(;;)
      ;
  }

  while(1){
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
      // buffer is full.
      // wait for uartstart() to open up space in the buffer.
      sleep(&uart_tx_r, &uart_tx_lock);
    } else {
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
      uart_tx_w += 1;
      uartstart();
      release(&uart_tx_lock);
      return;
    }
  }
}
```

`uartputc` gets a bit more interesting. Inside the UART there is a buffer used to send data; the buffer size is 32 characters. There is also a read pointer for the consumer and a write pointer for the producer, creating a ring buffer (also known as a circular queue).

The first thing in the function is to check whether the ring buffer is full. If the read and write pointers are equal, the buffer is empty; if the write pointer plus one equals the read pointer, the buffer is full. When the buffer is full, writing to it is meaningless, so here it sleeps for a while, yielding the CPU to other processes. Of course, for us the buffer is definitely not full, because the prompt `"$ "` is the first character we're sending. So the code reaches the `else` branch, the character is placed into the buffer, the write pointer is updated, and then `uartstart` is called.

```c
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
      // transmit buffer is empty.
      return;
    }

    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
      // the UART transmit holding register is full,
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    uart_tx_r += 1;
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);   //
    WriteReg(THR, c);     //
  }
}
```

`uartstart` notifies the device to perform an operation. First it checks whether the device is currently idle; if it is, we read data from the buffer and write it to the THR (Transmission Holding Register). This is effectively telling the device: "I have a byte here for you to send." Once the data reaches the device, the system call returns, and the user application (Shell) can continue executing. The mechanism for returning from the kernel to user space here is the same as the trap mechanism.

### bottom part

What does RISC-V do when an interrupt occurs while we're outputting characters to the Console?
We previously enabled interrupts in the SSTATUS register, so the processor will be interrupted. Suppose the keyboard generates an interrupt and sends it to the PLIC; the PLIC will route the interrupt to a specific CPU core. If that CPU core has the E bit set in the SIE register (for external interrupts), the following happens:

1. The corresponding bit in the SIE register is cleared, preventing the CPU core from being disturbed by other interrupts, allowing it to focus on the current interrupt. Once processing is complete, the SIE register bit can be restored.
2. The SEPC register is set to the current program counter. Assuming the Shell is running in user space and suddenly an interrupt arrives, the Shell's current program counter is saved.
3. The current mode is saved. In our example, since the Shell program is running, it records user mode.
4. The mode is then set to Supervisor mode.
5. Finally, the program counter value is set to the STVEC value.

In `trap.c` there's a section that can detect interrupts:

```c
usertrap:
else if((which_dev = devintr()) != 0){
    // ok
    }
```

In `trap.c`'s `devintr` function, the SCAUSE register is first checked to determine whether the current interrupt comes from an external device. If so, the `plic_claim` function is called to claim the interrupt.

```c
// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
  int hart = cpuid();
  int irq = *(uint32*)PLIC_SCLAIM(hart);
  return irq;
}
```

The `plic_claim` function is in `plic.c`. In this function, the current CPU core tells the PLIC that it wants to handle an interrupt. `PLIC_SCLAIM` returns the interrupt number; for UART, the returned interrupt number is 10.

```c
devintr:
if(irq == UART0_IRQ){
      uartintr();
    }
```

When `irq` is 10, the `uartintr()` function is called to send data to the UART, but right now there's no input data—the UART registers are empty.

```c
void
uartintr(void)
{
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
      break;
    consoleintr(c);
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
  uartstart();
  release(&uart_tx_lock);
}
```

This function will send out any characters the Shell has stored in the buffer. In fact, after the prompt `"$ "`, the Shell also outputs a space character. The `write` system call can, concurrently with the UART sending the `"$ "` prompt, write the space character to the buffer. So when the UART send interrupt triggers, it can find the space character still in the buffer, and then send it out.

## Interrupt Parallelism

The top and bottom parts of a driver run in parallel. For example, after transmitting the `"$ "` prompt, the Shell calls the `write` system call again to transmit the space character; the code enters the top part of the UART driver (the `uartputc` function) and writes the space into the buffer. But simultaneously, on another CPU core, an interrupt from the UART may arrive, causing the bottom part of the UART driver to execute, examining the same buffer. (The buffer is a shared queue for both top and bottom, and the same holds across CPUs.) So the top and bottom parts of a driver can run in parallel on different CPUs.

We saw many `lock` calls in the earlier code—these are for managing parallelism. What we want is for the `buffer` to be used by only one CPU at any given time.

Producer/Consumer concurrency in UART:

The producer (shell) can keep writing data until **the write pointer + 1 equals the read pointer**, because at that point the buffer is full. When the buffer is full, the producer must stop. We saw this earlier in `uartputc`: if the buffer is full, the code calls `sleep`, temporarily suspending the Shell and running other processes.

The interrupt handler—the `uartintr` function—is the consumer in this scenario. Whenever an interrupt occurs and the read pointer lags behind the write pointer, `uartintr` reads a character from the read pointer, sends it through the UART device, and increments the read pointer. When the read pointer catches up to the write pointer (i.e., when they are equal), the buffer is empty—no action is needed.

## Output from the Keyboard

The Shell calls the `read` function to read characters from the keyboard, which then calls `fileread`. Since this involves a peripheral interrupt, it then calls `consoleread`—similar to the write path.
But in this scenario, the Shell becomes the **consumer**, because the Shell reads data from the buffer. The keyboard is the **producer**, writing data into the buffer.

The flow for inputting a single character:

1. Check whether the read pointer and write pointer are equal to determine if the buffer is empty, and whether the process should sleep.
2. After the Shell prints `"$ "`, if there is no keyboard input, the Shell process sleeps until a character is typed on the keyboard.
3. So at some point, suppose the user types `"l"` on the keyboard. This causes `"l"` to be sent to the UART chip on the motherboard, generating an interrupt that is then routed by the PLIC to a CPU core. This triggers the `devintr` function. `devintr` detects that this is a UART interrupt, then retrieves the character via the `uartgetc` function, and passes the character to the `consoleintr` function. Here, ASCII code processing is involved (`#define C(x)  ((x)-'@')`  Control-x).

By default, the character is displayed on the console for the user to see via `consputc`. Afterwards, the character is stored in the buffer. When a newline character is encountered, the previously sleeping process (the Shell) is awakened, and the data is read from the buffer.

So here too, the buffer decouples the consumer and producer, allowing them to run independently in parallel at their own speeds. If one side runs too fast, the buffer will either be full or empty, and either the consumer or producer will sleep, waiting for the other to catch up.
