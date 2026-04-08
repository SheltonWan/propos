---
description: "Use when writing or editing Flutter UI layer — Pages or Widgets. Enforces color token usage, .when() state rendering, no business logic in Widgets, and go_router navigation."
applyTo: ["frontend/lib/**/pages/**", "frontend/lib/**/widgets/**"]
---

# Flutter UI 层约束

> 全局规则见 `.github/copilot-instructions.md`，本文件补充 pages / widgets 层特有强制规则。

## 颜色：只用 Theme Token，绝对禁止硬编码

```dart
// ✅ 正确 — 通过 colorScheme 取语义色
final color = switch (unit.status) {
  UnitStatus.leased       => theme.colorScheme.secondary,     // 绿色系
  UnitStatus.expiringSoon => theme.colorScheme.tertiary,      // 橙/黄色系
  UnitStatus.vacant       => theme.colorScheme.error,         // 红色系
  UnitStatus.nonLeasable  => theme.colorScheme.outlineVariant,// 灰色
  _                       => theme.colorScheme.outline,
};

// ❌ 禁止硬编码任何颜色
Color(0xFF4CAF50)
Colors.green
Colors.red.shade700
```

字号/间距同理：通过 `Theme.of(context).textTheme.bodyMedium` 取，不写 `fontSize: 14`。

## State 渲染：必须用 `.when()`

```dart
// ✅ 正确
BlocBuilder<ContractListBloc, ContractState>(
  builder: (context, state) => state.when(
    initial: () => const SizedBox.shrink(),
    loading: () => const Center(child: CircularProgressIndicator()),
    loaded:  (result) => _ContractList(contracts: result.items),
    error:   (msg) => _ErrorView(message: msg),
  ),
),

// ❌ 禁止散落的类型判断
if (state is ContractLoaded) ...
if (state is ContractError) ...
```

## Widget 职责铁律

Widget 中**不得出现**：
- HTTP 调用（`Dio`、`http` 等）
- 日期计算、业务判断、状态机逻辑
- `DateTime.now()`（日历组件除外，且须通过依赖注入）
- 直接实例化 Repository 或 Service

## 导航：go_router

```dart
// ✅
context.go(AppRoutes.contractDetail(id));
context.push(AppRoutes.createContract);

// ❌ 禁止
Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailPage(id: id)));
```

路由路径常量定义在 `lib/shared/constants/api_paths.dart`（或专用 `app_routes.dart`）。

## 分页常量

```dart
// ✅
import 'package:propos/shared/constants/ui_constants.dart';
pageSize: kDefaultPageSize  // = 20

// ❌
pageSize: 20
```

## BLocProvider 注入（页面顶层）

```dart
// 页面顶层包裹 BlocProvider，BLoC 通过 get_it 解析
BlocProvider(
  create: (_) => getIt<ContractListBloc>()..add(const LoadContracts()),
  child: const ContractListView(),
)
```

Widget 测试中通过传入 `FakeContractListBloc` 来替代真实 BLoC，不依赖 get_it。

## 复杂度控制

`*_page.dart` 超过 **150 行** 或 `build()` 嵌套超 **4 层** → 将子区域提取到 `widgets/` 下私有组件，页面只保留顶层组合。

## 平台适配

扫码等平台差异功能：

```dart
// ✅ 集中判断
if (PlatformUtils.supportsQrScan) _buildScanButton(),

// ❌ 不在 Widget 中直接写 kIsWeb / Platform.isIOS
```
