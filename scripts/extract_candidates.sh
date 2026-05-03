#!/usr/bin/env bash
# scripts/extract_candidates.sh
# 运行 DXF → 候选结构抽取，并将结果写入数据库（本地或远程）。
#
# ┌─────────────────────────────────────────────────────────────────────┐
# │  【本脚本本质是 structure_detector.py 的测试驱动工具】                 │
# │  【不是生产辅助工具，不能复现完整的后端导入流程】                        │
# │                                                                     │
# │  正常业务流程中，候选结构抽取由后端自动完成，无需调用本脚本：             │
# │    上传 DXF（POST /api/cad/buildings/{id}/import）                   │
# │      → CadImportService.uploadDxf()                                 │
# │        → 异步调用 split_dxf_by_floor.py --extract-structures        │
# │          → 写入 floor_maps.candidates（由 DATABASE_URL 注入）         │
# │                                                                     │
# │  本脚本的真正有效场景（仅 2 个）：                                     │
# │    1. 纯算法验证：不启动后端服务、不走 API，直接把 DXF 丢进来，          │
# │       观察 structure_detector.py 能否抽到正确的                        │
# │       wall / column / window，是迭代算法精度时的主要工具               │
# │    2. 本地开发环境不完整时：只需 .venv + PostgreSQL，                  │
# │       无需 Dart 运行时、无需 HTTP 服务                                 │
# │                                                                     │
# │  ⚠ 本脚本与后端行为不等价，存在以下差异：                              │
# │    1. --prefix 不同：本脚本输出 floor_<label>.svg（Python 默认值）     │
# │       后端使用原始文件名派生前缀，如 A座_<label>.svg                    │
# │       → 用本脚本结果无法复现后端 _extractLabel() 的匹配行为             │
# │    2. 不执行热区标注（后端会运行 annotate_hotzone.py）                  │
# │    3. 不做 SVG→楼层匹配→floor_plan 数据库归档                         │
# │    4. remote 模式写入 DB 的 candidates 前缀与后端不一致，               │
# │       无法作为生产补跑手段（需要补跑请重新调用 API 上传）                 │
# │                                                                     │
# │  如果你的目的是正常导入 CAD 文件，请使用 Admin 界面或 API，             │
# │  而不是直接调用本脚本。                                                │
# └─────────────────────────────────────────────────────────────────────┘
#
# 本脚本是 split_dxf_by_floor.py --extract-structures --db-url 的封装：
#   - local  模式：直接连接本地 PostgreSQL，使用本地 .venv 运行
#   - remote 模式：将 DXF + 脚本 rsync 到远程服务器，在远程服务器上以
#                  Docker 容器（python:3.11-slim，挂入 propos-net）执行，
#                  直接通过容器内部 DNS 访问 propos-postgres，无需 SSH 隧道。
#                  执行完毕后将生成的 SVG 文件 rsync 回本地 --out 目录。
#
# 用法:
#   bash scripts/extract_candidates.sh --target local  --dxf cad_intermediate/building_a/A座.dxf --out cad_intermediate/building_a/floors --prefix A座
#   bash scripts/extract_candidates.sh --target remote --dxf cad_intermediate/building_a/A座.dxf --out cad_intermediate/building_a/floors --prefix A座
#
# --prefix 说明:
#   SVG / candidates.json 的文件名前缀，默认 "floor"。
#   【重要】如需用回归测试验证结果正确性，必须传 --prefix A座（与测试 fixture 路径一致）：
#     python -m pytest scripts/floor_map/tests/ -v
#   tests/test_business_layer_f11.py 会读取 <out>/A座_F11.candidates.json 并校验
#   outline/columns/windows 数量阈值，是唯一可用的正确性验证手段。
#
# ⚠ 数据库写入说明:
#   脚本默认会 UPSERT 数据到 floor_maps 表（覆盖 candidates 字段），无交互确认。
#   如需仅输出本地文件、不写 DB（算法调试推荐），请加 --no-db 参数：
#     bash scripts/extract_candidates.sh --target local --dxf ... --out ... --prefix A座 --no-db
#   remote 模式传 --no-db 同样跳过 DB 写入（仅 rsync SVG 回本地）。
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
TARGET=""; DXF_FILE=""; OUT_DIR=""; PREFIX=""; NO_DB=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --dxf)    DXF_FILE="$2"; shift 2 ;;
        --out)    OUT_DIR="$2"; shift 2 ;;
        --prefix) PREFIX="$2"; shift 2 ;;
        --no-db)  NO_DB=1; shift ;;
        -h|--help)
            sed -n '2,65p' "$0"; exit 0 ;;
        *) error "未知参数: $1" ;;
    esac
