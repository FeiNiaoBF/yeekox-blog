# Yeelight の 小屋

Yeelight 的个人博客，使用 **Hugo Extended** 与自研主题 **Inyo** 构建，记录技术学习、游戏体验与生活随笔。

## 博客地址

- GitHub Pages：<https://feiniaobf.github.io/yeekox-blog/>
- Vercel 镜像：<https://yeekox-blog.vercel.app/>

## 主题：Inyo 陰陽

本站使用我使用 AI 做的 Hugo 主题 [hugo-theme-inyo](https://github.com/FeiNiaoBF/hugo-theme-inyo) —— 纸墨二元主题

## 技术栈

| 组件 | 要求 |
|---|---|
| Hugo | Extended `0.164.0` 或更高 |
| 主题 | Inyo `v0.5.1` |
| Go | `1.26.1` 或更高（Hugo Modules 需要） |
| 搜索 | Pagefind（构建期生成索引） |

## 内容结构

```text
content/
├── _index.{zh-cn,en,ja}.md
├── about.{zh-cn,en,ja}.md
└── posts/                       # 首页与博客入口的主 section
    └── <slug>/
        └── index.{zh-cn,en,ja}.md   # 每篇文章一个 bundle，按语言分文件
```

中文为默认语言；文章通过 `.zh-cn.md` / `.en.md` / `.ja.md` 后缀绑定语言。

## 本地开发

```shell
hugo mod tidy
hugo server --buildDrafts --disableFastRender
```

正式构建检查：

```shell
hugo --minify --printPathWarnings
```

写新文章可运行 `scripts/new-hugo-post.ps1`（自动创建三语文件），或手动在 `content/posts/` 下新建 bundle。

## 部署

- GitHub Pages：`.github/workflows/pages.yaml`（构建 + Pagefind 索引 + 自动部署）
- Vercel：`vercel.json`，构建逻辑在 `scripts/vercel-build.sh`（自动下载 Go/Hugo 工具链并生成 Pagefind 索引）

两个部署入口统一使用 Hugo `0.164.0`，满足 Inyo 的最低版本要求。
