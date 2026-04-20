# PropOS × Copilot 能力边界说明

> **版本**: v1.0  
> **日期**: 2026-04-20  
> **用途**: 客观记录 GitHub Copilot（Claude Sonnet 4.6）在本项目当前配置下的真实能力范围，避免过度依赖或错误预期。

---

## 一、当前配置状态

### 1.1 已配置的 Instructions（截至 2026-04-20）

| 文件 | 触发路径 | 状态 |
|------|---------|:----:|
| `copilot-instructions.md` | 全局（所有对话） | ✅ |
| `flutter.instructions.md` | `flutter_app/lib/**` | ✅ |
| `flutter-ui-spec.instructions.md` | `lib/**/presentation/**`, `lib/shared/widgets/**`, `lib/core/router/**` | ✅ |
| `api-contract.instructions.md` | API 相关路径（前后端 data 层） | ✅ |
| `backend-controller.instructions.md` | `backend/lib/**/controllers/**` | ✅ |
| `backend-repository.instructions.md` | `backend/lib/**/repositories/**` | ✅ |
| `backend-service.instructions.md` | `backend/lib/**/services/**` | ✅ |
| `dart-package.instructions.md` | `backend/packages/**` | ✅ |
| `database-migration.instructions.md` | `backend/lib/**/migrations/**` | ✅ |
| `vue-admin.instructions.md` | `admin/src/**` | ✅ |
| `security-checklist.instructions.md` | 无（按需 `@` 引用） | ✅ |

### 1.2 已配置的权威文档引用（Instructions 内已明确指向）

| 文档 | 行数 | 覆盖内容 |
|------|------|---------|
| `docs/backend/API_CONTRACT_v1.7.md` | 4866 行 | 全端点字段级 Request/Response 定义 |
| `docs/backend/API_INVENTORY_v1.7.md` | 593 行 | 端点清单与权限矩阵 |
| `docs/backend/ERROR_CODE_REGISTRY.md` | — | 业务错误码注册表 |
| `docs/frontend/PAGE_SPEC_FLUTTER_v1.9.md` | 2553 行 | Flutter 页面组件树与交互规格 |
| `docs/frontend/PAGE_WIREFRAMES_v1.8.md` | 2754 行 | ASCII 线框图布局原型 |

### 1.3 项目代码完成度（截至 2026-04-20）

| 模块 | 完成度 | 已有文件数 |
|------|:------:|:--------:|
| `auth`（认证） | ████████░░ ~80% | 10 |
| `core`（基础设施） | ███████░░░ ~70% | 24 |
| `shared`（共享组件） | ██████░░░░ ~60% | 7 |
| `assets`（资产） | ░░░░░░░░░░ 0% | 0 |
| `contracts`（合同） | ░░░░░░░░░░ 0% | 0 |
| `dashboard`（首页） | ░░░░░░░░░░ 0% | 0 |
| `finance`（财务） | ░░░░░░░░░░ 0% | 0 |
| `workorders`（工单） | ░░░░░░░░░░ 0% | 0 |
| `subleases`（二房东） | ░░░░░░░░░░ 0% | 0 |

---

## 二、Copilot 能做好的事

### 2.1 单模块四层骨架生成

给出明确的模块名和参考文档后，Copilot 能一次性生成符合规范的完整四层结构：

```
domain/entities/xxx.dart           ← @freezed 实体
domain/repositories/xxx_repo.dart  ← 抽象接口
data/models/xxx_model.dart         ← @freezed DTO + json_serializable
data/repositories/xxx_repo_impl.dart ← Repository 实现
presentation/bloc/xxx_cubit.dart   ← BLoC/Cubit 四态
presentation/pages/xxx_page.dart   ← Page Widget
presentation/widgets/             ← 子 Widget 拆分
```

**前提**：提示词中明确指向 `PAGE_SPEC_FLUTTER_v1.9.md` 对应章节 + `API_CONTRACT_v1.7.md` 对应端点。

### 2.2 字段名契约遵从

配置了 `api-contract.instructions.md` 后，Copilot 在生成 DTO 和 Repository 时会主动查阅 `API_CONTRACT_v1.7.md`，字段名与 API 契约一致性显著提升。

### 2.3 架构规范遵守

- BLoC 状态四态 + `switch` 渲染
- `ThemeExtension` 取色（不硬编码 `Colors.xxx`）
- `go_router` 路由（不用 `Navigator.push`）
- `PaginatedCubit` 基类复用（不重复手写分页逻辑）
- 错误处理统一 `emit(XxxState.error(...))`

### 2.4 纯计算逻辑实现

提供公式定义后，Copilot 能生成带单元测试的纯函数实现，适用于：

- `packages/rent_escalation_engine`（6 种递增类型）
- `packages/kpi_scorer`（线性插值打分）
- NOI / WALE 计算

### 2.5 代码补全与重构

在已有文件内做字段增补、接口调整、Bug 修复时，Copilot 的精确度最高，副作用最小。

---

## 三、Copilot 做不好的事（需人工介入）

### 3.1 跨对话一致性漂移 ⚠️

**问题**：每次对话的上下文窗口独立，第 5 个模块生成时可能忘记第 1 个模块已建立的约定（如命名风格、错误处理模式）。

**风险点**：
- 同样功能的 Cubit，不同对话生成的 state 字段名不一致
- 后生成的 Widget 复用了已有组件，但用了过时的调用签名