done

[[ -z "$TARGET"   ]] && error "--target 必填（local | remote）"
[[ -z "$DXF_FILE" ]] && error "--dxf 必填，例如: cad_intermediate/building_a/A座.dxf"
[[ -z "$OUT_DIR"  ]] && error "--out 必填，例如: cad_intermediate/building_a/floors"
[[ "$TARGET" != "local" && "$TARGET" != "remote" ]] && error "--target 只接受 local 或 remote"
[[ ! -f "$DXF_FILE" ]] && error "DXF 文件不存在: $DXF_FILE"

# 未指定 --prefix 时发出警告，说明验证测试将无法运行
if [[ -z "$PREFIX" ]]; then
    warn "--prefix 未指定，将使用 Python 默认值 \"floor\""
    warn "如需运行回归测试验证结果，请加 --prefix A座（或对应楼栋前缀）"
fi

# ── 定位项目根目录（兼容从任意子目录执行） ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_PYTHON="$PROJECT_ROOT/.venv/bin/python3"
PY_SCRIPT="$PROJECT_ROOT/scripts/split_dxf_by_floor.py"
FLOOR_MAP_DIR="$PROJECT_ROOT/scripts/floor_map"

# 将相对路径转为绝对路径（避免 cd 后路径失效）
# 注：BSD realpath（macOS 内置）不支持 -m，先创建目录再 realpath 以兼容 macOS
DXF_FILE="$(cd "$PROJECT_ROOT" && realpath "$DXF_FILE")"
(cd "$PROJECT_ROOT" && mkdir -p "$OUT_DIR")
OUT_DIR="$(cd "$PROJECT_ROOT" && realpath "$OUT_DIR")"

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
    [[ -n "$PREFIX" ]] && info "前缀: $PREFIX"

    PREFIX_ARGS=()
    [[ -n "$PREFIX" ]] && PREFIX_ARGS=("--prefix" "$PREFIX")

    DB_ARGS=()
    if [[ "$NO_DB" -eq 1 ]]; then
        info "--no-db 已设置：跳过 floor_maps 写入，仅输出本地文件"
    else
        warn "将向 ${PG_HOST}:${PG_PORT}/${PG_DB} 的 floor_maps 表执行 UPSERT（覆盖 candidates 字段）"
        warn "如需只读调试，请加 --no-db 参数"
        DB_ARGS=("--db-url" "$DB_URL")
    fi

    "$VENV_PYTHON" "$PY_SCRIPT" \
        "$DXF_FILE" "$OUT_DIR" \
        --extract-structures \
        "${DB_ARGS[@]}" \
        "${PREFIX_ARGS[@]}"

    success "本地候选结构抽取完成"

    # 提示如何验证结果正确性
    if [[ -n "$PREFIX" ]]; then
        echo ""
        info "验证结果正确性（回归测试需在项目根目录执行）:"
        info "  source .venv/bin/activate"
        info "  python -m pytest scripts/floor_map/tests/ -v"
        info "  → test_business_layer_f11.py 将读取 ${OUT_DIR}/${PREFIX}_F11.candidates.json"
        info "    并校验 outline / columns(≥10) / windows(≥15) 三项阈值"
    else
        warn "结果正确性无法通过回归测试验证（前缀 \"floor\" 与测试 fixture 不匹配）"
        warn "如需验证，请重新运行并加 --prefix A座"
    fi
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

# 准备远程 DB 参数
if [[ "$NO_DB" -eq 1 ]]; then
    REMOTE_DB_URL=""
    info "--no-db 已设置：跳过远程 floor_maps 写入，仅输出 SVG 并 rsync 回本地"
