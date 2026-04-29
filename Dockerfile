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
    thunar-archive-plugin mousepad ristretto exo-utils \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第三层：主题引擎 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    gtk2-engines-murrine gtk2-engines-pixbuf \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第四层：VNC 服务器 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server tigervnc-common tigervnc-tools \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.vnc \
    && printf 'vncpass\nvncpass\nn\n' | tigervncpasswd \
    && chmod 600 /root/.vnc/passwd

# ---------- 第五层：Chrome（Google Chrome，加超时重试） ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg \
    && wget -q --timeout=60 --tries=3 \
       https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# ---------- 第六层：uv ----------
RUN pip install --break-system-packages uv

# ---------- 第七层：qwenpaw ----------
RUN python3 -m venv /root/.qwenpaw/venv \
    && uv pip install --python /root/.qwenpaw/venv/bin/python --no-cache qwenpaw \
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
