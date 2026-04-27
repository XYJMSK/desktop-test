#!/bin/bash
# 双向同步脚本 - 基于 inotifywait 监控变化，rsync 同步到持久化层
# 用法: sync.sh start  (后台运行)
#       sync.sh stop   (停止)
#       sync.sh once  (单次同步)

SRC_BASE="/root"
DST_BASE="/mnt/workspace/root"

# 要同步的目录列表（相对于 $SRC_BASE）
SYNC_DIRS=(
    ".qwenpaw"
    ".mmx"
    ".ssh"
    ".config/fcitx"
    ".config/fcitx5"
)

LOGFILE="/tmp/sync.log"
PIDFILE="/tmp/sync.pid"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# ---------- 单次 rsync ----------
do_sync() {
    local src=$1
    local dst=$2
    rsync -a --delete "$src/" "$dst/" 2>/dev/null
}

# ---------- 恢复：持久化层 → 原目录（首次启动） ----------
restore_all() {
    log "恢复：从持久化层恢复到原目录"
    for item in "${SYNC_DIRS[@]}"; do
        src="$DST_BASE/$item"
        dst="$SRC_BASE/$item"
        if [ -d "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            log "  恢复 $item"
            rsync -a --delete "$src/" "$dst/" 2>/dev/null
        fi
    done
}

# ---------- 同步：原目录 → 持久化层（变更时） ----------
sync_to_persist() {
    log "同步：原目录 → 持久化层"
    for item in "${SYNC_DIRS[@]}"; do
        src="$SRC_BASE/$item"
        dst="$DST_BASE/$item"
        if [ -d "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            rsync -a --delete "$src/" "$dst/" 2>/dev/null
            log "  已同步 $item"
        fi
    done
}

# ---------- 监控模式 ----------
watch_loop() {
    local watch_dirs=""
    for item in "${SYNC_DIRS[@]}"; do
        if [ -d "$SRC_BASE/$item" ]; then
            watch_dirs="$watch_dirs $SRC_BASE/$item"
        fi
    done

    log "开始监控: $watch_dirs"
    inotifywait -m -r -e modify,create,delete,move $watch_dirs 2>/dev/null | while read -r path action file; do
        # 防抖：等待一小段时间让连续变更完成
        sleep 2
        sync_to_persist
    done &
    echo $! > "$PIDFILE"
    log "监控进程 PID: $(cat $PIDFILE)"
}

case "${1:-}" in
    start)
        restore_all
        sleep 1
        sync_to_persist
        watch_loop
        log "同步服务已启动"
        ;;
    stop)
        if [ -f "$PIDFILE" ]; then
            kill "$(cat "$PIDFILE")" 2>/dev/null
            rm -f "$PIDFILE"
            log "同步服务已停止"
        fi
        ;;
    once)
        restore_all
        sync_to_persist
        log "单次同步完成"
        ;;
    restore)
        restore_all
        log "恢复完成"
        ;;
    *)
        echo "用法: $0 {start|stop|once|restore}"
        ;;
esac
