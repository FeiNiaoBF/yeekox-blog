---
title: "App Router 和 Pages Router 的区别"
date: 2026-04-23T00:25:08+08:00
draft: false  # Is this a draft? true/false！！！
author:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
weight:
tags:
  - next
  - react
---

Next.js 中，**App Router** 和 **Pages Router** 是两种不同的路由系统，各有特点。

Pages Router：

- **目录结构：** 基于pages` 目录，文件路径直接映射到 URL 路径。
- 组件类型：** 默认使用客组件（Client Components），在浏览器中渲染。
- **性：** 主要依赖于文件系路由规则，支持动态路由，但功能相对简单。
- *渲染方* 更适合静态生成和客户端。

App Router

- **目录结构：** 基于 `app` 目录，支持布局和更灵活的文件组织。
- **组件类型：** 默服务器组件（Server mponents），在服务器上渲染。
- **功能特性：** 支持嵌套并行路由、拦截路由等高级功
- **渲染方式：** 提供更好的代码服务器端渲染支持。
