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

echo "=== xstartup 创建完成 ==="

# ---------- 修复 noVNC clipboard null bug ----------
echo "=== 修复 noVNC clipboard bug ==="
python3 -c "
import os
p='/opt/noVNC/app/ui.js'
if os.path.exists(p):
    with open(p) as f: c=f.read()
    c=c.replace(
        'document.getElementById(\"noVNC_clipboard_button\")\n            .addEventListener',
        'var _cb=document.getElementById(\"noVNC_clipboard_button\");if(_cb)_cb.addEventListener'
    )
    c=c.replace(
        'document.getElementById(\"noVNC_clipboard_text\")\n            .addEventListener',
        'var _ct=document.getElementById(\"noVNC_clipboard_text\");if(_ct)_ct.addEventListener'
    )
    with open(p,'w') as f: f.write(c)
    print('clipboard bug patched OK')
else:
    print('ui.js not found')
"

echo "=== noVNC 版本 ==="
python3 -c "import json; print('noVNC:', json.load(open('/opt/noVNC/package.json'))['version'])"

# ---------- 启动 VNC ----------
echo "启动 VNC 服务器 (${VNC_RESOLUTION} x ${VNC_DEPTH}bit)..."
vncserver :1 \
    -geometry "$VNC_RESOLUTION" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -xstartup /root/.vnc/xstartup \
    -SecurityTypes None --I-KNOW-THIS-IS-INSECURE \
    -dpi 96

sleep 5

# ---------- 确认 VNC 状态 ----------
echo "=== VNC/XFCE 进程 ==="
ps aux | grep -E "Xtigervnc|startxfce4" | grep -v grep || echo "(无)"

echo "=== VNC 日志 ==="
cat /root/.vnc/*:1.log 2>/dev/null | tail -15 || echo "(无)"

echo "=== 端口监听 ==="
netstat -tlnp 2>/dev/null | grep -E "5901|7860" || ss -tlnp | grep -E "5901|7860"

# ---------- 启动 noVNC ----------
echo "启动 noVNC Web 服务 (端口 7860)..."
# vnc_lite.html 没有 clipboard bug，直接替代 vnc.html
cp /opt/noVNC/vnc_lite.html /opt/noVNC/vnc.html
echo "vnc_lite.html 已替代 vnc.html"
websockify --web /opt/noVNC 7860 localhost:5901 &

sleep 2

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  noVNC: http://你的空间地址/vnc_lite.html"
echo "========================================"

if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
