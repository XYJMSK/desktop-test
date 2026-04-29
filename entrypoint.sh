#!/bin/bash
exec > /tmp/entrypoint.log 2>&1
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 清理 KDE 环境变量（基础镜像有 KDE 残留）
unset KDE_FULL_SESSION
unset KDE_SESSION_VERSION
export XDG_CURRENT_DESKTOP=XFCE
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# 替换 KDE opener → Chrome wrapper（彻底消除 KIO 拦截）
if [ -x /usr/bin/kde-open5 ]; then
    mv /usr/bin/kde-open5 /usr/bin/kde-open5.real
    cat > /usr/bin/kde-open5 << 'KDEW'
#!/bin/bash
exec /usr/local/bin/google-chrome-wrapper "$@"
KDEW
    chmod +x /usr/bin/kde-open5
    echo "kde-open5 → Chrome wrapper"
fi

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 恢复 API Keys（持久化层 → 环境变量） ----------
if [ -f /mnt/workspace/root/.mmx/config.json ]; then
    MINIMAX_KEY=$(python3 -c "import json; d=json.load(open('/mnt/workspace/root/.mmx/config.json')); print(d.get('api_key',''))" 2>/dev/null)
    if [ -n "$MINIMAX_KEY" ]; then
        export MINIMAX_API_KEY="$MINIMAX_KEY"
        echo "MiniMax API Key 已恢复"
    fi
fi

# ---------- 全局：设置默认浏览器 ----------
mkdir -p /root/.local/share/applications
# 创建 Chrome wrapper（部分镜像不提供）
if [ ! -x /usr/local/bin/google-chrome-wrapper ]; then
    cat > /usr/local/bin/google-chrome-wrapper << 'WRAP'
#!/bin/bash
exec /usr/bin/google-chrome --no-sandbox --disable-dev-shm-usage --disable-gpu "$@"
WRAP
    chmod +x /usr/local/bin/google-chrome-wrapper
    echo "google-chrome-wrapper 已创建"
fi
if [ -f /usr/share/applications/google-chrome.desktop ]; then
    DESKTOP_SRC=/usr/share/applications/google-chrome.desktop
elif [ -f /usr/share/applications/com.google.Chrome.desktop ]; then
    DESKTOP_SRC=/usr/share/applications/com.google.Chrome.desktop
else
    DESKTOP_SRC=
fi

if [ -n "$DESKTOP_SRC" ]; then
    sed 's|Exec=/usr/bin/google-chrome-stable[^ ]*|Exec=/usr/local/bin/google-chrome-wrapper|g' \
        "$DESKTOP_SRC" \
        > /root/.local/share/applications/google-chrome.desktop
    if [ -f /root/.local/share/applications/google-chrome.desktop ]; then
        xdg-mime default google-chrome.desktop x-scheme-handler/http 2>/dev/null || true
        xdg-mime default google-chrome.desktop x-scheme-handler/https 2>/dev/null || true
        xdg-mime default google-chrome.desktop text/html 2>/dev/null || true
        xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null || true
        echo "默认浏览器已设为 Chrome"
    else
        echo "警告：Chrome desktop 文件创建失败，跳过"
    fi
else
    echo "警告：未找到 Chrome desktop 文件，跳过"
fi

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
h = re.sub(
    r'import UI from [\'"]\./app/ui(?:\.[a-f0-9]+\.js)?[\'"]',
    f"import UI from './app/ui.{ts}.js'",
    h
)
h = re.sub(
    r"(UI\.start\(defaults, document\.getElementById\('noVNC_screen'\)\);)",
    r"defaults.connect = true;\n        defaults.auto_reconnect = true;\n        \1",
    h
)
with open("/opt/noVNC/vnc.html", 'w') as f: f.write(h)
# 清理旧 index.html（避免干扰）
old_idx = "/opt/noVNC/index.html"
if os.path.exists(old_idx):
    os.remove(old_idx)
    print("Removed old index.html")
print("Patched vnc.html (auto-connect enabled)")
PYEOF

echo "=== 启动双向同步 ==="
if [ -f /root/sync.sh ]; then
    chmod +x /root/sync.sh
    /root/sync.sh start
else
    echo "sync.sh 未找到，跳过"
fi

# ---------- 诊断信息 ----------
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
# 清理 KDE 环境，强制 XFCE
unset KDE_FULL_SESSION
unset KDE_SESSION_VERSION
export XDG_CURRENT_DESKTOP=XFCE
export XDG_RUNTIME_DIR=/tmp/runtime-root
mkdir -p /tmp/runtime-root 2>/dev/null && chmod 700 /tmp/runtime-root

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

# ---------- 清理旧 Chrome + 启动新窗口 ----------
echo "清理旧 Chrome 进程..."
# 先清理之前残留的 Chrome 进程，避免连接到无窗口的旧会话
pkill -f "/opt/google/chrome/chrome" 2>/dev/null || true
sleep 1
echo "启动 Chrome 窗口..."
DISPLAY=:1 nohup /usr/local/bin/google-chrome-wrapper \
    --new-window --force-new-window about:blank > /dev/null 2>/root/chrome-err.log &
CHROME_PID=$!
sleep 3
if kill -0 $CHROME_PID 2>/dev/null; then
    echo "Chrome 已启动 (PID: $CHROME_PID)"
else
    echo "Chrome 启动失败，错误日志："
    cat /root/chrome-err.log 2>/dev/null || echo "(无日志)"
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

# ---------- 诊断：测试 xdg-open ----------
echo "测试 xdg-open..."
DISPLAY=:1 xdg-open about:blank 2>/tmp/xdg-err.log
echo "xdg-open 退出码: $?"

wait
