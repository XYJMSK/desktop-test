#!/bin/bash
set -e
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 修复 noVNC clipboard bug + 构建 auto-connect index ----------
echo "=== 修复 noVNC clipboard bug + auto-connect ==="
python3 - << 'PYEOF'
import os, re, time, shutil

src = "/opt/noVNC/app/ui.js"
if not os.path.exists(src):
    print("ERROR: ui.js not found at", src)
    exit(1)

with open(src) as f: c = f.read()

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

ts = str(int(time.time()))
patched = f"/opt/noVNC/app/ui.{ts}.js"
with open(patched, 'w') as f: f.write(c)
print(f"Patched ui.js -> ui.{ts}.js ({done} patches)")

vnc_html = "/opt/noVNC/vnc.html"
with open(vnc_html) as f: h = f.read()
h = re.sub(
    r'import UI from [\'"]\./app/ui(?:\.[a-f0-9]+\.js)?[\'"]',
    f"import UI from './app/ui.{ts}.js'",
    h
)
h = re.sub(
    r"(defaults = await response\.json\(\);)",
    r"\1\n        defaults['host'] = 'localhost';\n        defaults['port'] = '7860';\n        defaults['connect'] = true;",
    h
)
with open("/opt/noVNC/index.html", 'w') as f: f.write(h)
print("Created index.html (vnc.html + patched ui.js + auto-connect)")
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
ss -tlnp | grep -E "5901|7860|8088" || netstat -tlnp | grep -E "5901|7860|8088"

# ---------- 启动 noVNC ----------
echo "启动 noVNC (7860)..."
websockify --web /opt/noVNC 7860 localhost:5901 &

sleep 2

# ---------- 启动 Chrome ----------
if command -v google-chrome &>/dev/null; then
    echo "启动 Chrome (Display :1)..."
    google-chrome \
        --headless \
        --no-sandbox \
        --disable-gpu \
        --disable-software-rasterizer \
        --disable-dev-shm-usage \
        --remote-debugging-port=9222 \
        --user-data-dir=/root/.chrome-debug &
    echo "Chrome PID: $!"
else
    echo "Chrome 未安装，跳过"
fi

# ---------- 启动 qwenpaw ----------
if command -v qwenpaw &>/dev/null; then
    echo "启动 qwenpaw (8088)..."
    cd /root
    nohup /root/.qwenpaw/venv/bin/qwenpaw app --host 0.0.0.0 --port 8088 > /root/qwenpaw.log 2>&1 &
    echo "qwenpaw PID: $!"
else
    echo "qwenpaw 未安装，跳过"
fi

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  noVNC:  7860"
echo "  qwenpaw: 8088"
echo "========================================"

# ---------- 启动自定义脚本 ----------
if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
