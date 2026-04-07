# PropOS Phase 1 项目开发日程计划

> **版本**: v1.1
> **制定日期**: 2026-04-05（v1.1 更新日期: 2026-04-06）
> **计划开始日期**: 2026-04-08（周三）
> **计划上线日期**: 2026-08-21（周五）
> **开发模式**: 独立开发（一人全栈）
> **每日投入**: 8 小时
> **总工期**: 20 周 / 98 个工作日
> **依据文档**: PRD v1.7 / ARCH v1.2 / data_model v1.2

---

## 总体排期概览

| 阶段 | 周次 | 日历区间 | 核心交付 | 工作日 |
|------|------|---------|---------|--------|
| Phase 0：基础搭建 | W1–W2 | 4/8–4/17 | 核心 Package + 后端框架 + Auth | 8 天 |
| Phase 1：M1 资产 | W3–W5 | 4/20–5/8 | 资产台账 + CAD 导入 + SVG 热区图 | 15 天 |
| Phase 2：M2 合同 | W6–W9 | 5/11–6/5 | 合同生命周期 + 递增规则 + WALE | 20 天 |
| Phase 3：M4 工单 | W10–W11 | 6/8–6/19 | 工单流转 + 移动端报修 + 推送 | 10 天 |
| Phase 4：M3 财务 | W12–W15 | 6/22–7/17 | 账单 + NOI 看板 + KPI 仪表盘 | 20 天 |
| Phase 5：M5 穿透 | W16–W17 | 7/20–7/31 | 子租赁 + 外部填报门户 + 审核流 | 10 天 |
| Phase 6：集成测试 | W18–W19 | 8/3–8/14 | 模块联动 + 数据初始化 + 回归 | 10 天 |
| Phase 7：UAT 上线 | W20 | 8/17–8/21 | 用户验收 + 正式 Go-live | 5 天 |

**模块开发顺序依据**：
- M1（资产）是数据底座，其他模块均依赖单元/楼层实体
- M2（合同）是业务主轴，M3 账单依赖 M2 递增规则，M5 穿透依赖 M2 主合同
- M4（工单）相对独立，M3 NOI 支出侧依赖 M4 维修成本，故先 M4 再 M3
- M3（财务）依赖 M1/M2/M4 全部数据源（KPI 10 指标跨模块聚合）
- M5（二房东穿透）依赖 M1 单元、M2 主合同，最后实现

---

## 里程碑一览

| 里程碑 | 完成日期 | 核心验证标准 |
|--------|---------|------------|
| M0 基础就绪 | 2026-04-17 | 两个核心 Package 全测试通过；后端启动成功；Flutter 登录页联调跑通 |
| M1 资产上线 | 2026-05-08 | 639 套 Excel 导入正常；楼层 SVG 热区图渲染正确；资产 Dashboard 三业态数据展示 |
| M2 合同上线 | 2026-06-05 | 合同状态机全流程；租金递增 6 种类型 + 混合分段；WALE 误差 < 0.01 年 |
| M4 工单上线 | 2026-06-19 | 移动端报修全链路；FCM 推送验证；成本接口预留 |
| M3 财务上线 | 2026-07-17 | 账单生成 < 30 秒；NOI 三业态拆分正确；KPI 2 套方案打分与手工一致 |
| M5 穿透上线 | 2026-07-31 | 外部门户可独立访问；审核流完整；行级隔离安全验证通过 |
| 集成完成 | 2026-08-14 | 全 PRD 验收项 Pass；50 并发压测达标；实际数据导入完成 |
| **正式上线** | **2026-08-21** | **PropOS Phase 1 全模块生产环境就绪** |

---

## Phase 0：项目基础搭建

> **时间**：2026-04-08（W1）— 2026-04-17（W2），共 8 个工作日

### 第 1 周（4/8 周三 — 4/10 周五）

#### Day 1 · 4月8日（周三）— `rent_escalation_engine` Package 骨架

- 创建 Monorepo 目录结构（`backend/packages/`、`flutter_app/`、`packages/`）
- `rent_escalation_engine/pubspec.yaml`（name: rent_escalation_engine，零外部依赖）
- `EscalationType` 枚举（6 种：fixedRate / fixedAmount / stepped / cpiLinked / everyNYears / postRenovation）
- `RentEscalationPhase` 数据类（阶段起止月份 + 递增参数 sealed union）
- `FixedRateRule` + `FixedAmountRule` 实现 + 单元测试 pass

#### Day 2 · 4月9日（周四）— `rent_escalation_engine` 复杂逻辑 + `kpi_scorer`

- `SteppedRule`（阶梯式分段表）+ `EveryNYearsRule`（每 N 年涨幅）实现
- `CpiLinkedRule`（CPI 年度挂钩）+ `PostRenovationRule`（免租结束后基准价）实现
- 混合分段 `RentCalculator.compute(phases, targetDate) → Money` 聚合逻辑
- `kpi_scorer/` Package：`KpiMetric`（含满分/及格/不及格阈值）+ `KpiScorer.score(metric, actual) → double`（线性插值）

#### Day 3 · 4月10日（周五）— 两个 Package 全覆盖测试

- `rent_escalation_test.dart`：固定比例 / 固定金额 / 阶梯 / 每 N 年 / CPI / 混合分段，每类型 ≥ 3 个用例
- `kpi_scorer_test.dart`：满分边界 / 线性插值中间值 / 零分边界 / 权重汇总 4 类用例
- `dart test` 全绿通过，Package 完工，可供后端和 Flutter 双端 path 依赖引用

### 第 2 周（4/13 周一 — 4/17 周五）

#### Day 4 · 4月13日（周一）— 后端项目初始化

- `backend/pubspec.yaml`（依赖：shelf, shelf_router, postgres, dart_jsonwebtoken, freezed, json_serializable, build_runner, crypto, path）
- `bin/server.dart` 启动入口（Shelf Pipeline 组装、`APP_PORT` 监听）
- `app_config.dart`：从 `Platform.environment` 读取 6 个必填变量，任一缺失时 `throw StateError` 输出明确错误
- `database.dart`：解析 `DATABASE_URL`，初始化 PostgreSQL 连接池

#### Day 5 · 4月14日（周二）— 后端核心中间件

- `app_exception.dart`（`AppException(code, message, statusCode)` 基类）
- `error_handler.dart`（全局 `try/catch` → `{"error":{"code":"...","message":"..."}}` HTTP 响应）
- `request_context.dart`（注入 userId, role, subLandlordScope 到 Request 扩展）
- `auth_middleware.dart`（Bearer Token 解析，JWT 验证，注入 RequestContext）
- `pagination.dart`（解析 page/pageSize，构建分页 meta 响应包装工具）

#### Day 6 · 4月15日（周三）— Auth 模块后端

- `user.dart`（@freezed）+ `users` 表迁移 SQL
- `user_repository.dart`（原生 SQL：findByUsername, findById, create, updateRole）
- `token_service.dart`（JWT 签发：sub + role + subLandlordScope + exp；验证：算法固定 HS256）
- `auth_service.dart`（登录：bcrypt 密码校验，签发 access + refresh token；刷新：验证 refresh token 后重新签发）

#### Day 7 · 4月16日（周四）— RBAC + 审计 + Auth 路由

- `rbac_middleware.dart`（按端点路径 + HTTP 方法配置角色白名单矩阵，权限不足返回 403）
- `audit_middleware.dart`（写 `audit_logs` 表：操作用户、端点、before/after JSON、时间戳）
- `auth_controller.dart`（`POST /api/auth/login`、`POST /api/auth/refresh`）
- `router/` 挂载，`bin/server.dart` 本地启动，curl 验证登录接口

