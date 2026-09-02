---
title: "The Magic of Bitwise Operations"
date: 2022-11-10T21:04:43+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Preface

Inside a computer, all data is stored in binary. So when computing, we need to know not just decimal arithmetic, but also binary arithmetic (+, -, *, /). These are called bitwise operations — where the sign bit participates in the operation along with the others.
<!--more-->

## Types of Bitwise Operations

Here's a quick overview of the available operations:

| Symbol | Name | Effect |
|:----:|:----:|:----:|
| + | Addition | Binary addition |
| - | Subtraction | Binary subtraction |
| & | AND | Both bits are 1 → result is 1 |
| \| | OR | Both bits are 0 → result is 0 |
| ^ | XOR | Same → 0, different → 1 |
| ~ | NOT | 0 becomes 1, 1 becomes 0 |
| << | Left shift | Shift all bits left, discard high bits, pad with 0 |
| >> | Right shift | Shift all bits right; unsigned: pad with 0; signed: compiler-dependent (arithmetic or logical shift) |

## How They Work

> Addition and subtraction are straightforward — we'll skip those.

### '&' — AND

Same as logical `AND`:

```c
0 & 0 = 0
0 & 1 = 0
1 & 0 = 0
1 & 1 = 1
```

**Negative numbers** participate in bitwise AND using their *two's complement* form.

### '|' — OR

Same as logical `OR`:

```c
0 | 0 = 0
0 | 1 = 1
1 | 0 = 1
1 | 1 = 1
```

**Negative numbers** participate in bitwise OR using their *two's complement* form.

### '^' — XOR

Same as exclusive OR:

```c
0 ^ 0 = 0
0 ^ 1 = 1
1 ^ 0 = 1
1 ^ 1 = 0
```

### '~' — NOT

Same as bitwise complement:

```c
~1 = 0
~0 = 1
```

### '<<' and '>>' — Left and Right Shift

Shift all bits of the operand left (or right) by a specified number of positions. Bits shifted out are discarded; vacant positions are padded with 0.

```c
a = 1010 0101;  # a << (>>) n
a << 2   --------- >    a = 1001 0100;
a >> 2   --------- >    a = 0010 1001;
```

## Summary

Numbers in computer memory are stored in binary, and bitwise operations manipulate them directly at the bit level. This makes them extremely efficient. Use bitwise operations wherever you can in your programs — they'll sharpen your binary thinking and significantly boost performance.

## External Links

This article references [Runoob — Bitwise Operations in C](https://www.runoob.com/w3cnote/bit-operation.html)
