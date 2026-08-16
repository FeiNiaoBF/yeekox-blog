---
aliases:
  - /blog/channel_err/
title: "The Most Common Channel Errors in Go: Panic and Goroutine Leaks"
date: 2025-03-12T10:51:46+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
---

## Three Common Crash Scenarios

1. Closing a nil channel
2. Sending to an already-closed channel
3. Closing an already-closed channel

## Goroutines, Channels, and Garbage Collection in Go

### Problem Analysis

Consider a `process` function where the main goroutine blocks. If the `process` function is no longer referenced, we need to think about three things:

1. Goroutine lifecycle
2. Channel blocking behavior
3. Go's garbage collection

### Goroutine Lifecycle

Goroutines don't terminate on their own. They end only when:

1. The goroutine's function returns
2. The entire program exits

In this case, if a timeout occurs, the main goroutine returns — but the child goroutine keeps running and attempts to send on the channel.

### Channel Blocking Behavior

An unbuffered channel (like `ch` in this example) blocks on send until a receiver is ready. After the timeout, no receiver exists, so the child goroutine blocks forever on `ch <- true`.

### Garbage Collection

Go's garbage collector cannot reclaim a goroutine that's still running. Even if the `process` function returns and is no longer referenced, the child goroutine is still alive — so it won't be collected.

Likewise, the channel `ch` won't be collected because the child goroutine still holds a reference to it.

### Conclusion

1. The main loop blocking won't directly cause goroutine or channel reclamation.
2. Even if `process` is no longer referenced, the child goroutine keeps running — GC won't touch it.
3. The channel `ch` also won't be collected, because it's still referenced by the child goroutine.
4. This creates a **goroutine leak** — the child goroutine lives on indefinitely, unreclaimable.

### Fixing It

To avoid goroutine leaks, consider these improvements:

1. Use `context` to control the goroutine lifecycle.
2. After a timeout, actively close the channel so the child goroutine knows to exit.
3. Add a `select` with an exit case inside the goroutine.

For example:

```go
func process(ctx context.Context, timeout time.Duration) bool {
    ch := make(chan bool)
    ctx, cancel := context.WithTimeout(ctx, timeout)
    defer cancel()

    go func() {
        // Simulate a time-consuming task
        select {
        case <-time.After(timeout + time.Second):
            ch <- true
        case <-ctx.Done():
            // Context cancelled, exit the goroutine
        }
        fmt.Println("exit goroutine")
    }()

    select {
    case result := <-ch:
        return result
    case <-ctx.Done():
        return false
    }
}

```

This ensures that on timeout or when the parent returns, the child goroutine properly exits — no leaks.
