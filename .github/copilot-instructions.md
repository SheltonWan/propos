# Workspace Instructions

> **重要**：实现任何 API 端点或调用时，必须先阅读权威文档：
> - 字段级契约：[`docs/backend/API_CONTRACT_v1.7.md`](../../docs/backend/API_CONTRACT_v1.7.md)
> - 端点清单与权限：[`docs/backend/API_INVENTORY_v1.7.md`](../../docs/backend/API_INVENTORY_v1.7.md)
> - 错误码注册表：[`docs/backend/ERROR_CODE_REGISTRY.md`](../../docs/backend/ERROR_CODE_REGISTRY.md)

## PropOS 项目上下文

### 项目概述
PropOS（Property Operating System）是一套自有混合型物业的内部数字化资产运营管理平台。
管理约 40,000 m²、639 套房源，覆盖写字楼/商铺/公寓三业态。

### 技术栈
- **后端**: Dart + Shelf（HTTP 中间件管道模式，遵循 Repository + Service 分层架构）
- **移动端（Flutter App）**: Flutter（Dart），覆盖 iOS / Android / HarmonyOS Next 三平台，状态管理使用 `flutter_bloc`（BLoC/Cubit + freezed 四态），路由使用 `go_router`，HTTP 使用 `dio`，依赖注入使用 `get_it`
- **Web 后台（PC Admin）**: Vue 3 + TypeScript + Vite + Element Plus，独立 `admin/` 目录，HTTP 使用 `axios`
- **移动端（uni-app）**: uni-app（Vue 3 + TypeScript），覆盖小程序 / HarmonyOS / H5 三平台，状态管理使用 `pinia`，HTTP 使用 `luch-request`，UI 组件使用 `wot-design-uni`，独立 `app/` 目录
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
6. Flutter / Admin / uni-app 前端严格遵循单向数据流：
   - **Flutter**：`Repository(实现) → BLoC/Cubit → Page/Widget`；Widget 不直接调用 ApiClient
   - **Admin**：`api/client → store → page/component`；不直接写 `fetch`/`axios`
   - **uni-app**：`api/modules → store → page/component`；不直接调用 `luch-request` 实例
   - 禁止在 Widget/Component 内硬编码 API 路径，统一使用常量文件（Flutter: `api_paths.dart`，Admin/uni-app: `api_paths.ts`）

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
| 前端 | Flutter: `core/constants/ui_constants.dart` 中定义 `defaultPageSize = 20`；Admin: `src/constants/ui_constants.ts` 中定义 `DEFAULT_PAGE_SIZE = 20` |

**错误处理模式**：
- 后端：抛出 `AppException(code, message, statusCode)`，由全局 `error_handler.dart` 统一转为 HTTP 响应，**禁止在 Controller/Service 中直接返回 `Response`**
- Flutter BLoC/Cubit：`try/catch` 捕获异常后 `emit(XxxState.error(e is ApiException ? e.message : '操作失败'))`，不透传原始异常对象
- Flutter ApiClient：`DioException` 统一包装为 `ApiException(code, message, statusCode)`，不透传原始 `DioException`
- Admin Store：`try/catch` 捕获异常后 `error.value = e instanceof ApiError ? e.message : '...'`，不透传原始 `AxiosError`
- uni-app Store：同 Admin 模式，`error.value = e instanceof ApiError ? e.message : '操作失败，请重试'`，不透传原始 `luch-request` 错误

**日期时间约定**：
- 数据库存储：统一 `TIMESTAMPTZ`（UTC）
- API 传输：ISO 8601 字符串（`2026-04-05T08:00:00Z`）
- Flutter 展示：使用 `intl` 包 `DateFormat('yyyy-MM-dd').format(dateTime.toLocal())` 转为本地时区显示
- Admin / uni-app 展示：使用 `dayjs(value).format('YYYY-MM-DD')` 转为本地时区显示
- **业务计算（WALE、逾期天数）在后端完成**，前端不做业务日期计算

