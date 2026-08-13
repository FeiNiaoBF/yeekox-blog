---
title: "MakeFile Notes"
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
  - Tools
---

## Compilation and Linking with MakeFile

> A great automation tool for large C projects — honestly, you can use it with any language.
<!--more-->

## How MakeFile Works

### The Rules

If you're going to use MakeFile, you need to know how it operates. It comes down to two things: **compiling** and **linking**. Instead of typing `gcc -g -o pro1.c pro2.c pro3.c... filename` every time, you define the rules once and build everything with one command.

What Make does:

> 1. If the project has never been compiled, all C files get compiled and linked.
> 2. If only a few C files were modified, only those get recompiled, then relinked.
> 3. If a header file changes, every C file that includes it gets recompiled, then relinked.

The Makefile syntax:

```makefile
target ... : prerequisites ...
    command
    ...
    ...
```

> 1. **target:** The output file — could be an executable, an object file, or even a label.
> 2. **prerequisites:** The dependencies — files that the target needs as input.
> 3. **command:** The actual build step. `eg：cc -o file.h`

In short: one or more targets depend on the files listed in prerequisites, and the build rules live in command.

### Tips: Variables

Makefile supports variables — think of them as C macros (`#define`), not mutable variables.

```makefile
object = $(boo)
```

Using variables keeps your Makefile clean instead of a messy wall of filenames.

## Writing Rules

### Explicit Rules

The most common form: explicitly state the target, dependencies, and commands:

```makefile
# target: dependencies
#	command (must be TAB, not spaces!)
main.o: main.c utils.h
	gcc -c -o main.o main.c
```

### Implicit Rules

Make has a bunch of built-in "conventions." You don't need to tell it how `.c` becomes `.o` — it already knows:

```makefile
# Just write target and dependencies, Make auto-derives the command
main.o: main.c utils.h  # Make auto-executes: cc -c main.c
```

### Wildcards and Pattern Rules

```makefile
# Wildcard: match all .c files
SRCS = $(wildcard *.c)

# Pattern rule: % is the wildcard part
%.o: %.c
	gcc -c $< -o $@
#   $< = first dependency (source file)
#   $@ = target name
```

### PHONY Targets

```makefile
.PHONY: clean all

all: main

clean:
	rm -f *.o main

main: main.o utils.o
	gcc -o main main.o utils.o
```

Why `.PHONY`? If there happens to be a file named `clean` in the directory, Make would think "the target already exists, nothing to do" and skip it. With `.PHONY`, the command always runs — file or no file.

### Automatic Variables Cheat Sheet

| Variable | Meaning |
|----------|--------|
| `$@` | Target filename |
| `$<` | First dependency filename |
| `$^` | All dependency filenames (deduplicated) |
| `$?` | All dependencies newer than the target |
| `$*` | The part matched by `%` in a pattern rule |

## A Complete Example

```makefile
CC = gcc
CFLAGS = -Wall -g
SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)  # Replace .c with .o
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

This Makefile compiles every `.c` file in the directory and links them into an `app`. Clean and tidy.

## Summary

- MakeFile boils down to three concepts: **target**, **prerequisites**, **command**
- Variables work like C macros — they simplify repeated content
- `$@`/`$<`/`$^` make your rules more generic
- `.PHONY` prevents "pseudo-targets" from being blocked by actual files
- **Remember: indentation before commands must be TAB, not spaces** — this is the #1 trap for Makefile newcomers