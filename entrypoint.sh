#!/bin/bash
set -e
exec > /tmp/entrypoint.log 2>&1
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 全局：设置默认浏览器（在桌面启动前就设好） ----------
mkdir -p /root/.local/share/applications
cat > /root/.local/share/applications/google-chrome.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome --no-sandbox --no-default-browser-check %U
Icon=/usr/share/icons/hicolor/48x48/apps/google-chrome.png
Categories=Network;WebBrowser;
Terminal=false
DESKTOP_EOF
cp /root/.local/share/applications/google-chrome.desktop /usr/share/applications/ 2>/dev/null || true

xdg-mime default google-chrome.desktop x-scheme-handler/http
xdg-mime default google-chrome.desktop x-scheme-handler/https
xdg-mime default google-chrome.desktop text/html
xdg-settings set default-web-browser google-chrome.desktop
echo "默认浏览器已设为 Chrome"

# ---------- 修复 noVNC clipboard bug + 构建 auto-connect index ----------
echo "=== 修复 noVNC clipboard bug + auto-connect ==="
python3 - << 'PYEOF'
import os, re, time

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

# Update import to renamed ui.js
h = re.sub(
    r'import UI from [\'"]\./app/ui(?:\.[a-f0-9]+\.js)?[\'"]',
    f"import UI from './app/ui.{ts}.js'",
    h
)

# After UI.start(), call UI.connect() for auto-connect
h = re.sub(
    r"(UI\.start\(defaults, document\.getElementById\('noVNC_screen'\)\);)",
    r"\1\n        // Auto-connect\n        setTimeout(function() { UI.connect(); }, 500);",
    h
)

with open("/opt/noVNC/index.html", 'w') as f: f.write(h)
print("Created index.html (vnc.html + patched ui.js + UI.connect() auto-connect)")
PYEOF

# ---------- 诊断：关键路径检查 ----------
echo "=== 诊断信息 ==="
echo "qwenpaw: $(command -v qwenpaw 2>/dev/null || echo '未找到')"
echo "google-chrome: $(command -v google-chrome 2>/dev/null || echo '未找到')"
echo "websockify: $(command -v websockify 2>/dev/null || echo '未找到')"
echo "noVNC index.html: $(ls /opt/noVNC/index.html 2>/dev/null || echo '未找到')"
python3 --version

# ---------- 创建 xstartup ----------
mkdir -p /root/.vnc
cat > /root/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --fork --sh-syntax)
fi
export DBUS_SESSION_BUS_ADDRESS

fcitx -d 2>/dev/null &
sleep 1

exec /usr/bin/startxfce4
XSTARTUP
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
ss -tlnp 2>/dev/null | grep -E "5901|7860|8088" || netstat -tlnp 2>/dev/null | grep -E "5901|7860|8088"

# ---------- 启动 noVNC ----------
echo "启动 noVNC (7860)..."
websockify --web /opt/noVNC 7860 localhost:5901 &
sleep 2

# ---------- 启动 qwenpaw ----------
if [ -x /root/.qwenpaw/venv/bin/qwenpaw ]; then
    echo "启动 qwenpaw (8088)..."
    cd /root
    nohup /root/.qwenpaw/venv/bin/qwenpaw app --host 0.0.0.0 --port 8088 > /root/qwenpaw.log 2>&1 &
    echo "qwenpaw PID: $!"
    sleep 3
    cat /root/qwenpaw.log 2>/dev/null | tail -5 || echo "(无日志)"
else
    echo "qwenpaw 未安装，跳过"
fi

echo "========================================"
echo "  Linux Desktop Container 已就绪！"
echo "  noVNC:   http://localhost:7860"
echo "  qwenpaw: http://localhost:8088"
echo "========================================"

# ---------- 启动自定义脚本 ----------
if [ -d "/root/startup" ] && [ -f "/root/startup/main.sh" ]; then
    chmod +x /root/startup/main.sh
    /root/startup/main.sh
fi

wait
