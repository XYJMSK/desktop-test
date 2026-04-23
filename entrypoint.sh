#!/bin/bash
set -e

echo "[qwenpaw] Starting QwenPaw app on port 8088..."
nohup qwenpaw app --host 0.0.0.0 --port 8088 > /var/log/qwenpaw.log 2>&1 &
echo "[qwenpaw] PID: $!"
sleep 2

exec /startup.sh
