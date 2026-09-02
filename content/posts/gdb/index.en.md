---
title: "GDB Basics"
date: 2023-04-24T19:10:36+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - C
  - Debug
  - GDB
  - Tools
---

## GDB Debugging Commands

> GDB is a command-line debugging tool for UNIX environments.
<!--more-->

## Getting into GDB

```c
# Compile with debug symbols first
gcc <program>.c -g -o <program>
# Then start GDB
gdb <program>
```

## Basic Commands

#### 1) View Source Code

```c
(gdb) l
```

Source code is displayed with line numbers.

If you need to check a function defined in another file, just add the function name after `l` to jump to its definition and surrounding code. Alternatively: set a breakpoint or step through until you reach the function, then use `s` to step into it.

#### 2) Set Breakpoints

```c
(gdb) b(reak) fun
or
(gdb) b row
```

This stops execution at the specified line (e.g., line 6), so you can inspect variable values, stack traces, etc. The line number is GDB's line number.

#### 3) Check Breakpoint Info

```c
 (gdb) info b
```

Type `info b` to see all active breakpoints. You can set as many as you want.

#### 4) Run the Program

```c
(gdb) r
```

#### 5) Display Variable Values

```c
(gdb) p n
```

When the program is paused, type `p <variable>` (print) to see its value.

GDB prefixes each displayed value with a `$N` marker — this is a reference handle for that value. Later, you can refer back to it with `$N` instead of retyping a long variable name.

#### 6) Watch a Variable

```c
(gdb) watch n
```

Inside a loop, you often want to observe how a variable changes over time. `watch` sets a watchpoint on `n`, and GDB will pause whenever `n` changes.

#### 7) Step (Next)

```c
(gdb) n
```

Executes the next line, stepping *over* function calls.

#### 8) Continue

```c
(gdb) c
```

Resumes execution until the next breakpoint or program exit.

## Full GDB Debugging: Tracking Down a Segfault in Practice

The commands above are individual techniques. Now let's string them together and walk through a real debugging workflow.

Say you've written a C program called `segfault.c`:

```c
#include <stdio.h>

void crash_here(int *p) {
    printf("value pointed to by p: %d\n", *p);  // p might be NULL!
}

int main() {
    int *ptr = NULL;
    crash_here(ptr);
    return 0;
}
```

Compile with debug symbols:

```bash
gcc -g -o segfault segfault.c
```

Run it — instant crash:

```bash
$ ./segfault
Segmentation fault (core dumped)
```

### Let's Debug with GDB

```bash
$ gdb ./segfault
```

**1. Set a breakpoint at crash_here:**

```gdb
(gdb) b crash_here
Breakpoint 1 at 0x401150: file segfault.c, line 4.
```

**2. Run the program:**

```gdb
(gdb) r
Starting program: ./segfault

Breakpoint 1, crash_here (p=0x0) at segfault.c:4
4           printf("value pointed to by p: %d\n", *p);
```

We've hit crash_here. Notice `p=0x0` — it's already NULL!

**3. Check the variables:**

```gdb
(gdb) p p
$1 = (int *) 0x0

(gdb) p *p
Cannot access memory at address 0x0
```

`p` is a null pointer. Dereferencing it causes the crash.

**4. Backtrace to see who passed NULL:**

```gdb
(gdb) bt
#0  crash_here (p=0x0) at segfault.c:4
#1  0x000000000040116a in main () at segfault.c:9
```

Clear as day: `main` at line 9 called `crash_here(ptr)`, and `ptr` was NULL.

**5. Switch to main's frame to inspect ptr:**

```gdb
(gdb) frame 1
#1  0x000000000040116a in main () at segfault.c:9
9           crash_here(ptr);

(gdb) p ptr
$2 = (int *) 0x0
```

Case closed. Fix: allocate valid memory for `ptr`.

### Debugging Workflow Summary

```
Compile(-g) → Launch GDB → Breakpoint(b) → Run(r) → Inspect vars(p) → Backtrace(bt) → Pinpoint → Quit(q)
```

*That's* the right way to use GDB. The individual commands are just fundamentals — what matters is stringing them together into this workflow.

## Exiting GDB

```gdb
# Type 'q'
(gdb) q
```

## Quick Reference

| Command | Short | What it does |
|---------|-------|-------------|
| `break` | `b` | Set a breakpoint |
| `run` | `r` | Run the program |
| `next` | `n` | Step over (don't enter functions) |
| `step` | `s` | Step into (enter functions) |
| `continue` | `c` | Continue running |
| `print` | `p` | Print a variable's value |
| `backtrace` | `bt` | Show the call stack |
| `frame` | `f` | Switch stack frames |
| `watch` | — | Watch a variable for changes |
| `quit` | `q` | Exit GDB |

GDB isn't complicated. The key is knowing how to **walk through that workflow when you hit a bug**.