**应对**：每隔 2-3 个模块后运行 `flutter analyze`，让 Copilot 修复后再继续。

### 3.2 业务规则歧义处理 ⚠️

**问题**：文档中存在歧义时，Copilot 会"合理猜测"而不报错，生成的代码看起来正确但行为错误。

**高风险场景**：
- 合同状态机的转换守卫条件（`CONTRACT_STATE_MACHINE.md`）
- 租金递增的混合分段边界计算
- KPI 打分的线性插值边缘值处理
- 二房东行级数据隔离的 SQL WHERE 条件

**应对**：这类逻辑必须人工对照文档 review，不能只靠编译通过来验证。

### 3.3 依赖注入完整性 ⚠️

**问题**：`core/di/injection.dart` 每新增一个模块就需要注册新的 Repository 和 Cubit，Copilot 经常遗漏。

**后果**：运行时 `getIt<XxxCubit>()` 抛出未注册异常，不会在编译期报错。

**应对**：每完成一个模块后手动检查 `injection.dart`，或在提示词中明确要求"同步更新 `injection.dart`"。

### 3.4 Mock 数据覆盖完整性 ⚠️

**问题**：新增接口后，`core/api/mock/mock_interceptor.dart` 不会自动补充对应 Mock 路由，导致 `FLUTTER_USE_MOCK=true` 时新接口返回 404。

**应对**：在提示词中明确要求"同步创建 `xxx_mock.dart` 并注册到 `mock_interceptor.dart`"。

### 3.5 pubspec.yaml 版本冲突 ⚠️

**问题**：Copilot 可能建议添加与现有依赖版本不兼容的包，或忽略 HarmonyOS 平台兼容性限制。

**应对**：依赖变更前先咨询，`flutter pub get` 后检查 `pubspec.lock`，不要让 Copilot 自行决定版本号。

### 3.6 测试逻辑覆盖质量 ⚠️

**问题**：Copilot 生成的 BLoC 单元测试往往只覆盖 happy path，边界值、异常分支、并发场景容易缺失。

**应对**：生成测试后人工补充边界 case，尤其是：
- 网络错误时的 state 转换
- 空列表 / 单条数据的分页 meta
- 权限不足时的 Cubit 行为

### 3.7 超过上下文窗口的大型重构 ❌

**问题**：涉及 10+ 个文件的大规模重构（如全局改字段名、跨模块 API 路径调整），Copilot 在一次对话中无法可靠完成。

**应对**：拆分为多次对话，每次聚焦 1-2 个文件；或使用 `vscode_renameSymbol` 工具做语义级重命名。

---

## 四、效果最佳的提示词模式

### 4.1 单模块完整实现

```
实现 [模块名] 模块的 Flutter 端：

参考文档：
- PAGE_SPEC_FLUTTER_v1.9.md [章节X.X]（Widget 树定义）
- API_CONTRACT_v1.7.md [端点名]（字段定义）

要求：
1. 完整三层结构（domain + data + presentation）
2. 同步更新 core/di/injection.dart
3. 同步创建对应 Mock 文件
4. 路由路径常量加入 route_paths.dart
```

### 4.2 单页面 UI 实现

```
实现 [页面名]（路由 [路径]）：

参考 PAGE_SPEC_FLUTTER_v1.9.md [章节X.X] 的 Widget 树。
使用已有的共享组件：StatusTag / MetricCard / PaginatedListView。
状态渲染使用 switch pattern matching，不用 if (state is Xxx)。
颜色通过 Theme.of(context).colorScheme 和 CustomColors 扩展获取。
```

### 4.3 Bug 修复 / 字段调整

```
修复 [文件路径] 的 [问题描述]。
字段名以 API_CONTRACT_v1.7.md 的 [端点名] 为准。
不要修改其他无关代码。
```

---

## 五、逐模块推进建议

每个模块完成后必须执行，再推进下一个：

```bash
# 1. 静态分析
flutter analyze lib/features/[module]/

# 2. 运行已有测试
flutter test test/features/[module]/

# 3. 检查 DI 注册
grep "[ModuleName]" lib/core/di/injection.dart

# 4. 检查路由注册
grep "[routePath]" lib/core/router/app_router.dart

# 5. 检查 Mock 覆盖
grep "[apiPath]" lib/core/api/mock/mock_interceptor.dart
```

---

## 六、需要人工决策的场景清单

以下场景 **不要** 直接让 Copilot 输出结论，需要人工判断后再让 Copilot 执行：

| 场景 | 风险 | 正确做法 |
|------|------|---------|
| 修改已上线的数据库 Migration | 不可逆，数据丢失 | 人工审查 SQL，再运行 |
| 变更 RBAC 权限规则 | 可能开放本不该开放的接口 | 对照 `RBAC_MATRIX.md` 人工确认 |
| 修改 `JWT_SECRET` / `ENCRYPTION_KEY` | 所有在线 Token 失效 | 只由人工修改 |
| 新增外部依赖包 | 版本冲突 / 许可证风险 | 人工确认版本后再让 Copilot 更新 |
| 合同状态机新增转换路径 | 业务数据状态不一致 | 对照 `CONTRACT_STATE_MACHINE.md` 人工确认 |
| 证件号 / 手机号字段的处理逻辑 | 数据泄露风险 | 必须 Code Review，不能只信任生成结果 |
