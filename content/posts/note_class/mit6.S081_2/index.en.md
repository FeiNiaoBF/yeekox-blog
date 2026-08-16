---
aliases:
  - /blog/note_class/mit6.s081_2/
title: "File Descriptors"
date: 2025-03-04T10:58:53+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Abstract Representation

> A file descriptor is a non-zero integer.

<!--more-->

Getting the operating system to recognize different files, sockets, external I/O resources and more is not trivial — but machines understand numbers. We can leverage this by abstractly describing resources. Hence, a **file descriptor** represents a resource. To keep resource usage orderly, the system maintains a global *table*, and each process has its own *table* as well. When a process opens a file, the OS creates corresponding entries in both the global and per-process file descriptor tables, keeping them in sync.

In plain terms, every process automatically opens three standard file descriptors at startup:

- File descriptor 0 (stdin): Standard input, typically keyboard input.
- File descriptor 1 (stdout): Standard output, typically text output to the screen.
- File descriptor 2 (stderr): Standard error output, also typically to the screen, but usually for error messages.

Subsequently, whenever a process opens or creates a *file*, the OS assigns a file descriptor to it and writes it into the table as an index, ready for subsequent `read` and `write` operations.

## Usage

Since file descriptors are a *resource abstraction* provided by the OS, they allow (system) programs to access files and I/O resources through a simple integer, without worrying about the underlying hardware details.

On Unix/Unix-like systems, you call `read()` and `write()` to read or write `n` bytes from/to the file referenced by the descriptor:

```c
char buf[512];

n = read(0, buf, sizeof(buf));

n = write(1, buf, sizeof(buf));
```

Both return the actual number of bytes read or written. If `n` is less than 0, an error has occurred.

This raises a new question: I've used standard input and standard output here. As mentioned earlier, when a file is opened or created, it gets a file descriptor — and the system assigns them sequentially. So if a new file is opened and its descriptor is `3`, how do I use `read` and `write` on it? Here lies one of Unix's great design moves — **I/O redirection**:

```c
// cat < input.txt
char *argv[2];
argv[0] = "cat";
argv[1] = 0;
if(fork() == 0) {
    close(0);
    open("input.txt", O_RDONLY);
    exec("cat", argv);
}
```

What happens above: `fork` creates a child process (inheriting the parent's table and everything). `close` shuts down standard input. `open` opens the new file `input.txt`. Since the system assigns descriptors sequentially, `input.txt` becomes `0` in the child process. And since `cat` reads from standard input, the code feeds `input.txt` into `cat`, which outputs to the shell.