#### Day 8 · 4月17日（周五）— Flutter 项目初始化 + Auth 前端

- `flutter create propos_app --org com.propos`，添加依赖：flutter_bloc, go_router, get_it, freezed, json_serializable, dio, bloc_test, mocktail, flutter_svg, file_picker, image_picker, mobile_scanner
- 骨架目录：`lib/shared/`（theme, constants, platform_utils）+ `lib/features/auth/domain/data/presentation/`
- `app_theme.dart`（Material 3，`useMaterial3: true`，状态色 Token 映射：secondary/tertiary/error/outlineVariant）
- `api_client.dart`（Dio 实例 + JWT Bearer 拦截器 + 401 自动刷新重试）
- `AuthRepository` 抽象接口 + `HttpAuthRepository` 实现 + `LoginBloc`（Event/State @freezed sealed）+ `LoginPage` UI + get_it DI 注册

> **Milestone 0**：`dart test` 两个核心 Package 全绿；`dart run bin/server.dart` 后端启动成功；Flutter 登录页与后端 `POST /api/auth/login` 端到端联调成功。

---

## Phase 1：M1 资产与空间可视化

> **时间**：2026-04-20（W3）— 2026-05-08（W5），共 15 个工作日

### 第 3 周（4/20 — 4/24）· M1 后端 CRUD

#### Day 9 · 4月20日（周一）— M1 API Contract + 路由骨架

- 输出 `docs/api/m1_assets.md`（buildings / floors / units / renovations 全部端点，含请求参数、响应 JSON、枚举表、error code，不转 PDF）
- 后端全部 M1 路由骨架：Controller 空实现，返回固定 mock JSON，服务可运行供前端提前对接结构

#### Day 10 · 4月21日（周二）— Building + Floor 后端

- `building.dart` / `floor.dart`（@freezed）+ 数据迁移 SQL（参照 data_model.md）
- `BuildingRepository`（list, getById, create, update；原生 SQL，LIMIT/OFFSET 分页）
- `FloorRepository`（含 svgPath 字段；`listByBuilding`）
- `BuildingService` + `FloorService`（业务校验层）
- `BuildingController`（`GET /api/buildings`, `GET/PUT /api/buildings/:id`）+ `FloorController`（`GET /api/buildings/:id/floors`）

#### Day 11 · 4月22日（周三）— Unit 后端（三业态差异化字段）

- `unit.dart`（@freezed，含 `propertyTypeDetails` JSONB 字段：OfficeDetails / RetailDetails / ApartmentDetails）
- `UnitRepository`（CRUD + 多条件查询：buildingId / propertyType / status；`getFloorHeatmap` — 返回楼层所有单元坐标 + 状态）
- `UnitService`（当前状态计算：Leased / Vacant / ExpiringSoon≤90天 / NonLeasable；单元不重叠在租校验）

#### Day 12 · 4月23日（周四）— Unit Controller + RenovationRecord

- `UnitController`（`GET /api/units`, `GET/POST/PUT /api/units/:id`, `GET /api/floors/:id/heatmap`）
- `renovation_record.dart`（@freezed）+ `RenovationRepository` + `RenovationService`
- `RenovationController`（`GET /api/units/:id/renovations`, `POST /api/units/:id/renovations`，照片上传）

#### Day 13 · 4月24日（周五）— Excel 批量导入后端

- `unit_import_service.dart`：解析三种 Excel 模板（写字楼 / 商铺 / 公寓字段映射），数据校验（单元号唯一、面积正数、业态枚举合法），批量 INSERT（事务包裹）
- `POST /api/units/import`（multipart/form-data，响应：成功条数 + 失败行列表）
- 本地用 20 条/业态样本数据测试导入正确性

### 第 4 周（4/27 — 5/1）· M1 后端 CAD 导入 + 前端 Domain/Data

#### Day 14 · 4月27日（周一）— CAD 导入后端（难点）

- 安装配置 ODA File Converter（DWG→DXF）+ `ezdxf[draw]`（Python，DXF→SVG），验证两步转换链路可用
- `cad_import_service.dart`：接收 `.dwg` 文件 → `Process.run` 调度 ODA File Converter（DWG→DXF）→ `Process.run` 调度 `ezdxf draw`（DXF→SVG）→ SVG 输出写入 `FILE_STORAGE_PATH/floors/{buildingId}/{floorId}.svg`
- `PUT /api/floors/:id/cad-upload`（multipart 大文件，异步任务，上传完成后返回 SVG 预览 URL）
- `GET /api/files/*`（鉴权后返回本地文件流，不直接暴露存储路径）

#### Day 15 · 4月28日（周二）— M1 前端 Domain 层

- freezed 模型：`Unit`, `Building`, `Floor`, `RenovationRecord`（纯 Dart，无 Flutter SDK 依赖）
- 抽象接口：`UnitRepository`, `BuildingRepository`, `FloorRepository`, `RenovationRepository`
- UseCase：`GetUnitsUseCase`, `GetFloorHeatmapUseCase`, `GetBuildingsUseCase`（注入接口，不直接实例化实现）

#### Day 16 · 4月29日（周三）— M1 前端 Data 层

- `HttpUnitRepository`（Dio 调用 `/api/units`，分页，枚举映射，异常包装为 `ApiException`）
- `HttpBuildingRepository` / `HttpFloorRepository` / `HttpRenovationRepository`
- `MockUnitRepository`（内存数据：写字楼 5 条 / 商铺 5 条 / 公寓 5 条，不同状态）
- `get_it` 注册 M1 dependencies，`--dart-define=USE_MOCK=true` 切换 Mock / 真实实现

#### Day 17 · 4月30日（周四）— M1 BLoC

- `AssetOverviewBloc`（加载三业态汇总：总套数 / 已租套数 / 空置套数 / 出租率）
- `BuildingListCubit` + `UnitListBloc`（Event：filterByPropertyType / filterByStatus / filterByBuilding / changePage）
- State 使用 `@freezed` sealed union（initial / loading / loaded / error），Widget 用 `.when()` 分支渲染
- BLoC 单元测试（`bloc_test` + `mocktail`，覆盖 loading → loaded / error 场景）

#### Day 18 · 5月1日（周五）— M1 UI — 资产概览 Dashboard

- `AssetOverviewPage`：三列卡片（写字楼 / 商铺 / 公寓），每列展示：总套数、已租套数、空置套数、出租率进度条
- `BuildingListPage` + `BuildingCard` Widget（楼栋名称、业态、GFA、出租率快速跳转楼层）
- 颜色严格使用 colorScheme Token：`leased` → secondary（绿），`vacant` → error（红），`expiring_soon` → tertiary（橙），`non_leasable` → outlineVariant（灰）

### 第 5 周（5/4 — 5/8）· M1 前端 楼层热区图 + 联调

#### Day 19 · 5月4日（周一）— 楼层平面图 SVG 渲染（难点）

- `FloorMapPage`：使用 `flutter_svg` 加载楼层 SVG 文件（通过 `/api/files/floors/...` 代理）
- `CustomPaint` 在 SVG 上叠加半透明状态色块多边形（coord 来自 API `heatmap` 端点）
- 楼层切换 Tab / Dropdown，按业态显示/隐藏开关，SVG 支持手势缩放平移（`InteractiveViewer`）

#### Day 20 · 5月5日（周二）— 热区交互 + 单元详情

- 热区点击识别：GestureDetector + 点坐标 → 查找命中 unitId → 跳转 `UnitDetailPage`
- `UnitDetailPage`：基本信息（面积 / 楼层 / 朝向 / 装修状态）+ 三业态差异化扩展字段 + 当前合同摘要占位（待 M2 联动）
- `RenovationHistoryWidget`：改造记录列表（改造类型 / 日期 / 造价）+ 照片网格 `GridView`

