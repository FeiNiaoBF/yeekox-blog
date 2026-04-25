---
title: "Go 中的环境变量"
date: 2026-04-23T19:19:27+08:00
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
  - Go
  - Environment
  - CLI
---

在 Go 语言中，环境变量是一种在运行时提供配置信息的机制。环境变量可以用于存储数据库连接字符串、API 密钥、配置选项等敏感信息，而不需要将它们硬编码在代码中。

## 了解每个GO文件的用途

在自己的 Bash 中，使用`go env`可以查看所有的环境变量

```bash
set GO111MODULE=on
set GOARCH=amd64
set GOBIN=C:\Users\User\local\envs\go\gopath\bin
set GOCACHE=C:\Users\User\AppData\Local\go-build
set GOENV=C:\Users\User\AppData\Roaming\go\env
set GOEXE=.exe
set GOEXPERIMENT=
set GOFLAGS=
set GOHOSTARCH=amd64
set GOHOSTOS=windows
set GOINSECURE=
set GOMODCACHE=C:\Users\User\local\envs\go\gopath\pkg\mod
set GONOPROXY=
set GONOSUMDB=
set GOOS=windows
set GOPATH=C:\Users\User\local\envs\go\gopath
set GOPRIVATE=
set GOPROXY=https://proxy.golang.org,direct
set GOROOT=C:\Users\User\local\envs\go\root\go1.23
set GOSUMDB=sum.golang.org
set GOTMPDIR=
set GOTOOLCHAIN=auto
set GOTOOLDIR=C:\Users\User\local\envs\go\root\go1.23\pkg\tool\windows_amd64
set GOVCS=
set GOVERSION=go1.23.5
set GODEBUG=
set GOTELEMETRY=local
set GOTELEMETRYDIR=C:\Users\User\AppData\Roaming\go\telemetry
set GCCGO=gccgo
set GOAMD64=v1
set AR=ar
set CC=gcc
set CXX=g++
set CGO_ENABLED=1
set GOMOD=NUL
set GOWORK=
set CGO_CFLAGS=-O2 -g
set CGO_CPPFLAGS=
set CGO_CXXFLAGS=-O2 -g
set CGO_FFLAGS=-O2 -g
set CGO_LDFLAGS=-O2 -g
set PKG_CONFIG=pkg-config
set GOGCCFLAGS=-m64 -mthreads -Wl,--no-gc-sections -fmessage-length=0 -ffile-prefix-map=C:\Users\Yeekox\AppData\Local\Temp\go-build2284745370=/tmp/go-build -gno-record-gcc-switches
```

下面就分别来说明一下：

- `GO111MODULE`：控制 Go 模块支持的环境变量。设置为 `on` 表示始终启用模块支持。 (重要)
- `GOARCH`：指定目标平台的架构，例如 `amd64`、`arm64` 等。
- `GOBIN`：指定 Go 可执行文件的安装目录。
- `GOCACHE`：指定 Go 构建缓存的目录。
- `GOENV`：指定 Go 环境变量文件的路径。
- `GOEXE`：指定 Go 可执行文件的扩展名，通常在 Windows 上为 `.exe`。
- `GOEXPERIMENT`：控制 Go 实验性功能的环境变量。
- `GOFLAGS`：指定默认的 Go 构建标志。
- `GOHOSTARCH`：指定主机平台的架构。
- `GOHOSTOS`：指定主机平台的操作系统。
- `GOINSECURE`：指定不安全的模块路径。
- `GOMODCACHE`：指定 Go 模块缓存的目录。
- `GONOPROXY`：指定不使用代理的模块路径。（重要）
- `GONOSUMDB`：指定不使用校验和数据库的模块路径。（重要）
- `GOOS`：指定目标平台的操作系统。
- `GOPATH`：指定 Go 工作区的路径。（重要）
- `GOPRIVATE`：指定私有模块路径。
- `GOPROXY`：指定 Go 模块代理的 URL。（重要）
- `GOROOT`：指定 Go 安装目录。（重要）
- `GOSUMDB`：指定 Go 模块校验和数据库的 URL。
- `GOTMPDIR`：指定 Go 临时文件的目录。
- `GOTOOLCHAIN`：指定 Go 工具链的版本。
- `GOTOOLDIR`：指定 Go 工具的目录。
- `GOVCS`：指定版本控制系统的环境变量。
- `GOVERSION`：指定 Go 版本。
- `GODEBUG`：控制 Go 运行时调试选项的环境变量。
- `GOTELEMETRY`：控制 Go 运行时遥测选项的环境变量。
- `GOTELEMETRYDIR`：指定 Go 运行时遥测数据的目录。
- `GCCGO`：指定使用的 gccgo 编译器。
- `GOAMD64`：指定 AMD64 架构的特定选项。
- `AR`：指定使用的归档工具。
- `CC`：指定使用的 C 编译器。
- `CXX`：指定使用的 C++ 编译器。
- `CGO_ENABLED`：控制是否启用 CGO 支持。
- `GOMOD`：指定 Go 模块文件的路径。
- `GOWORK`：指定 Go 工作区的路径。
- `CGO_CFLAGS`：指定 CGO 编译器的 CFLAGS。
- `CGO_CPPFLAGS`：指定 CGO 编译器的 CPPFLAGS。
- `CGO_CXXFLAGS`：指定 CGO 编译器的 CXXFLAGS。
- `CGO_FFLAGS`：指定 CGO 编译器的 FFLAGS。
- `CGO_LDFLAGS`：指定 CGO 编译器的 LDF
- `PKG_CONFIG`：指定使用的 pkg-config 工具。
- `GOGCCFLAGS`：指定 Go 使用的 gcc 编译器的额外标志。
