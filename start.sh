#!/bin/bash
set -e

# Set password
mkdir -p ~/.vnc
echo "${VNC_PW}" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start Xvfb
Xvfb :1 -screen 0 ${VNC_RESOLUTION}x24 &
sleep 1

# Start XFCE
export DISPLAY=:1
xfce4-session &
sleep 2

# Start TigerVNC server
vncserver :1 -geometry ${VNC_RESOLUTION} -depth 24 -localhost no

# Start noVNC (websocket to VNC proxy)
websockify --web /usr/share/novnc ${NOVNC_PORT} localhost:${VNC_PORT} &

# Keep container running
tail -f /dev/null
