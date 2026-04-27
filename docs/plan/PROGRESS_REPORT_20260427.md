# PropOS Phase 1 工作进度报告

> **版本**: v1.0
> **报告日期**: 2026-04-27（第 4 周）
> **基准计划**: PROJECT_PLAN v1.4 / PHASE1_SWIMLANE_PLAN v1.7 / PHASE1_IMPLEMENTATION_CHECKLIST v1.7
> **总工期**: 20 周 / 98 个工作日（2026-04-08 ~ 2026-08-21）

---

## 一、进度总览

| 阶段 | 计划区间 | 状态 | 完成度 |
|------|---------|------|--------|
| Phase 0：基础搭建 | W1–W2（4/8–4/17）| ✅ 已完成 | ~95% |
| Phase 1：M1 资产 | W3–W5（4/20–5/8）| 🔄 进行中 | ~55% |
| Phase 2：M2 合同 | W6–W9（5/11–6/5）| ⏳ 未开始 | — |
| Phase 3：M4 工单 | W10–W11（6/8–6/19）| ⏳ 未开始 | — |
| Phase 4：M3 财务 | W12–W15（6/22–7/17）| ⏳ 未开始 | — |
| Phase 5：M5 穿透 | W16–W17（7/20–7/31）| ⏳ 未开始 | — |
| Phase 6：集成测试 | W18–W19（8/3–8/14）| ⏳ 未开始 | — |
| Phase 7：UAT 上线 | W20（8/17–8/21）| ⏳ 未开始 | — |

---

## 二、Phase 0 详情（已完成）

### 2.1 核心 Dart 计算包 ✅

| 包名 | 文件结构 | 测试 |
|------|---------|------|
| `rent_escalation_engine` | `lib/src/calculator.dart` + `models/` | `test/calculator_test.dart` ✅ |
| `kpi_scorer` | `lib/src/scorer.dart` + `models/` | `test/scorer_test.dart` ✅ |

两个包均通过 `path` 依赖引用，零外部依赖，符合架构约束。

### 2.2 后端基础框架 ✅

| 类别 | 文件 | 状态 |
|------|------|------|
| 认证中间件 | `auth_middleware.dart` | ✅ |
| RBAC 中间件 | `rbac_middleware.dart` | ✅ |
| 审计中间件 | `audit_middleware.dart` | ✅ |
| CORS 中间件 | `cors_middleware.dart` | ✅ |
| 日志中间件 | `log_middleware.dart` | ✅ |
| 限流中间件 | `rate_limit_middleware.dart` | ✅ |
| 错误处理 | `app_exception.dart` + `error_handler.dart` | ✅ |
| 分页工具 | `pagination.dart` | ✅ |
| 请求上下文 | `request_context.dart` | ✅ |

Auth 模块（controller / service / repository / model）四层全部就位，含用户管理、登录、密码重置流程。

### 2.3 数据库迁移脚本 ✅（超前计划）

计划要求 14 步迁移，实际已完成 **22 个迁移脚本**，覆盖所有 v1.7 / v1.8 新增表：

| 序号 | 文件 | 覆盖内容 |
|------|------|---------|
| 001 | `001_create_enums.sql` | 基础枚举类型 |
| 002 | `002_create_departments.sql` | 组织架构（超前） |
| 003 | `003_create_users_and_audit.sql` | 用户与审计日志 |
| 004 | `004_create_assets.sql` | 楼栋 / 楼层 / 单元 |
| 005 | `005_create_user_managed_scopes.sql` | 员工管辖范围（超前） |
| 006 | `006_create_contracts.sql` | 合同主表 |
| 007 | `007_create_finance.sql` | 财务核心表 |
| 008 | `008_create_workorders.sql` | 工单表 |
| 009 | `009_create_deposits.sql` | 押金表（v1.7）|
| 010 | `010_create_meter_readings.sql` | 水电抄表（v1.7）|
| 011 | `011_create_turnover_reports.sql` | 营业额申报（v1.7）|
| 012 | `012_create_subleases.sql` | 二房东穿透 |
| 013 | `013_create_kpi.sql` | KPI 基础表 |
| 014 | `014_create_kpi_targets_and_appeals.sql` | KPI 目标与申诉 |
| 015 | `015_create_import_batches.sql` | 导入批次管理（v1.7）|
| 016 | `016_create_password_reset_otps.sql` | 密码重置 OTP |
| 017 | `017_create_noi_budgets.sql` | NOI 年度预算（v1.8）|
| 018 | `018_create_notifications.sql` | 通知系统（v1.8）|
| 019 | `019_add_deferred_foreign_keys.sql` | 延迟外键约束 |
| 020 | `020_seed_reference_data.sql` | 参考数据初始化 |
| 021 | `021_alter_assets_schema.sql` | 资产表结构扩展 |
| 022 | `022_extend_import_data_types.sql` | 导入数据类型扩展 |

