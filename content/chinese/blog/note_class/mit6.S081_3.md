---
title: "操作系统的具体学习"
date: 2025-03-04T11:01:10+08:00
draft: false  # Is this a draft? true/false！！！
author: ["Yeelight"]
math: false
toc: true
excludeSearch: true
---
## 通过 XV6 了解操作系统

我希望通过 6.S081 的学习来学习操作系统的强大
<!--more-->

### 在 XV 6 中 Syscall 函数

|**系统调用**|**描述**|
|---|---|
|`int fork()`|创建一个进程，返回子进程的PID|
|`int exit(int status)`|终止当前进程，并将状态报告给wait()函数。无返回|
| `int wait(int *status)` |等待一个子进程退出; 将退出状态存入 `*status`; 返回子进程 PID。|
|`int kill(int pid)`|终止对应PID的进程，返回0，或返回-1表示错误|
|`int getpid()`|返回当前进程的PID|
|`int sleep(int n)`|暂停n个时钟节拍|
|`int exec(char *file, char *argv[])`|加载一个文件并使用参数执行它; 只有在出错时才返回|
|`char *sbrk(int n)`|按n 字节增长进程的内存。返回新内存的开始|
|`int open(char *file, int flags)`|打开一个文件；flags表示read/write；返回一个fd（文件描述符）|
|`int write(int fd, char *buf, int n)`|从buf 写n 个字节到文件描述符fd; 返回n|
|`int read(int fd, char *buf, int n)`|将n 个字节读入buf；返回读取的字节数；如果文件结束，返回0|
|`int close(int fd)`|释放打开的文件fd|
|`int dup(int fd)`|返回一个新的文件描述符，指向与fd 相同的文件|
|`int pipe(int p[])`|创建一个管道，把read/write文件描述符放在p[0]和p[1]中|
|`int chdir(char *dir)`|改变当前的工作目录|
|`int mkdir(char *dir)`|创建一个新目录|
|`int mknod(char *file, int, int)`|创建一个设备文件|
|`int fstat(int fd, struct stat *st)`|将打开文件fd的信息放入*st|
|`int stat(char *file, struct stat *st)`|将指定名称的文件信息放入*st|
|`int link(char *file1, char *file2)`|为文件file1创建另一个名称(file2)|
|`int unlink(char *file)`|删除一个文件|

​ 来自表1.2：xv6系统调用（除非另外声明，这些系统调用返回0表示无误，返回-1表示出错）

## 课程教材

book-riscv-rev2

操作系统-三个简单的部分-ostep

鸟哥的Linux私房菜 基础学习篇 第四版 (鸟哥)

[命令行的艺术](https://github.com/jlevy/the-art-of-command-line/blob/master/README-zh.md)

[Missing-Semester](https://missing.csail.mit.edu/2020/)
[计算机教育中缺失的一课](https://missing-semester-cn.github.io/)

## 基础

- [ ] 学习 `Vim`  。
- [ ] 学会如何使用 `man` 命令去阅读文档。
  - [ ] `man bash`  [[Bash]]
- [x] 学会使用 `apropos` 去查找文档
- [ ] 知道有些命令并不对应可执行文件，而是在 Bash 内置好的，此时可以使用 `help` 和 `help -d` 命令获取帮助信息。
- [x] 你可以用 `type 命令` 来判断这个命令到底是可执行文件、shell 内置命令还是别名。
- [ ] 学会重定向
  - [ ] 了解标准输出 stdout 和标准错误 stderr。
  - [ ] 使用 `>` 和 `<` 来重定向输出和输入。
  - [ ] 学会使用 `|` 来重定向管道。明白 `>` 会覆盖了输出文件而 `>>` 是在文件末添加。

- [ ] 学会使用 `ssh` 进行远程命令行登录。

- [ ] 熟悉 Bash 中的任务管理工具。
  `&`，**ctrl-z**，**ctrl-c**，`jobs`，`fg`，`bg`，`kill`
- [ ] 学会使用特定符。
  - 通配符 `*`
- [ ] 学会基本的文件管理工具
- [ ] 熟悉正则表达式
    [[正则表达式]]

- [ ] 学会使用 `apt-get`，`yum`，`dnf` 或 `pacman` 等来查找和安装软件包。
