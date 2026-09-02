---
title: "App Router vs Pages Router in Next.js"
date: 2026-04-23T00:25:08+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - next
  - react
---

Next.js offers two routing systems — **App Router** and **Pages Router** — each with different characteristics.

**Pages Router:**

- **Directory Structure:** Based on the `pages/` directory; file paths map directly to URL routes.
- **Component Type:** Defaults to Client Components, rendered in the browser.
- **Capabilities:** Relies primarily on filesystem-based routing rules. Supports dynamic routes but with relatively simple functionality.
- **Rendering:** Better suited for static generation and client-side rendering.

**App Router:**

- **Directory Structure:** Based on the `app/` directory, supporting layouts and more flexible file organization.
- **Component Type:** Defaults to Server Components, rendered on the server.
- **Capabilities:** Supports nested layouts, parallel routes, intercepting routes, and other advanced patterns.
- **Rendering:** Offers improved code splitting and server-side rendering support.