#### Day 21 · 5月6日（周三）— Excel 导入前端 + 资产台账导出

- `ImportPage`：业态选择 Tabs + `file_picker` 选择 Excel + Http 上传进度 + 结果报告（成功条数 / 失败行明细）
- `UnitListPage`（表格模式，列：单元号 / 业态 / 面积 / 状态 / 当前租客，支持筛选 + 翻页）
- 导出按钮 → `GET /api/units/export`（后端生成 Excel，前端下载保存）

#### Day 22 · 5月7日（周四）— M1 前后端联调

- 切换 `USE_MOCK=false`，对接真实后端
- 修复数据格式差异（snake_case → camelCase 自动转换验证，日期 ISO 8601 解析，枚举映射不缺值）
- 真实 SVG 文件上传测试（测试用 .dwg → ODA File Converter→DXF → ezdxf→SVG 两步转换链路 → Flutter 渲染验证）

#### Day 23 · 5月8日（周五）— M1 缺陷修复 + 冒烟测试

- 按 PRD §七逐项核对：CAD 平面图展示、单元色块随合同状态联动（模拟切换状态验证）
- RBAC 验证：前线员工访问 `POST /api/units` 返回 403
- 记录 M1 → M2 联动遗留点（UnitDetailPage 当前合同摘要、楼层热区颜色驱动来源）

> **Milestone 1**：639 套 Excel 样本导入正常；楼层 SVG 热区图在 Flutter App 渲染正确；资产 Dashboard 三业态汇总数据展示。

---

## Phase 2：M2 租务与合同管理

> **时间**：2026-05-11（W6）— 2026-06-05（W9），共 20 个工作日

### 第 6 周（5/11 — 5/15）· M2 后端 Tenant + Contract

#### Day 24 · 5月11日（周一）— M2 API Contract + Tenant 后端

- 输出 `docs/api/m2_contracts.md`（tenants / contracts / rent-escalation / alerts / wale 全部端点）
- `tenant.dart`（@freezed，`idNumber` 字段标注 `// encrypted: AES-256`，API 响应默认后 4 位脱敏）
- `TenantRepository`（CRUD + 搜索；证件号存储前加密，取出后脱敏）
- `TenantService` + `TenantController`（`GET /api/tenants`, `GET/POST/PUT /api/tenants/:id`）

#### Day 25 · 5月12日（周二）— Contract 数据层

- `contract.dart`（@freezed，状态机枚举 + 免租期字段 + 付款周期 + 押金）
- `ContractRepository`（CRUD + 状态过滤 + 关联 Tenant/Unit JOIN 查询 + 分页）
- `contract_attachments` 表：`AttachmentRepository`（上传 → 存储 `contracts/{contractId}/{filename}` → 记录路径）

#### Day 26 · 5月13日（周三）— 合同状态机

- `ContractService`：状态转换方法（draft→pending_sign, pending_sign→active, active→expiring_soon 自动判断, active→terminated, active→renewed）
- 业务校验：起租日 < 到期日；免租期 ≤ 合同期；同一单元同一时段不可重叠出租（SQL 时间段 OVERLAP 查询）
- 续签：新合同关联原合同 ID，形成合同链 (`predecessor_contract_id`)

#### Day 27 · 5月14日（周四）— ContractController + 附件 + 递增规则持久化

- `ContractController`（`GET/POST/PUT /api/contracts`, `POST /api/contracts/:id/terminate`, `POST /api/contracts/:id/renew`, `GET /api/contracts/:id/attachments`）
- `rent_escalation_service.dart`：将 `List<RentEscalationPhase>` 序列化为 JSONB 存储；从库读取后反序列化，调用 `RentCalculator.compute()` 预算指定日期租金
- `GET /api/contracts/:id/rent-forecast`（按月返回全合同期预测租金数组）

#### Day 28 · 5月15日（周五）— WALE 服务

- `wale_service.dart`：$WALE = \sum(剩余租期_i \times 年化租金_i) / \sum(年化租金_i)$，调用 `RentCalculator` 获取各合同年化租金
- 支持 groupBy=overall / building / propertyType 三级
- `GET /api/wale`（支持 groupBy 参数）+ `GET /api/wale/trend?months=12`（历史 12 月 WALE 曲线数据）
- 用小样本合同数据手工验算对比，误差 < 0.001

### 第 7 周（5/18 — 5/22）· M2 后端 预警 + 前端 Domain/BLoC

#### Day 29 · 5月18日（周一）— 预警引擎后端

- `alert_service.dart`：扫描合同生成到期预警（提前 90/60/30 天），扫描账单生成逾期预警（第 1/7/15 天未到账）
- `AlertRepository`（create, listByRecipient, markRead, markAllRead）
- `POST /api/scheduler/run-alerts`（手动触发，Phase 1 替代 cron；响应：新生成预警数量）
- `GET /api/alerts`（分页，过滤：type / isRead）+ `PUT /api/alerts/:id/read`

#### Day 30 · 5月19日（周二）— M2 前端 Domain + Data 层

- freezed 模型：`Tenant`, `Contract`, `ContractAttachment`, `RentEscalationPhase`, `Alert`, `WaleData`, `RentForecastItem`（纯 Dart）
- 抽象接口：`TenantRepository`, `ContractRepository`, `AlertRepository`, `WaleRepository`, `EscalationRepository`
- HTTP 实现（Dio + 分页 + ApiException 包装）+ Mock 实现（含 3 种附件格式样本）

#### Day 31 · 5月20日（周三）— M2 BLoC

- `TenantListBloc`（Event：search, paginate）+ `TenantDetailCubit`（加载全景画像）
- `ContractListBloc`（过滤 Event：byStatus / byBuildingId / byPropertyType）+ `ContractDetailCubit`
- `AlertListBloc`（加载 + 标记已读 + 未读数角标 stream）+ `WaleCubit`（加载三级 WALE + 趋势）
- 全部 BLoC 单元测试通过（bloc_test + mocktail）

#### Day 32 · 5月21日（周四）— M2 UI 租客详情 + 合同列表

- `TenantListPage`（搜索框 + 列表：名称 / 类型 / 手机尾号 / 信用评级）
- `TenantDetailPage`（全景画像：基本信息 / 租赁历史 Tab / 缴费信用 Tab / 工单记录 Tab 占位）
- `ContractListPage`（状态 Tab 筛选 + 合同卡片：单元号 / 租客名 / 到期日 / 月租金 / 状态色标）

#### Day 33 · 5月22日（周五）— M2 UI 合同详情 + 操作 + 预警

- `ContractDetailPage`（合同详情 + 附件列表 + 操作区：终止/续签 确认弹窗）
- `ContractFormPage`（新建/编辑合同：单元选择 / 租客关联 / 免租期配置 / 付款周期）
- `AlertListPage`（按类型分组：到期预警 / 逾期预警 / 月度汇总；未读红标）
- `WaleDashboardWidget`（三业态 WALE 数值卡 + 12 月趋势折线图 `fl_chart`）

### 第 8 周（5/25 — 5/29）· M2 前端 租金递增配置器（难点）

#### Day 34 · 5月25日（周一）— 配置器整体架构

- `RentEscalationConfiguratorWidget`（StatefulWidget）：多阶段动态列表，支持增删阶段按钮
- 每个阶段渲染 `EscalationPhaseCard`（阶段序号 + 类型下拉 + 动态参数区）
- `EscalationTypeSelector`：6 种类型 DropdownButton，选中后切换对应参数 Form

