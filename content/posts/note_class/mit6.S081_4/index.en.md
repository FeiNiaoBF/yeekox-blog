---
aliases:
  - /blog/note_class/mit6.s081_4/
title: "Debugging XV6 with GDB"
date: 2025-03-04T11:36:58+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Basics

1. Use `tmux` to run two terminals simultaneously. For a detailed guide, see [here](https://101.lug.ustc.edu.cn/Ch04/#tmux).

<!--more-->

2. Tools you'll need:

```zsh
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install git build-essential gdb-multiarch qemu-system-misc \
    gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu
```

3. Work inside your local xv6 directory.
4. For a GDB primer, check out [this tutorial](https://linuxtools-rst.readthedocs.io/zh-cn/latest/tool/gdb.html).

## Step-by-step

1. Navigate to your xv6 working directory (mine is shown below):

```zsh
cd ~/workspace/xv6-labs-2021
```

Here's what it looks like:
![xv6 working directory](https://s2.loli.net/2023/11/29/CWyA7BolcYTSjwN.png)

2. Use `tmux` to split into two panes:

![](https://s2.loli.net/2023/12/02/UenKoWS8h2CIGAj.png)

In the first pane, run `make qemu-gdb`. In the second, run `gdb-multiarch`:

![](https://s2.loli.net/2023/12/02/pPy8eNamC9VgRB7.png)
![](https://s2.loli.net/2023/12/02/5SIylXBwPn2qYdc.png)

In the second pane, execute `set architecture riscv:rv64` to target the RISC-V architecture, then run `target remote localhost:26000` (the port number comes from the `make qemu-gdb` output).

![](https://s2.loli.net/2023/12/02/ZIw6R5UrmA4JWMo.png)

(*To be continued*)
