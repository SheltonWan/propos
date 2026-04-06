# Workspace Instructions

## PropOS 项目上下文

### 项目概述
PropOS（Property Operating System）是一套自有混合型物业的内部数字化资产运营管理平台。
管理约 40,000 m²、639 套房源，覆盖写字楼/商铺/公寓三业态。

### 技术栈
- **后端**: Dart + Shelf（HTTP 中间件管道模式，遵循 Repository + Service 分层架构）
- **移动端**: Flutter 3.x，路由使用 `go_router`（iOS/Android/macOS/Windows/Web 五端复用）
- **Web 后台**: Flutter Web（PC 优先响应式设计）
- **微信小程序**: 精简版（仅扫码报修 + 状态查看）
- **数据库**: PostgreSQL 15+；访问层使用 `postgres` 包写原生 SQL，**不引入任何 ORM**
- **文档**: Markdown → PDF（通过 scripts/md_to_pdf.sh）

### 架构约束
1. 所有 API 端点必须经过 RBAC 中间件验证角色权限
2. 二房东相关数据查询必须在 Repository 层加行级数据隔离过滤
3. 证件号、手机号字段在数据库层加密存储，API 层默认脱敏（仅显示后4位）
4. 操作审计日志覆盖：合同变更、账单核销、权限变更、二房东数据提交
5. 核心计算逻辑必须抽离为独立本地 package（零外部依赖），不得内联在 Service 层：
   - `packages/rent_escalation_engine`：租金递增计算（6种类型 + 混合分段）
   - `packages/kpi_scorer`：KPI 线性插值打分
   - 上述两个 package 通过 `path` 依赖引用，不发布到 pub.dev
6. Flutter App 严格遵循 `domain → data → presentation` 三层依赖方向，禁止反向依赖：
   - `presentation/bloc/` 只依赖 `domain/` 接口，不直接 import `data/` 实现
   - `domain/` 层不含任何 Flutter SDK 依赖（纯 Dart，可在 Dart VM 中测试）
   - `rent_escalation_engine` / `kpi_scorer` 两个后端 package Flutter 端可同路径复用，用于客户端离线预览计算

### 核心领域模型

三业态枚举：
- `PropertyType`: `office`（写字楼）/ `retail`（商铺）/ `apartment`（公寓）

关键实体层级：
```
Department（组织架构层，三级组织树）
Building → Floor → Unit（资产层）
Tenant → Contract → Invoice（租务财务层）
Contract → SubLease（二房东穿透层）
WorkOrder（工单层）
KpiScheme → KpiScore → KpiAppeal（KPI 考核层）
```

核心计算公式：
- NOI = EGI - OpEx；EGI = PGI - VacancyLoss + OtherIncome
- WALE = Σ(剩余租期ᵢ × 年化租金ᵢ) / Σ(年化租金ᵢ)
- KPI总分 = Σ(指标得分ᵢ × 权重ᵢ)

### API 协议约定

**响应信封格式**（后端所有接口统一，不得自行发明结构）：

```json
// 成功
{ "data": <payload>, "meta": { "page": 1, "pageSize": 20, "total": 639 } }
// 失败
{ "error": { "code": "CONTRACT_NOT_FOUND", "message": "合同不存在" } }
```

- `data` 为单对象或数组；分页列表必须附带 `meta`（无分页可省略 `meta`）
- 错误 `code` 使用 `SCREAMING_SNAKE_CASE`，Flutter 端按 `code` 做业务判断，不解析 `message`

**分页约定**：

| 参数/字段 | 规则 |
|---------|------|
| 请求参数 | `page`（从 1 开始）+ `pageSize`（默认 20，最大 100） |
| 响应字段 | `meta.page` / `meta.pageSize` / `meta.total`（总条数） |
| Flutter 端 | `ui_constants.dart` 中定义 `kDefaultPageSize = 20` |

**错误处理模式**：
- 后端：抛出 `AppException(code, message, statusCode)`，由全局 `error_handler.dart` 统一转为 HTTP 响应，**禁止在 Controller/Service 中直接返回 `Response`**
- Flutter BLoC：`try/catch` 捕获异常后 `emit(State.error(e.message))`，**不使用 `Either<Failure, T>`**（项目规模不需要）
- Flutter Repository：网络异常统一包装为 `ApiException`，不透传原始 `DioException`

**日期时间约定**：
- 数据库存储：统一 `TIMESTAMPTZ`（UTC）
- API 传输：ISO 8601 字符串（`2026-04-05T08:00:00Z`）
- Flutter 展示：在 Widget 层转换为本地时区显示，**业务计算（WALE、逾期天数）始终用 UTC**，不依赖 `DateTime.now()`，通过注入 `Clock` 接口便于测试

