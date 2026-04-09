#!/usr/bin/env bash
# scripts/check_env.sh — PropOS 开发环境就绪检查
#
# 用法：
#   bash scripts/check_env.sh          # 全量检查
#   bash scripts/check_env.sh --quick  # 跳过依赖安装状态检查
#
# 检查范围：
#   1. 后端工具链：Dart SDK ≥3.0、PostgreSQL ≥15
#   2. 前端工具链：Node.js ≥18、pnpm ≥8
#   3. Python 工具链：Python 3、python-docx、ezdxf
#   4. macOS 专属：Pages App（PDF 导出）、ODA File Converter（CAD）
#   5. 通用工具：Git
#   6. 环境变量：后端必需变量（检查 backend/.env 或 Shell 环境）
#   7. 数据库连通性：尝试连接 DATABASE_URL

set -uo pipefail

# ─────────────────────────────────────────────
#  颜色 & 输出工具
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'  # Reset

QUICK_MODE=false
[[ "${1:-}" == "--quick" ]] && QUICK_MODE=true

PASS=0
FAIL=0
WARN=0

ok()   { echo -e "  ${GREEN}✓${NC}  $1"; ((PASS++)); }
fail() { echo -e "  ${RED}✗${NC}  $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}!${NC}  $1"; ((WARN++)); }
info() { echo -e "  ${DIM}•${NC}  ${DIM}$1${NC}"; }
section() { echo -e "\n${BOLD}${CYAN}▸ $1${NC}"; }

# ─────────────────────────────────────────────
#  辅助：版本号比较（仅比较 major.minor）
#  compare_version <actual> <required>  → 0=OK, 1=FAIL
# ─────────────────────────────────────────────
compare_version() {
    local actual="$1" required="$2"
    local IFS=.
    read -r -a a <<< "${actual%%[^0-9.]*}"
    read -r -a r <<< "${required%%[^0-9.]*}"
    for i in 0 1; do
        local av="${a[$i]:-0}" rv="${r[$i]:-0}"
        (( av > rv )) && return 0
        (( av < rv )) && return 1
    done
    return 0
}

# ─────────────────────────────────────────────
#  加载 backend/.env（如存在），补充到当前环境
# ─────────────────────────────────────────────
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$WORKSPACE/backend/.env"

if [[ -f "$ENV_FILE" ]]; then
    # 导出非注释、非空行的变量（不覆盖已有 Shell 变量）
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE" 2>/dev/null || true
    set +a
fi

# ─────────────────────────────────────────────
#  打印标题
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   PropOS 开发环境就绪检查                    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo -e "  工作目录: ${DIM}$WORKSPACE${NC}"
[[ -f "$ENV_FILE" ]] && echo -e "  读取配置: ${DIM}backend/.env${NC}" || echo -e "  ${YELLOW}backend/.env 未找到，仅检查 Shell 环境变量${NC}"

# ══════════════════════════════════════════════
#  1. 后端工具链
# ══════════════════════════════════════════════
section "1. 后端工具链"

# Dart SDK ≥ 3.0
if command -v dart &>/dev/null; then
    DART_VER="$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'  | head -1)"
    if compare_version "$DART_VER" "3.0"; then
        ok "Dart SDK ${DART_VER}  （需 ≥3.0）"
    else
        fail "Dart SDK ${DART_VER}  （需 ≥3.0，请升级）"
        info "升级：https://dart.dev/get-dart"
    fi
else
    fail "Dart SDK 未找到"
    info "安装：brew install dart  或通过 Flutter SDK 获取"
fi

# PostgreSQL ≥ 15
if command -v psql &>/dev/null; then
    PG_VER="$(psql --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    PG_MAJOR="${PG_VER%%.*}"
    if (( PG_MAJOR >= 15 )); then
        ok "PostgreSQL ${PG_VER}  （需 ≥15）"
    else
        fail "PostgreSQL ${PG_VER}  （需 ≥15，请升级）"
        info "升级：brew install postgresql@15"
    fi
else
    fail "PostgreSQL 未找到（psql 命令不可用）"
    info "安装：brew install postgresql@15 && brew services start postgresql@15"
fi

# pg_isready（用于连通性测试，不阻断）
if ! command -v pg_isready &>/dev/null; then
    warn "pg_isready 未找到，跳过数据库连通性测试"
fi

# ══════════════════════════════════════════════
#  2. 前端工具链（uni-app + Vue3 Admin）
# ══════════════════════════════════════════════
section "2. 前端工具链（uni-app + Vue3 Admin）"

