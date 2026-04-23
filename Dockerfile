# desktop-test: 基于 openclaw_computer + qwenpaw
FROM ghcr.io/tunmax/openclaw_computer:latest

LABEL org.opencontainers.image.source=https://github.com/XYJMSK/desktop-test
LABEL org.opencontainers.image.description="Desktop environment with QwenPaw assistant"
LABEL org.opencontainers.image.licenses=MIT

# ============================================================
# 安装 uv，再用 uv 安装 Python 3.12
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    curl -LsSf https://astral.sh/uv/0.6.6/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:$PATH"

# ============================================================
# 用 uv 安装 Python 3.12 和 qwenpaw
# ============================================================
RUN uv python install 3.12 && \
    ln -sf /root/.local/share/uv/tools/cpython-3.12.13-linux-x86_64-gnu/bin/python3.12 /usr/local/bin/python3.12 && \
    /root/.local/share/uv/tools/cpython-3.12.13-linux-x86_64-gnu/bin/python3.12 -m venv /root/.qwenpaw/venv && \
    /root/.qwenpaw/venv/bin/pip install --upgrade pip && \
    /root/.qwenpaw/venv/bin/pip install qwenpaw && \
    ln -sf /root/.qwenpaw/venv/bin/qwenpaw /usr/local/bin/qwenpaw

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
