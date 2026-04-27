#!/usr/bin/env bash
# PropOS Backend 部署脚本
# 执行时机：每次发布 backend 新版本时执行
# 执行位置：本地开发机，在项目根目录或 backend/ 目录运行
# 前置条件：
#   1. 已执行 scripts/setup_server.sh（免密 SSH + 服务器 TCR 凭据已配置）
#   2. 服务器上 /opt/propos/.env 已填写完整
#   3. 项目根目录 .deploy.env 已填写 TCR_USER / TCR_PASSWORD（脚本自动登录，无需手动 docker login）

set -euo pipefail

# ============================================================
# 配置区（按需修改）
# ============================================================
readonly REGISTRY="ccr.ccs.tencentyun.com/ephnic/propos_backend"
readonly IMAGE_TAG="${1:-latest}"
readonly FULL_IMAGE="${REGISTRY}:${IMAGE_TAG}"
readonly SSH_ALIAS="propos-server"
readonly CONTAINER_NAME="propos-backend"
readonly ENV_FILE="/opt/propos/.env"
readonly UPLOADS_VOLUME="propos-uploads"

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
# 定位 backend 目录（兼容从项目根目录或 backend/ 下执行）
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# deploy.sh 在 backend/ 下
BACKEND_DIR="${SCRIPT_DIR}"

echo ""
echo "=========================================="
echo "  PropOS Backend 部署"
echo "  镜像: ${FULL_IMAGE}"
echo "  服务器: ${SSH_ALIAS}"
echo "=========================================="
echo ""

# ============================================================
# Step 1: 前置检查
# ============================================================
info "Step 1/5: 前置检查..."

command -v docker &>/dev/null || error "未找到 docker 命令，请先安装 Docker Desktop"
command -v ssh &>/dev/null    || error "未找到 ssh 命令"

# 验证 SSH 别名可连通
if ! ssh -o BatchMode=yes "${SSH_ALIAS}" "echo ok" &>/dev/null; then
    error "无法连接到 ${SSH_ALIAS}，请先执行 bash scripts/setup_server.sh"
fi
success "前置检查通过"

# 验证服务器上 .env 存在
if ! ssh "${SSH_ALIAS}" "[[ -f ${ENV_FILE} ]]"; then
    error "服务器上 ${ENV_FILE} 不存在，请先创建并填写生产环境变量"
fi

# ============================================================
# Step 2: 本地构建 Docker 镜像
# ============================================================
info "Step 2/5: 构建 Docker 镜像（这可能需要几分钟）..."
echo "  构建目录: ${BACKEND_DIR}"
echo "  目标镜像: ${FULL_IMAGE}"
echo ""

docker build \
    --platform linux/amd64 \
    -t "${FULL_IMAGE}" \
    "${BACKEND_DIR}"

success "镜像构建完成：${FULL_IMAGE}"

# ============================================================
# Step 3: 推送镜像到腾讯云 TCR
# ============================================================
info "Step 3/5: 推送镜像到腾讯云 TCR..."

# 尝试从项目根目录 .deploy.env 自动登录，避免每次手动执行 docker login
DEPLOY_ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.deploy.env"
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
    _TCR_USER=$(grep -E '^TCR_USER=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
    _TCR_PASS=$(grep -E '^TCR_PASSWORD=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
    _TCR_REG=$(grep -E '^TCR_REGISTRY=' "${DEPLOY_ENV_FILE}" | cut -d= -f2- | tr -d '"'"'" | xargs)
    _TCR_REG="${_TCR_REG:-ccr.ccs.tencentyun.com}"
    if [[ -n "${_TCR_USER}" && -n "${_TCR_PASS}" ]]; then
        info "使用 .deploy.env 凭据自动登录 ${_TCR_REG}..."
        echo "${_TCR_PASS}" | docker login "${_TCR_REG}" -u "${_TCR_USER}" --password-stdin
        success "TCR 登录成功"
    fi
    unset _TCR_USER _TCR_PASS _TCR_REG
fi

docker push "${FULL_IMAGE}"
success "镜像推送完成"

# ============================================================
# Step 4 & 5: 服务器拉取并重启容器
# ============================================================
info "Step 4/5: 服务器拉取最新镜像..."
ssh "${SSH_ALIAS}" docker pull "${FULL_IMAGE}"
success "镜像拉取完成"

info "Step 5/5: 重启 backend 容器..."
ssh "${SSH_ALIAS}" bash -s -- "${FULL_IMAGE}" "${CONTAINER_NAME}" "${ENV_FILE}" "${UPLOADS_VOLUME}" << 'REMOTE_SCRIPT'
set -euo pipefail
FULL_IMAGE="$1"
CONTAINER_NAME="$2"
ENV_FILE="$3"
UPLOADS_VOLUME="$4"

# 停止并删除旧容器（不存在则忽略）
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[远程] 停止旧容器..."
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
fi

# 启动新容器
echo "[远程] 启动新容器..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    --network propos-net \
    --restart unless-stopped \
    --env-file "${ENV_FILE}" \
    -p 8080:8080 \
    -v "${UPLOADS_VOLUME}:/data/uploads" \
    "${FULL_IMAGE}"

echo "[远程] 等待容器健康检查..."
sleep 3
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
success "Backend 部署完成！"
echo "=========================================="
echo ""
echo "  验证："
echo "    curl http://$(ssh "${SSH_ALIAS}" 'curl -s ifconfig.me 2>/dev/null || echo "111.230.112.246"'):8080/api/health"
echo ""
echo "  查看日志："
echo "    ssh ${SSH_ALIAS} docker logs -f ${CONTAINER_NAME}"
echo ""
