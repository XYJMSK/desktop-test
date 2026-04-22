FROM ghcr.io/xyjmsk/ubuntu_test:latest

# 在容器内启动自己的 Xvfb + x11vnc + noVNC
EXPOSE 7860

RUN apt-get update && apt-get install -y x11vnc xvfb && rm -rf /var/lib/apt/lists/*

CMD ["sh", "-c", "Xvfb :1 -screen 0 1920x1080x24 & sleep 1 && x11vnc -display :1 -shared -forever & sleep 1 && websockify --web /usr/share/novnc 7860 localhost:5900"]
