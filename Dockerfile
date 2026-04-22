FROM ghcr.io/xyjmsk/ubuntu_test:latest

# 完全重新启动桌面，使用 desktop-test 的方式
RUN apt-get update && apt-get install -y xfce4 xfce4-terminal && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 7860
CMD ["/start.sh"]
