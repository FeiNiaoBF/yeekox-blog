# Yeelight の 小屋

Yeelight 的个人博客，使用 Hugo Extended 与 Inyo 主题构建，记录技术学习、游戏体验和长期笔记。

## 技术要求

- Hugo Extended `0.164.0` 或更高版本
- Go `1.26.1` 或更高版本（Hugo Modules 需要）
- Inyo `v0.5.1`

## 内容结构

```text
content/
├── _index.{zh-cn,en,ja}.md
├── about.{zh-cn,en,ja}.md
└── posts/
```

`posts` 是首页和博客入口使用的主 section。Hugo 的其他顶层目录仍可按需要添加；只有配置到 `params.mainSections` 或导航中的目录才会成为主题的主入口。

站点启用中文、英文和日文三语。中文是默认语言，文章文件通过 `.zh-cn.md`、`.en.md` 和 `.ja.md` 后缀绑定语言。

## 本地开发

```shell
hugo mod tidy
hugo server --buildDrafts --disableFastRender
```

正式构建检查：

```shell
hugo --minify --printPathWarnings
```

站点保留 LaTeX passthrough 配置，主题通过站点参数或文章 Front Matter 的 `math: true` 启用 KaTeX。

## 部署

- GitHub Pages：`.github/workflows/pages.yaml`（构建 + Pagefind 搜索索引 + 自动部署）
- Vercel：`vercel.json`，构建逻辑在 `scripts/vercel-build.sh`（自动下载 Go/Hugo 工具链并生成 Pagefind 索引）

写新文章可使用 `scripts/new-hugo-post.ps1`（自动创建三语文件）。

所有部署入口统一使用 Hugo `0.164.0`，避免低于 Inyo 的最低版本要求。

## 主题

Inyo 提供纸墨双模式、三语切换、文章目录、标签、数学公式和响应式长文阅读布局。主题源码位于独立仓库：

<https://github.com/FeiNiaoBF/hugo-theme-inyo>
