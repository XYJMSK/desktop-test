# ================================================================
#  Linux Desktop Container - 适配魔搭创空间
#  架构: 浏览器 → noVNC(7860) → websockify → TigerVNC(5901) → XFCE4
# ================================================================
FROM debian:bookworm

# 避免交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive

# ---------- 第一层：基础系统工具 + 中文支持 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo wget curl git vim nano unzip tar gzip \
    ca-certificates gnupg \
    dbus-x11 x11-utils xvfb xdotool \
    libxtst6 libxrender1 libxfixes3 libxrandr2 libxcursor1 \
    libasound2 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libgbm1 libpango-1.0-0 libcairo2 libnss3 libnspr4 \
    fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk fonts-noto-color-emoji \
    locales locales-all \
    fcitx fcitx-libpinyin fcitx-config-gtk \
    fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-ui-classic \
    scrot xclip htop neofetch jq \
    python3 python3-pip python3-venv websockify \
    net-tools iputils-ping procps \
    && rm -rf /var/lib/apt/lists/*

# 设置中文 locale
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# ---------- 第二层：XFCE4 桌面环境 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal xfce4-whiskermenu-plugin \
    xfce4-panel-profiles xfce4-notifyd xfce4-taskmanager \
    xfce4-screenshooter xfce4-appfinder \
    thunar-archive-plugin mousepad ristretto \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第三层：主题引擎 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    gtk2-engines-murrine gtk2-engines-pixbuf \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第四层：VNC 服务器 + 生成密码文件 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server tigervnc-common tigervnc-tools \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.vnc \
    && printf 'vncpass\nvncpass\nn\n' | tigervncpasswd \
    && chmod 600 /root/.vnc/passwd

# ---------- 第五层：noVNC ----------
RUN mkdir -p /opt/noVNC \
    && cd /opt/noVNC \
    && wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.6.0.tar.gz | tar xz --strip-components=1 \
    && wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.12.0.tar.gz | tar xz \
    && mv websockify-0.12.0 /opt/noVNC/utils/websockify

# # ---------- 第六层（已禁用）：Chrome ----------
# RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
#     && rm google-chrome-stable_current_amd64.deb \
#     && rm -rf /var/lib/apt/lists/*

# # ---------- 第七层（已禁用）：VS Code ----------
# RUN wget -qO /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends /tmp/vscode.deb \
#     && rm /tmp/vscode.deb \
#     && rm -rf /var/lib/apt/lists/*

# # ============================================================
# # qwenpaw 版本控制（已禁用）
# # ============================================================
# ENV QWENPAW_VERSION=latest

# # ---------- 安装 uv ----------
# RUN if [ ! -f /root/.local/bin/uv ]; then \
#     apt-get update && apt-get install -y --no-install-recommends curl && \
#     curl -LsSf https://astral.sh/uv/install.sh | sh && \
#     rm -rf /var/lib/apt/lists/*; \
#     fi

# ENV PATH="/root/.local/bin:$PATH"

# # ---------- 安装 Python 3.12 + qwenpaw ----------
# RUN /root/.local/bin/uv python install 3.12 && \
#     /root/.local/share/uv/python/cpython-3.12.13-linux-x86_64-gnu/bin/python3.12 -m venv /root/.qwenpaw/venv && \
#     /root/.qwenpaw/venv/bin/pip install --upgrade pip && \
#     if [ "${QWENPAW_VERSION}" = "latest" ]; then \
#         /root/.qwenpaw/venv/bin/pip install qwenpaw; \
#     else \
#         /root/.qwenpaw/venv/bin/pip install "qwenpaw==${QWENPAW_VERSION}"; \
#     fi

# # 确保 qwenpaw 在 PATH 中
# RUN ln -sf /root/.qwenpaw/venv/bin/qwenpaw /usr/local/bin/qwenpaw

# ---------- 复制入口脚本 ----------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root

EXPOSE 7860 8088

ENTRYPOINT ["/entrypoint.sh"]
