#!/bin/bash
set -e
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "========================================"
echo "  Linux Desktop Container 启动中..."
echo "========================================"

# ---------- 运行时诊断 + 修复 noVNC clipboard 空指针 bug ----------
echo "=== 诊断 noVNC clipboard 状态 ==="
python3 - << 'PYEOF'
import os, re

p = "/opt/noVNC/app/ui.js"
if not os.path.exists(p):
    print("ERROR: ui.js not found at", p)
    exit(1)

with open(p) as f: c = f.read()

# Show version from package.json
pkg = "/opt/noVNC/package.json"
if os.path.exists(pkg):
    import json
    with open(pkg) as f: d = json.load(f)
    print("noVNC version:", d.get("version", "unknown"))

# Show the clipboard handler lines
print("\n=== clipboard handler lines ===")
lines = c.split('\n')
for i, line in enumerate(lines):
    if 'noVNC_clipboard_button' in line or 'noVNC_clipboard_text' in line:
        print(f"  line {i+1}: {line.rstrip()}")

# Patch: null-safe the clipboard addEventListener calls
orig = c
patches = [
    # Standard multiline pattern
    ('document.getElementById("noVNC_clipboard_button")\n            .addEventListener',
     'var _cb=document.getElementById("noVNC_clipboard_button");if(_cb)_cb.addEventListener'),
    ('document.getElementById("noVNC_clipboard_text")\n            .addEventListener',
     'var _ct=document.getElementById("noVNC_clipboard_text");if(_ct)_ct.addEventListener'),
    # Single-quote variants
    ("document.getElementById('noVNC_clipboard_button')\n            .addEventListener",
     "var _cb=document.getElementById('noVNC_clipboard_button');if(_cb)_cb.addEventListener"),
    ("document.getElementById('noVNC_clipboard_text')\n            .addEventListener",
     "var _ct=document.getElementById('noVNC_clipboard_text');if(_ct)_ct.addEventListener"),
    # Try to find any remaining chained getElementById + addEventListener
]

done = 0
for old, new in patches:
    if old in c:
        c = c.replace(old, new)
        done += 1
        print(f"PATCHED: {old[:50]}")

if done > 0:
    with open(p, 'w') as f: f.write(c)
    print(f"\nclipboard patch applied ({done} changes)")
else:
    print("\nWARNING: no clipboard patterns matched!")
    # Find addClipboardHandlers function and show it
    for i, line in enumerate(lines):
        if 'addClipboardHandlers' in line:
            print(f"\n=== addClipboardHandlers context (lines {i+1}-{i+6}) ===")
            for j in range(max(0,i), min(len(lines), i+6)):
                print(f"  {j+1}: {lines[j]}")
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
