---
aliases:
  - /blog/note_class/mit6.s081_3/
  - /en/posts/note_class/mit6.S081_3/
title: "Learning Operating Systems Hands-On"
weight: 40
date: 2025-03-04T11:01:10+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---
## Understanding Operating Systems Through XV6

I hope to understand the power of operating systems through studying 6.S081.

<!--more-->

### Syscall Functions in XV6

| **System Call** | **Description** |
|---|---|
| `int fork()` | Create a process; returns child's PID |
| `int exit(int status)` | Terminate current process; reports status to `wait()`. No return |
| `int wait(int *status)` | Wait for a child to exit; stores exit status in `*status`; returns child PID |
| `int kill(int pid)` | Terminate process with given PID; returns 0, or -1 on error |
| `int getpid()` | Return current process's PID |
| `int sleep(int n)` | Pause for n clock ticks |
| `int exec(char *file, char *argv[])` | Load a file and execute it with arguments; only returns on error |
| `char *sbrk(int n)` | Grow process memory by n bytes. Returns start of new memory |
| `int open(char *file, int flags)` | Open a file; flags indicate read/write; returns an fd (file descriptor) |
| `int write(int fd, char *buf, int n)` | Write n bytes from buf to file descriptor fd; returns n |
| `int read(int fd, char *buf, int n)` | Read n bytes into buf; returns bytes read, or 0 at end of file |
| `int close(int fd)` | Release open file fd |
| `int dup(int fd)` | Return a new file descriptor referring to the same file as fd |
| `int pipe(int p[])` | Create a pipe, placing read/write fds in p[0] and p[1] |
| `int chdir(char *dir)` | Change current working directory |
| `int mkdir(char *dir)` | Create a new directory |
| `int mknod(char *file, int, int)` | Create a device file |
| `int fstat(int fd, struct stat *st)` | Place info about open file fd into *st |
| `int stat(char *file, struct stat *st)` | Place info about named file into *st |
| `int link(char *file1, char *file2)` | Create another name (file2) for file1 |
| `int unlink(char *file)` | Remove a file |

From Table 1.2: xv6 system calls (unless otherwise stated, these return 0 on success and -1 on error)

## Course Textbooks

book-riscv-rev2

Operating Systems: Three Easy Pieces (OSTEP)

Bird Brother's Linux Private Kitchen, 4th Edition

[The Art of Command Line](https://github.com/jlevy/the-art-of-command-line/blob/master/README.md)

[Missing Semester](https://missing.csail.mit.edu/2020/)

## Fundamentals Checklist

- [ ] Learn `Vim`.
- [ ] Learn how to use the `man` command to read documentation.
  - [ ] `man bash`  [[Bash]]
- [x] Learn to use `apropos` to find documentation
- [ ] Know that some commands aren't executables but Bash builtins — use `help` and `help -d` to get help.
- [x] Use `type command` to determine whether a command is an executable, shell builtin, or alias.
- [ ] Learn redirection
  - [ ] Understand standard output (stdout) and standard error (stderr).
  - [ ] Use `>` and `<` to redirect output and input.
  - [ ] Learn to use `|` to pipe between commands. Know that `>` overwrites the output file while `>>` appends.
- [ ] Learn to use `ssh` for remote command-line login.
- [ ] Get familiar with Bash job control tools: `&`, **ctrl-z**, **ctrl-c**, `jobs`, `fg`, `bg`, `kill`
- [ ] Learn special characters.
  - Wildcard `*`
- [ ] Learn basic file management tools
- [ ] Get familiar with regular expressions [[Regex]]
- [ ] Learn to use `apt-get`, `yum`, `dnf`, or `pacman` to find and install packages.
