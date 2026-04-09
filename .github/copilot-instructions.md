# Workspace Instructions

## PropOS 项目上下文

### 项目概述
PropOS（Property Operating System）是一套自有混合型物业的内部数字化资产运营管理平台。
管理约 40,000 m²、639 套房源，覆盖写字楼/商铺/公寓三业态。

### 技术栈
- **后端**: Dart + Shelf（HTTP 中间件管道模式，遵循 Repository + Service 分层架构）
- **移动端 / 小程序**: uni-app 4.x（Vue 3 + TypeScript + Vite），一套代码覆盖 iOS / Android / HarmonyOS Next / 微信小程序 / H5，UI 库使用 `wot-design-uni`，HTTP 使用 `luch-request`，状态管理使用 `pinia`
- **Web 后台（PC Admin）**: Vue 3 + TypeScript + Vite + Element Plus，独立 `admin/` 目录，HTTP 使用 `axios`
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
   - 上述两个 package 通过 `path` 依赖引用，不发布到 pub.dev；**所有计算通过后端 API 调用，前端不直接引用**
6. uni-app / admin 前端严格遵循 `api → store → page/component` 单向数据流：
   - `store` 通过 `api/client` 调用后端，不直接写 `fetch`/`axios`
   - `page/component` 只使用 store 的 state/action，不内联 HTTP 请求
   - 禁止在 component 内硬编码 API 路径，统一使用 `@/constants/api_paths`

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
- 错误 `code` 使用 `SCREAMING_SNAKE_CASE`，前端按 `code` 做业务判断，不解析 `message`

**分页约定**：

| 参数/字段 | 规则 |
|---------|------|
| 请求参数 | `page`（从 1 开始）+ `pageSize`（默认 20，最大 100） |
| 响应字段 | `meta.page` / `meta.pageSize` / `meta.total`（总条数） |
| 前端 | `src/constants/ui_constants.ts` 中定义 `DEFAULT_PAGE_SIZE = 20` |

**错误处理模式**：
- 后端：抛出 `AppException(code, message, statusCode)`，由全局 `error_handler.dart` 统一转为 HTTP 响应，**禁止在 Controller/Service 中直接返回 `Response`**
- uni-app / admin Store：`try/catch` 捕获异常后 `error.value = e instanceof ApiError ? e.message : '...'`，不透传原始错误对象
- api/client：网络异常统一包装为 `ApiError(code, message, statusCode)`，不透传原始 `luch-request` / `AxiosError`

**日期时间约定**：
- 数据库存储：统一 `TIMESTAMPTZ`（UTC）
- API 传输：ISO 8601 字符串（`2026-04-05T08:00:00Z`）
- 前端展示：使用 `dayjs` 在组件层转换为本地时区显示，**业务计算（WALE、逾期天数）在后端完成**，前端不做业务日期计算

### 代码规范
- 后端 Dart：遵循 Effective Dart，使用 `freezed` 生成不可变数据类
- 前端 TypeScript：严格模式 `strict: true`，接口定义放 `src/types/`，组件 `<script setup lang="ts">`
- 命名：`camelCase`（变量/函数）/ `PascalCase`（类型/组件）/ `snake_case`（数据库列名）/ `SCREAMING_SNAKE_CASE`（前端常量）
- 测试：后端核心计算逻辑（WALE、NOI、KPI 打分）必须有单元测试
- 安全：租客证件号字段必须标注加密存储注释，API 响应默认脱敏

**常量管理规则**（禁止在业务代码中硬编码任何魔法数字或字符串）：

| 类型 | 归属文件 | 示例 |
|------|---------|------|
| 业务规则常量 | `src/constants/business_rules.ts`（app/ 与 admin/ 各自维护） | 预警天数 90/60/30、逾期节点 1/7/15 天、KPI 满分阈值 95% |
| UI 展示常量 | `src/constants/ui_constants.ts` | 分页大小、卡片最大宽度、动画时长 |
| API 路径常量 | `src/constants/api_paths.ts`（app/ 与 admin/ 各自维护） | `/api/contracts`、`/api/invoices` |
| 后端运行时配置 | `backend/lib/config/app_config.dart`（从环境变量读取） | JWT 密钥、DB 连接串、加密算法标识 |

> 后端运行时配置**不得**写成 Dart `const`，必须通过 `Platform.environment` 或 `.env` 文件注入，缺失时启动失败并输出明确错误。

