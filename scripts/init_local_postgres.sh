#!/usr/bin/env bash
# =============================================================================
# init_local_postgres.sh — PropOS 本地 PostgreSQL 一键初始化脚本
#
# 用途：
#   开发机首次搭建或重置本地数据库环境。按顺序完成以下步骤：
#   1. 校验管理员（超级用户）连接是否正常
#   2. 幂等创建业务角色（propos）和数据库（propos_dev），已存在则跳过
#   3. 按文件名顺序执行 backend/migrations/*.sql（DDL + 参考数据）
#   4. 可选执行 scripts/seed.sql（仅限开发/测试，⚠️ 勿在生产运行）
#
# 前提条件：
#   - 本机已安装 PostgreSQL 客户端工具（psql）
#   - 管理员账号（默认使用 libpq 环境变量，macOS 开发机通常为当前系统用户）
#
# 管理员身份连接方式（两种选其一）：
#   ① 环境变量 ADMIN_DATABASE_URL=postgres://superuser:pwd@host:5432/postgres
#   ② libpq 标准变量：PGHOST / PGPORT / PGUSER / PGPASSWORD / PGDATABASE
#      macOS 本地开发常见用法：
#        PGUSER=sheltonwan bash scripts/init_local_postgres.sh --seed
#
# 业务数据库连接参数（均有默认值，可通过选项或同名环境变量覆盖）：
#   APP_DB_NAME     数据库名，默认 propos_dev
#   APP_DB_USER     角色名，默认 propos
#   APP_DB_PASSWORD 密码，默认 ChangeMe_2026!（开发机专用，生产必须替换）
#   APP_DB_HOST     主机，默认 localhost（或 $PGHOST）
#   APP_DB_PORT     端口，默认 5432（或 $PGPORT）
#
# 典型用法：
#   # 首次初始化（不含测试数据）
#   PGUSER=sheltonwan bash scripts/init_local_postgres.sh
#
#   # 初始化并写入开发测试数据
#   PGUSER=sheltonwan bash scripts/init_local_postgres.sh --seed
#
#   # 重置数据库（先手动 DROP，再重建）
#   psql -d postgres -c "DROP DATABASE IF EXISTS propos_dev;"
#   PGUSER=sheltonwan bash scripts/init_local_postgres.sh --seed
#
#   # 只跑 migrations，跳过测试数据
#   PGUSER=sheltonwan bash scripts/init_local_postgres.sh --skip-migrations=false
#
#   # 预览会执行什么，不真正操作数据库
#   PGUSER=sheltonwan bash scripts/init_local_postgres.sh --seed --dry-run
#
# 注意事项：
#   - seed.sql 为开发专用测试数据，⚠️ 生产环境绝对不能执行 --seed
#   - migrations/ 下 *.undo.sql 文件会自动跳过，不会被执行
#   - 脚本幂等：重复运行不会报错（角色/数据库已存在时自动跳过）
#   - 执行失败时整体中止（set -euo pipefail + ON_ERROR_STOP=1）
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# 路径配置（支持通过环境变量覆盖，便于 CI 使用不同目录布局）
# -----------------------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-$ROOT_DIR/backend/migrations}"
SEED_FILE="${SEED_FILE:-$ROOT_DIR/scripts/seed.sql}"

# -----------------------------------------------------------------------------
# 业务数据库连接参数（默认值适用于本地开发机）
# -----------------------------------------------------------------------------
APP_DB_NAME="${APP_DB_NAME:-propos_dev}"
APP_DB_USER="${APP_DB_USER:-propos}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-ChangeMe_2026!}"
APP_DB_HOST="${APP_DB_HOST:-${PGHOST:-localhost}}"
APP_DB_PORT="${APP_DB_PORT:-${PGPORT:-5432}}"

# -----------------------------------------------------------------------------
# 初始超管账号（仅 migration 020 执行时使用，后端运行时不需要）
# 生产部署前必须通过环境变量覆盖；开发机使用下方占位默认值
# 生成 hash 命令（需安装 apache2-utils 或 httpd-tools）：
#   htpasswd -bnBC 12 '' 'ChangeMe@2026!' | tr -d ':\n' | sed 's/\$2y/\$2a/'
# -----------------------------------------------------------------------------
ADMIN_EMAIL="${ADMIN_EMAIL:-smartv@qq.com}"
# 开发机默认 hash，对应明文 'ChangeMe@2026!'（bcrypt cost=12）
# 用 if 条件赋值而非 ${:-} 语法，因 bcrypt hash 含 $ 字符，需单引号防止 bash 展开
if [[ -z "${ADMIN_PASSWORD_HASH:-}" ]]; then
    ADMIN_PASSWORD_HASH='$2a$12$cWEz0fB8xeh7o8WtGOqQi.TZCC9Cc2cWbOgG18qgLg3RJa8hCr9Sq'
fi

# -----------------------------------------------------------------------------
# 运行时标志（由命令行参数控制）
# -----------------------------------------------------------------------------
RUN_SEED=false        # --seed：是否执行 seed.sql
SKIP_MIGRATIONS=false # --skip-migrations：是否跳过 DDL 迁移
DRY_RUN=false         # --dry-run：只打印步骤，不真正执行
BACKFILL=false        # --backfill：将所有 migration 文件标记为已应用，不实际执行

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
        --backfill)
            BACKFILL=true
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

# 生成幂等的角色与数据库初始化 SQL（通过 psql \gexec 执行，避免 IF NOT EXISTS 兼容问题）
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

# 以管理员身份对管理库执行任意 SQL（用于建库/建角色，不访问业务库）
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

