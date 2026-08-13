---
title: "Redis Expiration Strategy: Why Your Cache Won't Grow Forever?"
date: 2025-03-12T10:52:45+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
comments: true
tags:
  - Redis
  - Cache
  - Expiration
  - Memory Management
---

> Redis is an in-memory database. If it doesn't clean up expired keys, memory will eventually blow up. So how does it pull it off?

## Let's Start with a Question

You store a key in Redis with a 10-second TTL. After 10 seconds, you `GET` it — returns nil. The key is gone. But what if nobody ever reads it? Does it just sit there in memory forever?

That's exactly what **expiration policies** are designed to solve: delete expired data promptly, but without burning too much CPU checking for it.

Redis's approach? **Lazy expiration + Periodic expiration**, a two-pronged strategy.

<!--more-->

## Three Expiration Strategies

### 1. Timer-based Expiration

Create a timer for every key with a TTL. When the timer fires, delete the key.

| Pros | Cons |
|------|------|
| Memory-friendly — deleted the moment it expires | CPU-unfriendly — massive timer overhead |

Redis does **not** use this strategy. For a high-throughput in-memory database, creating a timer per key would be a disaster.

### 2. Lazy Expiration

**Only check if a key has expired when it's accessed.**

```
Client: GET mykey →
  Redis checks TTL:
    - Expired → delete key, return nil
    - Not expired → return the value
```

- **Pros**: CPU-friendly. You only check when someone actually asks.
- **Fatal flaw**: If a key expires and nobody ever touches it again, it **lives in memory forever**. We call these "cold expired keys."

### 3. Periodic Expiration (Active Expiration)

This is the fix for lazy expiration's blind spot. Redis periodically **randomly samples** a batch of TTL-bearing keys in the background and deletes the expired ones.

**The Active Expire Cycle algorithm** (runs 10 times per second by default, controlled by `hz`):

```
1. Randomly pick 20 keys from the set of keys with TTLs
2. Delete any expired keys among them
3. If more than 25% of those 20 keys were expired (i.e., >=5):
   → Go back to step 1, keep cleaning
4. If the expired ratio is <= 25%:
   → End this cycle, wait for the next trigger
```

That `25%` threshold is clever:
- High expiration rate → heavy backlog → keep cycling, clean harder
- Low expiration rate → things are clean enough → stop, don't waste CPU spinning

> Starting from Redis 6, keys with TTLs are stored in a radix tree, making it faster to locate "about to expire" keys during periodic cleanup.

## Two-Pronged: Lazy + Periodic

Here's a diagram to show how they work together:

```
A key's fate after TTL expires:
                         ┌→ Client reads it → lazy check → deleted ✓
Key TTL expires →        │
                         └→ No one reads it → periodic scan picks it → deleted ✓
                                    └→ Not picked → sticks around (waiting for next scan)
```

This is why Redis can't guarantee instant deletion the moment a key expires — but it **does** guarantee it'll eventually be cleaned up.

## Expiration ≠ Eviction

A lot of people confuse "expiration" with "eviction," but they're completely different things:

| Dimension | Expiration | Eviction |
|-----------|------------|----------|
| **Trigger** | Key's TTL runs out | Memory exceeds `maxmemory` limit |
| **How it works** | Lazy + Periodic | Picks keys to evict by policy |
| **Goal** | Remove expired, useless data | Make room for new data |
| **Scope** | Only keys with TTLs | Any key |

Common eviction policies (`maxmemory-policy`):

| Policy | Scope | Behavior |
|--------|-------|----------|
| `noeviction` | — | Error on write when memory is full, no eviction |
| `allkeys-lru` | All keys | Evict least recently used |
| `allkeys-lfu` | All keys | Evict least frequently used |
| `volatile-lru` | TTL keys only | Evict least recently used |
| `volatile-lfu` | TTL keys only | Evict least frequently used |
| `volatile-ttl` | TTL keys only | Evict the one with shortest remaining TTL |

**In one sentence**: Expiration is "this data should be deleted now." Eviction is "memory's full, someone has to go."

## Summary

- Redis handles key expiration with **lazy expiration** (check on access) + **periodic expiration** (background random sampling with a 25% threshold loop)
- When memory is full, the **eviction policy** (LRU/LFU/TTL/noeviction) decides who gets kicked out
- Expiration and eviction are different mechanisms — don't mix them up
- The adaptive nature of periodic expiration is elegant: "clean aggressively when busy, waste less when idle"