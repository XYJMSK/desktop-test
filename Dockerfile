FROM ghcr.io/xyjmsk/ubuntu_test:latest

EXPOSE 7860

# 启动 Thunar 文件管理器，使用已有的 X display
CMD ["sh", "-c", "DISPLAY=:1 thunar"]
