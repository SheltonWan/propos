#!/usr/bin/env bash
# PropOS Admin 前端部署脚本
# 执行时机：每次发布 admin 新版本时执行
# 执行位置：本地开发机，在项目根目录运行
# 前置条件：
#   1. 已执行 scripts/setup_server.sh（免密 SSH 已配置）
#   2. 本地已安装 pnpm 和 rsync

set -euo pipefail

# ============================================================
# 配置区（按需修改）
# ============================================================
readonly SSH_ALIAS="propos-server"
readonly CONTAINER_NAME="propos-nginx"
readonly REMOTE_BASE="/opt/propos"
readonly REMOTE_DIST="${REMOTE_BASE}/admin-dist"
readonly REMOTE_NGINX_CONF="${REMOTE_BASE}/nginx.conf"
readonly NGINX_IMAGE="nginx:alpine"

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
# 定位 admin 目录（兼容从项目根目录或 admin/ 下执行）
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# deploy.sh 在 admin/ 下
ADMIN_DIR="${SCRIPT_DIR}"
NGINX_CONF="${ADMIN_DIR}/nginx.conf"

echo ""
echo "=========================================="
echo "  PropOS Admin 前端部署"
echo "  服务器: ${SSH_ALIAS}"
echo "=========================================="
echo ""

# ============================================================
# Step 1: 前置检查
# ============================================================
info "Step 1/5: 前置检查..."

command -v pnpm  &>/dev/null || error "未找到 pnpm，请先安装：npm install -g pnpm"
command -v rsync &>/dev/null || error "未找到 rsync 命令"
command -v ssh   &>/dev/null || error "未找到 ssh 命令"

if [[ ! -f "${NGINX_CONF}" ]]; then
    error "未找到 ${NGINX_CONF}，请确认 admin/nginx.conf 存在"
fi

# 验证 SSH 别名可连通
if ! ssh -o BatchMode=yes "${SSH_ALIAS}" "echo ok" &>/dev/null; then
    error "无法连接到 ${SSH_ALIAS}，请先执行 bash scripts/setup_server.sh"
fi
success "前置检查通过"

# ============================================================
# Step 2: 构建 admin 静态文件
# ============================================================
info "Step 2/5: 构建 admin 静态文件..."
echo "  构建目录: ${ADMIN_DIR}"
echo "  API 路径: 相对路径（由 Nginx 反代处理，无需硬编码服务器 IP）"
echo ""

# VITE_API_BASE_URL='' 使 axios baseURL 为空，请求走相对路径
# Nginx 将 /api/ 前缀的请求反代到 propos-backend:8080
(cd "${ADMIN_DIR}" && VITE_API_BASE_URL='' pnpm build)

LOCAL_DIST="${ADMIN_DIR}/dist"
if [[ ! -d "${LOCAL_DIST}" ]]; then
    error "构建产物目录 ${LOCAL_DIST} 不存在，构建可能失败"
fi
success "构建完成：${LOCAL_DIST}"

# ============================================================
# Step 3: 同步静态文件到服务器
# ============================================================
info "Step 3/5: 同步静态文件到服务器..."

# 确保远程目录存在
ssh "${SSH_ALIAS}" "mkdir -p ${REMOTE_DIST}"

# rsync 增量同步（--delete 清除服务器上已删除的旧文件）
rsync -avz --delete \
    --exclude='.DS_Store' \
    "${LOCAL_DIST}/" \
    "${SSH_ALIAS}:${REMOTE_DIST}/"

success "静态文件已同步至 ${SSH_ALIAS}:${REMOTE_DIST}"

# ============================================================
# Step 4: 同步 Nginx 配置
# ============================================================
info "Step 4/5: 同步 Nginx 配置..."
rsync -avz "${NGINX_CONF}" "${SSH_ALIAS}:${REMOTE_NGINX_CONF}"
success "Nginx 配置已同步"

# ============================================================
# Step 5: 启动或重启 Nginx 容器
# ============================================================
info "Step 5/5: 更新 Nginx 容器..."

ssh "${SSH_ALIAS}" bash -s -- "${CONTAINER_NAME}" "${NGINX_IMAGE}" "${REMOTE_DIST}" "${REMOTE_NGINX_CONF}" << 'REMOTE_SCRIPT'
set -euo pipefail
CONTAINER_NAME="$1"
NGINX_IMAGE="$2"
REMOTE_DIST="$3"
REMOTE_NGINX_CONF="$4"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # 容器已存在：重载配置并重启
    echo "[远程] 重启 ${CONTAINER_NAME} 容器..."
    # 先将最新 nginx.conf 复制进容器，再重载（避免完全停服）
    docker cp "${REMOTE_NGINX_CONF}" "${CONTAINER_NAME}:/etc/nginx/conf.d/default.conf"
    docker exec "${CONTAINER_NAME}" nginx -t 2>&1 | sed 's/^/  /'
    docker exec "${CONTAINER_NAME}" nginx -s reload
    echo "[远程] ✓ Nginx 配置已热重载"
else
    # 容器不存在：首次启动
    echo "[远程] 首次启动 ${CONTAINER_NAME} 容器..."
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --network propos-net \
        --restart unless-stopped \
        -p 80:80 \
        -v "${REMOTE_DIST}:/usr/share/nginx/html:ro" \
        -v "${REMOTE_NGINX_CONF}:/etc/nginx/conf.d/default.conf:ro" \
        "${NGINX_IMAGE}"
    echo "[远程] ✓ ${CONTAINER_NAME} 已启动"
fi

# 等待 Nginx 就绪
sleep 2
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[远程] ✓ ${CONTAINER_NAME} 运行中"
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "${CONTAINER_NAME}"
else
    echo "[远程] ✗ 容器未能正常启动，查看日志："
    docker logs --tail 30 "${CONTAINER_NAME}"
    exit 1
fi
REMOTE_SCRIPT

# ============================================================
# 完成
# ============================================================
echo ""
echo "=========================================="
success "Admin 前端部署完成！"
echo "=========================================="
echo ""
echo "  访问地址：http://111.230.112.246"
echo ""
echo "  查看日志："
echo "    ssh ${SSH_ALIAS} docker logs -f ${CONTAINER_NAME}"
echo ""
