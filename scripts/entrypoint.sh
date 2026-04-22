#!/bin/bash
set -e

if [ ! -f /root/.vnc/passwd ]; then
    echo "claude2024" | vncpasswd -f > /root/.vnc/passwd
    chmod 600 /root/.vnc/passwd
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
