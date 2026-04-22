# ================================================================
# Claude Desktop on ModelScope
# Based on: ghcr.io/tunmax/openclaw_computer:latest
# ================================================================
# 
# 直接使用 openclaw_computer，它已在 ModelScope 验证通过
# 只添加 Claude Code Best，保留原有桌面环境
# ================================================================

FROM ghcr.io/tunmax/openclaw_computer:latest

LABEL org.opencontainers.image.source=https://github.com/XYJMSK/claude-desktop-container
LABEL org.opencontainers.image.description="Claude Desktop in Linux KDE Desktop"

# 安装 Claude Code Best
RUN apt-get update && apt-get install -y npm nodejs && \
    npm install -g claude-code-best && \
    rm -rf /var/lib/apt/lists/*

# 重命名原 entrypoint，保留桌面启动
RUN mv /entrypoint.sh /entrypoint-openclaw.sh

# 我们的启动脚本（初始化 + 调用原 entrypoint）
COPY start.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# openclaw_computer 已暴露 7860 端口
EXPOSE 7860