### 代码规范
- **注释语言**：所有代码注释统一使用中文编写，包括但不限于：文档注释（`///`、`/** */`、`//!`）、行内注释（`//`）、TODO/FIXME 标记。变量名、函数名、类名等标识符仍使用英文命名
- 后端 Dart：遵循 Effective Dart，使用 `freezed` 生成不可变数据类
- Flutter Dart：`analysis_options.yaml` 开启 `strict-casts`/`strict-raw-types`/`strict-inference`；实体/DTO 使用 `@freezed`
- Admin TypeScript：严格模式 `strict: true`，接口定义放 `src/types/`，组件 `<script setup lang="ts">`
- 命名：`camelCase`（变量/函数）/ `PascalCase`（类型/组件/Widget）/ `snake_case`（数据库列名、Dart 文件名）
- 测试：后端核心计算逻辑（WALE、NOI、KPI 打分）必须有单元测试；Flutter BLoC/Cubit 必须有 `bloc_test` 单元测试
- 安全：租客证件号字段必须标注加密存储注释，API 响应默认脱敏

**常量管理规则**（禁止在业务代码中硬编码任何魔法数字或字符串）：

| 类型 | Flutter 归属文件 | Admin 归属文件 | uni-app 归属文件 | 示例 |
|------|-----------------|---------------|-----------------|------|
| 业务规则常量 | `flutter_app/lib/core/constants/business_rules.dart` | `admin/src/constants/business_rules.ts` | `app/src/constants/business_rules.ts` | 预警天数 90/60/30、逾期节点 1/7/15 天、KPI 满分阈值 95% |
| UI 展示常量 | `flutter_app/lib/core/constants/ui_constants.dart` | `admin/src/constants/ui_constants.ts` | `app/src/constants/ui_constants.ts` | 分页大小、动画时长 |
| API 路径常量 | `flutter_app/lib/core/constants/api_paths.dart` | `admin/src/constants/api_paths.ts` | `app/src/constants/api_paths.ts` | `/api/contracts`、`/api/invoices` |
| 后端运行时配置 | — | — | — | `backend/lib/config/app_config.dart`（从环境变量读取）：JWT 密钥、DB 连接串、加密算法标识 |

> 后端运行时配置**不得**写成 Dart `const`，必须通过 `Platform.environment` 或 `.env` 文件注入，缺失时启动失败并输出明确错误。

**后端模块目录结构**（每个 `lib/modules/<name>/` 下）：
```
models/ repositories/ services/ controllers/
```

**Flutter 端目录结构**（`flutter_app/lib/` 下）：
```
core/
  api/
    api_client.dart       # dio 封装，apiGet/apiPost/apiPatch/apiDelete
    api_paths.dart        # API 路径常量
    api_exception.dart    # ApiException(code, message, statusCode)
  constants/              # business_rules.dart / ui_constants.dart
  theme/
    app_theme.dart        # Material 3 ColorScheme + Typography + cupertinoOverrideTheme
  router/
    app_router.dart       # go_router 路由表 + 守卫
    route_paths.dart      # 路由路径常量
  di/
    injection.dart        # get_it 依赖注入注册
features/
  <module>/
    domain/
      entities/           # 纯 Dart 实体类（@freezed，无 Flutter SDK）
      repositories/       # 抽象接口（abstract class）
      usecases/           # 单一职责用例类
    data/
      models/             # freezed DTO + json_serializable
      repositories/       # Repository 实现，调用 ApiClient
    presentation/
      bloc/               # BLoC/Cubit + freezed 四态 State
      pages/              # Page Widget（≤ 150 行）
      widgets/            # 子 Widget（≤ 100 行）
shared/
  widgets/                # 全局共享 Widget
    cupertino_text_form_field.dart  # iOS 风格表单输入框（FormField<String> 封装，支持 validator）
  utils/                  # 工具函数
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

**app/ 端目录结构**（`app/src/` 下，uni-app）：
```
api/
  client.ts        # luch-request 封装，apiGet/apiGetList/apiPost/apiPatch/apiDelete
  index.ts         # 桶导出
  modules/         # 按领域拆分的 API 函数
  mock/            # Mock 拦截层（VITE_USE_MOCK=true 时生效）
