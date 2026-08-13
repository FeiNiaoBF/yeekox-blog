---
title: "Cache Notes"
date: 2024-05-13T08:39:14+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
showtoc: true
weight:
math: false
comments: true
tags:
  - Computer Architecture
  - Cache
  - Memory
---

> Cache might just be the greatest idea in the history of computer technology.

Let's start with a question: inside our computers, how do instructions control what's in memory? Because for a computer to actually run, the CPU has to reach out and *fetch* data — that's how instructions get executed. That's what makes a computer a computer.

<!-- more -->

Take a look at this diagram. It's a pretty complete picture of computer organization:

{{< callout emoji="🌐" >}}
*Source: cs61c*
{{< /callout >}}

## Components of a Computer

![Components of a Computer](https://s2.loli.net/2023/04/24/Fzb3uHQBLTlqOgD.png)

Here's what happens: when the CPU needs to run a process, it first tells main memory what instruction it wants. Main memory finds the address, loads the data into a CPU register, and then execution begins. After that, results get written back to main memory.
> There's an extra step here — memory first has to read data from disk.

But here's the problem. In reality, CPU registers and main memory are worlds apart in speed. Here's roughly how they compare:

![memory-steep](https://s2.loli.net/2023/04/24/KtvMSR7QmrXpjbl.png)

Whoa — that's about a **1,000x gap**. Think about it: the CPU finishes in 1 ns, then just sits there twiddling its thumbs for 1,000 ns waiting for memory. From the CPU's perspective, it's idle. That's an enormous waste.

So naturally, if we could speed up main memory, the whole system would get a huge performance boost. But trying to make memory faster *and* bigger *and* cheaper — that's asking too much. So we compromise: we build a tiny slice of blazing-fast storage. It's small, so it's affordable. We call it **cache**. Hardware-wise, we stick cache right between the CPU and main memory, serving as a buffer for frequently accessed data. When the CPU tries to load/store, it checks cache first. If the data's there — boom, straight back to the CPU.

![add-cache.png](https://s2.loli.net/2023/04/24/qLhOmsTV2IE9S8p.png)

I like the Library Analogy from CS61C, but my own analogy is more like modern logistics: you've got a big main warehouse, but also local distribution centers. When I need to ship something, I check the local warehouse first. If it's not there, I go to the main one — takes longer, but most stuff is already nearby.

> [[2. Areas/01 Blog/03-ComputerSystems/cs61c/SRAM vs. DRAM vs. Disk]]

## Memory Hierarchy

OK, so now we know why cache exists. Here's how the different levels stack up:

![Cache-line.png](https://s2.loli.net/2023/04/24/3anw1UgNoWDZBsq.png)

## Cache

### Cache Levels
>
> Each level of cache is essentially a copy of the level below it.

Cache speed directly affects system performance, too. When the data we want isn't in cache, we still have to suffer the long wait for main memory. To push performance even further, we introduce multiple cache levels. The cache we just talked about is L1 (Level 1). Behind L1, we add L2. Between L2 and main memory, we add L3. The higher the level, the slower but larger it gets.

### Temporal Locality
>
> If a memory location is referenced, it will tend to be referenced again soon.

Basically: I used this address once, so I'll keep it around in case I need it again.

### Spatial Locality
>
> If a memory location is referenced, locations with nearby addresses will tend to be referenced soon.

Like an array — when I read one element, the system grabs the neighboring ones too.

### Cache Hit vs Cache Miss

When we go looking for data, two things can happen: **Cache Hit** or **Cache Miss**.

#### Cache hit

The data you want *is in the cache*. Grab it from cache and send it to the processor.

#### Cache miss

The data you want *is not in the cache*. Go to main memory, find it, put it in cache, then send it to the processor.

## How Cache Works

Let's dig into how cache actually operates. First, some terminology:
**line / tag / index / offset / valid**

- **line:** We divide the cache into equal-sized chunks. Each chunk is a *cache line* (or *cache block*), and its size is the *cache line size*.
- **tag:** Used to identify the data. Each cache line has dedicated storage for a tag — it's the upper N bits of the memory address.
$$ addressbits - offsetbits $$
- **offset:** Identifies the byte offset within a line. Usually the lower few bits.
$$ offset = log_2(line\ size) $$
- **index:** The remaining bits of the address serve as the cache line index, used to locate a specific line.
- **Valid bit:** Tells you whether the data stored at a given cache line is actually valid.

> When a memory access maps to cache, the address is split into three fields: tag, set index, block offset. From a physical address, you can determine the data's location in the cache (set, way, byte).

![line-block.png](https://s2.loli.net/2023/04/24/mHdMoveGWXkiNL4.png)

### Direct Mapped Cache

Pros: simpler hardware design, lower cost.
> In a nutshell: load things into cache one by one. When cache is full, wrap around and start over.

> Only suitable for **large-capacity** caches.

Cons: when you access the next address, you still get cache misses. It's like fetching from main memory every time — the cache barely helps. You get *cache thrashing* (each memory block has exactly one fixed slot, so conflicts are common).

![Direct Mapped.png](https://s2.loli.net/2023/04/24/xeav7mlIDAyOwqK.png)

![Direct Mapped-cache.png](https://s2.loli.net/2023/04/24/4EYI7Va1S5lKgow.png)

### Two-way Set Associative Cache

**Cache is split into 2 sets**

Pros: reduces cache thrashing frequency.
> Set-associative mapping is really a compromise between direct-mapped and fully-associative.

Cons: more complex hardware, higher cost (needs to compare tags across multiple cache lines).

![set associative-cache.png](https://s2.loli.net/2023/04/24/yXE8J6RMo9F3Vxq.png)

### Fully Associative Cache

Pros: minimizes cache thrashing to the greatest extent.
> Only suitable for **small-capacity** caches.

Cons: more complex hardware, higher cost (needs to compare tags across multiple cache lines).

Extension: [[More Eviction Policies]]
![](https://s2.loli.net/2023/07/10/TRUdXNBPsveZS7D.png)

![Fully Associative.png](https://s2.loli.net/2023/04/24/76uSATyrPno1eYf.png)

Circuit for finding a hit:

![Required to Check for Hit](https://s2.loli.net/2023/04/24/3VYzGo9dkgHwcrS.png)

[[Types of Misses]]

![](https://s2.loli.net/2023/04/24/M4Fc1g6k5OrfBpj.png)

### Comparisons

How the three cache types compare:

![Comparisons](https://s2.loli.net/2023/04/24/iICnWkpOMcFtKZH.png)
**Needs supplement**