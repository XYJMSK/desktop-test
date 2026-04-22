# ================================================================
# Claude Desktop on ModelScope
# Based on: ghcr.io/tunmax/openclaw_computer:latest
# ================================================================

FROM ghcr.io/tunmax/openclaw_computer:latest

LABEL org.opencontainers.image.source=https://github.com/XYJMSK/claude-desktop-container
LABEL org.opencontainers.image.description="Claude Desktop in Linux KDE Desktop"

# 安装 Claude Code Best
RUN apt-get update && apt-get install -y npm nodejs && \
    npm install -g claude-code-best && \
    rm -rf /var/lib/apt/lists/*

# 直接使用原 entrypoint，不做 wrapper
EXPOSE 7860