# 以业务角色（propos）身份对业务库执行 SQL 文件（migrations / seed）
# -v admin_email / -v admin_password_hash 对所有 migration 透明传递，
# 仅 020_seed_reference_data.sql 实际引用这两个变量，其余文件忽略多余变量不报错
run_app_file() {
    local description="$1"
    local file_path="$2"

    info "$description: $file_path"
    if [[ "$DRY_RUN" == true ]]; then
        info "dry-run 模式下跳过文件执行"
        info "  psql -v admin_email=\"$ADMIN_EMAIL\" -v admin_password_hash=\"***\" ..."
        return 0
    fi

    PGPASSWORD="$APP_DB_PASSWORD" PAGER=cat psql -X -v ON_ERROR_STOP=1 \
        -v admin_email="$ADMIN_EMAIL" \
        -v admin_password_hash="$ADMIN_PASSWORD_HASH" \
        "${APP_PSQL_ARGS[@]}" -f "$file_path"
}

# 校验管理员 psql 连通性，失败时给出明确提示后中止
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

# 确保 schema_migrations 追踪表存在（幂等，用于记录已应用的 migration 文件名）
ensure_migrations_table() {
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    PGPASSWORD="$APP_DB_PASSWORD" PAGER=cat psql -X -v ON_ERROR_STOP=1 \
        "${APP_PSQL_ARGS[@]}" -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    filename   TEXT        PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);" >/dev/null
}

# 检查某个 migration 文件是否已应用
migration_applied() {
    local filename="$1"
    local result
    result="$(PGPASSWORD="$APP_DB_PASSWORD" PAGER=cat psql -X -t -A -v ON_ERROR_STOP=1 \
        "${APP_PSQL_ARGS[@]}" -c \
        "SELECT 1 FROM schema_migrations WHERE filename = '$filename';")"
    [[ "$result" == "1" ]]
}

# 记录 migration 已应用
mark_migration_applied() {
    local filename="$1"
    PGPASSWORD="$APP_DB_PASSWORD" PAGER=cat psql -X -v ON_ERROR_STOP=1 \
        "${APP_PSQL_ARGS[@]}" -c \
        "INSERT INTO schema_migrations (filename) VALUES ('$filename') ON CONFLICT DO NOTHING;" >/dev/null
}

# 按文件名字典序（即版本号顺序 001、002…）执行全部 DDL 迁移
# *.undo.sql 自动排除；已记录在 schema_migrations 表中的文件自动跳过
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

    ensure_migrations_table

    local applied_count=0
    local skipped_count=0

    while IFS= read -r migration_file; do
        [[ -n "$migration_file" ]] || continue
        local filename
        filename="$(basename "$migration_file")"

        # --backfill 模式：仅写入追踪表，不执行文件
        if [[ "$BACKFILL" == true ]]; then
            if [[ "$DRY_RUN" != true ]]; then
                mark_migration_applied "$filename"
            fi
            info "已回填（不执行）: $filename"
            (( applied_count++ )) || true
            continue
        fi

        if [[ "$DRY_RUN" != true ]] && migration_applied "$filename"; then
            info "跳过已应用的 migration: $filename"
            (( skipped_count++ )) || true
            continue
        fi

        run_app_file "执行 migration" "$migration_file"

        if [[ "$DRY_RUN" != true ]]; then
            mark_migration_applied "$filename"
        fi
        (( applied_count++ )) || true
    done <<< "$migration_files"

    if [[ "$BACKFILL" == true ]]; then
        ok "回填完成（已标记 ${applied_count} 个 migration 为已应用，未实际执行）"
    elif [[ "$DRY_RUN" == true ]]; then
        ok "dry-run 模式下已模拟 migrations 执行"
    else
        ok "migrations 执行完成（新应用: ${applied_count}，已跳过: ${skipped_count}）"
    fi
}

# 执行开发测试种子数据（仅在 --seed 参数存在时运行）
# ⚠️  生产环境禁止调用此函数
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

# 打印初始化结果摘要，并输出可直接写入 backend/.env 的 DATABASE_URL 参考值
print_summary() {
    ok "本地 PostgreSQL 初始化完成"
    printf '  db_name: %s\n' "$APP_DB_NAME"
    printf '  db_user: %s\n' "$APP_DB_USER"
    printf '  db_host: %s\n' "$APP_DB_HOST"
    printf '  db_port: %s\n' "$APP_DB_PORT"
    printf '  migrations: %s\n' "$([[ "$SKIP_MIGRATIONS" == true ]] && printf 'skipped' || printf 'tracked via schema_migrations')"
    printf '  seed: %s\n' "$([[ "$RUN_SEED" == true ]] && printf 'requested' || printf 'not requested')"
    printf '\n建议写入 backend/.env 的数据库配置：\n'
    printf 'DATABASE_URL=postgres://%s:<APP_DB_PASSWORD>@%s:%s/%s\n' \
        "$APP_DB_USER" "$APP_DB_HOST" "$APP_DB_PORT" "$APP_DB_NAME"
}

# =============================================================================
# 主执行流程（按依赖顺序串行，任意步骤失败则整体中止）
# =============================================================================
info "开始初始化 PropOS 本地 PostgreSQL"
check_admin_connection           # 步骤 1：校验管理员连接
run_admin_sql "创建或更新本地业务角色与数据库" "$(bootstrap_sql)"  # 步骤 2：建角色 + 建库
if [[ "$DRY_RUN" == true ]]; then
    ok "dry-run 模式下已模拟角色和数据库初始化"
else
    ok "角色和数据库已就绪"
fi
run_migrations   # 步骤 3：执行 DDL migrations
run_seed         # 步骤 4：写入开发测试数据（可选）
print_summary    # 步骤 5：打印结果摘要