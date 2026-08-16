---
aliases:
  - /blog/go_env_var/
title: "Environment Variables in Go"
date: 2026-04-23T19:19:27+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png
math: false
toc: true
comments: true
tags:
  - Go
  - Environment
  - CLI
---

In Go, environment variables provide a mechanism for supplying configuration at runtime. They're used to store database connection strings, API keys, configuration options, and other sensitive data — without hard-coding them into your source.

## What Each Go Environment Variable Does

Run `go env` in your shell to see all environment variables:

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

Here's what each one means:

- `GO111MODULE`: Controls Go module support. Set to `on` to always enable modules. *(important)*
- `GOARCH`: Target platform architecture, e.g. `amd64`, `arm64`.
- `GOBIN`: Directory where Go binaries are installed.
- `GOCACHE`: Directory for the Go build cache.
- `GOENV`: Path to the Go environment variable file.
- `GOEXE`: Executable file extension, typically `.exe` on Windows.
- `GOEXPERIMENT`: Controls Go experimental features.
- `GOFLAGS`: Default Go build flags.
- `GOHOSTARCH`: Host platform architecture.
- `GOHOSTOS`: Host platform operating system.
- `GOINSECURE`: Module paths to fetch insecurely.
- `GOMODCACHE`: Directory for the Go module cache.
- `GONOPROXY`: Module paths that bypass the proxy. *(important)*
- `GONOSUMDB`: Module paths that bypass the checksum database. *(important)*
- `GOOS`: Target operating system.
- `GOPATH`: Go workspace path. *(important)*
- `GOPRIVATE`: Private module paths.
- `GOPROXY`: Go module proxy URL. *(important)*
- `GOROOT`: Go installation directory. *(important)*
- `GOSUMDB`: Go module checksum database URL.
- `GOTMPDIR`: Directory for Go temporary files.
- `GOTOOLCHAIN`: Go toolchain version.
- `GOTOOLDIR`: Directory for Go tools.
- `GOVCS`: Version control system settings.
- `GOVERSION`: Go version.
- `GODEBUG`: Go runtime debug options.
- `GOTELEMETRY`: Go runtime telemetry options.
- `GOTELEMETRYDIR`: Directory for Go telemetry data.
- `GCCGO`: The gccgo compiler to use.
- `GOAMD64`: AMD64-specific options.
- `AR`: Archiver tool.
- `CC`: C compiler.
- `CXX`: C++ compiler.
- `CGO_ENABLED`: Whether CGO support is enabled.
- `GOMOD`: Path to the Go module file.
- `GOWORK`: Go workspace path.
- `CGO_CFLAGS`: CGO compiler CFLAGS.
- `CGO_CPPFLAGS`: CGO compiler CPPFLAGS.
- `CGO_CXXFLAGS`: CGO compiler CXXFLAGS.
- `CGO_FFLAGS`: CGO compiler FFLAGS.
- `CGO_LDFLAGS`: CGO compiler LDFLAGS.
- `PKG_CONFIG`: pkg-config tool.
- `GOGCCFLAGS`: Extra flags passed to gcc by Go.
