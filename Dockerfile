FROM ghcr.io/xyjmsk/ubuntu_test:latest

# 魔搭平台已启动 X11，不需要重复启动
# 只启动 websockify 转发 VNC 到 7860
EXPOSE 7860
CMD ["websockify", "--web", "/usr/share/novnc", "7860", "localhost:5901"]
