#!/usr/bin/env bash
# scripts/extract_candidates.sh
# 运行 DXF → 候选结构抽取，并将结果写入数据库（本地或远程）。
#
# 本脚本是 split_dxf_by_floor.py --extract-structures --db-url 的封装：
#   - local  模式：直接连接本地 PostgreSQL，使用本地 .venv 运行
#   - remote 模式：将 DXF + 脚本 rsync 到远程服务器，在远程服务器上以
#                  Docker 容器（python:3.11-slim，挂入 propos-net）执行，
#                  直接通过容器内部 DNS 访问 propos-postgres，无需 SSH 隧道。
#                  执行完毕后将生成的 SVG 文件 rsync 回本地 --out 目录。
#
# 用法:
#   bash scripts/extract_candidates.sh --target local  --dxf cad_intermediate/building_a/A座.dxf --out cad_intermediate/building_a/floors
#   bash scripts/extract_candidates.sh --target remote --dxf cad_intermediate/building_a/A座.dxf --out cad_intermediate/building_a/floors
#
# 环境变量（local 模式）:
#   PG_USER      默认 propos
#   PG_PASSWORD  默认 ChangeMe_2026!（必须与 .env 一致）
#   PG_HOST      默认 localhost
#   PG_PORT      默认 5432
#   PG_DB        默认 propos_dev
#
# 环境变量（remote 模式）:
#   SSH_ALIAS        远程 SSH 别名（默认 propos-server）
#   REMOTE_ENV_FILE  远程 .env 路径（默认 /opt/propos/.env），脚本从中读 DATABASE_URL
#
# 依赖:
#   - local 模式：Python 虚拟环境 .venv（项目根目录），含 ezdxf + psycopg[binary]
#   - remote 模式：ssh propos-server 免密可达；远程宿主机已安装 Docker

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ── 参数解析 ──────────────────────────────────────────────
TARGET=""; DXF_FILE=""; OUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --dxf)    DXF_FILE="$2"; shift 2 ;;
        --out)    OUT_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,45p' "$0"; exit 0 ;;
        *) error "未知参数: $1" ;;
    esac
done

[[ -z "$TARGET"   ]] && error "--target 必填（local | remote）"
[[ -z "$DXF_FILE" ]] && error "--dxf 必填，例如: cad_intermediate/building_a/A座.dxf"
[[ -z "$OUT_DIR"  ]] && error "--out 必填，例如: cad_intermediate/building_a/floors"
[[ "$TARGET" != "local" && "$TARGET" != "remote" ]] && error "--target 只接受 local 或 remote"
[[ ! -f "$DXF_FILE" ]] && error "DXF 文件不存在: $DXF_FILE"

# ── 定位项目根目录（兼容从任意子目录执行） ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_PYTHON="$PROJECT_ROOT/.venv/bin/python3"
PY_SCRIPT="$PROJECT_ROOT/scripts/split_dxf_by_floor.py"
FLOOR_MAP_DIR="$PROJECT_ROOT/scripts/floor_map"

# 将相对路径转为绝对路径（避免 cd 后路径失效）
DXF_FILE="$(cd "$PROJECT_ROOT" && realpath "$DXF_FILE")"
OUT_DIR="$(cd "$PROJECT_ROOT" && realpath -m "$OUT_DIR")"  # -m 允许目录不存在

# ── local 模式 ────────────────────────────────────────────
if [[ "$TARGET" == "local" ]]; then
    [[ ! -x "$VENV_PYTHON" ]] && error "未找到 .venv/bin/python3，请先执行: python3 -m venv .venv && source .venv/bin/activate && pip install ezdxf lxml Pillow psycopg[binary]"
    [[ ! -f "$PY_SCRIPT"   ]] && error "未找到 scripts/split_dxf_by_floor.py"

    : "${PG_USER:=propos}"
    : "${PG_PASSWORD:=ChangeMe_2026!}"
    : "${PG_HOST:=localhost}"
    : "${PG_PORT:=5432}"
    : "${PG_DB:=propos_dev}"

    DB_URL="postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DB}"

    info "目标: 本地数据库 ${PG_HOST}:${PG_PORT}/${PG_DB}"
    info "DXF:  $DXF_FILE"
    info "输出: $OUT_DIR"

    "$VENV_PYTHON" "$PY_SCRIPT" \
        "$DXF_FILE" "$OUT_DIR" \
        --extract-structures \
        --db-url "$DB_URL"

    success "本地候选结构抽取完成"
    exit 0
