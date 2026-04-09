#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-$ROOT_DIR/backend/migrations}"
SEED_FILE="${SEED_FILE:-$ROOT_DIR/scripts/seed.sql}"

APP_DB_NAME="${APP_DB_NAME:-propos_dev}"
APP_DB_USER="${APP_DB_USER:-propos}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-ChangeMe_2026!}"
APP_DB_HOST="${APP_DB_HOST:-${PGHOST:-localhost}}"
APP_DB_PORT="${APP_DB_PORT:-${PGPORT:-5432}}"

RUN_SEED=false
SKIP_MIGRATIONS=false
DRY_RUN=false

usage() {
    cat <<'EOF'
用法：
  bash scripts/init_local_postgres.sh [选项]

作用：
  1. 连接本地 PostgreSQL 管理库
  2. 幂等创建 PropOS 本地角色和数据库
  3. 按顺序执行 backend/migrations/*.sql（如存在）
  4. 可选执行 scripts/seed.sql

选项：
  --db-name NAME         业务数据库名，默认 propos_dev
  --db-user USER         业务数据库用户，默认 propos
  --db-password PASS     业务数据库密码，默认 ChangeMe_2026!
  --db-host HOST         业务数据库主机，默认 localhost
  --db-port PORT         业务数据库端口，默认 5432
  --seed                 执行 scripts/seed.sql
  --skip-migrations      跳过 backend/migrations/*.sql
  --dry-run              只打印即将执行的步骤，不真正连接数据库
  -h, --help             显示帮助

管理员连接方式：
  优先使用 ADMIN_DATABASE_URL；如果未设置，则回退到 libpq 标准环境变量：
    PGHOST / PGPORT / PGUSER / PGPASSWORD / PGDATABASE

示例：
  bash scripts/init_local_postgres.sh
  APP_DB_PASSWORD=LocalPass_2026 bash scripts/init_local_postgres.sh --seed
  PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=postgres \
    bash scripts/init_local_postgres.sh --db-password PropOS_2026!

说明：
  - 当前仓库 backend/migrations/ 还没有正式初始化 SQL，脚本会自动跳过空目录。
  - scripts/seed.sql 依赖目标表已存在，只有在 DDL 准备完成后再加 --seed。
EOF
}

info() {
    printf '[INFO] %s\n' "$1"
}

ok() {
    printf '[OK] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1" >&2
}

die() {
    printf '[ERROR] %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db-name)
            [[ $# -ge 2 ]] || die "--db-name 缺少参数"
            APP_DB_NAME="$2"
            shift 2
            ;;
        --db-user)
            [[ $# -ge 2 ]] || die "--db-user 缺少参数"
            APP_DB_USER="$2"
            shift 2
            ;;
        --db-password)
            [[ $# -ge 2 ]] || die "--db-password 缺少参数"
            APP_DB_PASSWORD="$2"
            shift 2
            ;;
        --db-host)
            [[ $# -ge 2 ]] || die "--db-host 缺少参数"
            APP_DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            [[ $# -ge 2 ]] || die "--db-port 缺少参数"
            APP_DB_PORT="$2"
            shift 2
            ;;
        --seed)
            RUN_SEED=true
            shift
            ;;
        --skip-migrations)
            SKIP_MIGRATIONS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "未知参数: $1"
            ;;
    esac
done

require_command psql

ADMIN_PSQL_ARGS=()
ADMIN_TARGET_DESCRIPTION="${PGDATABASE:-postgres}"

if [[ -n "${ADMIN_DATABASE_URL:-}" ]]; then
    ADMIN_PSQL_ARGS+=("$ADMIN_DATABASE_URL")
    ADMIN_TARGET_DESCRIPTION="$ADMIN_DATABASE_URL"
else
    if [[ -n "${PGHOST:-}" ]]; then
        ADMIN_PSQL_ARGS+=("-h" "$PGHOST")
        ADMIN_TARGET_DESCRIPTION="${PGHOST}:${PGPORT:-5432}/${PGDATABASE:-postgres}"
    fi
    if [[ -n "${PGPORT:-}" ]]; then
        ADMIN_PSQL_ARGS+=("-p" "$PGPORT")
    fi
    if [[ -n "${PGUSER:-}" ]]; then
        ADMIN_PSQL_ARGS+=("-U" "$PGUSER")
    fi
    ADMIN_PSQL_ARGS+=("-d" "${PGDATABASE:-postgres}")
fi

APP_PSQL_ARGS=("-h" "$APP_DB_HOST" "-p" "$APP_DB_PORT" "-U" "$APP_DB_USER" "-d" "$APP_DB_NAME")

bootstrap_sql() {
    cat <<'SQL'
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L',
    :'app_db_user',
    :'app_db_password'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = :'app_db_user'
)\gexec

SELECT format(
    'ALTER ROLE %I WITH LOGIN PASSWORD %L',
    :'app_db_user',
    :'app_db_password'
)\gexec

SELECT format(
    'CREATE DATABASE %I OWNER %I ENCODING ''UTF8''',
    :'app_db_name',
    :'app_db_user'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = :'app_db_name'
)\gexec

SELECT format(
    'ALTER DATABASE %I OWNER TO %I',
    :'app_db_name',
    :'app_db_user'
)\gexec

SELECT format(
    'GRANT ALL PRIVILEGES ON DATABASE %I TO %I',
    :'app_db_name',
    :'app_db_user'
)\gexec
SQL
}

run_admin_sql() {
    local description="$1"
    local sql="$2"

    info "$description"
    if [[ "$DRY_RUN" == true ]]; then
        printf '%s\n' "$sql"
        return 0
    fi

    PAGER=cat psql -X -v ON_ERROR_STOP=1 \
        -v app_db_name="$APP_DB_NAME" \
        -v app_db_user="$APP_DB_USER" \
        -v app_db_password="$APP_DB_PASSWORD" \
        "${ADMIN_PSQL_ARGS[@]}" <<SQL
$sql
SQL
}

run_app_file() {
    local description="$1"
    local file_path="$2"

    info "$description: $file_path"
    if [[ "$DRY_RUN" == true ]]; then
        info "dry-run 模式下跳过文件执行"
        return 0
    fi

    PGPASSWORD="$APP_DB_PASSWORD" PAGER=cat psql -X -v ON_ERROR_STOP=1 \
        "${APP_PSQL_ARGS[@]}" -f "$file_path"
}

check_admin_connection() {
    info "检查管理员连接: $ADMIN_TARGET_DESCRIPTION"

    if [[ "$DRY_RUN" == true ]]; then
        ok "dry-run 模式下跳过真实连接检查"
        return 0
    fi

    if ! PAGER=cat psql -X -v ON_ERROR_STOP=1 "${ADMIN_PSQL_ARGS[@]}" -c 'SELECT 1;' >/dev/null; then
        die "无法连接 PostgreSQL 管理库。可以设置 ADMIN_DATABASE_URL，或设置 PGHOST/PGPORT/PGUSER/PGPASSWORD 后重试。"
    fi

    ok "管理员连接正常"
}

run_migrations() {
    local migration_files

    if [[ "$SKIP_MIGRATIONS" == true ]]; then
        warn "已按参数要求跳过 migrations 执行"
        return 0
    fi

    if [[ ! -d "$MIGRATIONS_DIR" ]]; then
        warn "migrations 目录不存在，已跳过: $MIGRATIONS_DIR"
        return 0
    fi

    migration_files="$(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -name '*.sql' ! -name '*.undo.sql' | sort)"

    if [[ -z "$migration_files" ]]; then
        warn "未发现可执行的 migration SQL，已跳过"
        return 0
    fi

    while IFS= read -r migration_file; do
        [[ -n "$migration_file" ]] || continue
        run_app_file "执行 migration" "$migration_file"
    done <<< "$migration_files"

    if [[ "$DRY_RUN" == true ]]; then
        ok "dry-run 模式下已模拟 migrations 执行"
    else
        ok "migrations 执行完成"
    fi
}

run_seed() {
    if [[ "$RUN_SEED" != true ]]; then
        return 0
    fi

    [[ -f "$SEED_FILE" ]] || die "未找到 seed 文件: $SEED_FILE"
    run_app_file "执行 seed" "$SEED_FILE"
    if [[ "$DRY_RUN" == true ]]; then
        ok "dry-run 模式下已模拟 seed 执行"
    else
        ok "seed 执行完成"
    fi
}

print_summary() {
    ok "本地 PostgreSQL 初始化完成"
    printf '  db_name: %s\n' "$APP_DB_NAME"
    printf '  db_user: %s\n' "$APP_DB_USER"
    printf '  db_host: %s\n' "$APP_DB_HOST"
    printf '  db_port: %s\n' "$APP_DB_PORT"
    printf '  migrations: %s\n' "$([[ "$SKIP_MIGRATIONS" == true ]] && printf 'skipped' || printf 'checked')"
    printf '  seed: %s\n' "$([[ "$RUN_SEED" == true ]] && printf 'requested' || printf 'not requested')"
    printf '\n建议写入 backend/.env 的数据库配置：\n'
    printf 'DATABASE_URL=postgres://%s:<APP_DB_PASSWORD>@%s:%s/%s\n' \
        "$APP_DB_USER" "$APP_DB_HOST" "$APP_DB_PORT" "$APP_DB_NAME"
}

info "开始初始化 PropOS 本地 PostgreSQL"
check_admin_connection
run_admin_sql "创建或更新本地业务角色与数据库" "$(bootstrap_sql)"
if [[ "$DRY_RUN" == true ]]; then
    ok "dry-run 模式下已模拟角色和数据库初始化"
else
    ok "角色和数据库已就绪"
fi
run_migrations
run_seed
print_summary