#### Day 35 · 5月26日（周二）— 各类型参数表单

- `FixedRateForm`（涨幅百分比 + 递增周期年数）
- `FixedAmountForm`（固定金额 ¥/m²/月 + 递增周期）
- `SteppedForm`（DataTable：年份段 × 单价，可增删行）
- `CpiLinkedForm`（历年 CPI 录入表 + 生效年份选择）
- `EveryNYearsForm`（间隔 N 年 + 涨幅百分比）
- `PostRenovationForm`（免租结束后首年基准价 + 后续叠加规则选择）

#### Day 36 · 5月27日（周三）— 模板管理 + 预测图表

- `EscalationTemplatePage`（保存当前配置为命名模板，按业态分类，支持搜索/编辑/删除/设为默认）
- `RentForecastChart`（`fl_chart` 折线图：X 轴年月，Y 轴月租金，全合同期预测，支持年/月切换）
- `ContractFormPage` 集成配置器：保存时将阶段列表序化为 API JSON 格式

#### Day 37 · 5月28日（周四）— 配置器联调 + 混合分段验证

- 前后端联调：保存递增规则 → 请求 `GET /api/contracts/:id/rent-forecast` → 渲染预测图
- 测试 3 种混合分段场景（如"第1~2年固定 + 第3~4年5%递增 + 第5年CPI挂钩"）与手工计算对比
- 续签对比组件：显示原合同末期租金 vs 新合同起始租金、涨跌幅百分比

#### Day 38 · 5月29日（周五）— WALE 瀑布图 + M2 集成测试

- `LeaseExpiryWaterfallChart`（`fl_chart` 分组柱状图：X 轴年份，Y 轴到期面积 m²，按业态颜色区分）
- M2 全功能集成测试：合同全状态流转、递增规则联动账单预算、预警生成验证
- RBAC 测试：租务专员可新建合同，不可删除；财务人员不可修改合同

### 第 9 周（6/1 — 6/5）· M2 收尾

#### Day 39 · 6月1日（周一）— 商铺营业额分成

- `Contract` 模型增加 `revenueShareRate`（nullable，仅 retail 业态启用）+ `minimumRent`（保底租金）
- 商铺合同表单：选择"保底+分成"后展示分成参数输入区
- `POST /api/contracts/:id/revenue-entries`（录入当月营业额）+ `GET /api/contracts/:id/revenue-preview`（按营业额计算实收租金预览）

#### Day 40 · 6月2日（周二）— 合同附件管理完善

- `AttachmentWidget`（前端）：上传 PDF（file_picker）+ 文件预览/下载（通过 `/api/files/contracts/...` 代理）+ 单个删除确认弹窗
- 后端 RBAC：附件只有合同所属租务专员/管理层可删除，财务只读

#### Day 41 · 6月3日（周三）— M2 性能优化

- 合同列表 500+ 条分页 SQL `EXPLAIN ANALYZE`：确认 `(unit_id, status)` 复合索引生效
- Flutter `ContractListPage` 大列表性能：确认 `ListView.builder` 延迟渲染（非全量构建）
- 日期重计算优化：`daysUntilExpiry` 在后端 SQL 计算而非前端循环

#### Day 42 · 6月4日（周四）— M2 验收对标

- PRD §七核对：WALE 精度（与手工 Excel 误差 < 0.01）、递增规则自动计算、预警 10 分钟内触发
- 更新 `docs/api/m2_contracts.md`（补充联调过程中发现的边界行为）

#### Day 43 · 6月5日（周五）— M1-M2 跨模块联动

- `UnitDetailPage` 填充当前合同摘要（合同编号 / 月租金 / 到期日 / `daysUntilExpiry`）
- 楼层热区图颜色源改为 M2 合同到期日驱动（expiringSoon ≤90天 → tertiary 色）
- `TenantDetailPage` 工单 Tab 关联 M4 预留桩（待 M4 完工后回填）

> **Milestone 2**：合同状态机全流程跑通；租金递增配置器支持 6 种类型 + 混合分段；WALE 计算误差 < 0.01 年；楼层热区颜色实时联动合同到期日。

---

## Phase 3：M4 物业运营与工单系统

> **时间**：2026-06-08（W10）— 2026-06-19（W11），共 10 个工作日

### 第 10 周（6/8 — 6/12）· M4 后端 + 前端 Domain/Data/BLoC

#### Day 44 · 6月8日（周一）— M4 API Contract + 后端骨架

- 输出 `docs/api/m4_workorders.md`（work_orders / suppliers / photos / cost_entries 端点）
- `work_order.dart` + `supplier.dart`（@freezed，状态枚举 + 优先级枚举），数据迁移 SQL
- M4 路由骨架（Controller 空实现，返回 mock JSON）

#### Day 45 · 6月9日（周二）— M4 后端 Service + Controller

- `WorkOrderRepository`（CRUD + 按 status / buildingId / assigneeId / priority 多条件查询 + 分页）
- `WorkOrderService`：状态机转换（submitted→reviewed→processing→pending_acceptance→completed / rejected），RBAC 检查（只有审核权限角色可派单）
- `SupplierRepository` + `SupplierService`（CRUD + 按服务类型查询）
- `WorkOrderController`（`GET/POST /api/work-orders`, `PATCH /api/work-orders/:id/status`, `POST /api/work-orders/:id/photos`）

#### Day 46 · 6月10日（周三）— 推送服务后端

- `push_service.dart`：封装 Firebase Cloud Messaging HTTP v1 API（Authorization: Bearer `GoogleServiceAccount` 令牌）
- 工单状态变更触发推送：提单人（进度更新）+ 指派人（新工单通知）
- 桌面/Web 替代：状态变更时写入目标用户的 `alerts` 表（type: work_order_update）；外加 `GET /api/alerts/unread/count` 供 30 秒轮询

#### Day 47 · 6月11日（周四）— M4 前端 Domain/Data/BLoC

- freezed 模型：`WorkOrder`, `WorkOrderStatus`, `Supplier`, `CostEntry`
- 抽象接口 + HTTP 实现 + Mock 实现（5 条不同状态工单）
- `WorkOrderListBloc`（状态 Tab 过滤）+ `WorkOrderDetailCubit`（加载详情 + 状态更新）+ `ReportWorkOrderCubit`（表单状态管理）
- BLoC 单元测试覆盖（bloc_test）

#### Day 48 · 6月12日（周五）— M4 UI 工单列表 + 详情

- `WorkOrderListPage`（状态 Tab：待审核 / 处理中 / 待验收 / 已完成）+ `WorkOrderCard`（优先级色标 + 楼栋单元 + 提报时间）
- `WorkOrderDetailPage`：状态时间轴 `Stepper` + 照片网格 `GridView` + 费用明细 `ListTile` + 角色操作按钮（派单/完工/验收/拒绝）

### 第 11 周（6/15 — 6/19）· M4 前端 报修 + 推送 + 联调

#### Day 49 · 6月15日（周一）— 移动端报修页

- `ReportWorkOrderPage`：楼栋选择 → 楼层选择 → 单元选择（三级联动 Dropdown，数据从 M1 API 拉取）
- 问题类型选择（列表：水电 / 空调 / 消防 / 结构 / 其他）+ 紧急程度（一般 / 紧急 / 非常紧急）+ 描述文本框
- `image_picker` 照片选择（最多 5 张）+ 预览网格 + 多张并发上传进度条

#### Day 50 · 6月16日（周二）— QR 扫码 + 平台差异化

