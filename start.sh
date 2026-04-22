#!/bin/bash
set -e

# Set password
mkdir -p ~/.vnc
echo "headless" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start Xvfb
Xvfb :1 -screen 0 1360x768x24 &
sleep 2

# Start XFCE
export DISPLAY=:1
xfce4-session &
sleep 2

# Start TigerVNC server
vncserver :1 -geometry 1360x768 -depth 24 -localhost no
sleep 1

# Start noVNC on port 7860 (ModelScope requirement)
websockify --web /usr/share/novnc 7860 localhost:5901 &

# Keep container running
tail -f /dev/null
