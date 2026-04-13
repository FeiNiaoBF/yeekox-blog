---
title: "Redis过期策略"
date: 2025-03-12T10:52:45+08:00
draft: false  # Is this a draft? true/false！！！
author: ["Yeelight"]
math: false
toc: true
comments: true
---

- 定时过期：每个设置过期时间的键都需要创建一个定时器，到过期时间就会立即清除。
- 惰性过期：只有当访问一个键时，才会检查该键是否过期，如果过期则删除。
- 定期过期：Redis 每隔一段时间就会随机检查一部分设置了过期时间的键，删除其中过期的键。
