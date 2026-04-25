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
printf '%s\n' \
  '#!/bin/bash' \
  'unset SESSION_MANAGER' \
  'unset DBUS_SESSION_BUS_ADDRESS' \
  'export LANG=zh_CN.UTF-8' \
  'export LANGUAGE=zh_CN:zh' \
  'export LC_ALL=zh_CN.UTF-8' \
  'export GTK_IM_MODULE=fcitx' \
  'export QT_IM_MODULE=fcitx' \
  'export XMODIFIERS=@im=fcitx' \
  'export DefaultIMModule=fcitx' \
  'fcitx -d 2>/dev/null' \
  'dbus-run-session -- /usr/bin/startxfce4' \
  > /root/.vnc/xstartup
chmod +x /root/.vnc/xstartup

echo "=== xstartup 内容 ==="
cat /root/.vnc/xstartup
echo "=== 确认文件存在 ==="
ls -la /root/.vnc/xstartup

# ---------- 启动 VNC ----------
echo "启动 VNC 服务器 (${VNC_RESOLUTION} x ${VNC_DEPTH}bit)..."
vncserver :1 \
    -geometry "$VNC_RESOLUTION" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -xstartup /root/.vnc/xstartup \
    -SecurityTypes None \
    -dpi 96

sleep 5

# ---------- 确认 VNC 状态 ----------
echo "=== VNC 进程 ==="
ps aux | grep -E "Xtigervnc|startxfce4" | grep -v grep || echo "(无相关进程)"

echo "=== VNC 日志 ==="
cat /root/.vnc/*:1.log 2>/dev/null | tail -20 || echo "(无日志)"

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
