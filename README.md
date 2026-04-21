---
domain: multi-modal
tags:
- claude-code
- desktop-container
- AI-coding
datasets:
  evaluation: []
  test: []
  train: []
models: []
license: Apache License 2.0
---

# Claude Desktop Container

基于 Ubuntu 22.04 + XFCE 桌面 + Claude Code Best 的 Docker 容器，通过浏览器访问。

## 功能

- XFCE 轻量桌面环境
- noVNC 浏览器访问（端口 6080）
- VNC 连接（端口 5901）
- Claude Code Best (ccb) 自动启动

## Docker

镜像基于 ghcr.io/xyjmsk/claude-desktop-container:latest

#### Clone with HTTP
```bash
git clone https://www.modelscope.cn/studios/xyjmsk/Claude_desktop.git
```
