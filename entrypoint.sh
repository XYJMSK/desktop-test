#!/bin/bash
set -e

# PATH 包含各种二进制路径
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

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

# 用 Python 生成 VNC passwd 文件（vncpasswd 命令在 Debian bookworm 中不存在）
if [ -n "$VNC_PASSWORD" ]; then
    echo "设置 VNC 密码..."
    python3 -c "
import os, crypt, hashlib, binascii

def gen_vnc_passwd(password):
    # VNC 协议用 DES 加密的 8 字节 challenge
    salt = os.urandom(2)
    # 简单的 DES crypt（只取前 8 字符）
    p8 = password[:8].ljust(8, '\0').encode()
    h = crypt.crypt(p8, salt)
    # 取加密结果后 11 位（标准 VNC passwd 格式）
    key_part = binascii.unhexlify(h.split('$')[-1][:16])
    return binascii.hexlify(key_part).decode()

pw = '''${VNC_PASSWORD}'''
challenge = os.urandom(8)
response = hashlib.des(pw[:8].ljust(8,'\0').encode()).encrypt(challenge)
# 写 passwd 文件（无 salt 版 VNC 格式：8字节challenge + 8字节response）
with open('/root/.vnc/passwd', 'wb') as f:
    f.write(challenge + response)
"
else
    echo "VNC 无密码模式，跳过 passwd 文件"
fi
chmod 600 /root/.vnc/passwd 2>/dev/null || true

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