# Node.js ≥ 18（uni-app 4.x 与 Vue3 Admin 编译要求）
if command -v node &>/dev/null; then
    NODE_VER="$(node --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    if compare_version "$NODE_VER" "18.0"; then
        ok "Node.js ${NODE_VER}  （需 ≥18）"
    else
        fail "Node.js ${NODE_VER}  （需 ≥18，请升级）"
        info "升级：brew install node  或使用 nvm install 18"
    fi
else
    fail "Node.js 未找到"
    info "安装：brew install node  或 https://nodejs.org"
fi

# pnpm ≥ 8（项目包管理器）
if command -v pnpm &>/dev/null; then
    PNPM_VER="$(pnpm --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    if compare_version "$PNPM_VER" "8.0"; then
        ok "pnpm ${PNPM_VER}  （需 ≥8）"
    else
        fail "pnpm ${PNPM_VER}  （需 ≥8，请升级）"
        info "升级：npm install -g pnpm@latest"
    fi
else
    fail "pnpm 未找到"
    info "安装：npm install -g pnpm"
fi

# 检查 app/ 依赖是否已安装（uni-app）
if [[ -d "$WORKSPACE/app/node_modules" ]]; then
    ok "app/node_modules  — uni-app 依赖已安装"
elif [[ "$QUICK_MODE" == false ]] && [[ -f "$WORKSPACE/app/package.json" ]]; then
    warn "app/node_modules 不存在  — 请执行 cd app && pnpm install"
fi

# 检查 admin/ 依赖是否已安装（Vue3 Admin）
if [[ -d "$WORKSPACE/admin/node_modules" ]]; then
    ok "admin/node_modules  — Vue3 Admin 依赖已安装"
elif [[ "$QUICK_MODE" == false ]] && [[ -f "$WORKSPACE/admin/package.json" ]]; then
    warn "admin/node_modules 不存在  — 请执行 cd admin && pnpm install"
fi

# ══════════════════════════════════════════════
#  3. Python 工具链
# ══════════════════════════════════════════════
section "3. Python 工具链"

# Python 3（优先使用项目 .venv，兜底使用系统 python3）
VENV_PYTHON="$WORKSPACE/.venv/bin/python3"
if [[ -x "$VENV_PYTHON" ]]; then
    PYTHON="$VENV_PYTHON"
    PY_VER="$($VENV_PYTHON --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')"
    ok "Python ${PY_VER}  （.venv）"
elif command -v python3 &>/dev/null; then
    PYTHON="python3"
    PY_VER="$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')"
    ok "Python ${PY_VER}  （系统）"
    warn ".venv 未找到，包检查可能失败（运行 python3 -m venv .venv 创建）"
else
    fail "Python 3 未找到"
    PYTHON=""
fi

# python-docx（md2word.py 依赖）
if [[ -n "$PYTHON" ]]; then
    if $PYTHON -c "import docx" &>/dev/null; then
        DOCX_VER="$($PYTHON -c "import docx; print(docx.__version__)" 2>/dev/null || echo "已安装")"
        ok "python-docx ${DOCX_VER}  （md→docx 转换）"
    else
        fail "python-docx 未安装"
        info "安装：source .venv/bin/activate && pip install python-docx"
    fi

    # ezdxf（CAD DXF→SVG 转换）
    if $PYTHON -c "import ezdxf" &>/dev/null; then
        EZDXF_VER="$($PYTHON -c "import ezdxf; print(ezdxf.__version__)" 2>/dev/null || echo "已安装")"
        ok "ezdxf ${EZDXF_VER}  （CAD DXF→SVG 转换）"
    else
        warn "ezdxf 未安装  （CAD 模块 M1 需要）"
        info "安装：source .venv/bin/activate && pip install \"ezdxf[draw]\""
    fi
fi

# ══════════════════════════════════════════════
#  4. macOS 专属工具
# ══════════════════════════════════════════════
section "4. macOS 专属工具"

# macOS Pages App（docx2pdf.py 依赖 AppleScript 驱动 Pages）
PAGES_PATH="/Applications/Pages.app"
if [[ -d "$PAGES_PATH" ]]; then
    ok "Pages.app  （docx→PDF 导出）"
else
    fail "Pages.app 未找到  （PDF 导出功能不可用）"
    info "在 Mac App Store 安装 Pages：https://apps.apple.com/app/pages/id409201541"
fi

# ODA File Converter（DWG→DXF，M1 CAD 转换第一步）
ODA_PATH="/Applications/ODAFileConverter.app"
if [[ -d "$ODA_PATH" ]]; then
    ok "ODA File Converter  （DWG→DXF，CAD 转换第一步）"