> 所有 Phase 1 所需表均已落库，后续模块无需补写迁移脚本。

### 2.4 Flutter 鉴权骨架 ✅

| 层 | 状态 | 说明 |
|----|------|------|
| `core/api/` | ✅ | ApiClient（dio 封装）、ApiException、api_paths |
| `core/router/` | ✅ | go_router 路由表 + 守卫 |
| `core/di/` | ✅ | get_it 依赖注入注册 |
| `core/theme/` | ✅ | Cupertino 主题配置 |
| `features/auth` | ✅ | login_page + forgot_password_page + BLoC + data 层 |
| `features/dashboard` | ✅（shell）| 骨架页面已就位 |

### 2.5 Admin / uni-app 骨架 ✅

| 端 | 状态 | 说明 |
|----|------|------|
| Admin `src/api/client.ts` | ✅ | axios 封装，含 refresh queue |
| Admin `src/router/` | ✅ | Vue Router 4 + beforeEach 守卫 |
| Admin `src/views/auth/` | ✅ | LoginView |
| Admin `src/views/dashboard/` | ✅ | DashboardView shell |
| uni-app `src/pages/auth/` | ✅ | 登录页 |
| uni-app `src/api/client.ts` | ✅ | luch-request 封装 |

---

## 三、Phase 1 M1 资产（进行中，截止 2026-05-08）

### 3.1 已完成 ✅

#### 后端 Assets 模块（BE-05 / BE-06 完成）

| 层 | 文件 |
|----|------|
| Models | `building.dart` / `floor.dart` / `floor_plan.dart` / `unit.dart` / `renovation_record.dart` |
| Repositories | `building_repository.dart` / `floor_repository.dart` / `unit_repository.dart` / `renovation_repository.dart` / `import_batch_repository.dart` |
| Services | `building_service.dart` / `floor_service.dart` / `unit_service.dart` / `renovation_service.dart` |
| Controllers | `building_controller.dart` / `floor_controller.dart` / `floor_plan_controller.dart` / `unit_controller.dart` / `renovation_controller.dart` |

#### 后端 Org 模块（BE-16a 完成，计划 B4 阶段，**已超前**）

| 层 | 文件 |
|----|------|
| Models | `department.dart` / `managed_scope.dart` |
| Repositories | `department_repository.dart` / `managed_scope_repository.dart` |
| Services | `department_service.dart` / `managed_scope_service.dart` / `department_import_service.dart` |
| Controllers | `department_controller.dart` / `managed_scope_controller.dart` |

#### Admin 资产与系统管理视图

| 视图 | 状态 |
|------|------|
| `AssetsView.vue` | ✅ |
| `BuildingDetailView.vue` | ✅ |
| `FloorPlanView.vue` | ✅ |
| `UnitDetailView.vue` | ✅ |
| `UnitImportView.vue` | ✅ |
| `system/departments/` | ✅（超前）|
| `system/users/` | ✅（超前）|

Admin Store：`assets.ts` / `auth.ts` / `departments.ts` / `users.ts` 已完成。

Admin API 模块：`assets.ts` / `auth.ts` / `departments.ts` / `users.ts` 已完成。

#### uni-app

