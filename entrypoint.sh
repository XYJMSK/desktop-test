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

# ---------- 生成 VNC passwd 文件（Python + PTY） ----------
echo "生成 VNC 密码文件..."
python3 << 'PYEOF'
import os, pty, sys, time, subprocess

def run_vncpasswd():
    pw = "vncpass"
    # 用 PTY 运行 tigervncpasswd 来获取 TTY
    master, slave = pty.openpty()
    proc = subprocess.Popen(
        ['tigervncpasswd'],
        stdin=slave, stdout=slave, stderr=slave, close_fds=True
    )
    os.close(slave)

    def send(s):
        os.write(master, (s + '\r').encode())
        time.sleep(0.3)

    # 发送两次密码
    send(pw)
    send(pw)
    time.sleep(0.5)
    proc.wait()
    os.close(master)

    # tigervncpasswd 默认写到 ~/.vnc/passwd
    passwd_file = os.path.expanduser('/root/.vnc/passwd')
    if os.path.exists(passwd_file):
        os.chmod(passwd_file, 0o600)
        print(f"OK: {passwd_file} created")
    else:
        print("FAIL: passwd file not created", file=sys.stderr)

run_vncpasswd()
PYEOF

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
