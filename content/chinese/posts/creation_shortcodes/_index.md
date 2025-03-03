---
title: '[主题创作]做一个自己的短代码'
date: 2025-03-03T16:52:18+08:00
draft: false # Is this a draft? true/false！！！
author: ['Yeelight']
math: false
toc: true
excludeSearch: true
---

## 起因

我在重新寻找自己博客的时候，发现了一个好看的主题[hextra](https://github.com/imfing/hextra)，利用了hugo自己的[**Shortcodes**](https://gohugo.io/content-management/shortcodes/)功能来实现了专为构建美观的文档、博客和网站而设计，它提供了开箱即用的功能和灵活性，以满足各种需求。我想来做属于自己的代码layout。

<!-- More -->

好的，对于一天不看 b 站就难受的我来说，先来做一个**bilibili**的嵌入代码把。具体的参考看[custom](https://gohugo.io/content-management/shortcodes/#custom)。

我们先在自己的主题下目录中新建 **`layouts/shortcodes/bilibili.html`**

```bash
mkdir -p layouts/shortcodes
touch layouts/shortcodes/bilibili.html
```

## **分析现有代码**

主要想做一个符合 `hextra` 的短代码就先来看看作者怎么做的

```html
{{- $title := .Get "title" -}}
{{- $subtitle := .Get "subtitle" -}}
{{- $class := .Get "class" -}}
{{- $image := .Get "image" -}}
{{- $imageClass := .Get "imageClass" -}}
{{- $style := .Get "style" -}}
{{- $icon := .Get "icon" -}}
{{- $link := .Get "link" -}}

{{- $external := hasPrefix $link "http" -}}
{{- $href := cond (strings.HasPrefix $link "/") ($link | relURL) $link -}}

{{- if hasPrefix $image "/" -}}
  {{- $image = relURL (strings.TrimPrefix "/" $image) -}}
{{- end -}}

<a
  {{ with $link }}href="{{ $href }}" {{ with $external }} target="_blank" rel="noreferrer"{{ end }}{{ end }}
  {{ with $style }}style="{{ . | safeCSS }}"{{ end }}
  class="{{ $class }} hextra-feature-card not-prose hx-block hx-relative hx-overflow-hidden hx-rounded-3xl hx-border hx-border-gray-200 hover:hx-border-gray-300 dark:hx-border-neutral-800 dark:hover:hx-border-neutral-700 before:hx-pointer-events-none before:hx-absolute before:hx-inset-0 before:hx-bg-glass-gradient"
>
  <div class="hx-relative hx-w-full hx-p-6">
    <h3 class="hx-text-2xl hx-font-medium hx-leading-6 hx-mb-2 hx-flex hx-items-center">
      {{ with $icon -}}
        <span class="hx-pr-2">
          {{- partial "utils/icon.html" (dict "name" . "attributes" "height=1.5rem") -}}
        </span>
      {{ end -}}
      <span>{{ $title }}</span>
    </h3>
    <p class="hx-text-gray-500 dark:hx-text-gray-400 hx-text-sm hx-leading-6">{{ $subtitle | markdownify }}</p>
  </div>
  {{- with $image -}}
    <img src="{{ . }}" class="hx-absolute hx-max-w-none {{ $imageClass }}" alt="{{ $title }}" />
  {{- end -}}
</a>
```

1. **获取参数**
   - 代码开头使用 [.Get 方法](https://gohugo.io/methods/shortcode/get/)从 Shortcode 中提取命名参数，例如：
     - `$title := .Get "title"` 获取标题。
     - `$subtitle := .Get "subtitle"` 获取副标题。
     - 类似地，还获取了 `class`、`image`、`style`、`icon` 和 `link` 等参数。
   - 这些参数是在使用 Shortcode 时传入的，例如 `{\{< shortcode title="我的标题" subtitle="副标题" >}\}`。
2. **处理链接**

   - `$external := hasPrefix $link "http"` 检查链接是否以 "http" 开头，判断是否为外部链接。
   - `$href := cond (strings.HasPrefix $link "/") ($link | relURL) $link` 处理链接：
     - 如果链接以 "/" 开头，使用 relURL 函数将其转为相对路径。
     - 否则，保持原样。

   > 对于不同的`functions` hugo 做了相关[文档](https://gohugo.io/functions/)

3. **处理图片路径**
   - `if hasPrefix $image "/"` 检查图片路径是否以 "/" 开头。
   - 如果是，使用 [`relURL`](https://gohugo.io/functions/urls/relurl/#article) 和 [`strings.TrimPrefix`](https://gohugo.io/functions/strings/trimprefix/#article) 将其处理为相对路径，确保图片路径正确。
4. **HTML 结构**
   - **`<a>` 标签**：
     - 如果有 $link，设置 href="{{ $href }}"。
     - 如果是外部链接（$external 为真），添加 `target="\_blank" rel="noreferrer"`，让链接在新窗口打开。
     - 使用 $style 设置内联样式，通过 safeCSS 确保安全。
     - 类名由用户传入的 $class 和一堆预定义的 Tailwind CSS 类组成，用于样式控制。
   - **内部结构**：
     - 一个 `<div>` 包含内容，内边距为 hx-p-6。
     - `<h3>` 显示标题，支持可选图标（通过 partial "utils/icon.html" 渲染）。
     - `<p>` 显示副标题，支持 Markdown 渲染（markdownify）。
   - **图片**：
     - 如果提供了 $image，渲染一个 `<img>` 标签，路径为处理后的 $image，类名为 $imageClass。

## 开始动手

先来看看 HTML 中 `Bilibili` 嵌入代码

```html
<iframe
  src="//player.bilibili.com/player.html?bvid=BV1x411w7Kc"
  scrolling="no"
  border="0"
  frameborder="no"
  framespacing="0"
  allowfullscreen="true">
</iframe>
```

- bvid 是视频的唯一标识符（BV 号），这是我们最需要关注的参数。
- 其他参数（如 aid 和 cid）可选，但只需 bvid 即可正常播放。

希望用户只需提供 BV 号，就能嵌入视频。例如：

```html
{{</* bilibili BV1x411w7Kc */>}}
```

先来写写简单的版本

```html
{{/* 利用 Hugo 的shortcode做的嵌入式bilibili */}} {{- $bvid := .Get "bvid" -}}
{{- if not $bvid -}} {{- errorf "bvid is required" -}} {{- end -}}

<iframe
  src="//player.bilibili.com/player.html?bvid={{ $bvid }}"
  scrolling="no"
  border="0"
  frameborder="no"
  framespacing="0"
  allowfullscreen="true"
  style="width: 100%; height: 500px;">
  </iframe>
```

在自己的文档使用

```markdown
 {\{< media/bilibili bvid="BV1vrFieDE9f" >}\}
```

Dang~~
{{< media/bilibili bvid="BV1vrFieDE9f" >}}

## 重构

好的，现在加上点 `css` 样式

我们先在自己的主题下目录中新建`assets/css/custom.css`

```shell
mkdir -p assets/css
touch assets/css/custom.css
```

修改已有的代码

```html
{{/* 利用 Hugo 的shortcode做的嵌入式bilibili */}} {{- $bvid := .Get "bvid" -}}
{{- $width := .Get "width" | default "100%" -}} {{- $height := .Get "height" |
default "500" -}} {{- if not $bvid -}} {{- errorf "bvid is required" -}} {{- end
-}}

<div
  class="hextra-bilibili-container hx-relative hx-w-full \
        hx-rounded-2xl hx-border hx-border-gray-200 hx-bg-white \
        dark:hx-border-neutral-800 dark:hx-bg-neutral-900  \
        hx-overflow-hidden hx-shadow-md hover:hx-shadow-lg hx-transition-all">
  <iframe
    src="//player.bilibili.com/player.html?bvid={{ $bvid }}"
    scrolling="no"
    border="0"
    frameborder="no"
    framespacing="0"
    allowfullscreen="true"
    class="hx-w-full"
    style="aspect-ratio: 16/9;"
    width="{{ $width }}"
    style="width: {{ $width }}; height: {{ $height }};">
  </iframe>
</div>
```

好的，到此，就做好一个 Shortcode 了
