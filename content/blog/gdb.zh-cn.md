---
title: "GDB基本使用"
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
  - 工具
---

## gdb调试命令

> gdb是一个在UNIX环境下的命令行调试工具
<!--more-->

## 进入gdb

```c
# 先进入编译
gcc <program>.c -g -o <program>
# 编译后在
gdb <program>
```

## 基本命令

#### 1）查看源码　　

```c
(gdb) l
```

源码会进行行号提示。

如果需要查看在其他文件中定义的函数，在l后加上函数名即可定位到这个函数的定义及查看附近的其他源码。或者：使用断点或单步运行，到某个函数处使用s进入这个函数。

#### 2）设置断点　　

```c
(gdb) b（reak） fun
or
(gdb) b row
```

这样会在运行到源码第6行时停止，可以查看变量的值、堆栈情况等；这个行号是gdb的行号。

#### 3）查看断点处情况

```c
 (gdb) info b
```

可以键入"info b"来查看断点处情况，可以设置多个断点；

#### 4）运行代码

```c
(gdb) r
```

#### 5）显示变量值

```c
(gdb) p n
```

在程序暂停时，键入"p 变量名"(print)即可；

GDB在显示变量值时都会在对应值之前加上
`$N` 标记，它是当前变量值的引用标记，以后若想再次引用此变量，就可以直接写`$N`，而无需写冗长的变量名；

#### 6）观察变量

```c
(gdb) watch n
```

 在某一循环处，往往希望能够观察一个变量的变化情况，这时就可以键入命令"watch"来观察变量的变化情况，GDB在"n"设置了观察点；

#### 7）单步运行

```c
(gdb) n
```

#### 8）程序继续运行

```c
(gdb) c
```

使程序继续往下运行，直到再次遇到断点或程序结束；

## 完整的 GDB 调试：实战排查 Segfault

前面的命令都是零散的招式，现在我们把它们串起来，走一遍真实的调试流程。

假设你写了一个 C 程序 `segfault.c`：

```c
#include <stdio.h>

void crash_here(int *p) {
    printf("p 指向的值是: %d\n", *p);  // p 可能是 NULL！
}

int main() {
    int *ptr = NULL;
    crash_here(ptr);
    return 0;
}
```

编译（带调试符号）：

```bash
gcc -g -o segfault segfault.c
```

运行直接崩溃：

```bash
$ ./segfault
Segmentation fault (core dumped)
```

### 开始 GDB 调试

```bash
$ gdb ./segfault
```

**1. 设置断点在 crash_here 函数：**

```gdb
(gdb) b crash_here
Breakpoint 1 at 0x401150: file segfault.c, line 4.
```

**2. 运行程序：**

```gdb
(gdb) r
Starting program: ./segfault

Breakpoint 1, crash_here (p=0x0) at segfault.c:4
4           printf("p 指向的值是: %d\n", *p);
```

断在 crash_here 了，注意 `p=0x0` —— 这已经是 NULL 了！

**3. 检查变量：**

```gdb
(gdb) p p
$1 = (int *) 0x0

(gdb) p *p
Cannot access memory at address 0x0
```

`p` 是空指针，解引用就崩。

**4. 回溯调用栈，看谁传的 NULL：**

```gdb
(gdb) bt
#0  crash_here (p=0x0) at segfault.c:4
#1  0x000000000040116a in main () at segfault.c:9
```

一目了然：`main` 第 9 行调用了 `crash_here(ptr)`，而 `ptr` 是 NULL。

**5. 切到 main 帧，看 ptr 的值：**

```gdb
(gdb) frame 1
#1  0x000000000040116a in main () at segfault.c:9
9           crash_here(ptr);

(gdb) p ptr
$2 = (int *) 0x0
```

铁证如山。修 bug：给 ptr 分配有效内存。

### 调试流程总结

```
编译(-g) → GDB 启动 → 断点(b) → 运行(r) → 检查变量(p) → 回溯(bt) → 定位 → 退出(q)
```

这才是 GDB 的正确打开方式。之前的单个命令只是基本功，串起来才是真正的调试。

## 退出 GDB

```gdb
# 输入 'q'
(gdb) q
```

## 常用命令速查表

| 命令 | 缩写 | 作用 |
|------|------|------|
| `break` | `b` | 设置断点 |
| `run` | `r` | 运行程序 |
| `next` | `n` | 单步（不进入函数） |
| `step` | `s` | 单步（进入函数） |
| `continue` | `c` | 继续运行 |
| `print` | `p` | 打印变量 |
| `backtrace` | `bt` | 查看调用栈 |
| `frame` | `f` | 切换栈帧 |
| `watch` | - | 监视变量变化 |
| `quit` | `q` | 退出 |

GDB 不复杂，关键是**遇到 bug 时会用它走完上面那个流程**。
