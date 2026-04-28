#!/bin/bash
# 双向同步脚本 - 基于 inotifywait 监控变化，rsync 同步到持久化层
# 注意：.qwenpaw/venv 是镜像自带的，不同步（用 --exclude 保护）
# 用法: sync.sh start  (后台运行)
#       sync.sh stop   (停止)
#       sync.sh once  (单次同步)

SRC_BASE="/root"
DST_BASE="/mnt/workspace/root"

# 要同步的目录列表（相对于 $SRC_BASE）
# 注意：.qwenpaw 不整体同步，只同步内部子目录（见 below）
SYNC_DIRS=(
    ".qwenpaw.secret"
    ".mmx"
    ".ssh"
    ".config/fcitx"
    ".config/fcitx5"
)

LOGFILE="/tmp/sync.log"
PIDFILE="/tmp/sync.pid"

# ---------- qwenpaw 内部要同步的子目录 ----------
QWENPAW_EXCLUDE="--exclude=venv --exclude=bin --exclude=__pycache__ --exclude='*.pyc'"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# ---------- 单次 rsync（恢复/同步） ----------
do_rsync() {
    local src=$1
    local dst=$2
    local opts="${3:-}"
    mkdir -p "$(dirname "$dst")"
    rsync -a $opts "$src/" "$dst/" 2>/dev/null
}

# ---------- 恢复：持久化层 → 原目录（首次启动） ----------
# 注意：qwenpaw 的 venv 在镜像里，不从持久层恢复
restore_all() {
    log "恢复：从持久化层恢复到原目录"
    for item in "${SYNC_DIRS[@]}"; do
        src="$DST_BASE/$item"
        dst="$SRC_BASE/$item"
        if [ -d "$src" ]; then
            log "  恢复 $item"
            do_rsync "$src" "$dst" "--delete"
        fi
    done
    # qwenpaw 子目录（不含 venv）
    if [ -d "$DST_BASE/.qwenpaw" ]; then
        log "  恢复 .qwenpaw（配置）"
        do_rsync "$DST_BASE/.qwenpaw" "$SRC_BASE/.qwenpaw" "$QWENPAW_EXCLUDE"
    fi
}

# ---------- 同步：原目录 → 持久化层（变更时） ----------
sync_to_persist() {
    log "同步：原目录 → 持久化层"
    for item in "${SYNC_DIRS[@]}"; do
        src="$SRC_BASE/$item"
        dst="$DST_BASE/$item"
        if [ -d "$src" ]; then
            rsync -a --delete "$src/" "$dst/" 2>/dev/null
            log "  已同步 $item"
        fi
    done
    # qwenpaw 子目录（不含 venv）
    if [ -d "$SRC_BASE/.qwenpaw" ]; then
        rsync -a $QWENPAW_EXCLUDE "$SRC_BASE/.qwenpaw/" "$DST_BASE/.qwenpaw/" 2>/dev/null
        log "  已同步 .qwenpaw（配置）"
    fi
}

# ---------- 监控模式 ----------
watch_loop() {
    local watch_dirs=""
    for item in "${SYNC_DIRS[@]}"; do
        if [ -d "$SRC_BASE/$item" ]; then
            watch_dirs="$watch_dirs $SRC_BASE/$item"
        fi
    done
    # 监控 qwenpaw 子目录（不含 venv）
    if [ -d "$SRC_BASE/.qwenpaw" ]; then
        for subdir in "$SRC_BASE/.qwenpaw"/*/; do
            [ -d "$subdir" ] && [ "$(basename "$subdir")" != "venv" ] && watch_dirs="$watch_dirs $subdir"
        done
        watch_dirs="$watch_dirs $SRC_BASE/.qwenpaw/config.json $SRC_BASE/.qwenpaw/settings.json"
    fi

    log "开始监控: $watch_dirs"
    inotifywait -m -r -e modify,create,delete,move $watch_dirs 2>/dev/null | while read -r path action file; do
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
