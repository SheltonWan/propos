#!/usr/bin/env bash
# ============================================================
# PropOS Flutter 集成测试运行脚本
# 用法：
#   bash scripts/run_integration_tests.sh [选项]
#
# 选项：
#   -d <device_id>     指定设备/模拟器 ID（默认：自动选第一个可用设备）
#   -u <base_url>      后端 Base URL（默认：http://localhost:8080）
#   -e <email>         管理员邮箱（默认：admin@propos.local）
#   -p <password>      管理员密码（默认：Test1234!）
#   -t <test_file>     只运行指定测试文件（默认：全部 integration_test/）
#   -h                 显示此帮助信息
#
# 示例：
#   # 使用默认配置（本地后端 + 自动选设备）
#   bash scripts/run_integration_tests.sh
#
#   # 指定设备 + 后端地址
#   bash scripts/run_integration_tests.sh -d "iPhone 16 Pro" -u http://10.0.0.1:8080
#
#   # 只跑 auth 集成测试
#   bash scripts/run_integration_tests.sh -t integration_test/features/auth/auth_full_flow_test.dart
# ============================================================

set -euo pipefail

# ── 默认参数 ─────────────────────────────────────────────────────────────────
API_BASE_URL="http://localhost:8080"
IT_ADMIN_EMAIL="admin@propos.local"
IT_ADMIN_PASSWORD="Test1234!"
IT_SUBLORD_EMAIL="dingsheng@external.com"
IT_SUBLORD_PASSWORD="Test1234!"
DEVICE_ID="1C394CE5-A2FA-4E2B-9C54-39B6CE2E8BE8"
TEST_TARGET="integration_test/"

# ── 颜色输出 ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── 解析参数 ─────────────────────────────────────────────────────────────────
while getopts "d:u:e:p:t:h" opt; do
  case $opt in
    d) DEVICE_ID="$OPTARG" ;;
    u) API_BASE_URL="$OPTARG" ;;
    e) IT_ADMIN_EMAIL="$OPTARG" ;;
    p) IT_ADMIN_PASSWORD="$OPTARG" ;;
    t) TEST_TARGET="$OPTARG" ;;
    h)
      sed -n '/^# 用法/,/^# =====/p' "$0" | head -n -1 | sed 's/^# *//'
      exit 0
      ;;
    *)
      log_error "未知选项: -$OPTARG"
      exit 1
      ;;
  esac
done

# ── 切换到 flutter_app 目录 ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
cd "$APP_DIR"
log_info "工作目录: $APP_DIR"

# ── 检查 Flutter 环境 ────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
  log_error "未找到 flutter 命令，请确认 Flutter SDK 已添加到 PATH。"
  exit 1
fi
FLUTTER_VERSION=$(flutter --version --machine 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('frameworkVersion','unknown'))" 2>/dev/null || echo "unknown")
log_info "Flutter 版本: $FLUTTER_VERSION"

# ── 检查后端连通性 ────────────────────────────────────────────────────────────
log_info "检查后端 $API_BASE_URL/health ..."
if curl -sf --max-time 5 "${API_BASE_URL}/health" &>/dev/null; then
  log_ok "后端健康检查通过。"
else
  log_warn "无法连接到后端 ${API_BASE_URL}，集成测试将因 HTTP 错误而失败。"
  log_warn "如需继续（例如仅验证编译），请确认后端已启动后重试。"
  echo ""
  read -rp "是否仍要继续运行测试？[y/N] " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "已取消。"
    exit 0
  fi
fi

# ── 自动选择设备 ──────────────────────────────────────────────────────────────
if [[ -z "$DEVICE_ID" ]]; then
  log_info "扫描可用设备..."
  # 取第一个非标题行的设备 ID（格式：... • <id> • ...）
  DEVICE_ID=$(flutter devices 2>/dev/null \
    | grep -v "^No devices\|^[[:space:]]*$\|^Flutter\|devices" \
    | awk -F'•' 'NR==1{gsub(/[[:space:]]+/,"",$2); print $2}' \
    | head -n1)

  if [[ -z "$DEVICE_ID" ]]; then
    log_error "未找到可用设备。请启动模拟器或连接真机后重试。"
    echo ""
    log_info "提示：使用 'open -a Simulator' 启动 iOS 模拟器，"
    log_info "      或 'flutter emulators --launch <emulator_id>' 启动 Android 模拟器。"
    exit 1
  fi
  log_ok "自动选择设备: $DEVICE_ID"
else
  log_info "使用指定设备: $DEVICE_ID"
fi

# ── 输出测试配置 ──────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PropOS 集成测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  后端地址   : $API_BASE_URL"
echo "  管理员邮箱 : $IT_ADMIN_EMAIL"
echo "  管理员密码 : $(echo "$IT_ADMIN_PASSWORD" | sed 's/./*/g')"
echo "  设备 ID    : $DEVICE_ID"
echo "  测试目标   : $TEST_TARGET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 运行集成测试 ──────────────────────────────────────────────────────────────
START_TIME=$(date +%s)

flutter test "$TEST_TARGET" \
  --dart-define="API_BASE_URL=${API_BASE_URL}" \
  --dart-define="IT_ADMIN_EMAIL=${IT_ADMIN_EMAIL}" \
  --dart-define="IT_ADMIN_PASSWORD=${IT_ADMIN_PASSWORD}" \
  --dart-define="IT_SUBLORD_EMAIL=${IT_SUBLORD_EMAIL}" \
  --dart-define="IT_SUBLORD_PASSWORD=${IT_SUBLORD_PASSWORD}" \
  -d "$DEVICE_ID" \
  --reporter expanded

EXIT_CODE=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  log_ok "所有集成测试通过（耗时 ${ELAPSED}s）。"
else
  log_error "集成测试失败（耗时 ${ELAPSED}s，退出码 ${EXIT_CODE}）。"
fi

exit $EXIT_CODE
