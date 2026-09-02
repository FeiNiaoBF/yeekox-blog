---
title: "XV6 File System"
weight: 100
date: 2025-03-04T11:44:22+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

> And God said, "Let there be a file system," and there was a file system.

<!--more-->

We've been studying operations on memory and the CPU. These only work while power is on — data is wiped when power is lost, especially in *Random Access Memory* (RAM) chips and *CPU caches* (L1, L2, L3, etc.). So we urgently need a place to store data permanently. Generally, these kinds of **big problems** are solved by hardware first — and thus the disk was born, designed to store data "permanently." But a new problem arises: how do I **find**, **read**, and **store** data on the disk? That's where the operating system's file management system comes in.

## Disk

A disk is a storage device that uses *magnetic recording technology* to store data. Magnetic recording uses the magnetization of magnetic particles to preserve data. A disk typically consists of one or more magnetic platters that can spin. Data is stored on the surface of the platters, and read/write heads are responsible for reading and writing data on those platter surfaces.

The working principle of a disk involves the magnetization of magnetic particles and the operation of read/write heads. When writing data to the disk, the read/write head changes the magnetization direction of the magnetic particles, thereby recording the data. When reading data, the read/write head scans the disk surface and detects the magnetization direction of the magnetic particles to retrieve the data.

> A disk is a storage device relative to memory, so it's sometimes called **secondary storage**.

### Physical Structure

To understand disk storage, you need to know a bit about the physical structure of a disk:

A hard disk's physical structure generally consists of heads and platters, a motor, a main control chip, and connecting cables. When the spindle motor spins the platters, a secondary motor moves a set of (**heads**) to the corresponding platter and determines whether to read the front or back side. The head floats above the platter surface, drawing a circular track (**track** or **cylinder**) concentric with the platter. At this point, the head's magnetic induction coil senses the magnetism on the platter surface and uses the manufacturer-specified read time or data interval to locate the **sector**, thereby obtaining the sector's data content.

- **Platters**: The platters in a disk are circular structures stacked together that store data.
- **Head**: The head is a device mounted on the hard drive actuator arm, used to read or write data on the disk surface.
- **Spindle**: The spindle is a rotating shaft that holds the platters in place so the read/write arm can access data on them.
- **Actuator**: The actuator consists of the read/write heads and moves across the hard disk to save or retrieve information.
- **Cylinder**: These are circular tracks on the disk drive platters, all at equal distance from the disk center.
- **Sector**: Each track on the platter is divided into several arcs — these arcs are the disk's sectors. The first sector of a hard disk is called the boot sector.

> **Sectors** vs **Blocks**

- A **sector** is typically the smallest unit that a disk drive can read or write. It used to be 512 bytes.
- A **block** is typically data from the perspective of the operating system or file system. It's defined by the file system; in XV6 it's 1024 bytes. So in XV6, one block corresponds to two sectors. Generally, one block maps to one or more sectors.

### How It Works

When a hard disk reads data, the head senses the magnetic field on the platter, converts it into an electrical signal, and transmits it to the computer. When writing data, the head changes the magnetic field on the platter through electrical signals, thereby storing the data. This process is accomplished by the head moving across the platter, reading or writing data as needed.

As technology has advanced, we're no longer satisfied with the speed and capacity of traditional hard drives. We now have new types of disks: Solid State Drives (SSDs) use flash storage technology and offer faster read/write speeds and larger storage capacity.

### XV6

A file system must have a scheme for placing **inodes** and **content blocks** at specific locations on the disk. To achieve this, xv6 divides the disk into several sections. The file system doesn't use block 0 (it holds the boot sector). Block 1 is called the superblock: it contains metadata about the file system (file system size in blocks, number of data blocks, number of inodes, and number of blocks in the log). Blocks starting from 2 hold the log. After the log come the inodes, with multiple inodes per block. Then comes the bitmap block, tracking which data blocks are in use. The remaining blocks are data blocks: each is either marked free in the bitmap block or holds the content of a file or directory. The superblock is populated by a separate program called `mkfs`, which builds the initial file system.

