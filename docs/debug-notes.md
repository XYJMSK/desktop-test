# 魔搭 Linux 桌面镜像调试笔记

> 本文档记录魔搭创空间 Linux Desktop 容器的完整调试过程，包括遇到的问题、根因及解决方案。

---

## 问题一：heredoc (`<<'EOF'`) 在 sh 中不工作

**现象**：`entrypoint.sh` 中的 heredoc 语法在容器启动时无法创建文件，`/root/.vnc/xstartup` 不存在。

**根因**：魔搭容器使用 `sh`（Debian 上是 dash）而非 `bash`。dash 不支持 heredoc 语法（`<<'HEREDOC'`），会直接报错 "Syntax error: end of file unexpected"。

**解决**：改用 `printf` 命令写入文件内容。

```bash
# ❌ 不生效（dash 不支持 heredoc）
cat > /root/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
exec startxfce4
XSTARTUP

# ✅ 正确写法
printf '%s\n' \
  '#!/bin/bash' \
  'exec startxfce4' \
  > /root/.vnc/xstartup
chmod +x /root/.vnc/xstartup
```

---

## 问题二：TigerVNC `vncpasswd` 命令不存在

**现象**：构建时报错 `vncpasswd: command not found`。

**根因**：Debian bookworm 环境下，TigerVNC 不再提供独立的 `vncpasswd` 命令，只有 `tigervncpasswd`。且该命令默认需要 TTY 交互式输入密码。

**解决**：用管道自动填充密码（非交互式）。

```bash
printf 'vncpass\nvncpass\nn\n' | tigervncpasswd
```

注意第二个 `\n`（输入 `n` 后回车）用于跳过"是否设为 view-only 密码"的提示。

---

## 问题三：websockify 命令找不到

**现象**：`websockify: command not found`，noVNC 无法连接到 VNC 后端。

**根因**：
1. pip 安装的 `websockify` 包创建了 `/usr/local/bin/websockify` 目录（不是文件），导致 PATH 冲突
2. `/opt/noVNC/utils/websockify/websockify` 是一个 Python 脚本，被 pip 覆盖成目录后无法执行

**解决**：
```bash
# 移除 pip 覆盖的目录（如果 websockify 被安装成目录）
rm -rf /usr/local/bin/websockify
# pip install websockify 会创建一个同名的目录而非脚本
# 直接用 pip 安装的包，websockify 命令可用
```

---

## 问题四：`-xstartup` 参数失效，xfce4 桌面不启动

**现象**：VNC 连接成功，但显示的是空黑屏或宿主机目录，而非 Linux 桌面。

**根因**：
1. 早期版本的 `entrypoint.sh` 未显式指定 `-xstartup` 参数，VNC 使用默认的 minimal xstartup（只有 xterm）
2. 后来用 heredoc 写的 xstartup 因 dash 不支持 heredoc 而根本没有创建成功
3. 无 `-SecurityTypes` 参数时，TigerVNC 强制要求密码认证并拒绝无密码模式

**解决**：
```bash
# 创建 xstartup（用 printf 写法）
printf '%s\n' \
  '#!/bin/bash' \
  'unset SESSION_MANAGER' \
  'unset DBUS_SESSION_BUS_ADDRESS' \
  'export LANG=zh_CN.UTF-8' \
  'fcitx -d 2>/dev/null' \
  'dbus-run-session -- /usr/bin/startxfce4' \
  > /root/.vnc/xstartup
chmod +x /root/.vnc/xstartup

# 启动 VNC（显式指定 -xstartup）
vncserver :1 \
    -geometry "1920x1080" \
    -depth 24 \
    -localhost no \
    -xstartup /root/.vnc/xstartup \
    -SecurityTypes None --I-KNOW-THIS-IS-INSECURE \
    -dpi 96
```

**关键点**：
- `dbus-run-session -- startxfce4`：xfce4 需要 D-Bus session 环境
- `--I-KNOW-THIS-IS-INSECURE`：无密码模式必须加此参数
- `-localhost no`：允许非本地连接（noVNC 从外部连接）

