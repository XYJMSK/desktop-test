#!/bin/bash
set -e
# entrypoint.sh - Linux Desktop Container 启动脚本
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 运行时修复 noVNC clipboard 空指针 bug ----------
echo "修复 noVNC clipboard bug..."
python3 - << 'PYEOF'
import os, re
p = "/opt/noVNC/app/ui.js"
if not os.path.exists(p):
    print("WARN: ui.js not found")
    exit(0)
with open(p) as f: c = f.read()
orig = c
for old, new in [
    ('document.getElementById("noVNC_clipboard_button")\n            .addEventListener',
     'var _cb=document.getElementById("noVNC_clipboard_button");if(_cb)_cb.addEventListener'),
    ('document.getElementById("noVNC_clipboard_text")\n            .addEventListener',
     'var _ct=document.getElementById("noVNC_clipboard_text");if(_ct)_ct.addEventListener'),
    ("document.getElementById('noVNC_clipboard_button')\n            .addEventListener",
     "var _cb=document.getElementById('noVNC_clipboard_button');if(_cb)_cb.addEventListener"),
    ("document.getElementById('noVNC_clipboard_text')\n            .addEventListener",
     "var _ct=document.getElementById('noVNC_clipboard_text');if(_ct)_ct.addEventListener"),
]:
    if old in c:
        c = c.replace(old, new)
        print(f"patched: {old[:40]}...")
if c != orig:
    with open(p, 'w') as f: f.write(c)
    print("clipboard bug fixed OK")
else:
    print("no changes needed")
PYEOF

echo "=== noVNC 版本 ==="
python3 -c "import json; print('noVNC:', json.load(open('/opt/noVNC/package.json'))['version'])"

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

# ---------- 启动 VNC ----------
echo "启动 VNC 服务器..."
vncserver :1 \
    -geometry "1920x1080" \
    -depth 24 \
    -localhost no \
    -xstartup /root/.vnc/xstartup \
    -SecurityTypes None --I-KNOW-THIS-IS-INSECURE \
    -dpi 96

sleep 5

echo "=== VNC/XFCE 进程 ==="
ps aux | grep -E "Xtigervnc|startxfce4" | grep -v grep || echo "(无)"
echo "=== VNC 日志 ==="
cat /root/.vnc/*:1.log 2>/dev/null | tail -10 || echo "(无)"
echo "=== 端口监听 ==="
ss -tlnp | grep -E "5901|7860" || netstat -tlnp | grep -E "5901|7860"

# ---------- 启动 noVNC ----------
echo "启动 noVNC..."
websockify --web /opt/noVNC 7860 localhost:5901 &

sleep 2

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  noVNC: http://你的空间地址/vnc.html"
echo "========================================"

if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
