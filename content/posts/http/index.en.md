---
title: "What is HTTP?"
date: 2024-06-11T22:49:31+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - HTTP
  - Networking
  - Protocol
---

> In this article, you'll learn how the modern web works.

> Topics covered: What is HTTP, the Web, and more...

## Why Do We Need a Network?

Military applications, information exchange, cross-region data transfer, business connectivity... ...

**Networks** have become an indispensable part of modern society — they enable the flow of information, resource sharing, and globalization at scale.

To meet these needs, we need a standard for **network communication** — that's where HTTP comes in.

## What is HTTP?

HTTP is an **application-layer** communication protocol built on top of **TCP/IP (the transport layer)**. It standardizes how clients and servers **communicate**, defining how content is **requested** and **transmitted** over the internet.

As an application-layer protocol (the abstraction layer for client-server communication), HTTP relies on TCP/IP for sending requests and receiving responses. It defaults to TCP port 80.

The basic flow in HTTP:
> Browser → Server

![[Pasted image 20240526132924.png]]

## HTTP Versions

A tour through the HTTP version history.

### HTTP/0.9

The simplest protocol ever. Only one method: GET.

- Responses must be HTML
- GET only

### HTTP/1.0

A major leap for HTTP. It introduced support for response formats beyond HTML — **images**, **video files**, **plain text**, or any **other content type**. It added `POST` and `HEAD` methods, changed the request/response **format**, added HTTP **headers** to both requests and responses, introduced **status codes** to **identify responses**, and brought in charset support, multipart types, authorization, caching, content encoding, and more.

Request:

``` http
GET / HTTP/1.0
```

Response:

``` http
HTTP/1.0 200 OK
...
```

Major drawbacks of HTTP/1.0:

<!-- TODO LINK -->
🚧🚧🚧

- No persistent connections — [[Three-way Handshake]]
- Head-of-line blocking
- Limited request methods
- Verbose headers
- Limited caching

### HTTP/1.1

Compared to HTTP/1.0:

- ***Persistent connections*** — allows multiple consecutive requests
- New methods: `PUT`, `PATCH`, `OPTIONS`, `DELETE`
- **Host header** became mandatory in HTTP/1.1
- **Pipelining**
- More status codes
- And more

> For details, see [RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616)

Drawbacks:

1. **Head-of-line Blocking**: Although HTTP/1.1 supports pipelining, TCP's in-order delivery means a delayed response can block subsequent requests.
2. **Performance Bottleneck**: HTTP/1.1 still uses text-based headers, which can lead to larger data transfers and parsing overhead.
3. **No Server Push**: HTTP/1.1 doesn't support the server proactively pushing resources to the client — all resources must be explicitly requested.
4. **Header Redundancy**: Headers are repeated in every request, especially costly when using mechanisms like cookies.
5. **Lack of Modern Web Support**: As web apps grow more complex, HTTP/1.1 struggles with massive concurrency and real-time data transfer.

### SPDY (from Google)
>
> SPDY was the precursor to [HTTP/2](https://en.wikipedia.org/wiki/HTTP/2).

### HTTP/2

Advantages:

1. **Binary Framing** (Frames and Streams)
    HTTP/2 breaks data into smaller **binary** frames, each with its own type and stream identifier. This framing enables more efficient data transfer and multiplexing.
2. **I/O Multiplexing**:
    HTTP/2 allows multiple requests and responses to run in **parallel** over a single connection, eliminating the head-of-line blocking problem from HTTP/1.x and improving page load speed.
3. **Header Compression**:
    HTTP/2 uses the **HPACK** algorithm to compress header data, reducing transfer size and latency. (Related: Huffman Coding?)
    [RFC7541](https://datatracker.ietf.org/doc/html/rfc7541)
4. **Server Push**:
    HTTP/2 enables the server to **proactively** push resources to the client — the server can send resources the client is likely to need before the client requests them, improving page load efficiency.
5. **Prioritization and Dependencies**:
    HTTP/2 lets clients specify request priorities, so the server can optimize resource delivery order.
6. **Persistent Connections**:
    HTTP/2 uses persistent connections by default, reducing connection setup and teardown overhead.
7. **Backward Compatibility**:
    HTTP/2 maintains semantic compatibility with HTTP/1.x, so existing applications can migrate with little or no modification.

Drawbacks:

1. **Implementation Complexity**: HTTP/2's binary framing and multiplexing increase protocol complexity, demanding more from server and client implementations.
2. **Security Dependency**: While HTTP/2 doesn't strictly require encryption, most browsers and servers mandate HTTPS, adding deployment complexity and cost.
3. **TCP Head-of-line Blocking**: While HTTP/2 solves head-of-line blocking at the application layer, it persists at the TCP layer since TCP delivers data in order.
4. **Server Push Challenges**: While server push can boost performance, improper use can waste bandwidth or cause client-cache issues.
5. **Compatibility Issues**: Despite semantic compatibility with HTTP/1.x, real-world deployments can encounter edge cases, especially with older network devices and middleware.
6. **Limited Gains for Optimized Sites**: Well-optimized HTTP/1.x websites may not see dramatic performance improvements from migrating to HTTP/2.

## SSL, TLS, HTTPS

?

- **SSL/TLS**: These protocols sit between the application layer and the transport layer, providing encryption for upper-layer protocols. They establish a secure communication channel between client and server.
- **HTTPS**: This is an application-layer protocol that uses SSL/TLS to secure HTTP communication. HTTPS is the combination of HTTP and SSL/TLS, making web communication between browsers and servers secure.

## HTTP in Depth

### HTTP Request Packet

🚧🚧🚧

### HTTP Response Packet

🚧🚧🚧
**Response Headers** are a set of **key-value pairs** sent in an HTTP response. They provide **metadata** about the response — such as **content type**, **content length**, **cache control**, **server information**, and more. Response headers appear after the HTTP status line and before the response body, separated from the body by an empty line (CRLF).

```HTTP
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1234
Date: Mon, 21 Oct 2019 07:28:00 GMT
Server: Apache
```

### HTTP Methods

### HTTP Status Codes

- **1xx Informational** – Request received, continuing process
- **2xx Success** – Request received, understood, and accepted
- **3xx Redirection** – Further action required to complete the request
- **4xx Client Error** – Request contains bad syntax or cannot be fulfilled
- **5xx Server Error** – Server failed to fulfill an apparently valid request

## External Links

[What is HTTP](https://cs.fyi/guide/http-in-depth)

[SPDY](https://en.wikipedia.org/wiki/SPDY)

[HTTP docs](https://developer.mozilla.org/en-US/docs/Web/HTTP)