else
    # 从远程 .env 读取 DATABASE_URL（已含 propos-postgres 容器主机名）
    info "读取远程 DATABASE_URL from ${REMOTE_ENV_FILE}..."
    REMOTE_DB_URL="$(ssh "$SSH_ALIAS" "grep -E '^DATABASE_URL=' '${REMOTE_ENV_FILE}' | cut -d= -f2- | tr -d '\"'")"
    [[ -z "$REMOTE_DB_URL" ]] && error "未能从 ${REMOTE_ENV_FILE} 读取 DATABASE_URL，请确认文件存在且含该变量"
    warn "将向远程数据库的 floor_maps 表执行 UPSERT（覆盖 candidates 字段）"
    warn "如需只读调试，请加 --no-db 参数"
    info "远程 DB: $REMOTE_DB_URL"
fi

info "DXF:     $DXF_FILE"
info "本地输出: $OUT_DIR"

DXF_BASENAME="$(basename "$DXF_FILE")"

# 在远程创建工作目录并 rsync 脚本 + DXF
# 注：同时上传脚本，以确保容器内版本与本地一致（防止镜像 tag 滞后）
info "上传脚本与 DXF 到 ${SSH_ALIAS}:${REMOTE_WORK_DIR} ..."
ssh "$SSH_ALIAS" "mkdir -p ${REMOTE_WORK_DIR}/scripts/floor_map ${REMOTE_WORK_DIR}/dxf ${REMOTE_WORK_DIR}/out"
rsync -az "$PY_SCRIPT"         "${SSH_ALIAS}:${REMOTE_WORK_DIR}/scripts/"
rsync -az "${FLOOR_MAP_DIR}/"  "${SSH_ALIAS}:${REMOTE_WORK_DIR}/scripts/floor_map/"
rsync -az "$DXF_FILE"          "${SSH_ALIAS}:${REMOTE_WORK_DIR}/dxf/"

# 构建容器内 Python 命令的 --db-url / --prefix 参数（空值时不传）
CONTAINER_DB_ARGS=""
[[ -n "$REMOTE_DB_URL" ]] && CONTAINER_DB_ARGS="--db-url \"${REMOTE_DB_URL}\""
CONTAINER_PREFIX_ARGS=""
[[ -n "$PREFIX" ]] && CONTAINER_PREFIX_ARGS="--prefix \"${PREFIX}\""

# 在远程以 Docker 容器运行抽取（挂入 propos-net，直连 propos-postgres）
# 使用 python:3.12-slim（与 Dockerfile 一致），安装字体解决 CJK 空框问题，
# 通过 --env 传递路径与 DB_URL，规避 bash -c 字符串内的引号转义陷阱
info "在 ${SSH_ALIAS} 上启动 python:3.12-slim 容器执行抽取..."
ssh "$SSH_ALIAS" docker run --rm \
    --network propos-net \
    --env "DXF_PATH=/work/dxf/${DXF_BASENAME}" \
    -v "${REMOTE_WORK_DIR}:/work" \
    python:3.12-slim \
    bash -c "
        apt-get update -q \
        && apt-get install -y --no-install-recommends \
               fonts-dejavu-core fonts-wqy-microhei -q \
        && apt-get clean && rm -rf /var/lib/apt/lists/*
        pip install ezdxf lxml Pillow 'psycopg[binary]' -q \
            -i https://pypi.tuna.tsinghua.edu.cn/simple
        python3 /work/scripts/split_dxf_by_floor.py \
            \"\$DXF_PATH\" \
            /work/out \
            --extract-structures \
            ${CONTAINER_DB_ARGS} \
            ${CONTAINER_PREFIX_ARGS}
    "

# rsync 生成的 SVG 文件回本地 OUT_DIR
info "同步 SVG 输出到本地 ${OUT_DIR} ..."
rsync -az "${SSH_ALIAS}:${REMOTE_WORK_DIR}/out/" "$OUT_DIR/"

# 清理远程临时目录（忽略失败，不阻断主流程）
ssh "$SSH_ALIAS" "rm -rf '${REMOTE_WORK_DIR}'" \
    || warn "远程临时目录清理失败，请手动删除：${SSH_ALIAS}:${REMOTE_WORK_DIR}"

success "远程候选结构抽取完成，SVG 已同步至 $OUT_DIR"
