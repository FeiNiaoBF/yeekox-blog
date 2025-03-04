---
title: "Http 是什么"
date: 2024-06-11T22:49:31+08:00
draft: false  # Is this a draft? true/false！！！
author: ["Yeelight"]
math: false
toc: true
comments: true
---

> 在这篇文章里，可以学习到现代网络的工作模式

> 比如：什么是http、Web...

## Why need network？

军事方面、信息交换、跨地域传输、业务连接... ...

**网络**已经成为现代社会不可或缺的基础设施，它极大地促进了信息的流通、资源的共享和全球化的进程。

看来我们为了满足需要，我们要规范 **network** ，因此出现HTTP

## What is HTTP?

HTTP 是基于 **TCP/IP（传输层）** 的**应用层**通信协议，它标准化了客户端和服务器之间的**通信**方式。定义了如何通过互联网**请求（Requests）** 和 **传输（Transmissions）** 内容。

通过应用层协议（客户端和服务器之间的通信方式抽象层），HTTP 本身依赖于 TCP/IP 来获取客户端和服务器之间的请求和响应。默认使用 TCP 端口 80。

在 http 中的主要流程为：
> 浏览器 -> 服务器

![[Pasted image 20240526132924.png]]

## HTTP Version

 HTTP 的历代版本

### HTTP/0.9

有史以来最简单的协议，只有一个名为 GET 的方法。

- 响应必须是 HTML 文件
- 只有 GET

### HTTP/1.0

 HTTP 的大发展
可以处理其他响应格式，即**图像**、**视频文件**、**纯文本**或**任何其他内容**类型。它添加 `POST` 和 `HEAD` 方法、更改了请求/响应 **格式**、将 HTTP **标头**添加到请求和响应中、添加了**状态代码**来**标识响应**、还有引入了字符集支持、多部分类型、授权、缓存、内容编码等都包括在内。

请求：

``` http
GET / HTTP/1.0
```

响应：

``` http
HTTP/1.0 200 OK
...
```

HTTP/1.0 的主要缺点

<!-- TODO LINK -->
🚧🚧🚧

- 无持久连接 ---  [[Three-way Handshake(三次握手)]]
- 队头阻塞
- 请求方法有限
- 头部信息冗余
- 缓存有限

### HTTP/1.1

相比于 HTTP/1.0

- ***持久连接*** --- 允许多个连续请求
- 添加了新的方法，其中引入了 `PUT`、`PATCH`、`OPTIONS`、`DELETE`
- 主机名**标识**在 HTTP/1.1 使其成为必要的
- **Pipelining** 管道化
- 更多的状态码
- 等等

> 更多 [RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616)

 缺点：

1. **队头阻塞（Head-of-line Blocking）**：虽然HTTP/1.1 支持管道化，但由于TCP的特性，如果前一个请求的响应延迟，后续请求仍然会被阻塞。
2. **性能瓶颈**：由于HTTP/1.1 仍然依赖于文本格式的头部信息，这可能导致较大的数据传输量和解析延迟。
3. **不支持服务器推送**：HTTP/1.1 不支持服务器主动向客户端推送资源，所有资源都需要客户端明确请求。
4. **头部冗余**：HTTP/1.1 的头部信息在每次请求中都会重复发送，尤其是在使用Cookie等机制时，增加了数据传输量。
5. **缺乏对现代Web应用的支持**：随着Web应用变得越来越复杂，HTTP/1.1 在处理大量并发请求、实时数据传输等方面显得力不从心。