| 模块 | 状态 | 说明 |
|------|------|------|
| `pages/assets/` | ✅（骨架）| 页面目录已建 |
| `api/modules/assets.ts` | ✅ | API 函数已完成 |
| `api/modules/contracts.ts` | ✅（超前）| |
| `api/modules/finance.ts` | ✅（超前）| |
| `api/modules/workorders.ts` | ✅（超前）| |

### 3.2 尚未完成 ❌

| 任务 | 计划编号 | 优先级 | 剩余时间 |
|------|---------|-------|---------|
| Flutter 资产台账列表页（含批次跟踪） | FE-03 | 🔴 紧急 | 1.5 周 |
| Flutter 楼层图查看 + 热区渲染 + 多版本图纸 | FE-04 | 🔴 紧急 | 1.5 周 |
| uni-app 业务 store（contracts/finance/workorders/assets）| — | 🟡 重要 | — |
| Admin contracts API 模块 + Pinia store | — | 🟡 重要 | — |
| Admin finance API 模块 + Pinia store | — | 🟡 重要 | — |
| Admin workorders API 模块 + Pinia store | — | 🟡 重要 | — |
| Admin subleases API 模块 + Pinia store | — | 🟡 重要 | — |

---

## 四、后续模块预判

以下模块均按计划排在 M1 之后，当前尚未启动：

| 模块 | 后端当前状态 | 计划启动 |
|------|------------|---------|
| Contracts（M-09 ~ M-12c）| controllers/services/repositories 均为 `.gitkeep` | W6（5/11）|
| Finance（M-13 ~ M-16f）| 同上 | W12（6/22）|
| Workorders（M-17 ~ M-19a）| 同上 | W10（6/8）|
| Subleases（M-20 ~ M-23）| 同上 | W16（7/20）|

---

## 五、里程碑口径对照

| 里程碑 | 完成标准 | 当前状态 |
|--------|---------|---------|
| **L1 主数据可用** | 资产台账、CAD 展示、导入工具通过样本验证；导入批次可追溯 | 🔄 进行中（后端完成，Flutter 端缺失）|
| L2 业财闭环可用 | 合同、递增、账单、核销、NOI 全链路打通 | ⏳ 未开始 |
| L3 运营闭环可用 | 工单、二房东填报、审核、看板 | ⏳ 未开始 |
| L4 上线准备完成 | 安全、审计、失败补偿、验收样本全部闭环 | ⏳ 未开始 |

---

## 六、主要风险

| 风险 | 严重度 | 说明 |
|------|--------|------|
| Flutter 资产模块（FE-03/FE-04）缺失 | 🔴 高 | 距 M1 截止（5/8）仅 1.5 周，`features/assets/` 仅有 README，四层全部未开始 |
| uni-app 业务 store 全部缺失 | 🟡 中 | 页面骨架已建，但无数据层，无法完整运行 |
| Admin contracts/finance/workorders/subleases 无 API 模块和 Store | 🟡 中 | 视图 shell 已就位，但无法联调 |

---

## 七、超前亮点

| 项目 | 计划阶段 | 实际完成 |
|------|---------|---------|
| 数据库迁移（22 脚本） | B1~B5 分批 | 全部提前完成，覆盖 v1.7/v1.8 所有新增表 |
| Org 模块（departments + managed_scope）| B4 阶段 | 当前 W4 已完成 |
| Admin 系统管理视图（用户/部门） | F4 阶段 | 当前 W4 已完成 |
| uni-app 主要 API 模块 | F2~F4 阶段 | contracts/finance/workorders 已完成 |

---

## 八、当前最优先行动建议

1. **立即启动 Flutter 资产模块**（FE-03/FE-04）——推荐使用 `PropOS Feature Builder` Agent，整体编排 `features/assets/` 四层（domain/data/BLoC/Pages）。
2. **补全 uni-app 业务 store**——至少完成 `assets.ts` / `contracts.ts` 以支撑现有页面联调。
3. **补全 Admin API 模块 + Store**——contracts / finance / workorders / subleases 四个模块依次推进，使现有视图 shell 可运行。

---

*本报告由 GitHub Copilot 根据代码库实际状态自动生成，如有差异请以代码库为准。*