fi

# ── remote 模式 ───────────────────────────────────────────
# 正确拓扑：Python 在远程宿主机的 Docker 容器内运行，直接通过 propos-net
# 容器内部 DNS 访问 propos-postgres，与 propos-backend 容器同网段。
# 不使用 SSH 隧道（隧道方向相反，且绕过 Docker 网络）。
: "${SSH_ALIAS:=propos-server}"
: "${REMOTE_ENV_FILE:=/opt/propos/.env}"
REMOTE_WORK_DIR="/tmp/propos_extract"

# 检查 SSH 连通性
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_ALIAS" "echo ok" &>/dev/null; then
    error "无法连接到 $SSH_ALIAS，请先执行 bash scripts/setup_server.sh"
fi

# 从远程 .env 读取 DATABASE_URL（已含 propos-postgres 容器主机名）
info "读取远程 DATABASE_URL from ${REMOTE_ENV_FILE}..."
REMOTE_DB_URL="$(ssh "$SSH_ALIAS" "grep -E '^DATABASE_URL=' '${REMOTE_ENV_FILE}' | cut -d= -f2- | tr -d '\"'")"
[[ -z "$REMOTE_DB_URL" ]] && error "未能从 ${REMOTE_ENV_FILE} 读取 DATABASE_URL，请确认文件存在且含该变量"

info "远程 DB: $REMOTE_DB_URL"
info "DXF:     $DXF_FILE"
info "本地输出: $OUT_DIR"

# 在远程创建工作目录并 rsync 脚本 + DXF
info "上传脚本与 DXF 到 ${SSH_ALIAS}:${REMOTE_WORK_DIR} ..."
ssh "$SSH_ALIAS" "mkdir -p ${REMOTE_WORK_DIR}/scripts/floor_map ${REMOTE_WORK_DIR}/dxf ${REMOTE_WORK_DIR}/out"
rsync -az "$PY_SCRIPT"         "${SSH_ALIAS}:${REMOTE_WORK_DIR}/scripts/"
rsync -az "${FLOOR_MAP_DIR}/"  "${SSH_ALIAS}:${REMOTE_WORK_DIR}/scripts/floor_map/"
rsync -az "$DXF_FILE"          "${SSH_ALIAS}:${REMOTE_WORK_DIR}/dxf/"

DXF_BASENAME="$(basename "$DXF_FILE")"

# 在远程以 Docker 容器运行抽取（挂入 propos-net，直连 propos-postgres）
info "在 ${SSH_ALIAS} 上启动 python:3.11-slim 容器执行抽取..."
ssh "$SSH_ALIAS" docker run --rm \
    --network propos-net \
    -v "${REMOTE_WORK_DIR}:/work" \
    python:3.11-slim \
    bash -c "
        pip install ezdxf lxml Pillow 'psycopg[binary]' -q
        python3 /work/scripts/split_dxf_by_floor.py \
            /work/dxf/'${DXF_BASENAME}' \
            /work/out \
            --extract-structures \
            --db-url '${REMOTE_DB_URL}'
    "

# rsync 生成的 SVG 文件回本地 OUT_DIR
info "同步 SVG 输出到本地 ${OUT_DIR} ..."
mkdir -p "$OUT_DIR"
rsync -az "${SSH_ALIAS}:${REMOTE_WORK_DIR}/out/" "$OUT_DIR/"

success "远程候选结构抽取完成，SVG 已同步至 $OUT_DIR"
