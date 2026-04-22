#!/bin/bash
set -e

# Kill any existing X/VNC processes first
pkill -9 Xvfb 2>/dev/null || true
pkill -9 vncserver 2>/dev/null || true
sleep 1

# Set VNC password
mkdir -p ~/.vnc
echo "desktop123" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start Xvfb
Xvfb :1 -screen 0 1024x768x24 &
sleep 2

# Start XFCE
export DISPLAY=:1
xfce4-session &
sleep 2

# Start TigerVNC
vncserver :1 -geometry 1024x768 -depth 24 -localhost no
sleep 1

# Start noVNC on port 7860
websockify --web /usr/share/novnc 7860 localhost:5901 &

# Keep running
tail -f /dev/null