### 代码规范
- Dart：遵循 Effective Dart，使用 `freezed` 生成不可变数据类
- 命名：`camelCase`（变量/函数）/ `PascalCase`（类型）/ `snake_case`（数据库列名）
- 测试：核心计算逻辑（WALE、NOI、KPI 打分）必须有单元测试
- 安全：租客证件号字段必须标注加密存储注释，API 响应默认脱敏

**常量管理规则**（禁止在业务代码中硬编码任何魔法数字或字符串）：

| 类型 | 归属文件 | 示例 |
|------|---------|------|
| 业务规则常量 | `lib/shared/constants/business_rules.dart`（Flutter）<br>`lib/shared/constants/business_rules.dart`（后端） | 预警天数 90/60/30、逾期节点 1/7/15 天、KPI 满分阈值 95% |
| UI 展示常量 | `lib/shared/constants/ui_constants.dart` | 分页大小、卡片最大宽度、动画时长 |
| API 路径常量 | `lib/shared/constants/api_paths.dart`（Flutter 端） | `/api/contracts`、`/api/invoices` |
| 后端运行时配置 | `backend/lib/config/app_config.dart`（从环境变量读取） | JWT 密钥、DB 连接串、加密算法标识 |

> 后端运行时配置**不得**写成 Dart `const`，必须通过 `Platform.environment` 或 `.env` 文件注入，缺失时启动失败并输出明确错误。

**后端模块目录结构**（每个 `lib/modules/<name>/` 下）：
```
models/ repositories/ services/ controllers/
```

**Flutter 端模块目录结构**（`lib/features/<name>/` 下，BLoC 三层架构）：
```
domain/          # 纯 Dart：Repository 抽象接口 + UseCase + freezed 数据类
data/            # Repository 实现（调用后端 REST API），依赖 domain 接口
presentation/
  bloc/          # BLoC/Cubit（Event → State），只依赖 domain 接口，不 import flutter/material.dart
  pages/         # 页面 Widget，只持有 BlocBuilder/BlocListener，无业务逻辑
  widgets/       # 模块私有 Widget 组件
```

Flutter 分层规则：
- `State` 使用 `freezed` sealed union（`initial / loading / loaded / error`），Widget 中用 `.when()` 分支渲染，禁止散落 `if (state is Xxx)` 判断
- BLoC 通过构造函数注入 Repository **接口**，不直接实例化 Repository 实现（便于 `mocktail` mock 测试）
- Widget 不含 HTTP 调用、日期计算、业务判断，只做状态到 UI 的映射
- `get_it` 作为 DI 容器，在 `main.dart` 统一注册所有依赖
- 单元测试使用 `bloc_test` + `mocktail`；Widget 测试通过 `BlocProvider` 注入 Fake BLoC

**UI 主题规范**：
- 所有 Theme 定义集中在 `lib/shared/theme/app_theme.dart`，Widget 内禁止硬编码颜色、字号、间距，统一通过 `Theme.of(context)` 取值
- 使用 Material 3（`useMaterial3: true`），禁止覆盖为 Material 2 风格
- 状态色语义映射（生成 UI 时严格遵守，不得用其他颜色替代）：

| 状态 | Token | 含义 |
|------|-------|------|
| `leased` / `paid` | `colorScheme.secondary`（绿色系） | 已租 / 已核销 |
| `expiring_soon` / `warning` | `colorScheme.tertiary`（黄/橙色系） | 即将到期 / 预警 |
| `vacant` / `overdue` / `error` | `colorScheme.error`（红色系） | 空置 / 逾期 / 错误 |
| `non_leasable` | `colorScheme.outlineVariant`（中性灰） | 非可租区域 |

**文件复杂度超限时的拆分策略**（生成代码时主动应用，不得机械截断）：

| 文件类型 | 超限信号 | 拆分策略 |
|---------|---------|---------|
| `*_bloc.dart` > 200 行 | `on<>` 处理方法超过 5 个，或单个方法超 30 行 | 按职责拆出独立 Cubit（如 `ContractFormCubit` 处理表单，`ContractListBloc` 处理列表） |
| `*_repository.dart` > 300 行（后端） | 查询方法超过 10 个 | 提取 `*_query_builder.dart` 封装复杂 SQL 片段，Repository 只组装调用 |
| `*_page.dart` > 150 行 | `build()` 嵌套超过 4 层 | 将子区域提取到 `widgets/` 下的私有组件，页面只保留顶层组合 |
| `*_service.dart` > 250 行（后端） | 方法超过 8 个，或含多个不同业务方向 | 按子领域拆分 Service（如 `WaleService` 独立于 `ContractService`） |
| `*_controller.dart` > 150 行（后端） | 路由 handler 超过 6 个 | 按资源拆分 Controller 文件，统一在 `router/` 挂载 |
| package 内计算文件 | 不以行数判断 | 以「一个公共函数/类一个文件」为单位拆分，保持 package API surface 清晰 |

