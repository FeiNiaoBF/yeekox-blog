---
# 系列入口模板（hugo new posts/<series-name>/_index.md）
# 这个文件定义「系列」本身：标题、简介、阅读顺序说明。
# 系列下的文章用 weight 字段排序，不用改文件名编号。
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
layout: series
description: ""
summary: ""
pinned: false
draft: true
cascade:
  layout: post
---