- `QrScanPage`：`mobile_scanner` 集成，扫码后解析 unitId（二维码内容格式约定：`propos://units/{unitId}`）→ 自动预填 `ReportWorkOrderPage`
- `PlatformUtils.supportsQrScan` 判断：桌面/Web 端隐藏扫码入口，降级展示手动选择楼栋/楼层/单元的完整表单
- 相机权限请求封装（iOS `permission_handler`）

#### Day 51 · 6月17日（周三）— 费用录入 + 供应商管理

- `CostEntryPage`（完工后录入：材料费 + 人工费 + 供应商关联 + 完工照片上传）
- `SupplierListPage`（供应商列表 + 搜索 + 类型筛选）+ `SupplierFormPage`（新增/编辑）
- 后端：`POST /api/work-orders/:id/cost-entry`，费用写入 `expenses` 表并设 `source: work_order`（M3 NOI 联动接口预留）

#### Day 52 · 6月18日（周四）— M4 前后端联调

- 完整工单流转联调：移动端报修 → PC 端派单 → 处理中 → 完工费用录入 → 验收完成
- FCM 推送验证（iOS/Android 测试设备，状态变更 → 通知栏出现推送）
- 桌面端轮询验证：工单状态变更 → 10 秒内 `/api/alerts/unread/count` 数值更新

#### Day 53 · 6月19日（周五）— M4 验收 + 微信小程序骨架

- 验收：报修全流程 + 成本汇入（Day 51 接口联动确认）+ RBAC（前线员工不可审核/派单）
- 微信小程序骨架：`app.json` 配置 2 页（报修表单页 + 工单状态查询页），API 接口复用后端（不开发推送）

> **Milestone 3**：工单从提报到完工全链路跑通；移动端 FCM 推送验证成功；维修成本写入 expenses 表接口联调确认。

---

## Phase 4：M3 财务与业财一体化

> **时间**：2026-06-22（W12）— 2026-07-17（W15），共 20 个工作日

### 第 12 周（6/22 — 6/26）· M3 后端 账单 + 收款 + NOI

#### Day 54 · 6月22日（周一）— M3 API Contract + Invoice 后端

- 输出 `docs/api/m3_finance.md`（invoices / payments / expenses / noi / kpi 端点）
- `invoice.dart` + `payment.dart` + `expense.dart`（@freezed），数据迁移 SQL
- `InvoiceRepository`（CRUD + 按合同/月份/状态查询 + 按维度聚合）

#### Day 55 · 6月23日（周二）— 账单自动生成（难点）

- `invoice_service.generateMonthlyInvoices(targetMonth)`：遍历所有 `active` 合同，调用 `RentCalculator.compute(phases, targetMonth)` 获取当月租金，生成 `Invoice` + `InvoiceItem`（租金 / 物管费 / 水电代收）
- 免租期判断：当月在免租期内则 `InvoiceItem.isExempt = true`，不计入逾期
- `POST /api/invoices/generate`（触发批量生成，事务包裹，目标 639 条 < 30 秒）+ `POST /api/invoices/export`（Excel 下载）

#### Day 56 · 6月24日（周三）— 收款核销

- `payment_service.dart`：录入到账信息 → 按合同/金额自动匹配未核销账单 → 标记核销状态，差额处理（多付/少付）
- 逾期账单：调用 `alert_service.createOverdueAlert()` 在第 1/7/15 天生成催收提醒 Alert
- `paymentController`（`POST /api/payments`, `POST /api/invoices/:id/reconcile`）+ 发票号录入 (`PATCH /api/invoices/:id/invoice-no`)

#### Day 57 · 6月25日（周四）— Expense + NOI 计算

- `expense_repository.dart`（CRUD + 按 category / buildingId / month 聚合查询）
- `noi_service.computeNoi(month, {buildingId, propertyType})`：PGI（合同月租合计）- VacancyLoss（空置单元市值估算）+ OtherIncome（停车/储藏室）- OpEx（expenses 聚合）= NOI
- `GET /api/noi/summary`（月度 NOI：全局 + 三业态拆分）+ `GET /api/noi/trend?months=12`

#### Day 58 · 6月26日（周五）— 工单成本 → NOI 支出联动

- M4 `CostEntry` 保存时调用 `expense_service.createFromWorkOrder(workOrderId, amount, category)`，自动写 `expenses` 表，`source = 'work_order'`
- `GET /api/expenses/by-category`（按类型汇总：维修 / 物管 / 保险 / 税金 / 其他）
- 回填 Day 51 工单费用录入接口，端到端测试：工单完工 → 费用录入 → NOI 支出更新

### 第 13 周（6/29 — 7/3）· M3 后端 KPI 引擎

#### Day 59 · 6月29日（周一）— KPI 指标定义存储

- `kpi_metric_definitions` 表初始化（10 条预定义指标 K01~K10，含 code/name/defaultFullScore/defaultPassScore）
- `kpi_schemes` + `kpi_scheme_metrics`（多对多关联，含权重 + 本方案满分阈值微调）
- `KpiRepository`（方案 CRUD：create / update / delete + 权重校验 sum=1.0）

#### Day 60 · 6月30日（周二）— KPI 数据聚合

- `kpi_service.gatherMetricData(metricCode, schemeId, period)`：按指标 code 从各模块聚合真实数据
  - K01 出租率（units 表），K02 收款及时率（invoices/payments），K03 租户集中度（contracts 聚合）
  - K04 续约率（contract_status = renewed），K05 工单响应时效（work_orders 平均时长）
  - K06 空置周转天数（units 状态变更历史），K07 NOI 达成率（noi 实际/预算）
  - K08 逾期率（invoices 逾期金额占比），K09 递增执行率（递增生效合同数占比），K10 满意度（手动录入）

#### Day 61 · 7月1日（周三）— KPI 打分 + 快照持久化

- 调用 `KpiScorer.score(metric, actualValue)` 计算每个指标得分（0~100）
- $KPI_{总分} = \sum(得分_i \times 权重_i)$
- `kpi_service.computeAndSaveSnapshot(schemeId, targetPeriod)`：计算所有绑定指标并写入 `kpi_score_snapshots` + `kpi_score_snapshot_items` 表
- `POST /api/kpi/compute`（触发计算 + 持久化，返回快照 ID）

#### Day 62 · 7月2日（周四）— KPI 查询接口

- `GET /api/kpi/schemes`（列表）+ CRUD（创建/更新/删除方案）
- `GET /api/kpi/snapshots?schemeId=&period=`（历史评分快照）+ `GET /api/kpi/snapshots/:id`（含各指标得分明细）
- `GET /api/kpi/ranking?schemeId=&period=`（同方案员工/部门排名）
- `GET /api/kpi/trend?schemeId=&months=6`（某方案历史趋势数组）

#### Day 63 · 7月3日（周五）— M3 后端验收 + 性能

- 账单批量生成性能：批量生成 639 条，`EXPLAIN ANALYZE` 确认 < 30 秒
- KPI 打分结果与手工计算对比（配置 2 套不同权重方案，结果一致性验证）
- 账单/支出 Excel 导出测试（按业态 / 时间段 / 楼栋维度各导出一次）

### 第 14 周（7/6 — 7/10）· M3 前端 账单 + NOI

#### Day 64 · 7月6日（周一）— M3 前端 Domain/Data/BLoC

- freezed 模型：`Invoice`, `InvoiceItem`, `Payment`, `Expense`, `NoiSummary`, `KpiScheme`, `KpiSnapshot`, `KpiMetricScore`
- HTTP 实现 + Mock 实现（各 5 条样本，含已核销 / 逾期 / 待核销三种状态）
- BLoC：`InvoiceListBloc`, `PaymentCubit`, `ExpenseListBloc`, `NoiDashboardCubit`, `KpiDashboardCubit`
- 全部 BLoC 单元测试 pass

