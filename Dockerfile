FROM ghcr.io/xyjmsk/desktop-test:latest

# 安装 Claude Code Best
RUN apt-get update && apt-get install -y npm nodejs && \
    npm install -g claude-code-best && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 7860
ENTRYPOINT ["/start.sh"]