---

## 问题五：noVNC HTML/JS 版本不匹配（clipboard 空指针）

**现象**：noVNC 连接成功但报错 `Cannot read properties of null (reading 'addEventListener')`，点击 `vnc.html` 显示错误页，但 `vnc_lite.html` 能正常打开桌面。

**根因**：
- noVNC v1.6.0 重写了 UI，在 `app/ui.js` 的 `addClipboardHandlers()` 函数中存在空指针引用
- `document.getElementById("noVNC_clipboard_button").addEventListener(...)` 在该元素不存在时直接崩溃
- 这是 v1.6.0 新 UI 的 regression bug，v1.5.0 中无此问题

**解决**：降级到 noVNC v1.5.0（稳定版）。

```dockerfile
# ---------- 第五层：noVNC ----------
ENV NO_VNC_VERSION=1.5.0
RUN mkdir -p /opt/noVNC \
    && cd /opt/noVNC \
    && wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | tar xz --strip-components=1 \
    && wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.12.0.tar.gz | tar xz \
    && mv websockify-0.12.0 /opt/noVNC/utils/websockify
```

---

## 问题六：魔搭镜像构建缓存

**现象**：多次推送代码修改，但构建仍然很快，日志内容没有变化，说明魔搭跳过了 Dockerfile 重新构建。

**原因**：魔搭对 Docker 镜像层有缓存策略，仅修改 `entrypoint.sh`（COPY 层之后）不足以触发重建。

**解决**：
1. 下线项目后重新上线（强制刷新镜像）
2. 在 Dockerfile 的早期层添加修改（如加一个 `ENV` 变量），强制使后续层失效
3. 如果魔搭有"禁用缓存构建"选项，务必勾选

---

## 完整架构图

```
浏览器 → noVNC(7860) → websockify → TigerVNC(:1/5901) → XFCE4/X11
```

- **noVNC**：Web 端 VNC 客户端（通过浏览器访问）
- **websockify**：WebSocket 到 TCP VNC 协议的转换代理
- **TigerVNC**：VNC 服务器，提供 X11 会话
- **XFCE4**：Linux 桌面环境（通过 dbus-run-session 启动）

---

## 关键文件清单

| 文件 | 作用 |
|------|------|
| `Dockerfile` | 容器镜像构建定义 |
| `entrypoint.sh` | 容器启动脚本（创建 xstartup → 启动 VNC → 启动 noVNC） |
| `/root/.vnc/xstartup` | VNC 会话启动脚本（启动 fcitx + xfce4） |
| `/opt/noVNC/` | noVNC Web 文件目录 |
| `5901` | VNC 服务端口（display :1） |
| `7860` | noVNC/WebSocket 端口 |

---

## 最终 Dockerfile 关键配置

```dockerfile
FROM debian:bookworm

# 中文 + fcitx 输入法支持
RUN apt-get install -y locales locales-all fcitx fcitx-libpinyin

# XFCE4 桌面环境
RUN apt-get install -y xfce4 xfce4-terminal

# TigerVNC 服务器（无密码模式）
RUN apt-get install -y tigervnc-standalone-server tigervnc-common \
    && printf 'vncpass\nvncpass\nn\n' | tigervncpasswd

# noVNC v1.5.0（稳定版，无 clipboard bug）
RUN mkdir -p /opt/noVNC \
    && wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | tar xz --strip-components=1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 7860 8088
WORKDIR /root
CMD ["/entrypoint.sh"]
```

## 最终 entrypoint.sh 核心逻辑

1. 创建 `/root/.vnc/xstartup`（printf 写法，dash 兼容）
2. 启动 `vncserver :1`（指定 xstartup、无密码模式）
3. 启动 `websockify --web /opt/noVNC 7860 localhost:5901`
4. 访问 `http://空间地址/vnc.html` 即可连接桌面