#### Day 65 · 7月7日（周二）— 账单列表 + 详情 + 核销

- `InvoiceListPage`（Tab 过滤：全部 / 待核销 / 逾期 / 已核销，展示收款进度对比条）
- `InvoiceDetailPage`（费项明细 DataTable + 核销操作 + 发票号录入 + 状态色标）
- `PaymentFormPage`（录入到账信息：金额 / 到账日期 / 备注）+ 自动匹配账单提示

#### Day 66 · 7月8日（周三）— NOI 实时看板

- `NoiDashboardPage`：月度三栏卡片（EGI / OpEx / NOI 数值 + 环比变化箭头）
- 三业态 NOI 拆分 `Row`（写字楼 / 商铺 / 公寓各自 NOI 柱状对比）
- 12 月 NOI 趋势折线图（`fl_chart` LineChart）+ 月份横向滑动选择

#### Day 67 · 7月9日（周四）— NOI 细项 + 出租率仪表盘

- 出租率 `CircularProgressIndicator` 仪表盘（全局 + 三业态下钻 Tab）
- 空置损失测算展示（空置单元数 × 市值单价 × 面积）
- 本月收款进度 `LinearProgressIndicator`（应收 vs 实收，点击展开未缴款租户列表）

#### Day 68 · 7月10日（周五）— 运营支出录入 UI

- `ExpenseListPage`（按类目 Tab：维修 / 物管 / 保险 / 税金 / 其他；包含工单来源标记）
- `ExpenseFormPage`（手动新增支出：类目 / 金额 / 付款日期 / 楼栋关联 / 备注）

### 第 15 周（7/13 — 7/17）· M3 前端 KPI 仪表盘 + 联调

#### Day 69 · 7月13日（周一）— KPI 方案配置器

- `KpiSchemePage`（方案列表 + 新建入口 + 当前生效标记）
- `KpiSchemeFormPage`：
  - 指标勾选 `CheckboxListTile`（10 个预定义指标，含说明文字）
  - 权重输入 `TextFormField`（实时合计校验 = 100% 提示）
  - 满分/及格阈值微调 `Slider`
  - 评估周期、适用对象（部门/员工）配置

#### Day 70 · 7月14日（周二）— KPI 评分看板

- `KpiDashboardPage`：当期方案总览卡（总分 + 等级标签）+ 各指标得分 `RadarChart`（`fl_chart`）
- 员工/部门排名 `ListTile` 列表（头像 + 姓名 + 得分 + 名次变化箭头）
- 指标下钻：点击雷达图某顶点 → `BottomSheet` 展示原始数据明细

#### Day 71 · 7月15日（周三）— KPI 历史趋势 + 导出

- 历史折线图（过去 6~12 月 KPI 总分曲线 + 各指标分项趋势可切换）
- 同比/环比数值对比显示（与上月、去年同期）
- `KpiExportButton`（调用 `POST /api/kpi/snapshots/:id/export` 下载 PDF 报告，`file_picker` 保存路径）

#### Day 72 · 7月16日（周四）— M3 前后端联调

- 账单自动生成联调：M2 合同递增规则 → `POST /api/invoices/generate` → 前端列表即时刷新
- KPI 联调：配置方案 → `POST /api/kpi/compute` → 前端雷达图更新
- NOI 联调：工单费用录入 → expenses 更新 → NOI 看板数值变化

#### Day 73 · 7月17日（周五）— M3 验收对标

- PRD §七逐项：NOI 实时展示一致性、账单 < 30 秒、KPI 2 套方案打分与手工一致
- 权限验证：财务人员可录入支出/核销账单，不可配置 KPI 方案（403）
- 记录 M3 → M5 穿透视角联动待办（NOI 看板增加穿透口径切换）

> **Milestone 4**：账单自动生成完成（三业态多费项）；NOI 三业态拆分正确；KPI 两套方案自动打分与手工一致；工单费用 → NOI 支出链路打通。

---

## Phase 5：M5 二房东租赁信息穿透管理

> **时间**：2026-07-20（W16）— 2026-07-31（W17），共 10 个工作日

### 第 16 周（7/20 — 7/24）· M5 后端 + 外部门户

#### Day 74 · 7月20日（周一）— M5 API Contract + 行级隔离后端

- 输出 `docs/api/m5_subleases.md`（subleases 端点 + 外部门户专用端点）
- `sublease.dart`（@freezed，`idNumber` 字段标注 `// encrypted`，API 响应脱敏）
- `SubleaseRepository`：所有查询强制附加 `WHERE master_contract_id = ANY($subLandlordScope)` 行级隔离，绝不通过应用层过滤代替 SQL 过滤

#### Day 75 · 7月21日（周二）— M5 Service + 审核流

- `SubleaseService`：子租赁 CRUD + 审核状态机（pending_review→approved / rejected），拒绝时必填理由
- 审核通过/拒绝均记录 `audit_logs`（before/after JSON 完整对比）
- `sublease_import_service.dart`：解析二房东 Excel 模板，校验（单元必须在主合同覆盖范围、子租赁到期日 ≤ 主合同到期日、同单元无重叠在租），批量 INSERT

#### Day 76 · 7月22日（周三）— M5 Controller + 提醒接口

- `SubleaseController`（内部管理端：CRUD + 审核操作 `PATCH /api/subleases/:id/review`）
- `POST /api/subleases/external`（外部门户专用，要求角色 `sub_landlord`，仅限 JWT 中 `subLandlordScope` 范围）
- `POST /api/scheduler/run-sublease-reminders`（遍历所有二房东合同，发送月度填报提醒邮件/短信）

#### Day 77 · 7月23日（周四）— 外部二房东填报门户（Flutter Web，独立路由）

- 独立路由 `/sublease-portal`（与主 App 同代码库，`go_router` 条件分支：sub_landlord 角色自动重定向此路由）
- `SubleasePortalLoginPage`（独立登录页，Logo/文案与主 App 区分）
- `SubleasePortalHomePage`：显示自身主合同覆盖单元列表，空置/已租/待审核状态标记
- `SubleaseFormPage`（逐条填报：租客信息 / 租金 / 入住状态，含字段实时校验）

#### Day 78 · 7月24日（周五）— 外部门户 Excel 上传 + 提交确认

- 模板下载按钮（`GET /api/subleases/template`，返回预填表头的 Excel 文件）
- Excel 批量上传 + 后端返回校验结果（成功行数 + 失败行明细），前端 `DataTable` 展示错误行
- 提交后：状态变为"待审核"，不可再次编辑（只读显示），展示提交时间戳
- 变更历史 Tab：按时间排序的历史提交记录（修改前后字段对比）

### 第 17 周（7/27 — 7/31）· M5 前端 内部管理 + 穿透看板

#### Day 79 · 7月27日（周一）— M5 前端 Domain/Data/BLoC

- freezed 模型：`Sublease`, `SubleaseStatus`, `SublandlordOverview`, `SubleaseReviewRecord`
- 抽象接口 + HTTP 实现 + Mock 实现
- `SubleaseListBloc`（按主合同/状态过滤）+ `SubleaseReviewCubit`（加载审核相关详情）

#### Day 80 · 7月28日（周二）— M5 内部管理 UI

- `SubleaseManagementPage`：按主合同分组 `ExpansionTile`，子租赁列表（单元号 / 终端租客 / 租金 / 状态）
- 待审核条目高亮（使用 `colorScheme.tertiary` 背景）+ 快速审批操作按钮
- `SubleaseDetailPage`（查看子租赁详情 + 审核历史 + 证件脱敏展示）
- `SubleaseFormPage`（内部录入：单元下拉限主合同范围，起止日期校验）

