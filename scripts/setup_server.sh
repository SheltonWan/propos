#!/usr/bin/env bash
# PropOS 服务器首次初始化脚本
# 执行时机：仅在首次部署时执行一次
# 执行位置：本地开发机，在项目根目录运行
# 用途：配置免密 SSH + 初始化服务器（Docker 网络、PostgreSQL、目录结构）

set -euo pipefail

# ============================================================
# 0. 命令行参数解析
# ============================================================
RESET_DB=false
for arg in "$@"; do
    case "${arg}" in
        --reset-db) RESET_DB=true ;;
    esac
done
readonly RESET_DB

# ============================================================
# 配置区（从 .deploy.env 读取，仅 SSH_KEY_PATH 为本地固定路径）
# ============================================================
DEPLOY_ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)/.deploy.env"

# 从 .deploy.env 读取服务器地址（部署到不同服务器只需改 .deploy.env）
SERVER_HOST=$(grep -E '^SERVER_HOST=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'\''  ' | xargs)
if [[ -z "${SERVER_HOST}" ]]; then
    error ".deploy.env 中未设置 SERVER_HOST，请先填写目标服务器公网 IP"
fi
readonly SERVER_HOST

readonly SERVER_USER="root"
readonly SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
readonly SSH_ALIAS="propos-server"
readonly REMOTE_BASE="/opt/propos"
readonly PG_USER="propos"
# 数据库密码（初始化后记得写入 .env 的 DATABASE_URL）
readonly PG_DB="propos"

# ============================================================
# 颜色输出
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ============================================================
# A. 本地免密 SSH 配置
# ============================================================
echo ""
echo "=========================================="
echo "  PropOS 服务器初始化脚本"
echo "  目标服务器: ${SERVER_USER}@${SERVER_HOST}"
echo "=========================================="
echo ""

# A1. 检查或生成 SSH 密钥
info "检查 SSH 密钥..."
if [[ ! -f "${SSH_KEY_PATH}" ]]; then
    warn "未找到 ${SSH_KEY_PATH}，正在生成 ed25519 密钥..."
    ssh-keygen -t ed25519 -f "${SSH_KEY_PATH}" -N "" -C "propos-deploy@$(hostname)"
    success "SSH 密钥已生成：${SSH_KEY_PATH}"
else
    success "SSH 密钥已存在：${SSH_KEY_PATH}"
fi

# A2. 推送公钥到服务器（若密钥认证已生效则直接跳过）
if ssh -o BatchMode=yes -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_HOST}" "echo ok" &>/dev/null; then
    success "SSH 密钥认证已生效，跳过 ssh-copy-id"
