# desktop-test: 基于 openclaw_computer + 自控版本 qwenpaw
FROM ghcr.io/tunmax/openclaw_computer:qwenpaw_latest

LABEL org.opencontainers.image.source=https://github.com/XYJMSK/desktop-test
LABEL org.opencontainers.image.description="Desktop environment with QwenPaw (self-controlled version)"
LABEL org.opencontainers.image.licenses=MIT

# ============================================================
# qwenpaw 版本控制（默认 latest，可改成具体版本如 1.1.2）
# ============================================================
ENV QWENPAW_VERSION=latest

# 清理旧的 venv（强制重新安装）
RUN rm -rf /root/.qwenpaw/venv

# ============================================================
# 安装 uv（如果还没有）
# ============================================================
RUN if [ ! -f /root/.local/bin/uv ]; then \
    apt-get update && apt-get install -y --no-install-recommends curl && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*; \
    fi

ENV PATH="/root/.local/bin:$PATH"

# ============================================================
# 用 uv 安装 Python 3.12，创建 venv，安装 qwenpaw
# ============================================================
RUN /root/.local/bin/uv python install 3.12 && \
    /root/.local/share/uv/python/cpython-3.12.13-linux-x86_64-gnu/bin/python3.12 -m venv /root/.qwenpaw/venv && \
    /root/.qwenpaw/venv/bin/pip install --upgrade pip

# qwenpaw 最新版（不用 ==latest）
RUN if [ "${QWENPAW_VERSION}" = "latest" ]; then \
        /root/.qwenpaw/venv/bin/pip install qwenpaw; \
    else \
        /root/.qwenpaw/venv/bin/pip install "qwenpaw==${QWENPAW_VERSION}"; \
    fi

# 确保 qwenpaw 在 PATH 中
RUN ln -sf /root/.qwenpaw/venv/bin/qwenpaw /usr/local/bin/qwenpaw

ENV PATH="/root/.qwenpaw/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# 继承原有的 entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
