---
aliases:
  - /blog/note_class/mit6.824_1/
title: "MIT6.824 Distributed System(1)"
date: 2024-07-01T17:16:12+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Distributed Systems

> Below are some insights and specific experiments from my study of distributed systems.
> This study is based on the MIT 6.824 labs, serving as technical notes.

<!--more-->

### What is a Distributed System

A distributed system is a system composed of **multiple independent computers** that coordinate and cooperate over a network to collectively accomplish a specific task. These computers communicate and share resources via message passing, while presenting themselves to the user as a single, consistent system.

Key characteristics:
1. **Decentralization**: No single central control node; each node is peer-to-peer and autonomous.
2. **Cooperativity**: Nodes work together through network communication to achieve common goals.
3. **Transparency**: Users perceive the system as a single coherent whole, unaware of the underlying multi-node architecture.
4. **Scalability**: Nodes can be added or removed as needed, enabling elastic scaling.

### Motivation

Distributed systems exist mainly to solve the following problems:

1. **High Availability**: Duplicate service instances across multiple machines; if one node fails, others can continue serving.
2. **Scalability**: Centralized systems have performance bottlenecks—adding more resources to a single machine eventually hits physical limits. Distributed systems scale horizontally across machines.
3. **Geographic Distribution**: Services must be deployed globally to provide low-latency access to users in different regions.
4. **Isolation**: Isolating data and tasks across different nodes to ensure independence.

These motivations are why distributed systems have become the backbone of modern Internet infrastructure.

### Challenges

Most of a distributed system's complexity stems from two aspects:

#### Failure Handling

Some specific failures include:
- Network failures, network delays, network partitioning
- Node crashes
- Clock skew and clock synchronization across different machines

Distributed systems must maintain correctness despite partial failures—this is the fundamental difficulty of distributed computing.

#### Performance Constraints

The performance of a distributed system cannot be simply measured by the number of nodes; many factors interact:
- Load imbalance
- Network latency and bandwidth
- Data skew

### Abstractions

In computer science, a key technique for implementing complex systems is abstraction. Abstraction makes it possible to separate implementation from specification, where **specification** expresses what the system should achieve, and **implementation** describes the concrete steps and code. This decoupling is critical in distributed systems because debugging is far more difficult than in single-machine programs.

Abstraction's goal: A strict specification that the implementation must follow, enabling clear reasoning about system correctness.

#### RPC

RPC (Remote Procedure Call) is the most fundamental abstraction in distributed systems. It provides an abstraction similar to local function calls, making developers feel as though they are calling a local function. Under the hood, RPC handles data serialization, network transmission, and error handling, and these implementation details are usually hidden from the caller. However, the underlying network introduces uncertainty in latency and success, so it's not quite the same as a local function call—this is the difference between abstraction and reality.

RPC is a request-response protocol:

```
  Client                        Server
    | ────── request (func, args) ────> |
    | <──── response (result) ────────── |
```

#### Transactions

Another important abstraction is transactions. Transaction processing ensures that related operations are either all applied successfully (committed) or none are applied (aborted), maintaining consistency.

But in distributed systems, transactions face new challenges: when data is spread across multiple servers, how to coordinate commits to maintain atomicity? This is where **2PC (Two-Phase Commit)** comes in: a coordinator asks all participants to prepare in the first phase, and then instructs them to commit in the second. 2PC is a widely used protocol in distributed databases.

### In Practice

Developing a distributed system involves many practical concerns:

#### Scalability

A system is called scalable if it can increase its total throughput by adding more nodes or resources. Scalability is a key system design goal. Achieving scalability often involves sharding data, load balancing, and designing stateless components.

#### Availability

Availability is a measure of a system's "health"—the fraction of time the system provides usable service. High availability is an important distributed system objective, often achieved through replication. In a replicated system, multiple copies are maintained; if one copy fails, requests can be directed to others.

#### Consistency

Consistency in distributed systems means that replica nodes see the same data at the same time. Strong consistency means that readers always get the latest written value, no matter which replica they read from. But achieving strong consistency introduces performance overhead.

Strong consistency, while offering the highest data accuracy, is expensive to implement. In a distributed system, replicas are often geographically distributed for fault tolerance and performance reasons. This increases cross-replica communication latency, thereby affecting system responsiveness. Therefore, many systems choose weak consistency in exchange for better performance and fault tolerance.

### Personal Learning Goals

1. Gain a foundational understanding of distributed system functionality and concrete implementation.
2. Hand-build a small distributed system, paying attention to the details of distributed systems.
3. Summarize and reflect on the problems encountered during this distributed systems study, along with any lessons learned.

## External Links

[Lecture 01 - Introduction](https://mit-public-courses-cn-translatio.gitbook.io/mit6-824/lecture-01-introduction)
