# desktop-test: 基于 openclaw_computer + qwenpaw
FROM ghcr.io/tunmax/openclaw_computer:latest

LABEL org.opencontainers.image.source=https://github.com/XYJMSK/desktop-test
LABEL org.opencontainers.image.description="Desktop environment with QwenPaw assistant"
LABEL org.opencontainers.image.licenses=MIT

# ============================================================
# 从 bookworm-backports 安装 Python 3.12
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && \
    curl -fsSL https://people.debian.org/~aparicio/deb12-backports-repo.gpg.key \
      -o /etc/apt/trusted.gpg.d/bookworm-backports.asc && \
    echo "deb https://deb.debian.org/debian bookworm-backports main" \
      > /etc/apt/sources.list.d/bookworm-backports.list && \
    apt-get update && apt-get install -y -t bookworm-backports \
    python3.12 python3.12-venv python3.12-dev && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# 安装 qwenpaw
# ============================================================
RUN python3.12 -m venv /root/.qwenpaw/venv && \
    /root/.qwenpaw/venv/bin/pip install --upgrade pip && \
    /root/.qwenpaw/venv/bin/pip install qwenpaw && \
    ln -sf /root/.qwenpaw/venv/bin/qwenpaw /usr/local/bin/qwenpaw

ENV PATH="/root/.qwenpaw/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# ============================================================
# 初始化 qwenpaw 工作目录
# ============================================================
RUN mkdir -p /root/.qwenpaw/workspaces/default && \
    mkdir -p /root/.qwenpaw/skill_pool && \
    qwenpaw init --defaults --accept-security --force

# ============================================================
# 入口脚本：启动 qwenpaw 后执行原入口
# ============================================================
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh && sed -i 's/\r$//' /opt/entrypoint.sh

EXPOSE 8088
ENTRYPOINT ["/opt/entrypoint.sh"]
