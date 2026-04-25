#!/bin/bash
set -e

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

ROOT_PASSWORD="${ROOT_PASSWORD:-123456}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

echo "root:${ROOT_PASSWORD}" | chpasswd

# ---------- 创建 xstartup ----------
mkdir -p /root/.vnc
printf '#!/bin/bash\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexport LANG=zh_CN.UTF-8\nexport LANGUAGE=zh_CN:zh\nexport LC_ALL=zh_CN.UTF-8\nexport GTK_IM_MODULE=fcitx\nexport QT_IM_MODULE=fcitx\nexport XMODIFIERS=@im=fcitx\nexport DefaultIMModule=fcitx\nfcitx -d 2>/dev/null\ndbus-run-session -- startxfce4\n' > /root/.vnc/xstartup
chmod +x /root/.vnc/xstartup
echo "xstartup created:"
cat /root/.vnc/xstartup
echo "---"

# ---------- 启动 VNC ----------
echo "启动 VNC 服务器 (${VNC_RESOLUTION} x ${VNC_DEPTH}bit)..."
vncserver :1 \
    -geometry "$VNC_RESOLUTION" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -dpi 96

sleep 5

# ---------- 启动 noVNC ----------
echo "启动 noVNC Web 服务 (端口 7860)..."
websockify --web /opt/noVNC 7860 localhost:5901 &

sleep 2

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  noVNC 访问地址: http://你的空间地址/vnc.html"
echo "========================================"

if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