**后端模块目录结构**（每个 `lib/modules/<name>/` 下）：
```
models/ repositories/ services/ controllers/
```

**uni-app 端目录结构**（`app/src/` 下）：
```
api/
  client.ts        # luch-request 封装，apiGet/apiPost/apiPatch/apiDelete
  modules/         # 按业务模块拆分的 API 函数
  index.ts         # 桶导出
constants/         # api_paths.ts / business_rules.ts / ui_constants.ts
stores/            # Pinia stores，defineStore setup 风格
types/             # TypeScript 接口定义（api.ts 含信封类型）
composables/       # 可复用的 Composition API 函数
pages/             # 按 pages.json 结构组织页面
components/        # 全局共享组件
```

**admin/ 端目录结构**（`admin/src/` 下）：
```
api/
  client.ts        # axios 封装，含 refresh subscriber queue
  modules/
constants/         # 同 app/ 命名规范
stores/            # Pinia stores
router/            # Vue Router 4，含 beforeEach 守卫
views/
  layout/          # AppLayout（侧边栏 + 顶部栏）
  auth/            # LoginView
  dashboard/ assets/ contracts/ finance/ workorders/ subleases/
components/
types/
```

前端分层规则：
- Store 使用 `defineStore(id, setup)` setup 风格；state = `ref`，getters = `computed`，actions = async 函数
- Store state 固定字段：`list / item / loading / error / meta`（meta 含分页信息）
- 错误处理统一：`catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }`
- Page/Component 不含 HTTP 调用，只访问 store；禁止在 `<template>` 里写业务逻辑
- 日期显示统一用 `dayjs(value).format('YYYY-MM-DD')`，不直接操作 Date

**UI 色彩规范**：
- uni-app（wot-design-uni）：使用 CSS 变量 `--color-success / --color-warning / --color-danger / --color-neutral`，禁止内联 `style="color: green"`
- admin（Element Plus）：状态 Tag 使用 `type="success" / "warning" / "danger" / "info"`
- 状态色语义映射（严格遵守）：

| 状态 | 语义色 | 含义 |
|------|-------|------|
| `leased` / `paid` | success（绿色系） | 已租 / 已核销 |
| `expiring_soon` / `warning` | warning（黄/橙色系） | 即将到期 / 预警 |
| `vacant` / `overdue` / `error` | danger（红色系） | 空置 / 逾期 / 错误 |
| `non_leasable` | info（中性灰） | 非可租区域 |

**文件复杂度超限时的拆分策略**（生成代码时主动应用，不得机械截断）：

| 文件类型 | 超限信号 | 拆分策略 |
|---------|---------|---------|
| `*Store.ts` > 200 行 | action 超过 8 个，或 state 字段超过 10 个 | 按子领域拆分 store（如 `useContractListStore` + `useContractFormStore`） |
| `*View.vue` > 250 行 | `<template>` 嵌套超过 4 层或含复杂逻辑 | 将子区域提取到 `components/` 下独立组件，页面只保留顶层组合 |
| `*_repository.dart` > 300 行（后端） | 查询方法超过 10 个 | 提取 `*_query_builder.dart` 封装复杂 SQL 片段，Repository 只组装调用 |
| `*_service.dart` > 250 行（后端） | 方法超过 8 个，或含多个不同业务方向 | 按子领域拆分 Service（如 `WaleService` 独立于 `ContractService`） |
| `*_controller.dart` > 150 行（后端） | 路由 handler 超过 6 个 | 按资源拆分 Controller 文件，统一在 `router/` 挂载 |
| package 内计算文件 | 不以行数判断 | 以「一个公共函数/类一个文件」为单位拆分，保持 package API surface 清晰 |

### Phase 1 模块边界
| 模块 | 状态 |
|------|------|
| M1 资产与空间可视化 | 含 CAD(.dwg→SVG/PNG) 转换 + 楼层热区状态色块 |
| M2 租务与合同管理 | 含状态机、WALE、租金递增规则配置器 |
| M3 财务与 NOI | 含自动账单生成、NOI 实时看板、KPI 正式考核仪表盘（含排名/申诉/导出） |
| M4 工单系统 | 含 uni-app 移动端 + 精简微信小程序 |
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
- 前端通过 `GET /api/files/{path}` 代理访问，不直接暴露存储地址

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
