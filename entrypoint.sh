#!/bin/bash
set -e
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 修复 noVNC clipboard bug + 改名绕过浏览器缓存 ----------
echo "=== 修复 noVNC clipboard bug ==="
python3 - << 'PYEOF'
import os, re, json, time, shutil

src = "/opt/noVNC/app/ui.js"
if not os.path.exists(src):
    print("ERROR: ui.js not found")
    exit(1)

with open(src) as f: c = f.read()

# Patch clipboard null pointers
patches = [
    ('document.getElementById("noVNC_clipboard_button")\n            .addEventListener',
     'var _cb=document.getElementById("noVNC_clipboard_button");if(_cb)_cb.addEventListener'),
    ('document.getElementById("noVNC_clipboard_text")\n            .addEventListener',
     'var _ct=document.getElementById("noVNC_clipboard_text");if(_ct)_ct.addEventListener'),
]
done = 0
for old, new in patches:
    if old in c:
        c = c.replace(old, new)
        done += 1

# Rename to bust browser cache
ts = str(int(time.time()))
patched = f"/opt/noVNC/app/ui.{ts}.js"
with open(patched, 'w') as f: f.write(c)
print(f"Patched ui.js saved to ui.{ts}.js ({done} patches)")

# Update vnc.html import to point to renamed file
vnc_html = "/opt/noVNC/vnc.html"
if os.path.exists(vnc_html):
    with open(vnc_html) as f: h = f.read()
    h_new = re.sub(
        r'import UI from [\'"]\./app/ui(?:\.[a-f0-9]+\.js)?[\'"]',
        f"import UI from './app/ui.{ts}.js'",
        h
    )
    with open(vnc_html, 'w') as f: f.write(h_new)
    print(f"Updated vnc.html import to ui.{ts}.js")
else:
    print("vnc.html not found")

# Use vnc_lite.html as index (auto-connect via URL params ?host=...&port=...)
shutil.copy("/opt/noVNC/vnc_lite.html", "/opt/noVNC/index.html")
print("Copied vnc_lite.html as index.html")
PYEOF

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
echo "=== 端口监听 ==="
ss -tlnp | grep -E "5901|7860" || netstat -tlnp | grep -E "5901|7860"

# ---------- 启动 noVNC ----------
echo "启动 noVNC..."
websockify --web /opt/noVNC 7860 localhost:5901 &

sleep 2

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  访问地址: http://你的空间地址/?host=localhost&port=7860"
echo "========================================"

if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
