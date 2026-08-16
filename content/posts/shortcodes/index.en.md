---
aliases:
  - /blog/shortcodes/
title: 'Building Your Own Shortcode'
date: 2025-03-03T16:52:18+08:00
draft: false
authors: ['Yeelight']
math: false
toc: true
comments: true
tags:
  - Hugo
  - Shortcode
---

## Why This?

While hunting for a new blog theme, I stumbled upon [hextra](https://github.com/imfing/hextra) — a beautiful Hugo theme that leverages Hugo's own [**Shortcodes**](https://gohugo.io/content-management/shortcodes/) to build elegant documentation, blogs, and websites right out of the box. I wanted to create my own custom shortcodes for my layout.

<!-- More -->

So — being the kind of person who can't go a day without browsing Bilibili — I decided to start with a **bilibili** embed shortcode. For reference, see [custom shortcodes](https://gohugo.io/content-management/shortcodes/#custom).

First, create **`layouts/shortcodes/bilibili.html`** under your theme directory:

```bash
mkdir -p layouts/shortcodes
touch layouts/shortcodes/bilibili.html
```

## Analyzing Existing Code

Let's look at how the Hextra theme author builds a shortcode:

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

1. **Getting Parameters**
   - The code uses [.Get method](https://gohugo.io/methods/shortcode/get/) to extract named parameters from the shortcode, e.g.:
     - `$title := .Get "title"` gets the title.
     - `$subtitle := .Get "subtitle"` gets the subtitle.
     - Similarly for `class`, `image`, `style`, `icon`, and `link`.
   - These parameters are passed when using the shortcode, e.g. `{\{< shortcode title="My Title" subtitle="Subtitle" >}\}`.
2. **Handling Links**

   - `$external := hasPrefix $link "http"` checks if the link starts with "http" — external links.
   - `$href := cond (strings.HasPrefix $link "/") ($link | relURL) $link` processes the link:
     - If it starts with "/", use `relURL` to make it a relative path.
     - Otherwise, leave it as-is.

   > Hugo has [documentation](https://gohugo.io/functions/) covering the various functions used here.

3. **Handling Image Paths**
   - `if hasPrefix $image "/"` checks if the image path starts with "/".
   - If so, uses [`relURL`](https://gohugo.io/functions/urls/relurl/#article) and [`strings.TrimPrefix`](https://gohugo.io/functions/strings/trimprefix/#article) to convert it to a relative path.
4. **HTML Structure**
   - **`<a>` tag**:
     - If `$link` exists, sets `href="{{ $href }}"`.
     - If external (`$external` is true), adds `target="_blank" rel="noreferrer"` to open in a new window.
     - Applies inline styles via `$style` with `safeCSS` for security.
     - The class string combines the user-supplied `$class` with a pile of Tailwind CSS utility classes for styling.
   - **Inside the card**:
     - A `<div>` wrapping the content with `hx-p-6` padding.
     - `<h3>` displays the title, with an optional icon (rendered via `partial "utils/icon.html"`).
     - `<p>` displays the subtitle with Markdown support via `markdownify`.
   - **Image**:
     - If `$image` is provided, renders an `<img>` tag with the processed path and `$imageClass`.

## Let's Build

First, let's look at the raw HTML for a Bilibili embed:

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

- `bvid` is the unique video identifier (BV number) — the only parameter we really need.
- Other parameters (`aid`, `cid`) are optional; just the BV number is enough for playback.

The goal: users provide only the BV number and get a video embed. For example:

```html
{{</* bilibili BV1x411w7Kc */>}}
```

Here's a basic version:

```html
{{/* Hugo shortcode for Bilibili embeds */}} {{- $bvid := .Get "bvid" -}}
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

Use it in your content:

```markdown
{{< media/bilibili bvid="BV1vrFieDE9f" >}}
```

Dang~~
{{< media/bilibili bvid="BV1vrFieDE9f" >}}

## Refactoring

Now let's add some CSS flair. Create `assets/css/custom.css` under your theme:

```shell
mkdir -p assets/css
touch assets/css/custom.css
```

Then update the shortcode:

```html
{{/* Hugo shortcode for Bilibili embeds */}} {{- $bvid := .Get "bvid" -}}
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

And that's it — a custom shortcode is done!
