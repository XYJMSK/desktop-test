#!/bin/bash
# ================================================================
# Claude Desktop 启动脚本
# 1. 初始化（如果需要）
# 2. 调用原 openclaw_computer 的 entrypoint
# ================================================================

echo "[claude-desktop] 启动中..."

# 这里可以加初始化逻辑

# 调用原 openclaw_computer 的 entrypoint（已重命名）
exec /entrypoint-openclaw.sh