#### Day 81 · 7月29日（周三）— M5 穿透分析看板

- `SublandlordDashboardPage`：
  - 每家二房东总览卡（主合同租金 / 已填报数 / 终端出租面积 / 终端空置面积）
  - 转租溢价分析：终端均价 vs 主合同单价 + 溢价率百分比（ColoredBox 红绿标记）
  - 穿透出租率 vs 整体出租率双条进度条对比
  - 子租赁集中到期预警时间轴
  - 填报完整度监控（已填报单元数 / 主合同覆盖总单元数 + 进度环）

#### Day 82 · 7月30日（周四）— 楼层热区穿透模式 + 跨模块联动

- `FloorMapPage` 增加"穿透模式" `Switch`（`AppBar` 操作区）
- 穿透模式开启时：单元 Tooltip 显示终端租客名称 / 实际月租金 / 入住状态（从 sublease API 聚合）
- `ContractDetailPage` 增加"子租赁"Tab（展示该主合同下所有子租赁记录列表）
- M3 `NoiDashboardPage` 增加"穿透视角"切换（按终端口径统计出租率，区别于主合同口径）

#### Day 83 · 7月31日（周五）— M5 联调 + 验收 + 安全测试

- 外部门户全流程联调：二房东登录 → 查看单元 → 填报 → Excel 上传 → 提交待审核 → 内部审核通过 → 数据生效
- 行级隔离安全测试：使用二房东 A 的 JWT 发送请求，强制携带二房东 B 的 `master_contract_id`，后端必须返回 403 / 空结果
- 审计日志完整性：每次提交/修改/审核均有对应 `audit_logs` 记录（before/after 内容非 null）
- RBAC：二房东角色不可访问 `/api/units`、`/api/contracts` 等内部端点（403 测试）

> **Milestone 5**：外部填报门户可独立访问，行级隔离安全验证通过；子租赁审核流完整；穿透模式在楼层热区正确叠加终端租客信息；二房东角色数据不出圈。

---

## Phase 6：集成测试 + 数据初始化

> **时间**：2026-08-03（W18）— 2026-08-14（W19），共 10 个工作日

### 第 18 周（8/3 — 8/7）· 全模块集成 + 数据初始化

#### Day 84 · 8月3日（周一）— 全模块跨领域联动验证

- M1 单元状态 ← M2 合同到期日驱动（热区颜色实时一致性，模拟修改合同 endDate 验证）
- M4 工单费用 → M3 NOI 支出（录入工单费用 → NOI 支出金额变化断言）
- M3 KPI 跨模块数据抽取：修改 M1/M2/M4 数据后重触发 KPI 计算，结果变化方向符合预期
- M5 子租赁审核通过 → M3 穿透视角出租率更新

#### Day 85 · 8月4日（周二）— 预警全链路 + 推送端到端

- 合同到期预警全链路：手动修改合同 endDate 为 20 天后 → `POST /api/scheduler/run-alerts` → 10 分钟内 `GET /api/alerts` 出现新预警
- 逾期账单预警：手动将账单 dueDate 设为 1/7/15 天前 → 触发 → 验证 Alert 类型和接收人
- FCM 推送端到端：工单状态变更 → iOS/Android 测试机收到通知（截图记录）
- 桌面端轮询：工单状态变更 → PC 桌面端 30 秒内角标更新

#### Day 86 · 8月5日（周三）— 数据初始化 Excel 模板制作

- 制作三份单元导入模板（写字楼 / 商铺 / 公寓），包含：字段列头、类型说明行（注释）、数据验证规则（下拉枚举）、3 条样本行
- 制作合同历史导入模板（含递增规则 JSONB 序列化格式说明）
- 制作子租赁信息导入模板（供二房东使用，含字段校验说明）
- 制作操作手册 v1.0（面向运营团队的导入操作步骤说明，含截图）

#### Day 87 · 8月6日（周四）— 实际数据导入（配合运营团队）

- 写字楼单元数据批量导入（约 441 套），验证导入结果（楼层 / 单元号 / 面积核对）
- 商铺 + 公寓批量导入（约 198 套）
- 实际 CAD 文件处理：.dwg → SVG 批量转换，在 Flutter App 楼层平面图真实渲染验证
- 历史在租合同导入（预估 500+ 条，分批次）

#### Day 88 · 8月7日（周五）— 财务 + KPI 初始数据

- 录入当前未结账单（财务人员协作），标记历史付款记录为已核销
- 初始化 KPI 方案：租务部（K01/K02/K04/K09 四指标）+ 财务部（K02/K07/K08 三指标）+ 物业运营部（K05/K06 两指标 + K10）
- 补录 6 个月 KPI 历史快照（为趋势图提供初始数据，可用估算值）
- 二房东账号创建（各二房东账号 + 绑定主合同范围）

### 第 19 周（8/10 — 8/14）· 全量回归 + 性能 + 安全

#### Day 89 · 8月10日（周一）— 全量功能回归测试

- 按 PRD §七验收标准逐项测试，制作测试矩阵（功能点 / 测试步骤 / 预期结果 / 实际结果 / Pass or Fail）
- 重点验收项：WALE 精度（< 0.01 年）/ 递增规则计算准确性 / KPI 打分与手工一致 / 账单生成 < 30 秒 / 穿透看板数据

#### Day 90 · 8月11日（周二）— 性能测试

- `hey -n 500 -c 50 https://localhost:8080/api/dashboard` 并发压测，目标：P99 < 3 秒
- 账单批量生成 639 条压测：`time curl -X POST /api/invoices/generate`，目标 < 30 秒
- PostgreSQL 慢查询分析：`pg_stat_statements` 找出 Top 5 慢查询 + `EXPLAIN ANALYZE` 优化
- Flutter DevTools Timeline：Dashboard 页首屏帧率检查（目标 60fps 无掉帧）

#### Day 91 · 8月12日（周三）— 安全审查

- SQL 注入：全库 grep 确认所有 SQL 使用参数化查询（无字符串拼接）
- JWT：确认算法固定为 HS256（`only: ['HS256']` 校验，禁止 `alg: none`）
- IDOR：所有 `GET /api/xxx/:id` 端点测试跨用户访问是否 403
- 证件号：grep 全库确认 API 响应中 `idNumber` 均脱敏（仅末 4 位），数据库字段均有 `// encrypted` 注释
- 二房东隔离：行级隔离 SQL 条件覆盖测试（携带非授权 contractId，期望空结果 / 403）
- CORS：生产环境 `CORS_ORIGINS` 限制为实际域名（非 `*`）

#### Day 92 · 8月13日（周四）— 回归缺陷修复

- 修复 Day 89-91 测试发现的 P0 / P1 缺陷（P0 = 崩溃/数据错误，P1 = 功能不符合 PRD）
- P2 级问题（UI 细节 / 非核心功能）记录到 Backlog，不阻断上线
- 审计日志最终完整性检查（4 类操作覆盖：合同变更 / 账单核销 / 权限变更 / 二房东数据提交）

#### Day 93 · 8月14日（周五）— 部署准备

- 编写 `README.md`（启动步骤 / 环境变量 / 数据库初始化 SQL 运行顺序）
- `.env.example`（6 个必填 + 3 个可选变量，含说明注释）
- `Dockerfile`（多阶段构建：build → dart compile AOT → 最小 runtime 镜像）
- 数据库自动备份脚本（每日 pg_dump + 7 天滚动删除）
- 生产环境 Checklist（防止上线遗漏）

> **Milestone 6**：全部 PRD 验收项 Pass；50 并发压测 P99 < 3 秒；实际 639 套数据导入完成；安全审查无 P0 漏洞。