### Phase 1 模块边界
| 模块 | 状态 |
|------|------|
| M1 资产与空间可视化 | 含 CAD(.dwg→SVG/PNG) 转换 + 楼层热区状态色块 |
| M2 租务与合同管理 | 含状态机、WALE、租金递增规则配置器 |
| M3 财务与 NOI | 含自动账单生成、NOI 实时看板、KPI 正式考核仪表盘（含排名/申诉/导出） |
| M4 工单系统 | 含 Flutter App 移动端 + 精简小程序 |
| M5 二房东穿透管理 | 含主从两级租赁、外部填报 Web 页、审核流 |

Phase 2 功能（租户门户、门禁、电子签章等）**不在当前开发范围内**，生成代码时不要超前实现。

### 文件存储约定

| 文件类型 | 存储路径规则 | 示例 |
|---------|------------|------|
| CAD 转换 SVG | `floors/{building_id}/{floor_id}.svg` | `floors/uuid1/uuid2.svg` |
| 楼层 PNG 备用 | `floors/{building_id}/{floor_id}.png` | |
| 合同 PDF | `contracts/{contract_id}/{filename}` | `contracts/uuid/signed.pdf` |
| 工单照片 | `workorders/{work_order_id}/{index}.jpg` | `workorders/uuid/0.jpg` |
| 改造照片 | `renovations/{record_id}/{index}.jpg` | |

- 路径中均用 UUID，不含业务编号（防止编号变更导致路径失效）
- Flutter 端通过 `GET /api/files/{path}` 代理访问，不直接暴露存储地址

### 后端启动环境变量

以下变量缺失时服务**必须拒绝启动**并输出明确错误（在 `app_config.dart` 中 `assert` 或 `throw`）：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `DATABASE_URL` | PostgreSQL 连接串 | `postgres://user:pwd@host:5432/propos` |
| `JWT_SECRET` | JWT 签名密钥（≥32位） | `random-secret-key` |
| `JWT_EXPIRES_IN_HOURS` | Token 有效期（小时） | `24` |
| `FILE_STORAGE_PATH` | 本地文件存储根目录 | `/data/uploads` |
| `ENCRYPTION_KEY` | AES-256 密钥（证件号加密） | `32-byte-hex-string` |
| `APP_PORT` | HTTP 监听端口 | `8080` |

可选变量（缺失时使用默认值，不阻断启动）：`CORS_ORIGINS`、`LOG_LEVEL`、`MAX_UPLOAD_SIZE_MB`

---

## Markdown 文档生成工作流

每当你（Copilot）生成 Markdown 文档，必须严格按以下流程执行，不得跳过：

### 步骤

1. **按模块保存 Markdown**：根据下方模块映射表，将 `.md` 文件写入对应子目录
2. **执行转换流水线**（在 workspace 根目录执行）：
   ```bash
   bash scripts/md_to_pdf.sh docs/<module>/<name>.md
   ```
   该脚本自动完成：`md → docx（中间文件）→ pdf`，并删除 `.docx`
3. **确认**：验证 `pdfdocs/<module>/<name>.pdf` 已生成，再向用户报告完成

### 模块 → 子目录映射

| 涉及模块 | Markdown 路径 | PDF 输出路径 |
|---------|--------------|-------------|
| backend（Dart 服务端） | `docs/backend/<name>.md` | `pdfdocs/backend/<name>.pdf` |
| frontend（Flutter 客户端） | `docs/frontend/<name>.md` | `pdfdocs/frontend/<name>.pdf` |
| 跨模块 / 通用 | `docs/<name>.md` | `pdfdocs/<name>.pdf` |

### 路径规范

| 类型 | 目录 |
|------|------|
| Markdown 源文件 | `docs/<module>/` 或 `docs/` |
| 中间 Word 文件 | 与 md 同目录（脚本自动删除） |
| 最终 PDF 输出 | `pdfdocs/<module>/`（自动镜像 docs 子目录结构） |

### 注意

- 不要手动调用 `md2word.py` 或 `docx2pdf.py`，统一使用 `scripts/md_to_pdf.sh`
- 如果 `pdfdocs/` 目录不存在，脚本会自动创建
- 批量生成时支持 `bash scripts/md_to_pdf.sh docs/<module>/*.md`
