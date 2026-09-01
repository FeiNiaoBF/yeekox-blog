---
# 兜底模板（posts/ 以外的内容，如 about 等）
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