constants/
  api_paths.ts     # API 路径常量
  business_rules.ts
  ui_constants.ts
  theme.ts         # 主题 token（唯一允许定义颜色的文件）
stores/            # Pinia stores（setup 风格）
pages/             # 页面，在 pages.json 注册
  auth/ dashboard/ assets/ contracts/ finance/ workorders/ profile/
components/        # 共享组件
composables/       # 组合式函数
types/             # TypeScript 接口定义
static/
  icons/           # 自制 SVG 图标
  tabbar/          # TabBar PNG 图标
styles/
  tokens.scss      # CSS 变量定义（唯一允许定义颜色变量的文件）
  mixins.scss
```

Flutter 前端分层规则：
- **UI 组件体系**：使用 **苹果 Cupertino 设计语言**（`package:flutter/cupertino.dart`），以下 Material 组件已替换为 Cupertino 等价物：
  - `NavigationBar` → `CupertinoTabBar`（置于 `Scaffold.bottomNavigationBar`）
  - `AppBar` → `CupertinoNavigationBar`（实现 `PreferredSizeWidget`，置于 `Scaffold.appBar`）
  - `FilledButton` → `CupertinoButton.filled`
  - `TextButton` → `CupertinoButton`
  - `TextFormField` → `CupertinoTextFormField`（`shared/widgets/` 封装）
  - `Checkbox` → `CupertinoCheckbox`
  - `CircularProgressIndicator` → `CupertinoActivityIndicator`
  - `AlertDialog` → `showCupertinoDialog` + `CupertinoAlertDialog`
  - `PopupMenuButton` → `showCupertinoModalPopup` + `CupertinoActionSheet`
  - `Card` → `Container` + `BoxDecoration`（圆角 + 阴影）
  - `Icons.xxx` → `CupertinoIcons.xxx`
- `MaterialApp.router` 保留（`go_router` 和 BLoC 覆盖层兼容性要求），`ThemeData.cupertinoOverrideTheme` 注入 Cupertino 主色
- 非 Tab 页面路由使用 `CupertinoPage`（`pageBuilder:` 参数），提供 iOS 右滑返回动画
- BLoC/Cubit 状态必须为 `@freezed` sealed union 四态：initial / loading / loaded / error
- BLoC 通过构造函数注入 domain 层 Repository 接口，禁止直接实例化
- 错误处理统一：`catch (e) { emit(XxxState.error(e is ApiException ? e.message : '操作失败，请重试')); }`
- Page/Widget 不含 HTTP 调用，只通过 `BlocBuilder`/`BlocListener` 获取状态并渲染
- 状态渲染必须使用 `.when()` 或 Dart 3 `switch` pattern matching，禁止散落 `if (state is Xxx)`
- 日期显示统一用 `DateFormat('yyyy-MM-dd').format(dt.toLocal())`，不直接操作 DateTime

Admin 前端分层规则：
- Store 使用 `defineStore(id, setup)` setup 风格；state = `ref`，getters = `computed`，actions = async 函数
- Store state 固定字段：`list / item / loading / error / meta`（meta 含分页信息）
- 错误处理统一：`catch (e) { error.value = e instanceof ApiError ? e.message : '操作失败，请重试' }`
- Page/Component 不含 HTTP 调用，只访问 store；禁止在 `<template>` 里写业务逻辑
- 日期显示统一用 `dayjs(value).format('YYYY-MM-DD')`，不直接操作 Date

uni-app 前端分层规则：
- 与 Admin 共享相同的 Pinia setup 风格和 Store state 固定字段
- 路由导航使用 `uni.navigateTo` / `uni.redirectTo` / `uni.switchTab`，禁用 Vue Router
- 路由守卫通过 `uni.addInterceptor` 在 `App.vue` 中全局注册
- 平台差异必须用 uni-app 条件编译指令（`// #ifdef APP-HARMONY` 等）隔离，禁止 `navigator.userAgent` 判断
- 颜色只通过 CSS 变量使用（`var(--color-primary)` 等），禁止内联 `style` 硬编码颜色；`pnpm lint:theme` 在提交前强制校验
- 详细规范见 `.github/instructions/uniapp.instructions.md`（`applyTo: app/src/**`）

