---
# 普通文章模板（hugo new posts/<slug>/index.zh-cn.md）
# 字段说明：
#   description - 列表页摘要，一句话说明文章内容（SEO 也会用）
#   summary     - 目录/系列页导读，可选
#   draft       - true=草稿（本地可见，线上不发布），写完改 false
#   math        - 文章有 LaTeX 公式就改成 true（微积分/算法笔记）
#   categories  - 大类，例如 [Go]、[数学]、[操作系统]
#   tags        - 细标签，例如 [并发, xv6, 锁]
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
layout: post
date: {{ .Date }}
description: ""
summary: ""
draft: true
math: false
categories: []
tags: []
---