---

## Phase 7：用户验收测试（UAT）+ 正式上线

> **时间**：2026-08-17（W20）— 2026-08-21（周五），共 5 个工作日

#### Day 94 · 8月17日（周一）— UAT 启动 + 资产模块演示

- 向超级管理员/运营管理层演示 M1 资产台账、楼层热区图操作
- 采集用户反馈（UI 易用性、数据显示、操作流程），填写 UAT 问题单
- M1 发现问题即时修复（当天修复当天验证）

#### Day 95 · 8月18日（周二）— UAT 合同 + 工单模块

- 租务专员操作 M2（新建合同 / 录入递增规则 / 查看 WALE 仪表盘）
- 前线员工操作 M4 移动端报修（扫码 / 手填 / 上传照片 / 查看进度）全流程演示
- 二房东账号操作外部填报门户（登录 / 填报子租赁 / 提交审核）

#### Day 96 · 8月19日（周三）— UAT 财务 + KPI

- 财务人员操作账单核销、录入支出、查看 NOI 看板
- 管理层查看 KPI 评分仪表盘（雷达图 / 排名榜 / 历史趋势）
- UAT 问题单汇总，确认上线阻断项

#### Day 97 · 8月20日（周四）— UAT 缺陷修复

- 修复 UAT 反馈的全部上线阻断问题（P0/P1 级，限制在 6 小时内）
- 更新操作手册截图（若 UI 有调整）
- 验收签字确认（与运营团队负责人确认验收通过）

#### Day 98 · 8月21日（周五）— **正式上线**

- 生产环境部署：后端服务启动验证（6 个必填环境变量 assert 通过）、PostgreSQL 连接、文件存储挂载
- 生产环境冒烟测试（登录 / 数据查询 / 账单生成各触发一次）
- 全量数据在生产库确认完整（与测试环境数据核对关键指标）
- 向团队宣布 **PropOS Phase 1 正式上线**
- 开始 Phase 2 规划冲刺（租户自助门户 / 电子签章优先级评估）

> **最终里程碑：PropOS Phase 1 于 2026-08-21 正式上线，639 套房源三业态全数字化管理就位，M1~M5 五個模块全面运行。**

---

## 关键风险预案

| 风险点 | 概率 | 影响 | 预案 |
|--------|------|------|------|
| CAD .dwg → SVG 转换工具不可用或输出质量差 | 中 | M1 延期 1–2 天 | W3 末若 ODA File Converter + ezdxf 链路输出质量不符合要求，降级为"手动上传 SVG/PNG"；CAD 自动转换列为 Phase 2 补充 |
| 租金递增配置器 UI 复杂度超估 | 中 | M2 延期 2–3 天 | Day 36 前若配置器 UI 未完工，先简化为纯 Form 表单（暂不含实时预测图），功能完整性优先 |
| KPI 10 指标跨模块聚合 SQL 难度超估 | 中 | M3 延期 2 天 | K10 满意度固定为手动录入；其余 9 个自动指标若有 2 个数据源不稳定，先返回 0 值，待稳定后补接 |
| 真实 CAD 文件结构与测试文件不同 | 中 | 数据初始化延期 | Day 13 前向运营团队索取 1 层实际 .dwg 文件用作早期验证 |
| 外部门户行级隔离漏洞 | 低 | 严重安全问题 | M5 行级隔离 SQL 必须先于外部门户联调完成；Day 91 安全审查作为硬性上线 Gate |
| 数据初始化工作量超出预期 | 中 | Phase 6 延期 1 周 | 提前 2 周与运营团队划定责任边界：数据收集/整理由团队负责，导入工具由开发方提供 |
| 功能范围蔓延（Scope Creep） | 高 | 整体延期 | Phase 2 功能请求（租户门户 / 门禁 / 电子签章）严格挡在上线后评估；Copilot 指令中已明确禁止超前实现 |

---

## 附录：工作日历

> 中国法定节假日影响（2026 年）：
> - 五一劳动节（5/1–5/5，本计划 5/1 已纳入工作日，如需休假则 M1 顺延一天）
> - 端午节（5/29 前后，如为法定休假则 M2 调整 1 天）
> - 国庆长假（10月，Phase 1 在 8月完成，不受影响）

建议：节假日对应的工作内容可在前后 1 天内灵活调整，不改变里程碑日期目标。

---

*本计划基于 PropOS PRD v1.7（2026-04-06）及 ARCH.md v1.2（2026-04-06）制定。如 PRD 需求变更，相关模块排期对应调整。*

---

## 附录 B：v1.7 需求变更对排期的影响评估

> 以下变更项来自 PRD v1.6 → v1.7 升级，均为 Phase 1 Must 范围内新增能力。原 v1.0 日程计划的任务骨架保持不变，但涉及以下模块的工作日需相应扩展。

### 新增工作量估算

| 变更项 | 影响阶段 | 估算新增工作日 | 建议嵌入时段 |
|--------|---------|--------------|-------------|
| 合同-单元 M:N 关联（contract_units） | Phase 2 M2 | +1 天 | Day 25~26 合同数据层 |
| 合同提前终止流程（3 种终止类型） | Phase 2 M2 | +1 天 | Day 26~27 状态机 |
| 含税/不含税标识 + 税率字段 | Phase 2 M2 + Phase 4 M3 | +0.5 天 | Day 25（后端）+ Day 65（前端） |
| 押金独立管理（deposits + transactions） | Phase 2 M2 | +2 天 | Day 27~28 之间新增 |
| 租户信用评级（A/B/C 自动重算） | Phase 2 M2 | +0.5 天 | Day 24 Tenant 后端 |
| 水电抄表与计费（meter_readings） | Phase 4 M3 | +2 天 | Day 55~56 之间新增 |
| 商铺营业额申报审核（turnover_reports） | Phase 4 M3 | +1.5 天 | Day 39（已有骨架）扩展 |
| WALE 双口径（收入加权 + 面积加权） | Phase 2 M2 | +0.5 天 | Day 28 WALE 服务 |
| KPI 指标方向（positive/negative） | Phase 4 M3 | +0.5 天 | Day 59~61 KPI 引擎 |
| 导入批次管理（import_batches + dry_run + 回滚） | Phase 1 M1 + Phase 6 | +1 天 | Day 13 导入后端 |
| 迁移脚本扩展（10 步 → 14 步） | Phase 0 | +0.5 天 | Day 4~5 |
| PIPL 合规 + HTTPS/TLS + 密码复杂度 | Phase 5 M5 + 安全审查 | +0.5 天 | Day 91 安全审查 |
| **合计** | | **+11 天** | |

### 排期调整建议

1. **不改变里程碑日期**：通过提高并行度和减少缓冲来吸收新增 11 天工作量。具步骤：
   - Phase 2（M2）原计划 20 天缓冲 2 天 → 改为满载；押金管理和合同终止与合同 CRUD 交叉推进。
   - Phase 4（M3）原计划 20 天 → 水电抄表与账单生成并行后端开发；营业额申报复用 Day 39 已有分成代码骨架。
   - Phase 6（集成测试）原计划 10 天 → 将导入批次测试与数据初始化合并执行。

2. **若无法吸收，备选方案**：将 S-06（KPI 试运行看板）和 S-07（信用评级可视化）从 Should 延后至 Phase 1.5，释放约 3 天给 Must 新增项。

3. **风险提示**：新增 4 张数据表（deposits、meter_readings、turnover_reports、import_batches）及对应 API/页面，开发密度上升约 12%。建议在 Wave 2 结束时（Day 43 前后）评估进度，若落后超 3 天则立即启动 Should 延期决策。
