#!/usr/bin/env bash
# scripts/apply_migration.sh
# 单独应用某个 migration 文件到本地或远程数据库（不重跑历史 migration）。
#
# 适用场景：
#   - 后端代码迭代后，新增了某个 migration（例如 027_create_floor_maps.sql）
#   - 不想动 setup_server.sh / init_local_postgres.sh 的整体流程
#   - 也不想 rsync 整个 migrations 目录
#
# 行为：
#   - 计算文件 MD5 → 检查 _schema_migrations / schema_migrations 表中是否已记录
#   - 已记录且 hash 一致 → 跳过；已记录且 hash 不一致 → 报错退出
#   - 未记录 → 执行 SQL 并写入记录表
#
# 用法:
#   bash scripts/apply_migration.sh --target local  --file backend/migrations/027_create_floor_maps.sql
#   bash scripts/apply_migration.sh --target remote --file backend/migrations/027_create_floor_maps.sql
#
# 环境变量:
#   PG_USER         本地连接用户（默认 propos）
#   PG_DB           本地数据库名（默认 propos_dev）
#   PG_HOST         本地主机（默认 localhost）
#   PG_PORT         本地端口（默认 5432）
#   PGPASSWORD      本地密码（必填，local 模式）
#   SSH_ALIAS       远程 SSH 别名（默认 propos-server，remote 模式）
#   REMOTE_PG_USER  远程 PostgreSQL 用户（默认 propos，remote 模式）
#   REMOTE_PG_DB    远程数据库名（默认 propos，remote 模式）
#
# 注意：本脚本只负责追加单个 migration。回滚请使用对应 *.undo.sql 或手工 SQL。

set -euo pipefail

TARGET=""
SQL_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --file)   SQL_FILE="$2"; shift 2 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$TARGET" || -z "$SQL_FILE" ]]; then
    echo "错误: --target 和 --file 均必填" >&2
    sed -n '15,18p' "$0" >&2
    exit 1
fi

if [[ ! -f "$SQL_FILE" ]]; then
    echo "错误: SQL 文件不存在 — $SQL_FILE" >&2
    exit 1
fi

FILENAME="$(basename "$SQL_FILE")"

# --- 计算 hash（兼容 macOS / Linux）---
if command -v md5sum >/dev/null 2>&1; then
    CURRENT_HASH="$(md5sum "$SQL_FILE" | cut -d' ' -f1)"
else
    CURRENT_HASH="$(md5 -q "$SQL_FILE")"
fi

case "$TARGET" in
    local)
        : "${PG_USER:=propos}"
        : "${PG_DB:=propos_dev}"
        : "${PG_HOST:=localhost}"
        : "${PG_PORT:=5432}"
        if [[ -z "${PGPASSWORD:-}" ]]; then
            echo "错误: 请通过 PGPASSWORD 提供本地数据库密码" >&2
            exit 1
        fi

        PSQL=(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -tA)

        # 确保追踪表存在（与 init_local_postgres.sh 字段一致：filename + applied_at）
        "${PSQL[@]}" -c "
            CREATE TABLE IF NOT EXISTS schema_migrations (
                filename   TEXT PRIMARY KEY,
                applied_at TIMESTAMPTZ DEFAULT NOW()
            );
        " >/dev/null

        EXISTING="$("${PSQL[@]}" -c "SELECT 1 FROM schema_migrations WHERE filename='${FILENAME}';")"
        if [[ -n "$EXISTING" ]]; then
            echo "[本地] ✓ 跳过（已应用）：${FILENAME}"
            exit 0
        fi

        echo "[本地] → 执行：${FILENAME}"
        "${PSQL[@]}" < "$SQL_FILE"
        "${PSQL[@]}" -c "INSERT INTO schema_migrations (filename) VALUES ('${FILENAME}');" >/dev/null
        echo "[本地] ✓ 完成：${FILENAME}"
        ;;

    remote)
        : "${SSH_ALIAS:=propos-server}"
        : "${REMOTE_PG_USER:=propos}"
        : "${REMOTE_PG_DB:=propos}"

        # 1) 上传 SQL 文件到远程临时目录
        REMOTE_TMP="/tmp/${FILENAME}"
        echo "[远程] → rsync ${SQL_FILE} → ${SSH_ALIAS}:${REMOTE_TMP}"
        rsync -az "$SQL_FILE" "${SSH_ALIAS}:${REMOTE_TMP}"

        # 2) 在远程检查 + 应用（沿用 setup_server.sh 的 _schema_migrations 表，含 file_hash）
        ssh "$SSH_ALIAS" bash -s -- "$REMOTE_PG_USER" "$REMOTE_PG_DB" "$FILENAME" "$CURRENT_HASH" "$REMOTE_TMP" << 'REMOTE_APPLY'
set -euo pipefail
PG_USER="$1"; PG_DB="$2"; FILENAME="$3"; CURRENT_HASH="$4"; SQL_PATH="$5"

docker exec propos-postgres psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -c "
CREATE TABLE IF NOT EXISTS _schema_migrations (
    filename   TEXT PRIMARY KEY,
    file_hash  TEXT NOT NULL DEFAULT '',
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE _schema_migrations ADD COLUMN IF NOT EXISTS file_hash TEXT NOT NULL DEFAULT '';
" >/dev/null

ROW="$(docker exec propos-postgres psql -U "$PG_USER" -d "$PG_DB" -tAc \
    "SELECT file_hash FROM _schema_migrations WHERE filename='${FILENAME}';")"

if [[ -n "$ROW" ]]; then
    if [[ "$ROW" != "$CURRENT_HASH" && "$ROW" != "" ]]; then
        echo "[远程] ✗ 危险：${FILENAME} 已应用但 hash 不一致（已存档=${ROW}, 当前=${CURRENT_HASH}）"
        echo "        Migration 必须为 append-only，请创建新文件而非修改已有文件。"
        rm -f "$SQL_PATH"
        exit 1
    fi
    echo "[远程] ✓ 跳过（已应用）：${FILENAME}"
    rm -f "$SQL_PATH"
    exit 0
fi

# 拷入容器再执行（避免 docker exec -i 在某些 SSH/TTY 场景下的边界问题）
docker cp "$SQL_PATH" propos-postgres:/tmp/migration.sql
docker exec propos-postgres psql -U "$PG_USER" -d "$PG_DB" -v ON_ERROR_STOP=1 -f /tmp/migration.sql
docker exec propos-postgres psql -U "$PG_USER" -d "$PG_DB" -c \
    "INSERT INTO _schema_migrations (filename, file_hash) VALUES ('${FILENAME}', '${CURRENT_HASH}');" >/dev/null
docker exec propos-postgres rm -f /tmp/migration.sql
rm -f "$SQL_PATH"
echo "[远程] ✓ 完成：${FILENAME}"
REMOTE_APPLY
        ;;

    *)
        echo "错误: --target 仅支持 local | remote" >&2
        exit 1
        ;;
esac
