#!/usr/bin/env bash
# Vercel build script: download Go + Hugo toolchains, build site, index with Pagefind.
# Called from vercel.json buildCommand (installCommand intentionally empty).
set -euo pipefail

# Go toolchain — Hugo Modules (inyo theme) requires the `go` binary
GO_TGZ="$(curl -fsSL https://go.dev/VERSION?m=text | head -1).linux-amd64.tar.gz"
curl -fsSL -o go.tgz "https://go.dev/dl/${GO_TGZ}"
tar -xzf go.tgz
rm go.tgz

# Hugo extended — pinned to the version used locally
curl -fsSL -o hugo.tar.gz \
  https://github.com/gohugoio/hugo/releases/download/v0.164.0/hugo_extended_0.164.0_linux-amd64.tar.gz
tar -xzf hugo.tar.gz
rm hugo.tar.gz

export PATH="$PWD/go/bin:$PATH"
./hugo --gc --minify --baseURL "https://${VERCEL_PROJECT_PRODUCTION_URL:-yeekox-blog.vercel.app}"
npx --yes pagefind@1 --site public
