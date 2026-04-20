---
description: "Use when designing or implementing Flutter page UI, widgets, navigation structure, or route definitions. Enforces PAGE_SPEC_FLUTTER_v1.9 and PAGE_WIREFRAMES_v1.8 as the single source of truth for all UI layout and component decisions."
applyTo: |
  flutter_app/lib/**/presentation/pages/**
  flutter_app/lib/**/presentation/widgets/**
  flutter_app/lib/shared/widgets/**
  flutter_app/lib/core/router/**
---

# Flutter UI 规格约束（PropOS）

> **权威文档**（设计或实现任何页面、Widget、路由前必须先查阅）：
> - 页面组件树 & 交互规格：[`docs/frontend/PAGE_SPEC_FLUTTER_v1.9.md`](../../../docs/frontend/PAGE_SPEC_FLUTTER_v1.9.md)
> - 页面布局线框图（ASCII 原型）：[`docs/frontend/PAGE_WIREFRAMES_v1.8.md`](../../../docs/frontend/PAGE_WIREFRAMES_v1.8.md)
>
> 当代码与规格文档冲突时，**以文档为准**，不得自行设计布局或发明 Widget 树结构。

---

## 1. 全局导航结构

Flutter 移动端采用 `go_router` + `StatefulShellRoute`（5 个 Tab 保持独立页面栈）：

| Tab | 路径 | 图标 | 标签 |
|-----|------|------|------|
| 1 | `/dashboard` | `Icons.dashboard` | 首页 |
| 2 | `/assets` | `Icons.apartment` | 资产 |
| 3 | `/contracts` | `Icons.description` | 合同 |
| 4 | `/workorders` | `Icons.build` | 工单 |
| 5 | `/finance` | `Icons.account_balance` | 财务 |

- 底部导航使用 Material 3 `NavigationBar`（非 `BottomNavigationBar`）
- Tab 可见性依据 `AuthCubit.state.role` 控制，权限不足时**不渲染**对应 `NavigationDestination`
- 路由路径常量统一放 `core/router/route_paths.dart`
- 禁止使用 `Navigator.push/pop`，统一用 `context.go()` / `context.push()` / `context.pop()`

### 完整子页面路由表

实现任何页面前，先在此表确认路由路径：

| 页面 | 路径 | 是否 Tab |
|------|------|:--------:|
| 登录 | `/login` | — |
| 首页 | `/dashboard` | ✅ |
| NOI 分析 | `/dashboard/noi-detail` | — |
| WALE 分析 | `/dashboard/wale-detail` | — |
| 资产总览 | `/assets` | ✅ |
| 楼栋详情 | `/assets/buildings/:id` | — |
| 楼层热区图 | `/assets/buildings/:bid/floors/:fid` | — |
| 房源详情 | `/assets/units/:id` | — |
| 合同管理 | `/contracts` | ✅ |
| 合同详情 | `/contracts/:id` | — |
| 财务总览 | `/finance` | ✅ |
| 账单列表 | `/finance/invoices` | — |
| KPI 考核 | `/finance/kpi` | — |
| 催收记录 | `/finance/dunning` | — |
| 工单管理 | `/workorders` | ✅ |
| 工单详情 | `/workorders/:id` | — |
| 新建工单 | `/workorders/new` | — |
| 二房东管理 | `/subleases` | — |
| 二房东详情 | `/subleases/:id` | — |
| 通知中心 | `/notifications` | — |
| 审批队列 | `/approvals` | — |

---

## 2. 状态色语义（禁止硬编码颜色）

所有状态色必须通过 `Theme.of(context)` 和 `ThemeExtension<CustomColors>` 获取，**禁止** `Colors.xxx` 或 `Color(0xFF...)`。

| 状态语义 | Flutter token | 典型状态值 |
|---------|--------------|-----------|
| 已租 / 已核销 / 已通过 | `customColors.success` | `leased` `paid` `approved` |
| 即将到期 / 预警 / 待审核 | `customColors.warning` | `expiring_soon` `pending` |
| 空置 / 逾期 / 已拒绝 | `colorScheme.error` | `vacant` `overdue` `rejected` |
| 非可租 / 已作废 | `colorScheme.outline` | `non_leasable` `cancelled` |
| 执行中 / 处理中 / 草稿 | `colorScheme.primary` | `active` `in_progress` `draft` |

---

## 3. 通用 Widget 规范

以下 Widget 已在规格书中定义，**直接复用，不重复自建**。

### StatusTag

```dart
StatusTag(status: String)
// 通过 Theme.of(context).extension<CustomColors>() 取色
// 禁止在 StatusTag 内部硬编码颜色
```

### PaginatedListView（分页列表，替代手写 ScrollController）

```dart
PaginatedListView<T>(
  cubit: PaginatedCubit<T>,
  itemBuilder: (context, item) => Widget,
)
```

四态渲染：`initial/loading` → `CircularProgressIndicator`；`loaded` → `RefreshIndicator` + `ListView.builder`（触底加载更多）；`error` → `ErrorRetryWidget`

### MetricCard（指标卡）

```dart
MetricCard(title: String, value: String, {String? subtitle, VoidCallback? onTap})
```

### FilterChipBar（筛选标签栏）

```dart
FilterChipBar(
  options: List<FilterOption>,
  selected: String?,
  onSelected: (String?) => void,
)
// 内部使用 SingleChildScrollView(horizontal) + FilterChip
```

### 表单模式

所有表单统一使用 `Form` + `TextFormField` + `GlobalKey<FormState>`，提交逻辑放 Cubit。

---

## 4. BlocBuilder 状态渲染模板

**必须**使用 Dart 3 `switch` expression，禁止散落 `if (state is Xxx)`：

```dart
BlocBuilder<XxxCubit, XxxState>(
  builder: (context, state) => switch (state) {
    XxxInitial() => const SizedBox.shrink(),
    XxxLoading() => const Center(child: CircularProgressIndicator()),
    XxxLoaded(:final data) => _buildContent(data),
    XxxError(:final message) => ErrorRetryWidget(
      message: message,
      onRetry: () => context.read<XxxCubit>().fetch(),
    ),
  },
)
```

---

## 5. 页面复杂度限制

| 类型 | 行数上限 | 超限处理 |
|------|---------|---------|
| `*_page.dart` | 150 行 | 将子区域提取到 `widgets/` 下独立私有组件 |
| `*_widget.dart` | 100 行 | 继续拆分为更小的组合 Widget |

---

## 6. 实现新页面的检查清单

在生成任何页面代码前，先完成以下确认：

- [ ] 在 `PAGE_SPEC_FLUTTER_v1.9.md` 中找到该页面的 Flutter Widget 树定义
- [ ] 在 `PAGE_WIREFRAMES_v1.8.md` 中查看对应的 ASCII 线框图布局
- [ ] 路由路径与上方路由表一致，并已在 `route_paths.dart` 中定义常量
- [ ] 状态色通过 `ThemeExtension` / `colorScheme` 获取，无硬编码颜色
- [ ] 使用规格书定义的通用 Widget（`StatusTag` / `MetricCard` / `PaginatedListView` 等）
- [ ] BLoC 状态渲染使用 `switch` pattern matching
- [ ] Page ≤ 150 行，Widget ≤ 100 行
