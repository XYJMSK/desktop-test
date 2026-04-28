# ================================================================
#  Linux Desktop Container - 适配魔搭创空间
#  架构: 浏览器 → noVNC(7860) → websockify → TigerVNC(5901) → XFCE4
# ================================================================
FROM debian:bookworm

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
    python3 python3-pip python3-venv websockify rsync inotify-tools \
    net-tools iputils-ping procps \
    && rm -rf /var/lib/apt/lists/*
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
ENV NO_VNC_VERSION=1.5.0
RUN mkdir -p /opt/noVNC \
    && cd /opt/noVNC \
    && wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz | tar xz --strip-components=1 \
    && wget -qO- https://github.com/novnc/websockify/archive/refs/tags/v0.12.0.tar.gz | tar xz \
    && mv websockify-0.12.0 /opt/noVNC/utils/websockify

# ---------- 第六层：Chrome ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg \
    && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第七层：uv ----------
RUN curl -LsSf https://astral.sh/uv/0.6.6/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# ---------- 第八层：qwenpaw（hermes-agent 方案：用系统 Python 建 venv） ----------
RUN python3 -m venv /root/.qwenpaw/venv \
    && /root/.local/bin/uv pip install --python /root/.qwenpaw/venv/bin/python --no-cache qwenpaw \
    && ln -sf /root/.qwenpaw/venv/bin/qwenpaw /usr/local/bin/qwenpaw \
    && echo "=== qwenpaw 验证 ===" \
    && /root/.qwenpaw/venv/bin/qwenpaw --version

# ---------- 复制入口脚本 ----------
COPY sync.sh /root/sync.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /root/sync.sh

WORKDIR /root

EXPOSE 7860 8088

ENTRYPOINT ["/entrypoint.sh"]