else
    # 从 .deploy.env 读取 SERVER_SSH_PASSWORD（可选，DEPLOY_ENV_FILE 已在配置区定义）
    _SSH_PASS=""
    if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
        _SSH_PASS=$(grep -E '^SERVER_SSH_PASSWORD=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
    fi

    if [[ -n "${_SSH_PASS}" ]] && command -v sshpass &>/dev/null; then
        info "使用 .deploy.env 中的 SERVER_SSH_PASSWORD 自动推送公钥..."
        sshpass -p "${_SSH_PASS}" ssh-copy-id \
            -o StrictHostKeyChecking=accept-new \
            -i "${SSH_KEY_PATH}.pub" \
            "${SERVER_USER}@${SERVER_HOST}"
        success "公钥已推送（自动）"
    else
        if [[ -n "${_SSH_PASS}" ]]; then
            warn "已在 .deploy.env 配置 SERVER_SSH_PASSWORD，但本地未安装 sshpass"
            warn "安装命令：brew install hudochenkov/sshpass/sshpass"
            warn "回退到手动输入密码..."
        else
            info "推送公钥到服务器（会提示输入一次服务器密码）..."
        fi
        ssh-copy-id -i "${SSH_KEY_PATH}.pub" "${SERVER_USER}@${SERVER_HOST}"
        success "公钥已推送"
    fi
    unset _SSH_PASS
fi

# A3. 写入 ~/.ssh/config（避免重复添加）
SSH_CONFIG="$HOME/.ssh/config"
if grep -q "Host ${SSH_ALIAS}" "${SSH_CONFIG}" 2>/dev/null; then
    warn "~/.ssh/config 中已存在 Host ${SSH_ALIAS}，跳过写入"
else
    info "写入 SSH 配置别名 ${SSH_ALIAS}..."
    # 确保 config 文件存在且权限正确
    touch "${SSH_CONFIG}"
    chmod 600 "${SSH_CONFIG}"
    cat >> "${SSH_CONFIG}" << EOF

# PropOS 腾讯云轻量服务器
Host ${SSH_ALIAS}
    HostName ${SERVER_HOST}
    User ${SERVER_USER}
    IdentityFile ${SSH_KEY_PATH}
    ServerAliveInterval 60
    StrictHostKeyChecking accept-new
EOF
    success "SSH 配置已写入：${SSH_ALIAS} → ${SERVER_USER}@${SERVER_HOST}"
fi

# A4. 验证免密登录
info "验证免密登录..."
if ssh -o BatchMode=yes "${SSH_ALIAS}" "echo ok" &>/dev/null; then
    success "免密 SSH 验证成功 ✓"
else
    error "免密 SSH 验证失败，请检查服务器安全组是否放行 22 端口，以及公钥是否正确写入"
fi

# ============================================================
# A5. （仅 --reset-db）确认危险操作
# ============================================================
if [[ "${RESET_DB}" == "true" ]]; then
    echo ""
    echo -e "${RED}==========================================${NC}"
    echo -e "${RED}  ⚠  --reset-db 将销毁服务器全部数据！  ${NC}"
    echo -e "${RED}  ⚠  此操作不可撤销，数据将永久丢失。  ${NC}"
    echo -e "${RED}==========================================${NC}"
    echo ""
    # 检测是否生产环境（服务器 .env 中 ALLOW_TEST_ENDPOINTS=false 视为生产）
    _is_prod=false
    if ssh -o BatchMode=yes "${SSH_ALIAS}" \
            "grep -q 'ALLOW_TEST_ENDPOINTS=false' ${REMOTE_BASE}/.env 2>/dev/null"; then
        _is_prod=true
    fi
    if [[ "${_is_prod}" == "true" ]]; then
        warn "检测到生产环境标志（ALLOW_TEST_ENDPOINTS=false）"
        read -r -p "  输入 CONFIRM_RESET 以继续（其他任何输入将取消）: " _reset_confirm
        if [[ "${_reset_confirm}" != "CONFIRM_RESET" ]]; then
            error "操作已取消"
        fi
    else
        read -r -p "  输入 RESET 以继续（其他任何输入将取消）: " _reset_confirm
        if [[ "${_reset_confirm}" != "RESET" ]]; then
            error "操作已取消"
        fi
    fi
    success "确认通过，将在数据库迁移阶段执行重置"
fi

# ============================================================
# B. 配置服务器端腾讯云 TCR 免密拉取
# ============================================================
echo ""
info "配置服务器端 Docker 镜像仓库登录凭据..."

# 优先从项目根目录 .deploy.env 自动读取 TCR 凭据（DEPLOY_ENV_FILE 已在配置区定义）
TCR_USER=""
TCR_PASSWORD=""

if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
    # 安全读取：仅提取 TCR_USER / TCR_PASSWORD，忽略其他行
    TCR_USER=$(grep -E '^TCR_USER=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
    TCR_PASSWORD=$(grep -E '^TCR_PASSWORD=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
fi

if [[ -n "${TCR_USER}" && -n "${TCR_PASSWORD}" ]]; then
    info "已从 .deploy.env 读取 TCR 凭据，自动配置服务器端登录..."
else
    echo ""
    warn "未在 .deploy.env 中找到 TCR 凭据，回退到手动输入"
    warn "（推荐：复制 .deploy.env.example 为 .deploy.env 并填写凭据，之后无需手动输入）"
    warn "如果没有独立的 TCR 访问账号，可使用腾讯云主账号 / 子账号的 docker login 凭据"
    echo ""
    read -r -p "  TCR 用户名（腾讯云账号 ID 或子账号 UIN）: " TCR_USER
    read -r -s -p "  TCR 密码（访问密钥 SecretKey 或独立镜像仓库密码）: " TCR_PASSWORD
    echo ""
fi

if [[ -z "${TCR_USER}" || -z "${TCR_PASSWORD}" ]]; then
    warn "TCR 凭据为空，跳过服务器端 docker login（部署时服务器将无法 pull 私有镜像）"
else
    info "在服务器上执行 docker login..."
    # 使用 --password-stdin 避免密码出现在进程列表中
    ssh "${SSH_ALIAS}" "echo '${TCR_PASSWORD}' | docker login ccr.ccs.tencentyun.com -u '${TCR_USER}' --password-stdin"
    success "服务器 TCR 登录成功，凭据已保存至 /root/.docker/config.json"
fi

# ============================================================
# C. 服务器初始化（远程执行）
# ============================================================
echo ""
info "开始服务器初始化..."

# 提示设置数据库密码
echo ""
warn "请设置 PostgreSQL 数据库密码（该密码同时需要写入 /opt/propos/.env 的 DATABASE_URL）"
read -r -p "  输入 PostgreSQL 密码（留空则使用随机密码）: " PG_PASSWORD
if [[ -z "${PG_PASSWORD}" ]]; then
    PG_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
    warn "已生成随机密码，请妥善保存：${PG_PASSWORD}"
fi

echo ""
info "正在初始化服务器（创建网络、启动 PostgreSQL、准备目录）..."

ssh "${SSH_ALIAS}" bash -s -- "${PG_USER}" "${PG_PASSWORD}" "${PG_DB}" "${REMOTE_BASE}" << 'REMOTE_SCRIPT'
set -euo pipefail

PG_USER="$1"
PG_PASSWORD="$2"
PG_DB="$3"
REMOTE_BASE="$4"

echo "[远程] 创建 Docker 网络 propos-net..."
docker network create propos-net 2>/dev/null && echo "[远程] ✓ 网络已创建" || echo "[远程] ✓ 网络已存在，跳过"

echo "[远程] 启动 PostgreSQL 15 容器..."
if docker ps -a --format '{{.Names}}' | grep -q '^propos-postgres$'; then
    echo "[远程] ✓ propos-postgres 容器已存在，跳过"
else
    docker run -d \
        --name propos-postgres \
        --network propos-net \
        --restart unless-stopped \
        -e POSTGRES_USER="${PG_USER}" \
        -e POSTGRES_PASSWORD="${PG_PASSWORD}" \
        -e POSTGRES_DB="${PG_DB}" \
        -v propos-pgdata:/var/lib/postgresql/data \
        postgres:15-alpine
    echo "[远程] ✓ PostgreSQL 已启动"
fi

echo "[远程] 等待 PostgreSQL 就绪..."
for i in $(seq 1 15); do
    if docker exec propos-postgres pg_isready -U "${PG_USER}" -d "${PG_DB}" &>/dev/null; then
        echo "[远程] ✓ PostgreSQL 已就绪"
        break
    fi
    echo "[远程]   等待中... (${i}/15)"
    sleep 2
done

echo "[远程] 创建应用目录..."
mkdir -p "${REMOTE_BASE}"
chmod 755 "${REMOTE_BASE}"
echo "[远程] ✓ 目录 ${REMOTE_BASE} 已准备"

echo "[远程] 创建文件存储卷..."
docker volume create propos-uploads 2>/dev/null || echo "[远程] ✓ 卷 propos-uploads 已存在"
REMOTE_SCRIPT

# D. 上传并执行数据库迁移（幂等：已建表则 SQL 中的 CREATE 语句不会重复执行）
info "上传数据库迁移文件..."
MIGRATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backend/migrations"
REMOTE_MIGRATIONS="${REMOTE_BASE}/migrations"

# 确保远端目录存在
ssh "${SSH_ALIAS}" "mkdir -p ${REMOTE_MIGRATIONS}"

# 仅上传 .sql 文件（忽略 .gitkeep 等）
rsync -az --include='*.sql' --exclude='*' "${MIGRATIONS_DIR}/" "${SSH_ALIAS}:${REMOTE_MIGRATIONS}/"
success "迁移文件已上传至 ${REMOTE_MIGRATIONS}"

# 读取超管账号凭据（migration 020 需要通过 psql -v 注入，不得硬编码在 SQL 文件中）
_ADMIN_EMAIL=$(grep -E '^ADMIN_EMAIL=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d "\"'" | xargs)
_ADMIN_PASSWORD_HASH=$(grep -E '^ADMIN_PASSWORD_HASH=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d "\"'" | xargs)

# 读取顶级企业名称（migration 023 需要通过 psql -v 注入）
_COMPANY_NAME=$(grep -E '^COMPANY_NAME=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d "\"'" | xargs)
if [[ -z "${_COMPANY_NAME}" ]]; then
    _COMPANY_NAME="PropOS 物业管理"
    warn "未在 .deploy.env 中找到 COMPANY_NAME，使用默认值：${_COMPANY_NAME}"
fi

if [[ -z "${_ADMIN_EMAIL}" ]]; then
    echo ""
    warn "未在 .deploy.env 中找到 ADMIN_EMAIL，需要手动输入"
    read -r -p "  超级管理员登录邮箱: " _ADMIN_EMAIL
fi
if [[ -z "${_ADMIN_EMAIL}" ]]; then
    _ADMIN_EMAIL="admin@propos.cn"
    warn "邮箱留空，使用默认值：${_ADMIN_EMAIL}"
fi

if [[ -z "${_ADMIN_PASSWORD_HASH}" ]]; then
    echo ""
    warn "未在 .deploy.env 中找到 ADMIN_PASSWORD_HASH（bcrypt hash，cost≥12）"
    warn "留空则使用开发默认 hash（明文 ChangeMe@2026!），生产环境请在首次登录后立即修改密码"
    read -r -s -p "  粘贴 bcrypt hash（留空使用默认）: " _ADMIN_PASSWORD_HASH
    echo ""
    if [[ -z "${_ADMIN_PASSWORD_HASH}" ]]; then
        # 开发默认 hash，对应明文 ChangeMe@2026!（bcrypt cost=12）
        _ADMIN_PASSWORD_HASH='$2a$12$cWEz0fB8xeh7o8WtGOqQi.TZCC9Cc2cWbOgG18qgLg3RJa8hCr9Sq'
        warn "使用开发默认密码 hash，首次登录后请立即修改密码"
    fi
fi

info "执行数据库迁移..."
# 含特殊字符或空格的参数统一 base64 编码后传递，避免 SSH word-split 或 shell 展开
_ADMIN_PASSWORD_HASH_B64=$(printf '%s' "${_ADMIN_PASSWORD_HASH}" | base64 | tr -d '\n')
_COMPANY_NAME_B64=$(printf '%s' "${_COMPANY_NAME}" | base64 | tr -d '\n')

ssh "${SSH_ALIAS}" bash -s -- "${PG_USER}" "${PG_DB}" "${REMOTE_MIGRATIONS}" "${_ADMIN_EMAIL}" "${_ADMIN_PASSWORD_HASH_B64}" "${_COMPANY_NAME_B64}" "${RESET_DB}" << 'RUN_MIGRATIONS'
set -euo pipefail
PG_USER="$1"; PG_DB="$2"; MIGRATIONS_DIR="$3"; ADMIN_EMAIL="$4"; ADMIN_PASSWORD_HASH_B64="$5"; COMPANY_NAME_B64="$6"; RESET_DB="$7"
# base64 解码还原原始值（含 $ 字符、空格等），避免 SSH 参数传递时被 shell 展开或 word-split
ADMIN_PASSWORD_HASH=$(printf '%s' "${ADMIN_PASSWORD_HASH_B64}" | base64 -d)
COMPANY_NAME=$(printf '%s' "${COMPANY_NAME_B64}" | base64 -d)

# ─── --reset-db 路径：清空数据库，重新从头执行所有迁移 ────────────────────
if [[ "${RESET_DB}" == "true" ]]; then
    echo "[重置] DROP SCHEMA public 并重建..."
    docker exec propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" -c "
        DROP SCHEMA public CASCADE;
        CREATE SCHEMA public;
        GRANT ALL ON SCHEMA public TO ${PG_USER};
        GRANT ALL ON SCHEMA public TO public;
    "
    echo "[重置] ✓ 数据库已清空，将从头执行所有迁移"
fi

# 创建迁移记录表（若不存在），含 file_hash 列用于检测已应用迁移被篡改
docker exec propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" -c "
CREATE TABLE IF NOT EXISTS _schema_migrations (
    filename   TEXT PRIMARY KEY,
    file_hash  TEXT NOT NULL DEFAULT '',
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
-- 兼容旧表（无 file_hash 列时补充）
ALTER TABLE _schema_migrations ADD COLUMN IF NOT EXISTS file_hash TEXT NOT NULL DEFAULT '';
" > /dev/null

echo "[迁移] 开始执行..."
for f in $(ls "${MIGRATIONS_DIR}"/*.sql 2>/dev/null | sort); do
    filename=$(basename "$f")
    # 计算文件 MD5（Linux md5sum，取第一列）
    current_hash=$(md5sum "$f" | cut -d' ' -f1)

    # 检查是否已执行
    row=$(docker exec propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" -tAc \
        "SELECT file_hash FROM _schema_migrations WHERE filename='${filename}';")

    if [[ -n "${row}" ]]; then
        # 已执行：检测文件内容是否被修改（防止静默跳过已篡改的迁移）
        if [[ "${row}" != "${current_hash}" && "${row}" != "" ]]; then
            echo "[迁移] ✗ 危险：${filename} 已应用但文件内容已被修改！"
            echo "         已记录 hash：${row}"
            echo "         当前文件 hash：${current_hash}"
            echo "         迁移应为只追加（append-only），请创建新的迁移文件而非修改已有文件。"
            exit 1
        fi
        echo "[迁移] ✓ 跳过（已执行）：${filename}"
        continue
    fi

    echo "[迁移] → 执行：${filename}"
    # 000_consolidated_schema.sql 需要同时注入超管账号、企业名称三个变量
    if [[ "${filename}" == "000_consolidated_schema.sql" ]]; then
        docker exec -i propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" \
            -v "admin_email=${ADMIN_EMAIL}" \
            -v "admin_password_hash=${ADMIN_PASSWORD_HASH}" \
            -v "company_name=${COMPANY_NAME}" \
            -v ON_ERROR_STOP=1 < "$f"
        # 执行后验证超管账号确实已入库，防止变量注入失败被静默记录
        admin_count=$(docker exec propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" -tAc \
            "SELECT COUNT(*) FROM users WHERE role='super_admin';")
        if [[ "${admin_count}" -lt 1 ]]; then
            echo "[迁移] ✗ 000 执行后超管账号未入库，可能是变量注入失败，终止。"
            exit 1
        fi
    else
        docker exec -i propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" \
            -v ON_ERROR_STOP=1 < "$f"
    fi

    # 记录已执行（含文件 hash，供后续篡改检测使用）
    docker exec propos-postgres psql -U "${PG_USER}" -d "${PG_DB}" -c \
        "INSERT INTO _schema_migrations (filename, file_hash) VALUES ('${filename}', '${current_hash}');" > /dev/null
    echo "[迁移] ✓ 完成：${filename}"
done
echo "[迁移] 所有迁移执行完毕"
RUN_MIGRATIONS
success "数据库迁移完成（超管账号：${_ADMIN_EMAIL}）"

# B. 在服务器上生成生产环境 .env（与本地开发 .env 有关键差异，不能直接复制）
info "生成服务器生产环境 .env..."

# 只有在服务器上 .env 不存在时才生成（避免覆盖已配置的生产 .env）
if ssh "${SSH_ALIAS}" "[[ -f ${REMOTE_BASE}/.env ]]"; then
    warn "服务器上 ${REMOTE_BASE}/.env 已存在，跳过生成（避免覆盖生产配置）"
else
    # 在本地生成随机密钥（避免服务器上没有 openssl 或 /dev/urandom 差异）
    JWT_SECRET_VAL=$(openssl rand -base64 48)
    ENCRYPTION_KEY_VAL=$(openssl rand -hex 32)

    # 从 .deploy.env 读取 SMTP 配置（与本地统一）
    _SMTP_HOST=$(grep -E '^SMTP_HOST=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'"'" | xargs)
    _SMTP_PORT=$(grep -E '^SMTP_PORT=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'"'" | xargs)
    _SMTP_USER=$(grep -E '^SMTP_USER=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'"'" | xargs)
    _SMTP_PASSWORD=$(grep -E '^SMTP_PASSWORD=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'"'" | xargs)
    _SMTP_FROM=$(grep -E '^SMTP_FROM=' "${DEPLOY_ENV_FILE}" 2>/dev/null | cut -d= -f2- | tr -d '"'"'" | xargs)
    # 默认值兜底
    _SMTP_PORT="${_SMTP_PORT:-465}"

    # 通过 SSH heredoc 写入服务器，注意与本地 .env 的关键差异：
    #   DATABASE_URL host → propos-postgres（Docker 容器名，非 localhost）
    #   FILE_STORAGE_PATH  → /data/uploads（容器挂载卷，非本地相对路径）
    #   CORS_ORIGINS       → 服务器公网 IP（非本地 dev server 端口）
    #   LOG_LEVEL          → info（非 debug）
    #   ALLOW_TEST_ENDPOINTS → false（生产环境严禁开启）
    #   SMTP → 与本地统一，从 .deploy.env 读取
    ssh "${SSH_ALIAS}" bash -s -- \
        "${PG_USER}" "${PG_PASSWORD}" "${PG_DB}" "${REMOTE_BASE}" \
        "${JWT_SECRET_VAL}" "${ENCRYPTION_KEY_VAL}" "${SERVER_HOST}" \
        "${_SMTP_HOST}" "${_SMTP_PORT}" "${_SMTP_USER}" "${_SMTP_PASSWORD}" "${_SMTP_FROM}" << 'WRITE_ENV'
set -euo pipefail
PG_USER="$1"; PG_PASSWORD="$2"; PG_DB="$3"; REMOTE_BASE="$4"
JWT_SECRET_VAL="$5"; ENCRYPTION_KEY_VAL="$6"; SERVER_HOST="$7"
SMTP_HOST="$8"; SMTP_PORT="$9"; SMTP_USER="${10}"; SMTP_PASSWORD="${11}"; SMTP_FROM="${12}"

cat > "${REMOTE_BASE}/.env" << ENV_CONTENT
# PropOS Backend 生产环境变量
# 由 setup_server.sh 自动生成，请勿提交到版本控制
# 生成日期：$(date '+%Y-%m-%d %H:%M:%S')

# PostgreSQL（host 使用 Docker 容器名，非 localhost）
DATABASE_URL=postgres://${PG_USER}:${PG_PASSWORD}@propos-postgres:5432/${PG_DB}
DB_SSL_MODE=disable

# JWT
JWT_SECRET=${JWT_SECRET_VAL}
JWT_EXPIRES_IN_HOURS=24

# 文件存储（容器内挂载卷路径，非本地相对路径）
FILE_STORAGE_PATH=/data/uploads

# AES-256 加密密钥
ENCRYPTION_KEY=${ENCRYPTION_KEY_VAL}

# HTTP 端口
APP_PORT=8080

# SMTP 邮件服务（与本地开发环境统一）
# 端口 465 → 隐式 SSL；端口 587 → STARTTLS
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_FROM=${SMTP_FROM}

# 可选配置
CORS_ORIGINS=http://${SERVER_HOST}
LOG_LEVEL=info
MAX_UPLOAD_SIZE_MB=50

# 集成测试端点（生产环境必须为 false）
ALLOW_TEST_ENDPOINTS=false
ENV_CONTENT

chmod 600 "${REMOTE_BASE}/.env"
echo "[远程] ✓ .env 已生成：${REMOTE_BASE}/.env"
WRITE_ENV

    success "服务器 .env 已生成（JWT_SECRET 和 ENCRYPTION_KEY 已自动生成随机值）"
fi

# ============================================================
# 完成提示
# ============================================================
echo ""
echo "=========================================="
success "服务器初始化完成！"
echo "=========================================="
echo ""
echo -e "${YELLOW}后续步骤：${NC}"
echo ""
echo "  1. （可选）查看服务器 .env 确认配置："
echo "     ssh ${SSH_ALIAS} cat ${REMOTE_BASE}/.env"
echo ""
echo "  2. 部署后端："
echo "     bash backend/deploy.sh"
echo ""
echo "  3. 部署前端："
echo "     bash admin/deploy.sh"
echo ""
echo -e "${YELLOW}注意：数据库密码、JWT_SECRET、ENCRYPTION_KEY 已自动生成并写入服务器 .env，"
echo -e "请妥善备份 ${REMOTE_BASE}/.env（ssh ${SSH_ALIAS} cat ${REMOTE_BASE}/.env）${NC}"
echo ""
