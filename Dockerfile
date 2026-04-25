FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV DEBIAN_FRONTEND=noninteractive

# ---------- 中文支持 + 输入法 ----------
RUN apt-get update &amp;&amp; apt-get install -y --no-install-recommends \
    fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk fonts-noto-color-emoji \
        locales locales-all \
            fcitx fcitx-libpinyin fcitx-config-gtk \
                fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-ui-classic \
                    &amp;&amp; rm -rf /var/lib/apt/lists/*

                    ENV LANG=zh_CN.UTF-8d
                    ENV LANGUAGE=zh_CN:zh
                    ENV LC_ALL=zh_CN.UTF-8

                    # ---------- 常用工具 ----------
                    RUN apt-get update &amp;&amp; apt-get install -y --no-install-recommends \
                        vim nano htop neofetch jq git curl wget unzip \
                            python3 python3-pip \
                                net-tools iputils-ping procps \
                                    &amp;&amp; rm -rf /var/lib/apt/lists/*

                                    # ---------- 可选：Google Chrome ----------
                                    RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
                                        &amp;&amp; apt-get update \
                                            &amp;&amp; apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
                                                &amp;&amp; rm google-chrome-stable_current_amd64.deb \
                                                    &amp;&amp; rm -rf /var/lib/apt/lists/*

                                                    # ---------- 可选：VS Code ----------
                                                    RUN wget -qO /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&amp;os=linux-deb-x64" \
                                                        &amp;&amp; apt-get update \
                                                            &amp;&amp; apt-get install -y --no-install-recommends /tmp/vscode.deb \
                                                                &amp;&amp; rm /tmp/vscode.deb \
                                                                    &amp;&amp; rm -rf /var/lib/apt/lists/*

                                                                    # ---------- 输入法环境变量 ----------
                                                                    ENV GTK_IM_MODULE=fcitx
                                                                    ENV QT_IM_MODULE=fcitx
                                                                    ENV XMODIFIERS=@im=fcitx
                                                                    ENV DefaultIMModule=fcitx

                                                                    # ---------- 自启动 fcitx ----------
                                                                    RUN mkdir -p /etc/xdg/autostart &amp;&amp; \
                                                                        echo "[Desktop Entry]\nName=Fcitx\nExec=fcitx -d\nType=Application\nX-GNOME-Autostart-enabled=true" > /etc/xdg/autostart/fcitx.desktop