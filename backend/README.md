# PropOS Backend

基于 [Shelf](https://pub.dev/packages/shelf) 的 Dart HTTP 服务，承载 PropOS 物业运营平台所有 REST API。

---

## 快速启动（本地开发）

### 1. 检查开发环境

在项目根目录运行环境就绪检查脚本，确认 Dart SDK、PostgreSQL、Flutter 等工具链版本符合要求：

```bash
bash scripts/check_env.sh
```

如需跳过 `flutter doctor` 详情输出：

```bash
bash scripts/check_env.sh --quick
```

脚本检查范围：
- Dart SDK ≥ 3.0、PostgreSQL ≥ 15、Flutter ≥ 3.0
- Python 3、python-docx、ezdxf（文档工具链）
- Git
- `backend/.env` 中必需变量是否齐全
- 尝试连接 `DATABASE_URL` 验证数据库连通性

### 2. 初始化本地数据库

脚本幂等可重复执行，连接 PostgreSQL 管理库后自动创建角色和数据库：

```bash
bash scripts/init_local_postgres.sh
```

常用选项：

| 选项 | 说明 |
|------|------|
| `--seed` | 执行 `scripts/seed.sql` 导入种子数据（需 DDL 已就位） |
| `--skip-migrations` | 跳过 `backend/migrations/*.sql` |
| `--dry-run` | 只打印步骤，不实际连接数据库 |
| `--db-name NAME` | 业务库名，默认 `propos_dev` |
| `--db-user USER` | 业务用户，默认 `propos` |
| `--db-password PASS` | 业务密码，默认 `ChangeMe_2026!` |

管理员连接优先使用 `ADMIN_DATABASE_URL`；未设置时回退到 `PGHOST / PGPORT / PGUSER / PGPASSWORD`。

### 3. 配置 `.env`

将 `backend/.env.example`（如有）复制为 `backend/.env` 并按需修改；或直接参考以下说明新建文件。`.env` 由启动入口自动加载，**不提交到版本库**。

```bash
# backend/.env

# ── 必填变量（缺失时服务拒绝启动）────────────────────────────────

# PostgreSQL 连接串
DATABASE_URL=postgres://propos:ChangeMe_2026!@localhost:5432/propos_dev

# JWT 签名密钥（≥32 字节）
JWT_SECRET=<随机生成，至少32字符>

# JWT 有效期（小时）
JWT_EXPIRES_IN_HOURS=24

# 文件存储根目录（支持相对路径，以服务启动目录为基准）
FILE_STORAGE_PATH=.local/uploads

# AES-256 加密密钥（用于证件号字段，≥32 字节十六进制字符串）
ENCRYPTION_KEY=<openssl rand -hex 32>

# HTTP 监听端口
APP_PORT=8080

# ── 可选变量（缺失时使用默认值）──────────────────────────────────

# 跨域允许来源，默认 *
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# 日志级别：debug / info / warning / error，默认 info
LOG_LEVEL=info

# 上传文件大小上限（MB），默认 50
MAX_UPLOAD_SIZE_MB=50
```

生成随机密钥的参考命令：

```bash
# JWT_SECRET（48字符十六进制）
openssl rand -hex 24

# ENCRYPTION_KEY（64字符十六进制，对应32字节）
openssl rand -hex 32
```

> **生产环境**：不使用 `.env` 文件，由部署平台（Kubernetes Secret / Docker `--env-file` / systemd `EnvironmentFile`）直接向进程注入环境变量，`Platform.environment` 中已有这些变量时 `.env` 文件不需要存在。

### 4. 启动服务

```bash
cd backend
dart run bin/server.dart
# [PropOS] 服务已启动: http://0.0.0.0:8080
```

---

## Docker

```bash
docker build . -t propos-backend
docker run -it -p 8080:8080 \
  -e DATABASE_URL=postgres://... \
  -e JWT_SECRET=... \
  -e JWT_EXPIRES_IN_HOURS=24 \
  -e FILE_STORAGE_PATH=/data/uploads \
  -e ENCRYPTION_KEY=... \
  -e APP_PORT=8080 \
  propos-backend
```

---

## 单元测试

### 测试目录结构

```
test/
├── config_state_error_test.dart      # 环境变量缺失时的启动失败断言
├── unit/                             # 单元测试（无外部依赖）
│   ├── auth_service_test.dart
│   ├── auth_middleware_test.dart
│   ├── auth_controller_test.dart
│   ├── login_service_test.dart
│   ├── building_service_test.dart
│   ├── building_controller_test.dart
│   ├── floor_service_test.dart
│   ├── floor_controller_test.dart
│   ├── unit_service_test.dart
│   ├── unit_controller_test.dart
│   ├── renovation_service_test.dart
│   ├── renovation_controller_test.dart
│   ├── email_service_test.dart
│   ├── encryption_test.dart          # 证件号 AES-256 加解密验证
│   └── helpers/                      # 共享 Mock / Stub 工厂
└── integration/                      # 集成测试（需真实数据库连接）
    ├── auth_integration_test.dart
    └── assets_integration_test.dart

packages/
├── kpi_scorer/test/
│   └── scorer_test.dart              # KPI 线性插值打分单元测试
└── rent_escalation_engine/test/
    └── calculator_test.dart          # 租金递增计算单元测试（6 种类型 + 混合分段）
```

### 运行单元测试

```bash
cd backend

# 运行全部单元测试
dart test test/unit/

# 运行单个测试文件
dart test test/unit/auth_service_test.dart

# 运行启动配置测试
dart test test/config_state_error_test.dart
```

### 运行核心计算包测试

```bash
# KPI 打分引擎
cd packages/kpi_scorer
dart test

# 租金递增引擎
cd ../../packages/rent_escalation_engine
dart test
```

### 运行集成测试

集成测试需要真实的 PostgreSQL 数据库连接，运行前确保 `.env` 已配置且数据库已完成迁移。

```bash
cd backend
dart test test/integration/
```

### 测试规范

| 规则 | 说明 |
|------|------|
| 单元测试无外部依赖 | 使用 Mock Repository/Service，不连接数据库或网络 |
| BLoC/Cubit 必须有测试 | 每个 Cubit 对应一个 `*_cubit_test.dart`，使用 `bloc_test` 包 |
| 核心计算强制覆盖 | `kpi_scorer` 和 `rent_escalation_engine` 所有公共函数必须有单元测试 |
| 证件号加密验证 | `encryption_test.dart` 覆盖加密、解密、脱敏三个场景 |
| 集成测试隔离 | 每个集成测试在事务中运行，结束后回滚，不污染测试数据库 |
