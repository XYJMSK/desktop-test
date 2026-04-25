FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV DEBIAN_FRONTEND=noninteractive

# ---------- 中文支持 + 输入法 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk fonts-noto-color-emoji \
    locales locales-all \
    fcitx fcitx-libpinyin fcitx-config-gtk \
    fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-ui-classic \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8

# ---------- 常用工具 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim nano htop neofetch jq git curl wget unzip \
    python3 python3-pip \
    net-tools iputils-ping procps \
    && rm -rf /var/lib/apt/lists/*

# ---------- 输入法环境变量 ----------
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV DefaultIMModule=fcitx

# ---------- 自启动 fcitx ----------
RUN mkdir -p /etc/xdg/autostart && \
    echo "[Desktop Entry]\nName=Fcitx\nExec=fcitx -d\nType=Application\nX-GNOME-Autostart-enabled=true" > /etc/xdg/autostart/fcitx.desktop