else
    warn "ODA File Converter 未找到  （M1 CAD 模块导入 .dwg 文件需要）"
    info "下载：https://www.opendesign.com/guestfiles/oda_file_converter"
fi

# ══════════════════════════════════════════════
#  5. 通用工具
# ══════════════════════════════════════════════
section "5. 通用工具"

# Git
if command -v git &>/dev/null; then
    GIT_VER="$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    ok "Git ${GIT_VER}"
else
    fail "Git 未找到"
    info "安装：brew install git"
fi

# bash（脚本依赖）
if command -v bash &>/dev/null; then
    BASH_VER="$(bash --version | head -1 | grep -oE '[0-9]+\.[0-9]+')"
    ok "Bash ${BASH_VER}"
fi

# ══════════════════════════════════════════════
#  6. 后端必需环境变量
# ══════════════════════════════════════════════
section "6. 后端必需环境变量"

check_env_var() {
    local name="$1" desc="$2" min_len="${3:-1}"
    local val="${!name:-}"
    if [[ -z "$val" ]]; then
        fail "${name}  — ${desc}  （未设置）"
    elif (( ${#val} < min_len )); then
        warn "${name}  — 值过短（当前 ${#val} 位，建议 ≥${min_len} 位）"
    else
        # 脱敏输出：只显示前4位 + ***
        local preview="${val:0:4}***"
        ok "${name}  — ${desc}  ${DIM}(${preview})${NC}"
    fi
}

check_env_var "DATABASE_URL"         "PostgreSQL 连接串"          20
check_env_var "JWT_SECRET"           "JWT 签名密钥"               32
check_env_var "JWT_EXPIRES_IN_HOURS" "Token 有效期（小时）"        1
check_env_var "FILE_STORAGE_PATH"    "本地文件存储根目录"           2
check_env_var "ENCRYPTION_KEY"       "AES-256 证件号加密密钥"      32
check_env_var "APP_PORT"             "HTTP 监听端口"               1

# ══════════════════════════════════════════════
#  7. 数据库连通性
# ══════════════════════════════════════════════
section "7. 数据库连通性"

DB_URL="${DATABASE_URL:-}"
if [[ -z "$DB_URL" ]]; then
    warn "DATABASE_URL 未设置，跳过连通性测试"
else
    # 从 DATABASE_URL 中提取连接信息 postgres://user:pwd@host:port/db
    if [[ "$DB_URL" =~ ^postgres(ql)?://([^:@]+)(:([^@]+))?@([^:/]+)(:([0-9]+))?/(.+) ]]; then
        PG_USER="${BASH_REMATCH[2]}"
        PG_HOST="${BASH_REMATCH[5]}"
        PG_PORT="${BASH_REMATCH[7]:-5432}"
        PG_DB="${BASH_REMATCH[8]}"

        if command -v pg_isready &>/dev/null; then
            if pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -q 2>/dev/null; then
                ok "数据库 ${PG_DB}@${PG_HOST}:${PG_PORT}  连通正常"
            else
                fail "数据库 ${PG_DB}@${PG_HOST}:${PG_PORT}  无法连接"
                info "检查 PostgreSQL 是否已启动：brew services start postgresql@15"
                info "检查 DATABASE_URL 格式：postgres://user:pwd@host:5432/dbname"
            fi
        elif command -v psql &>/dev/null; then
            if PGPASSWORD="${BASH_REMATCH[4]:-}" psql "$DB_URL" -c "SELECT 1" -q &>/dev/null 2>&1; then
                ok "数据库 ${PG_DB}@${PG_HOST}:${PG_PORT}  连通正常"
            else
                fail "数据库 ${PG_DB}@${PG_HOST}:${PG_PORT}  无法连接"
                info "检查 PostgreSQL 是否已启动：brew services start postgresql@15"
            fi
        else
            warn "psql / pg_isready 均不可用，跳过连通性测试"
        fi
    else
        warn "DATABASE_URL 格式无法解析，跳过连通性测试"
        info "预期格式：postgres://user:pwd@host:5432/dbname"
    fi
fi

# ══════════════════════════════════════════════
#  8. 项目目录结构
# ══════════════════════════════════════════════
section "8. 项目目录结构"

check_dir() {
    local path="$1" label="$2"
    if [[ -d "$WORKSPACE/$path" ]]; then
        ok "${path}/  — ${label}"
    else
        warn "${path}/  — ${label}  （目录不存在）"
    fi
}

check_dir "backend"   "后端 Dart 项目"
check_dir "app"       "移动端 uni-app 项目"
check_dir "admin"     "PC 管理后台 Vue3 Admin"
check_dir "docs"      "项目文档"
check_dir "scripts"   "工具脚本"
check_dir "pdfdocs"   "PDF 文档输出"

# 检查 backend 是否已初始化（有 pubspec.yaml）
if [[ -f "$WORKSPACE/backend/pubspec.yaml" ]]; then
    ok "backend/pubspec.yaml  — Dart 项目已初始化"
else
    warn "backend/pubspec.yaml 未找到  — 后端尚未初始化"
    info "初始化：cd backend && dart create -t server-shelf . --force"
fi

# 检查 app（uni-app）是否已初始化
if [[ -f "$WORKSPACE/app/package.json" ]]; then
    ok "app/package.json  — uni-app 项目已初始化"
else
    warn "app/package.json 未找到  — uni-app 项目尚未初始化"
    info "初始化：参考 docs/DEV_ENV_SETUP.md  uni-app 章节"
fi

# 检查 admin（Vue3 Admin）是否已初始化
if [[ -f "$WORKSPACE/admin/package.json" ]]; then
    ok "admin/package.json  — Vue3 Admin 项目已初始化"
else
    warn "admin/package.json 未找到  — Vue3 Admin 项目尚未初始化"
    info "初始化：参考 docs/DEV_ENV_SETUP.md  admin 章节"
fi

# ══════════════════════════════════════════════
#  9. VS Code 工作区配置
# ══════════════════════════════════════════════
section "9. VS Code 工作区配置"

VSCODE_SETTINGS="$WORKSPACE/.vscode/settings.json"
VSCODE_SETTING_TYPO="$WORKSPACE/.vscode/setting.json"

# 检查是否存在拼写错误的 setting.json（缺少 's'，VS Code 不读取）
if [[ -f "$VSCODE_SETTING_TYPO" ]] && [[ ! -f "$VSCODE_SETTINGS" ]]; then
    fail ".vscode/setting.json 存在但 VS Code 不读取（文件名缺少 's'）"
    info "修复：mv .vscode/setting.json .vscode/settings.json"
elif [[ -f "$VSCODE_SETTINGS" ]]; then
    ok ".vscode/settings.json  — 工作区配置存在"

    # 检查 typescript.tsdk 是否配置（防止 VS Code 内置 TS 版本解析 extends 路径失败）
    if grep -q '"typescript.tsdk"' "$VSCODE_SETTINGS"; then
        TSDK_VAL="$(grep '"typescript.tsdk"' "$VSCODE_SETTINGS" | grep -oE '"[^"]*node_modules[^"]*"' | tr -d '"')"
        if [[ -n "$TSDK_VAL" ]]; then
            ok "typescript.tsdk  — ${TSDK_VAL}"
        else
            warn "typescript.tsdk 已配置但值可能有误（检查是否指向 app/node_modules/typescript/lib）"
        fi
    else
        warn ".vscode/settings.json 未配置 typescript.tsdk"
        info "VS Code 内置 TypeScript 7.0+ 解析 @vue/tsconfig/tsconfig.json 时会报错"
        info "修复：在 .vscode/settings.json 中添加 \"typescript.tsdk\": \"./app/node_modules/typescript/lib\""
    fi
else
    warn ".vscode/settings.json 不存在"
    info "创建后添加：\"typescript.tsdk\": \"./app/node_modules/typescript/lib\""
    info "防止 VS Code 内置 TypeScript 误报 @vue/tsconfig/tsconfig.json 找不到"
fi

# ══════════════════════════════════════════════
#  汇总
# ══════════════════════════════════════════════
TOTAL=$((PASS + FAIL + WARN))
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   检查汇总                                   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo -e "  共检查项目：${BOLD}${TOTAL}${NC}"
echo -e "  ${GREEN}✓ 通过：${PASS}${NC}"
echo -e "  ${YELLOW}! 警告：${WARN}${NC}"
echo -e "  ${RED}✗ 失败：${FAIL}${NC}"
echo ""

if (( FAIL == 0 && WARN == 0 )); then
    echo -e "  ${GREEN}${BOLD}✅ 环境完全就绪，可开始开发！${NC}"
elif (( FAIL == 0 )); then
    echo -e "  ${YELLOW}${BOLD}⚠️  核心环境就绪，存在部分可选项未配置（见上方警告）${NC}"
else
    echo -e "  ${RED}${BOLD}❌ 发现 ${FAIL} 项问题，请修复后重新检查${NC}"
    echo -e "  ${DIM}提示：修复后执行 bash scripts/check_env.sh 再次验证${NC}"
fi

echo ""
# 以失败数作为退出码（0=全部通过，>0=有失败项）
exit "$FAIL"
