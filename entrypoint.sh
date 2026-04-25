#!/bin/bash
set -e

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

ROOT_PASSWORD="${ROOT_PASSWORD:-123456}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

echo "root:${ROOT_PASSWORD}" | chpasswd

# 用 tigervncpasswd 生成密码文件（两次输入相同值即可非交互）
# 用 expect 模拟 tigervncpasswd 交互
expect -c "
spawn tigervncpasswd
expect \"Password:\"
send \"vncpass\r\"
expect \"Verify:\"
send \"vncpass\r\"
expect eof
" > /root/.vnc/passwd 2>/dev/null || true
chmod 600 /root/.vnc/passwd

# ---------- xstartup ----------
mkdir -p /root/.vnc
cat > /root/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx

fcitx -d 2>/dev/null &

startxfce4 &
XSTARTUP

chmod +x /root/.vnc/xstartup

# ---------- 启动 VNC ----------
echo "启动 VNC 服务器 (${VNC_RESOLUTION} x ${VNC_DEPTH}bit)..."
vncserver :1 \
    -geometry "$VNC_RESOLUTION" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -alwaysshared \
    -dpi 96

sleep 2

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