### SPDY (from Google)
>
> SPDY也就是[HTTP/2](https://zh.wikipedia.org/wiki/HTTP/2 "HTTP/2")的前身

### HTTP/2

优点：

1. **二进制分帧**（Frames and Streams）
 HTTP/2 将数据分割成更小的**二进制**帧，每个帧都有自己的类型和流标识符。这种分帧机制使得数据传输更加高效，并且可以实现多路复用。
2. **I/O多路复用**：
 HTTP/2 允许在单个连接上**并行**处理多个请求和响应，消除了 HTTP/1.x 中的队头阻塞问题，提高了页面加载速度
3. **头部压缩**：
 HTTP/2 使用 **HPACK** 算法压缩头部信息，减少了数据传输量，降低了延迟。(Huffman Code ?)
 [RFC7541](https://datatracker.ietf.org/doc/html/rfc7541)
4. **服务器推送**：
 HTTP/2 支持服务器**主动**向客户端推送资源，即服务器可以在客户端请求之前发送客户端可能需要的资源，提高了页面加载效率。
5. **优先级和依赖**：
 HTTP/2 允许客户端指定请求的优先级，服务器可以根据这些信息优化资源的传输顺序。
6. **保持连接**：
  HTTP/2 默认使用持久连接，减少了连接建立和断开的开销。
7. **兼容性**：
 HTTP/2 保持了与 HTTP/1.x 的语义兼容性，现有的应用可以无需修改或只需少量修改即可迁移到 HTTP/2。

缺点：

1. **实现复杂性**：HTTP/2 的二进制分帧和多路复用机制增加了协议实现的复杂性，对服务器和客户端的实现提出了更高的要求。
2. **安全依赖**：虽然 HTTP/2 本身不强制要求使用加密，但大多数浏览器和服务器实现都要求使用 HTTPS，这增加了部署的复杂性和成本。
3. **队头阻塞问题**：虽然 HTTP/2 在应用层解决了队头阻塞问题，但在TCP层仍然存在队头阻塞，因为TCP协议本身是按顺序传输数据的。
4. **服务器推送的挑战**：服务器推送虽然可以提高性能，但如果不当使用，可能会导致资源浪费或客户端缓存问题。
5. **兼容性问题**：虽然HTTP/2 与 HTTP/1.x 语义兼容，但在实际部署中可能会遇到一些兼容性问题，尤其是在旧的网络设备和中间件上。
6. **性能提升有限**：对于一些优化良好的HTTP/1.x 网站，迁移到 HTTP/2 可能不会带来显著的性能提升。

## SSL、TLS、HTTPS

？

- **SSL/TLS**：这两个协议位于应用层和传输层之间，为上层协议提供加密服务。它们负责在客户端和服务器之间建立安全的通信通道。
- **HTTPS**：这是一个应用层协议，它使用SSL/TLS来保护HTTP通信的安全。HTTPS是HTTP和SSL/TLS的结合体，它使得Web浏览器和服务器之间的通信变得安全。

## 继续学习 HTTP 的详解

### HTTP 请求包

🚧🚧🚧

### HTTP 响应包

🚧🚧🚧
**响应头**（Response Headers）是在 HTTP 响应中发送的一组**键值对（key-value pair）**，它们提供了关于响应的**元数据信息**，如**内容类型**、**内容长度**、**缓存控制**、**服务器信息**等。响应头位于 HTTP 响应的起始行（状态行）之后，响应体之前，并且以空行（CRLF）与响应体分隔。

```HTTP
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1234
Date: Mon, 21 Oct 2019 07:28:00 GMT
Server: Apache
```

### HTTP 的方法

### HTTP 的状态码

- 1 XX 提示信息 - 表示请求已被成功接收，继续处理
- 2 XX 成功 - 表示请求已被成功接收，理解，接受
- 3 XX 重定向 - 要完成请求必须进行更进一步的处理
- 4 XX 客户端错误 - 请求有语法错误或请求无法实现
- 5 XX 服务器端错误 - 服务器未能实现合法的请求

## 外部链接

[什么是HTTP](https://cs.fyi/guide/http-in-depth)

[SPDY](https://en.wikipedia.org/wiki/SPDY)

[HTTP docs](https://developer.mozilla.org/en-US/docs/Web/HTTP)
