#!/bin/bash
set -e

# 确保 PATH 包含 /usr/bin（tigervnc 的 vncpasswd 在此处）
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/root/.local/bin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 环境变量 ----------
ROOT_PASSWORD="${ROOT_PASSWORD:-123456}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

# 设置 root 密码
echo "root:${ROOT_PASSWORD}" | chpasswd

# ---------- 配置 VNC ----------
mkdir -p /root/.vnc

if [ -n "$VNC_PASSWORD" ]; then
    echo "设置 VNC 密码..."
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
else
    echo "VNC 无密码模式..."
    echo "" | vncpasswd -f > /root/.vnc/passwd
fi
chmod 600 /root/.vnc/passwd

# ---------- xstartup ----------
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

# ---------- 启动 qwenpaw ----------
echo "启动 qwenpaw (端口 8088)..."
cd /root
nohup /root/.qwenpaw/venv/bin/qwenpaw app --host 0.0.0.0 --port 8088 > /root/qwenpaw.log 2>&1 &
echo "qwenpaw PID: $!"

# 自定义启动脚本
if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
