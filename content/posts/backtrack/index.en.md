---
title: "Backtracking Algorithm"
date: 2024-06-11T22:39:52+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - Algorithm
  - Backtracking
  - Combinatorics
---

> Where there are combinations, there is backtracking.

## The Problem

Let's start with a question:
How do you write an algorithm to compute combinatorial math problems — permutations, combinations, subsets?

These problems share a key feature: they all involve matching numbers against constraints, then checking whether a result fits the requirements.

I'll approach this from two angles: visual intuition and mathematical structure.

### The Visual Intuition

I remember when I used to compute combinations, I'd draw diagrams — N-ary trees to count possibilities, something like this:

Rotate this diagram 90 degrees to the right, and you get a decision tree. You can read it horizontally or vertically — same structure.

### The Mathematical Angle

Each level of recursion is one pass through the search space.

Recursion has three parts:

1. Base case (termination condition)
2. Parameters and return values
3. Core logic

Backtracking is fundamentally **Depth-First Search (DFS)** over a decision tree.

- Each recursive level = making one decision (pick or skip? pick which one?)
- Hitting the base case = reaching a leaf = one complete solution
- Backtracking = undoing the last choice, trying the next option

The classic template:

```
def backtrack(path, choices):
    if termination_condition_met:
        collect result
        return
    for choice in choices:
        make choice      # add to path
        backtrack(path, new_choices)
        undo choice      # backtrack: reverse the operation
```

### In Practice: LeetCode 77 — Combinations

> Given two integers n and k, return all possible combinations of k numbers from the range [1, n].

First, draw the decision tree (n=4, k=2):

```
                     []
        ┌──────┬──────┬──────┐
       [1]    [2]    [3]    [4]
      /  \    /  \     |
   [1,2] [1,3] [2,3] [3,4]
    ...    [1,4] [2,4]
```

From the tree, number of combinations = number of leaf nodes. Here's the code:

```python
def combine(n, k):
    res = []
    path = []

    def backtrack(start):
        if len(path) == k:          # base case: we have k numbers
            res.append(path[:])     # collect result
            return
        for i in range(start, n + 1):
            path.append(i)          # make choice
            backtrack(i + 1)        # recurse (start from i+1 to avoid duplicates)
            path.pop()              # backtrack: undo choice

    backtrack(1)
    return res

# combine(4, 2) → [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
```

### Backtracking vs Plain Recursion

| Regular Recursion | Backtracking |
|-------------------|-------------|
| Go down one path, aggregate results | Go down one path, undo, try another |
| "Divide and conquer" | "Trial and error" |
| Merge sort, quicksort | Combinations, permutations, N-Queens |

## Summary

- Where there are combinations, permutations, or subsets, there's backtracking
- Three steps: **base case → iterate choices → make choice + recurse + undo**
- Drawing the decision tree is the most effective way to understand it — once you see the tree, the code writes itself
