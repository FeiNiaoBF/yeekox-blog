---
aliases:
  - /blog/note_class/mit6.824_lab1/
  - /en/posts/note_class/mit6.824_lab1/
title: "MIT6.824 Distributed System (1) — Lab01"
weight: 20
date: 2024-07-01T17:16:23+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## How MapReduce Works

> From the MapReduce paper
<!--more-->

1. The MapReduce library in the user program first splits the input files into M pieces of typically 16 megabytes to 64 megabytes (MB) per piece (controllable by the user via an optional parameter). It then starts up many copies of the program on a cluster of machines.

2. One of the copies of the program is special – the master. The rest are workers that are assigned work by the master. There are M map tasks and R reduce tasks to assign. The master picks idle workers and assigns each one a map task or a reduce task.

3. A worker who is assigned a map task reads the contents of the corresponding input split. It parses key/value pairs out of the input data and passes each pair to the user-defined Map function. The intermediate key/value pairs produced by the Map function are buffered in memory.

4. Periodically, the buffered pairs are written to local disk, partitioned into R regions by the partitioning function. The locations of these buffered pairs on the local disk are passed back to the master, who is responsible for forwarding these locations to the reduce workers.

5. When a reduce worker is notified by the master about these locations, it uses remote procedure calls to read the buffered data from the local disks of the map workers. When a reduce worker has read all intermediate data, it sorts it by the intermediate keys so that all occurrences of the same key are grouped together. The sorting is needed because typically many different keys map to the same reduce task. If the amount of intermediate data is too large to fit in memory, an external sort is used.

6. The reduce worker iterates over the sorted intermediate data and for each unique intermediate key encountered, it passes the key and the corresponding set of intermediate values to the user's Reduce function. The output of the Reduce function is appended to a final output file for this reduce partition.

7. When all map tasks and reduce tasks have been completed, the master wakes up the user program. At this point, the MapReduce call in the user program returns back to the user code.

## Lab 01

### Introduction

![MapReduce]( https://imgs.search.brave.com/kRnqIwaErmRijpPv2RKP_0fFRkVYZkSCNJ0WCW5355A/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9pLnNz/dGF0aWMubmV0L0VI/OHRZLmpwZw )

This is a typical MapReduce Job. To give the full picture, let me introduce some terminology:

- **Job**: The entire MapReduce computation is called a Job.
- **Task**: Each individual MapReduce invocation is called a Task.

### Task Description

Implement a distributed MapReduce system with a `Coordinator` (Master) and reusable `Worker` processes. For this lab, everything runs on a single machine. Workers interact with the coordinator via RPC. A worker requests a task, performs the computation (`mapf` and `reducef`), writes out results, and atomically renames them to `mr-X-Y` files.

### Implementation

#### Abstracting the Master

The lab guide suggests starting by modifying the worker struct and then having the worker request a task from the Coordinator via RPC—i.e., request a new map task. In practice, though, I found I couldn't jump straight into writing that code. I had to define the Coordinator's abstract data structure first. Only once I understood what data the coordinator manages could I proceed with development. So I abstracted the coordinator's data structure first, then wrote the Worker code.

```go
type Coordinator struct {
mu              sync.Mutex // lock
files           []string   // all input file
nReduce         int        // number of reduce tasks
nMap            int        // number of map tasks
mapTasks        []Task     // index(id): 0~(nmap-1)
reduceTasks     []Task
nmapFinished    int
nreduceFinished int
}
```

Then I wrote the `Worker` function. Drawing from the lab's examples, I referenced the `RPC` example. This example takes two parameters: the first is passed to the coordinator, and the second is an empty parameter filled in by the coordinator on return. Through `RPC`, we can coordinate across different systems to build a distributed system.

```go
// example function to show how to make an RPC call to the coordinator.
//
// the RPC argument and reply types are defined in rpc.go.
func CallExample() {
// declare an argument structure.
args := ExampleArgs{}

// fill in the argument(s).
args.X = 10

// declare a reply structure.
reply := ExampleReply{}

// send the RPC request, wait for the reply.
// the "Coordinator.Example" tells the
// receiving server that we'd like to call
// the Example() method of struct Coordinator.
ok := call("Coordinator.Example", &args, &reply)
if ok {
   // reply.Y should be 100.
   fmt.Printf("reply.Y %v\n", reply.Y)
} else {
   fmt.Printf("call failed!\n")
   }
}
```

#### Abstracting Workers (Tasks)

Following the example, I could "draw a cat by looking at a tiger"—modeling my implementation after the sample. Specifically, I needed to nail down the concept of a **task**. After reading *MapReduce*, I realized that the `Worker` code must branch based on the task type. It turns out **workers** have three different states (actually four, one of which is the special manager—**Master**): map, reduce, and idle. So we need an abstract data structure for each worker type. For ease of management and coordination, we abstract each worker into a task—each `task` representing an independent unit of work, carrying that work's status information.

```go
// Task is a struct that represents a worker task

type Task struct {
    Id          int        // worker ID
    Type        workerType // worker state
    Status      statusType // 0 "Unassigned", 1 "Assigned", 2 "Finished"
    Timestamp   time.Time  // Start time
    MapFile     string     // File for map task
    ReduceFiles []string   // List of files for reduce task
}
// MapReduceArgs is the message worker sends to coordinator
// that have the worker's task and message type
type MapReduceArgs struct {
    Task        Task
    MessageType messageType
}

// MapReduceReply is the message coordinator sends to worker
// when coordinator receives the worker's request.
// that have the worker's task and number of reduce tasks of can be assigned
type MapReduceReply struct {
    Task    Task
    NReduce int
    NMap    int
}
// workerType is an enum for the type of worker
type workerType int
// Idle: 0, Map: 1, Reduce: 2
const (
    Idle workerType = iota
    Map
    Reduce
)

// messageType: 0 "RequestTask", 1 "FinishTask"
type messageType int
const (
    RequestTask messageType = iota
    FinishTask
)

type statusType int
const (
    Unassigned statusType = iota
    Assigned
    Finished
)
```

#### Coordinator Allocation

With the `worker` code done, it was time to write the `coordinator`. The coordinator is the manager that allocates tasks to each requesting worker—its main job is allocation. I structured it to iterate based on the task type. When a slot is idle, I assign a new task to the worker. The task type always starts as map, and later transitions to reduce. The control flow: once all allocation is complete, the system has finished its work.

![test map task](https://s2.loli.net/2024/07/01/WjyKLIMPOtJVRUv.png)

One small pitfall: when writing the allocation logic, I had to pay close attention to distinguishing each task's status. Different status transitions (or lack thereof) lead to different system behaviors, so I needed to understand and handle these state changes very clearly.

### Lab Complete

![done lab](https://s2.loli.net/2024/07/01/IEe7s4hyFQRuqxw.png)

## External Links

[6.5840 Lab 1: MapReduce](https://pdos.csail.mit.edu/6.824/labs/lab-mr.html)