**UI 色彩规范**：
- Flutter：优先使用 `CupertinoTheme.of(context).primaryColor` 获取主色；渐变/错误等通过 `Theme.of(context).colorScheme.*` 获取；禁止 `Colors.green` / `Color(0xFF...)` 硬编码；语义色通过 `ThemeExtension<CustomColors>` 扩展
- admin（Element Plus）：状态 Tag 使用 `type="success" / "warning" / "danger" / "info"`
- 状态色语义映射（严格遵守）：

| 状态 | Flutter token | Admin tag type | 含义 |
|------|--------------|----------------|------|
| `leased` / `paid` | `colorScheme.primary` / extension `success` | `success` | 已租 / 已核销 |
| `expiring_soon` / `warning` | `colorScheme.tertiary` / extension `warning` | `warning` | 即将到期 / 预警 |
| `vacant` / `overdue` / `error` | `colorScheme.error` | `danger` | 空置 / 逾期 / 错误 |
| `non_leasable` | `colorScheme.outline` | `info` | 非可租区域 |

**文件复杂度超限时的拆分策略**（生成代码时主动应用，不得机械截断）：

| 文件类型 | 超限信号 | 拆分策略 |
|---------|---------|---------|
| `*_cubit.dart` / `*_bloc.dart` > 200 行（Flutter） | 方法超过 6 个，或 State 超过 5 个变体 | 按子领域拆分 Cubit |
| `*_page.dart` > 150 行（Flutter） | Widget 树嵌套超过 4 层 | 将子区域提取到 `widgets/` 下独立组件 |
| `*_widget.dart` > 100 行（Flutter） | 单个 build 方法超过 60 行 | 继续拆分为更小的组合 Widget |
| `*Store.ts` > 200 行（Admin） | action 超过 8 个，或 state 字段超过 10 个 | 按子领域拆分 store |
| `*View.vue` > 250 行（Admin） | `<template>` 嵌套超过 4 层或含复杂逻辑 | 将子区域提取到 `components/` 下独立组件 |
| `*Store.ts` > 200 行（uni-app） | 同 Admin 规则 | 按子领域拆分 store |
| `*.vue` > 250 行（uni-app） | `<template>` 嵌套超过 4 层或含复杂逻辑 | 将子区域提取到 `components/` 下独立组件 |
| `*_repository.dart` > 300 行（后端） | 查询方法超过 10 个 | 提取 `*_query_builder.dart` 封装复杂 SQL 片段 |
| `*_service.dart` > 250 行（后端） | 方法超过 8 个，或含多个不同业务方向 | 按子领域拆分 Service |
| `*_controller.dart` > 150 行（后端） | 路由 handler 超过 6 个 | 按资源拆分 Controller 文件 |
| package 内计算文件 | 不以行数判断 | 以「一个公共函数/类一个文件」为单位拆分 |

### Phase 1 模块边界
| 模块 | 状态 |
|------|------|
| M1 资产与空间可视化 | 含 CAD(.dwg→SVG/PNG) 转换 + 楼层热区状态色块 |
| M2 租务与合同管理 | 含状态机、WALE、租金递增规则配置器 |
| M3 财务与 NOI | 含自动账单生成、NOI 实时看板、KPI 正式考核仪表盘（含排名/申诉/导出） |
| M4 工单系统 | 含 Flutter 移动端 |
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
| frontend（Flutter / admin 前端） | `docs/frontend/<name>.md` | `pdfdocs/frontend/<name>.pdf` |
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