![xv6filesys](https://s2.loli.net/2024/01/17/QkH19owu6DUxTjY.png)

Generally, the `bitmap block`, `inode blocks`, and `log blocks` are collectively called **metadata blocks**. They don't store actual data, but they store the metadata that helps the file system do its work.

Before continuing, let's pose a few questions:

1. How does the file system represent data on disk?
2. How do we recover when the system crashes? How do we ensure **crash safety**?
3. Secondary storage performance is on the order of milliseconds — how do we improve performance?

## Buffer Cache

The buffer cache is designed to solve two problems: the performance gap between disk and memory, and ensuring that two or more processes don't interfere with each other.

It has two main tasks:

1. Synchronize access to disk blocks to ensure that a disk block has only one copy in memory and that only one kernel thread uses that copy at a time.
2. Cache frequently used blocks so they don't need to be re-read from the slow disk.

```c
struct {
  struct spinlock lock;
  struct buf buf[NBUF];
  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head;
} bcache;
```

Within this, the `buf` data structure is essentially a **block**:

```c
struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  uint dev;
  uint blockno;
  struct sleeplock lock;
  uint refcnt;
  struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE];
};
```

The main interfaces of the buffer cache layer are `bread` and `bwrite`: the former retrieves a `buf` from the cache containing a copy of a block that can be read or modified in memory; the latter writes a modified buffer to the corresponding block on disk. You can think of the buffer cache as being in memory. Kernel threads must release buffers by calling `brelse`. The buffer cache uses one **sleep lock** per buffer, ensuring each buffer is used by only one thread at a time. `bread` returns a locked buffer, and `brelse` releases that lock.

In the buffer cache, the number of buffers holding disk blocks is fixed, meaning that if the file system requests a block not yet cached and the cache is full, the buffer cache must evict a buffer currently holding an old block's content. The buffer cache uses an **LRU** eviction policy. The reasoning is that the least recently used buffer is the least likely to be needed again soon.

Let's look at the implementation of `bread` and `bwrite`:

```c
// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
```

The `bread` function first calls `bget`, which finds the block's cache from the buffer cache for us.

```c
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  acquire(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}
```

This `bget` implementation is a doubly-linked list: traverse forward to find a specific block, traverse backward to find an empty slot.

When multiple processes call `bget` concurrently, one of them acquires the `bcache` lock and scans the `buffer cache`. At this point, other processes cannot modify the buffer cache. The process then looks up whether the block number is in the cache; if so, it increments the block cache's reference count (`refcnt`) by 1, indicating that the current process holds a reference to this block cache, and then releases the `bcache` lock. If a second process also wants to scan the buffer cache, it can now acquire the `bcache` lock. Suppose the second process also wants the cache for block 33 — it will also increment that block cache's reference count. Finally, both processes will try to call `acquiresleep` on block 33's block cache. So in xv6, any modification to the `buffer cache` must hold the `bcache` lock; any modification to an individual block's cache must hold that block's sleep lock.

And `bwrite` simply writes the locked block's content to the virtio disk:

```c
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}
```

`brelse` is called when a thread finishes operating on a block:

```c
// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  acquire(&bcache.lock);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }

  release(&bcache.lock);
}
```

When the caller is done using a buffer, it must call `brelse` to release and recycle it. `brelse` releases the sleep lock and moves the buffer to the front of the linked list. Moving the buffer sorts the list by how recently each buffer was used: the first buffer in the list is the most recently used, and the last is the least recently used. The two loops in `bget` exploit this: in the worst case, scanning for an existing buffer must process the entire list, but checking the most recently used buffers first (starting from `bcache.head` and following the next pointer) reduces scan time under good reference locality.

The block cache implementation is critical for performance, because reading and writing to disk is an expensive operation that can take hundreds of milliseconds. The block cache ensures that if we recently read a block from disk, we won't need to read that same block from disk again.

## Logging

**Logging** — one of the most important components of an operating system — is a mechanism designed to ensure **crash safety**. When using a machine, what we fear most are crashes or power failures that could leave the file system on disk in an inconsistent or incorrect state. To ensure system safety, we need mechanisms that either prevent problems from happening or repair them.

Logging. This is a very popular solution that originally came from the database world, and now many file systems use logging. It's popular because it's a very effective method. What follows is the **simple logging implementation** in XV6. It contains some subtle issues — we'll discuss the problems, then solve them. That's also why file system logging is worth studying.

- First, it ensures that file system system calls are **atomic**. For example, when you call `create`/`write`, the effects of these system calls must either fully appear or not appear at all, preventing a situation where only part of a system call's disk writes appear on disk.
- Second, it supports **Fast Recovery**. After a reboot, we don't need to do a massive amount of work to repair the file system — only a very small amount. "Fast" here is relative to another approach where you might need to read every block of the file system, every inode, every bitmap block, check if the file system is still in a correct state, and then repair it. Logging provides fast recovery.
- Finally, in principle, it can be very efficient, although the implementation we see in XV6 is not particularly efficient.

First, let's think about what the general process of writing to a file looks like:

1. Create the file
2. Find a free **inode** and update the **inode**'s data.
3. In the **bitmap**, find the current directory's **data block** and add the inode to it, informing the directory of the new data.
4. Update the file's **inode** again.
5. Write data
6. Scan the **bitmap** to find an unused **data block**, returning the new address found in **data blocks**.
7. In xv6, you can write one byte (one character) at a time, so for several characters you call for new **data blocks** the same number of times.
8. Finally, update the file's **inode** with size and other information.

![logblockno.png](https://s2.loli.net/2024/01/18/fbGkiN3wFc1AYZ7.png)

So the data flow is from **memory** to **block cache** to **disk**. Where does the log fit in? Actually, when we cache a **bitmap block** in memory — say, we plan to write to block 45 — when we need to update the bitmap, we don't write directly to the block. Instead, we write the data to the **log** and record that this update should be written to block 70. The same operation applies to all block writes: for example, updating an inode also records a log entry for writing to block 33. So the log appears *before* the actual block write.

Then, at some point, when the file system operation completes — say all 4-5 block writes from the previous section are done and all exist in the log — we **commit** the file system operation. This means we record somewhere in the log the number of operations belonging to the same file system operation, for example, 5.

Afterward, when we've stored all the block-write content in the log, if we want to actually execute the writes to disk, we just move the blocks from the log partition to the file system partition. We know the first operation should write to block 45, so we directly write the data from the log to block 45; the second operation should write to block 33, so we write it to block 33, and so on.

Finally, once that's done, we can clear the log. Clearing the log essentially means setting the count of operations for that file system operation to 0.

The basic workflow of logging:

1. Log write
2. Commit op
3. Install log
4. Clean log

Suppose we **crash** and reboot. On reboot, the file system checks the log's commit record value. If it's 0, do nothing. If it's greater than 0, we know the blocks stored in the log need to be written to the file system. Clearly, when we crashed, we may not have finished installing the log — we might have crashed after commit but before clean log. So at this point we need to **reinstall** (i.e., write the log blocks to the file system again), and then clean the log.

Now let's look at the log structure in XV6:

```c
struct log {
  struct spinlock lock;
  int start;
  int size;
  int outstanding; // how many FS sys calls are executing.
  int committing;  // in commit(), please wait.
  int dev;
  struct logheader lh;
};
```

Here, `logheader` is essentially the log block's header, and it looks like this:

```c
struct logheader {
  int n;                // n represents the number of valid log blocks
  int block[LOGSIZE];   // the actual block numbers for each log block, e.g. 45, 33
};
```

Finally, let's see how the log is used in system calls. A typical log usage looks like this:

```c
 begin_op();
 ...
 bp = bread(...);
 bp->data[...] = ...;
 log_write(bp);
 ...
 end_op();
```

A *transaction* starts with `begin_op` and ends with `end_op`. All block writes within the transaction are atomic, meaning these block writes either all happen or none happen.

Between `begin_op` and `end_op`, data structures on disk or in memory may be updated. But before `end_op`, no actual changes occur (i.e., nothing is written to the actual blocks). At `end_op`, we write the data to the log, then write the commit record or log header. The interesting part is: what happens when a file system call performs a disk write?

`log_write` is a method provided by the file system's logging implementation. Every write operation between `begin_op` and `end_op` in any file system call always goes through `log_write`. The `log_write` function is in `log.c`. In the file system, all `bwrite` calls need to be replaced with `log_write`:

```c
void
log_write(struct buf *b)
{
  int i;

  acquire(&log.lock);
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    if (log.lh.block[i] == b->blockno)   // log absorption
      break;
  }
  log.lh.block[i] = b->blockno;
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
    printf("log_write: blockno: %d\n", b->blockno);
  // printf("log_write: log.lh.n: %d\n", log.lh.n);
  // printf("log_write: log.committing: %d\n", log.committing);
  release(&log.lock);
}
```

Next, let's look at the file system recovery flow that happens during XV6's startup process. When the system crashes and reboots, one of the things done during XV6's startup is calling the `initlog` function:

```c
void
initlog(int dev, struct superblock *sb)
{
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  initlock(&log.lock, "log");
  log.start = sb->logstart;
  log.size = sb->nlog;
  log.dev = dev;
  recover_from_log();
}
```

```c
static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
  log.lh.n = 0;
  write_head(); // clear the log
}
```

`recover_from_log` first calls `read_head` to read the header from disk, then calls `install_trans`. This function is also called in the `commit` function — it reads **n** from the log header and copies all log blocks to the file system blocks based on n. At the end, `recover_from_log` clears the log just as before.

That's the entire recovery flow. If we crash again inside `install_trans`, there's no problem, because the next time we reboot, XV6 will call `initlog` again, which calls `recover_from_log` to reinstall the log. If we crash multiple times before a commit, the log may be installed multiple times once a commit finally succeeds.

(Other questions pending)

The difference between log and cache:

- **Log**: A log is used to record system runtime status, events, and operations. It's typically used for troubleshooting, monitoring system operation, and tracking user actions. Log files can contain records at different levels such as system errors, warnings, and informational messages, helping system administrators or developers understand the system's operating condition.
- **Cache**: A cache is a high-speed data storage layer used to temporarily store data, usually transient in nature. Caches are used to store recently or frequently accessed data to improve data access speed. It's a smaller, faster, more expensive type of memory used to improve the performance of recently or frequently accessed data. Caches are commonly used by CPUs, applications, web browsers, and operating systems to reduce data access time, decrease latency, and improve I/O performance.

## Inode

## Directory

## Pathname
