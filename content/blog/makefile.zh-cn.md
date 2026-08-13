---
title: "MakeFile使用笔记"
date: 2023-04-24T19:08:45+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - MakeFile
  - 工具
---

## MakeFile的编译和连接

> 对于大量的c语言文件一个很好的自动化工具,其实可以用到任何语言
<!--more-->

## MakeFile的一般使用

### 使用规则

既然要用MakeFile，那就要知道它是怎么使用的；主要还是`编译`&`链接`，将大量的文件，通过直接或间接的方式来一键编译，就不必像`gcc -g -o pro1.c pro2.c pro3.c... filename`如此这般麻烦的编译了。

写入Make的文件的规则:

> 1. 如果这个工程没有编译过，那么我们的所有c文件都要编译并被链接。
> 2. 如果这个工程之中的某几个c文件被修改，那么我们只编译被修改的c文件，并链接目标程序。
> 3. 如果这个工程的头文件被改变了，那么我们需要编译引用了这几个头文件的c文件，并链接目标程序。

对makefile的书写规则：

```makefile
target ... : prerequisites ...
    command
    ...
    ...
```

> 1. **target:** 这个是的目标文件，也可以是一个执行文件，还可以是一个标签（label）。
> 2. **prerequisites:** 这个是一个依赖文件，是对`target`文件的输入。
> 3. **command:** 这个是对文件的命令具体操作。`eg：cc -o file.h`

简而言之，target这一个或多个的目标文件依赖于prerequisites中的文件，其生成规则定义在command中。

### make的使用技巧

#### 变量的使用

在makefile里面也是可以使用变量的，但是这是不可变的(是不是有点矛盾),它更像是c语言里面的宏(#define)。

```makefile
object = $(boo)
```

这样的好处是我们可以简化我们的make文件，是它不是这么的杂乱无章。

## 书写规则


### 显式规则

最常用的形式，明确指定目标、依赖和命令：

```makefile
# 目标: 依赖
#	命令（注意：必须是 TAB，不能是空格！）
main.o: main.c utils.h
	gcc -c -o main.o main.c
```

### 隐式规则

Make 内置了许多"潜规则"。比如你不需要告诉它 `.c` 怎么变成 `.o`，它自己知道：

```makefile
# 你只需要写目标和依赖，make 自动用 cc -c 编译
main.o: main.c utils.h  # Make 自动推导命令：cc -c main.c
```

### 通配符和模式规则

```makefile
# 通配符：匹配所有 .c 文件
SRCS = $(wildcard *.c)

# 模式规则：% 是通配部分
%.o: %.c
	gcc -c $< -o $@
#   $< = 第一个依赖（源文件）
#   $@ = 目标名
```

### 伪目标（PHONY）

```makefile
.PHONY: clean all

all: main

clean:
	rm -f *.o main

main: main.o utils.o
	gcc -o main main.o utils.o
```

为什么需要 `.PHONY`？因为如果目录里恰好有一个叫 `clean` 的文件，make 会认为"目标已存在，不需要执行"。加上 `.PHONY` 后，不论有没有同名文件，命令都会执行。

### 自动变量速查

| 变量 | 含义 |
|------|------|
| `$@` | 目标文件名 |
| `$<` | 第一个依赖文件名 |
| `$^` | 所有依赖文件名（去重） |
| `$?` | 所有比目标新的依赖文件 |
| `$*` | 模式规则中 `%` 匹配的部分 |

## 一个完整的示例

```makefile
CC = gcc
CFLAGS = -Wall -g
SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)  # 把 .c 替换成 .o
TARGET = app

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
```

这个 Makefile 可以编译目录下所有 `.c` 文件，链接成一个 `app`，干净利落。

## 总结

- Makefile 的核心就三个概念：**目标（target）、依赖（prerequisites）、命令（command）**
- 变量像 C 语言的宏，简化重复内容
- `$@`/`$<`/`$^` 这些自动变量让规则更通用
- `.PHONY` 防止"伪目标"被文件干扰
- **记住：命令前面的缩进必须是 TAB，不能是空格**——这是 Makefile 新手的头号陷阱
