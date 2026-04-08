# PropOS Flutter 前端页面规格文档 v1.7

> **文档版本**: v1.0  
> **日期**: 2026-04-08  
> **依据**: PRD v1.7 / ARCH v1.2 / API_INVENTORY v1.7 / API_CONTRACT v1.7 / SWIMLANE_PLAN v1.7  
> **范围**: Phase 1 全部 Flutter 页面（Web 管理后台 + App 移动端 + 二房东门户）  
> **设计体系**: Material 3（`useMaterial3: true`），所有色彩/字号/间距通过 `Theme.of(context)` 取值

---

## 目录

1. [全局导航结构](#一全局导航结构)
2. [通用组件规范](#二通用组件规范)
3. [认证模块页面](#三认证模块页面)
4. [概览 Dashboard 模块](#四概览-dashboard-模块)
5. [资产模块页面](#五资产模块页面)
6. [租务与合同模块页面](#六租务与合同模块页面)
7. [财务模块页面](#七财务模块页面)
8. [工单模块页面](#八工单模块页面)
9. [二房东门户模块页面](#九二房东门户模块页面)
10. [系统设置模块页面](#十系统设置模块页面)
11. [响应式断点与布局策略](#十一响应式断点与布局策略)
12. [状态色语义映射速查](#十二状态色语义映射速查)

---

## 一、全局导航结构

### 1.1 主导航骨架 `MainScaffold`

**路由**: `ShellRoute` 包裹所有主导航页面

**Web/桌面端布局**（宽度 ≥ 840px）:

```
┌──────────────────────────────────────────────────────────────┐
│  AppBar: Logo + 标题 "PropOS"  |  未读预警 Badge  |  头像菜单 │
├──────────┬───────────────────────────────────────────────────┤
│          │                                                    │
│  侧边栏   │            主内容区域（child）                      │
│  Nav Rail │                                                    │
│          │                                                    │
│  📊 概览  │                                                    │
│  🏢 资产  │                                                    │
│  📋 租务  │                                                    │
│  💰 财务  │                                                    │
│  🔧 工单  │                                                    │
│          │                                                    │
│  ─────── │                                                    │
│  ⚙ 设置  │                                                    │
└──────────┴───────────────────────────────────────────────────┘
```

**移动端布局**（宽度 < 840px）:

```
┌──────────────────────────────────────────────────────────────┐
│  AppBar: ≡ Drawer 按钮 | 页面标题 | 未读预警 Badge | 头像     │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│                     主内容区域（child）                          │
│                                                                │
├──────────────────────────────────────────────────────────────┤
│  概览  |  资产  |  租务  |  财务  |  工单                      │
│  BottomNavigationBar（5 个 Tab）                               │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 角色路由访问矩阵

| 路由路径 | 超级管理员 | 运营管理层 | 租务专员 | 财务人员 | 前线员工 | 二房东 |
|---------|:--------:|:--------:|:------:|:------:|:------:|:----:|
| `/dashboard` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `/assets/**` | ✅ | ✅ | ✅(只读) | ✅(只读) | ✅(只读) | ❌ |
| `/contracts/**` | ✅ | ✅ | ✅ | ✅(只读) | ❌ | ❌ |
| `/tenants/**` | ✅ | ✅ | ✅ | ✅(只读) | ✅(只读) | ❌ |
| `/finance/**` | ✅ | ✅(只读) | ✅(只读) | ✅ | ❌ | ❌ |
| `/workorders/**` | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| `/sublease-portal/**` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| `/settings/**` | ✅ | ✅(部分) | ❌ | ❌ | ❌ | ❌ |

### 1.3 AppBar 组件树

```
AppBar
├── Leading: Logo 图标 / Drawer 按钮（移动端）
├── Title: Text("PropOS")
└── Actions:
    ├── IconButton(预警铃铛)
    │   └── Badge(count: unreadAlertCount)  // 30s 轮询 /api/alerts/unread
    └── PopupMenuButton(头像)
        ├── MenuItem: 个人信息
        ├── MenuItem: 修改密码 → /auth/change-password
        └── MenuItem: 退出登录
```

---

## 二、通用组件规范

### 2.1 数据表格 `ProposDataTable`

所有列表页面统一使用的分页数据表格组件：

| 属性 | 说明 |
|------|------|
| 分页 | 底部分页栏，`page` 从 1 开始，`pageSize` 默认 20，可选 10 / 20 / 50 |
| 排序 | 列头点击切换排序，`sortBy` + `sortOrder` 传入 BLoC |
| 筛选 | 表头上方筛选栏，按列提供 TextField / Dropdown / DateRange |
| 空态 | 无数据时展示插图 + "暂无数据" 文案 |
| 加载态 | Shimmer 骨架屏占位 |
| 错误态 | ErrorWidget + 重试按钮 |

### 2.2 状态标签 `StatusChip`

```
StatusChip
├── Container(borderRadius: 12, padding: EdgeInsets.symmetric(h:12, v:4))
│   └── Text(statusLabel, style: TextStyle(color: foreground, fontSize: 12))
└── 背景色 + 前景色由 status → Theme Token 映射（见第十二节）
```

### 2.3 统计卡片 `MetricCard`

Dashboard 和各模块概览页复用：

```
MetricCard
├── Container(elevation: 1, borderRadius: 12)
│   ├── Row
│   │   ├── Icon(metricIcon, size: 40, color: colorScheme.primary)
│   │   └── Column(crossAxisAlignment: start)
│   │       ├── Text(label, style: titleSmall, color: onSurfaceVariant)
│   │       └── Text(value, style: headlineMedium, color: onSurface)
│   └── 可选: TrendIndicator(↑/↓ + 百分比, color: green/red)
```

### 2.4 表单页通用结构

```
Scaffold
├── AppBar(title: "新建XXX" / "编辑XXX", actions: [保存按钮])
└── SingleChildScrollView
    └── Form(key: _formKey)
        └── Column(children: [
            SectionHeader("基本信息"),
            TextFormField(...),
            TextFormField(...),
            SectionHeader("详细配置"),
            ...
            SizedBox(height: 80),  // 留白防止被键盘遮挡
        ])
```

### 2.5 BLoC 状态分支渲染

所有页面统一使用 `freezed` sealed union + `.when()` 模式：

```dart
BlocBuilder<XxxBloc, XxxState>(
  builder: (context, state) => state.when(
    initial:  () => const SizedBox.shrink(),
    loading:  () => const ShimmerPlaceholder(),
    loaded:   (data) => _buildContent(data),
    error:    (message) => ErrorRetryWidget(message: message, onRetry: ...),
  ),
)
```

### 2.6 确认弹窗 `ProposConfirmDialog`

全局统一确认弹窗，禁止在页面中裸写 `showDialog` + `AlertDialog`。

**三种变体**：

| 变体 | 使用场景 | 主按钮色 |
|------|---------|--------|
| `ProposConfirmDialog.normal` | 普通确认（提交审核、派单） | `colorScheme.primary` |
| `ProposConfirmDialog.danger` | 不可逆操作（终止合同、作废账单、删除用户） | `colorScheme.error` |
| `ProposConfirmDialog.withInput` | 需要输入理由/金额（退回原因、冲抵金额） | 按语义选 `primary` 或 `error` |

**组件树**：

```
Dialog(shape: RoundedRectangleBorder(borderRadius: AppRadius.xl))
└── Padding(all: AppSpacing.lg)
    └── Column(mainAxisSize: min)
        ├── Icon(警示图标, size: 48)
        │   ├── normal → Icons.help_outline, color: primary
        │   └── danger → Icons.warning_amber_rounded, color: error
        ├── SizedBox(h: AppSpacing.md)
        ├── Text(title, style: headlineMedium, textAlign: center)
        ├── SizedBox(h: AppSpacing.sm)
        ├── Text(message, style: bodyMedium, color: onSurfaceVariant, textAlign: center)
        ├── ── withInput 变体追加 ──
        │   SizedBox(h: AppSpacing.md)
        │   TextFormField(controller, validator, maxLines, decoration)
        ├── SizedBox(h: AppSpacing.lg)
        └── Row(mainAxisAlignment: end)
            ├── OutlinedButton("取消", onPressed: Navigator.pop)
            ├── SizedBox(w: AppSpacing.sm)
            └── FilledButton(
                  confirmLabel,
                  style: danger ? FilledButton.styleFrom(backgroundColor: error) : null,
                  onPressed: → _onConfirm,
                )
```

**异步提交状态**（弹窗内按钮须处理 loading）：

```
点击确认按钮
  → 主按钮变为 CircularProgressIndicator（尺寸 20）+ 禁用取消按钮
  → await onConfirm() 回调
  ├── 成功 → Navigator.pop(true) → 外层根据返回值执行后续
  └── 失败 → 恢复按钮 + 弹窗内底部显示错误提示文本（红色）
  （弹窗不关闭，用户可重试或取消）
```

**调用方式统一封装**：

```dart
// lib/shared/widgets/propos_confirm_dialog.dart
final confirmed = await ProposConfirmDialog.danger(
  context: context,
  title: '终止合同',
  message: '终止后未来账单将自动取消，此操作不可撤销。',
  confirmLabel: '确认终止',
  onConfirm: () => bloc.add(TerminateContractEvent(id)),
);
```

### 2.7 Toast / SnackBar `ProposToast`

基于 `ScaffoldMessenger.showSnackBar` 封装，禁止在页面中裸写 `ScaffoldMessenger.of(context).showSnackBar`。

**四种语义**：

| 语义 | 图标 | 背景色 | 前景色 | 时长 | 示例 |
|------|------|--------|--------|------|------|
| `success` | `Icons.check_circle` | `colorScheme.secondaryContainer` | `colorScheme.onSecondaryContainer` | 3s | "合同保存成功" |
| `error` | `Icons.error` | `colorScheme.errorContainer` | `colorScheme.onErrorContainer` | 5s | "保存失败: 网络异常" |
| `warning` | `Icons.warning_amber` | `colorScheme.tertiaryContainer` | `colorScheme.onTertiaryContainer` | 4s | "该合同即将到期" |
| `info` | `Icons.info_outline` | `colorScheme.surfaceContainerHighest` | `colorScheme.onSurface` | 3s | "已复制到剪贴板" |

**组件树**：

```
SnackBar(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
  margin: EdgeInsets.only(bottom: 24, left: 24, right: 24),
  duration: Duration(seconds: variant.duration),
  backgroundColor: variant.backgroundColor,
  content: Row(
    children: [
      Icon(variant.icon, color: variant.foreground, size: 20),
      SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(message, style: bodyMedium.copyWith(color: variant.foreground))),
    ],
  ),
  action: SnackBarAction(label: actionLabel, onPressed: onAction),  // 可选：如"撤销"
)
```

**位置规则**：
- 移动端：底部浮动（避开 BottomNavigationBar，margin-bottom ≥ 80）
- 桌面端/Web：底部居中浮动，maxWidth 560

**队列行为**：相同语义的 Toast 覆盖前一条（`ScaffoldMessenger.hideCurrentSnackBar` 后再 `show`），不堆叠。

### 2.8 加载状态 `ProposLoadingOverlay`

**三种使用场景及对应方案**：

| 场景 | 方案 | 说明 |
|------|------|------|
| 页面级加载 | `ShimmerPlaceholder` 骨架屏 | BLoC `loading` state → 2.5 节的 `.when()` 渲染 |
| 全屏阻塞操作 | `ProposLoadingOverlay` | 提交表单、批量导入等需要阻止一切交互的场景 |
| 按钮级加载 | 按钮内 `SizedBox(16×16, CircularProgressIndicator(strokeWidth: 2))` | 单个按钮的提交态（如弹窗确认按钮） |

**`ProposLoadingOverlay` 组件树**：

```
Stack
├── child  // 被遮挡的页面内容
└── if (isLoading)
    Positioned.fill(
      child: ColoredBox(
        color: colorScheme.scrim.withOpacity(0.32),
        child: Center(
          child: Card(
            child: Padding(all: AppSpacing.lg)
              └── Column(mainAxisSize: min)
                  ├── CircularProgressIndicator()
                  ├── SizedBox(h: AppSpacing.md)
                  └── Text(message ?? "处理中...", style: bodyMedium)
          ),
        ),
      ),
    )
```

**使用规则**：
- `isLoading` 由 BLoC 的 `submitting` 状态驱动，**不在 Widget 中维护 `setState`**
- 全屏遮罩必须阻止物理返回键（`WillPopScope` / `PopScope` 拦截）
- 骨架屏用于首次加载；全屏遮罩用于写操作提交；不得混用

### 2.9 BlocListener 反馈模式

**规则**：BLoC 禁止直接触发 UI 副作用。所有操作反馈通过 `BlocListener` 在 Widget 层统一响应。

**标准模式**：

```dart
BlocListener<XxxBloc, XxxState>(
  listenWhen: (prev, curr) => prev != curr,
  listener: (context, state) => state.whenOrNull(
    // 提交成功 → 显示成功 Toast + 页面跳转/返回
    submitted: () {
      ProposToast.success(context, '保存成功');
      context.pop();  // 或 context.go(targetRoute)
    },
    // 操作失败 → 显示错误 Toast（弹窗内的错误不走这里）
    error: (message) {
      ProposToast.error(context, message);
    },
    // 删除/终止等不可逆操作成功
    deleted: () {
      ProposToast.success(context, '已删除');
      context.pop();
    },
  ),
)
```

**与 `ProposLoadingOverlay` 配合**：

```dart
// 典型表单页 build()
BlocConsumer<ContractFormCubit, ContractFormState>(
  listener: (context, state) => state.whenOrNull(
    submitted: () { ProposToast.success(context, '合同已保存'); context.pop(); },
    error:     (msg) => ProposToast.error(context, msg),
  ),
  builder: (context, state) => ProposLoadingOverlay(
    isLoading: state.maybeWhen(submitting: () => true, orElse: () => false),
    message: '正在保存合同...',
    child: _buildForm(),
  ),
)
```

### 2.10 弹窗选型规则

| 弹窗类型 | 移动端（< 840px） | 桌面端/Web（≥ 840px） | 适用场景 |
|---------|:----------------:|:-------------------:|------|
| `ProposConfirmDialog` | 居中 Dialog | 居中 Dialog | 二次确认、危险操作确认 |
| 带输入弹窗 | 居中 Dialog | 居中 Dialog | 退回原因、冲抵金额、审批备注 |
| 单选/多选列表 | `showModalBottomSheet` | 居中 Dialog | 指派处理人、选择模板、业态筛选 |
| 详情预览 | `DraggableScrollableSheet` | 侧边 Drawer 或 Dialog | 楼层图单元详情、快速预览 |
| 日期/时间选取 | 系统原生 Picker | 系统原生 Picker | DatePicker、TimePicker |

**通用约定**：
- 弹窗外部点击（barrier tap）：确认类弹窗**不可**关闭（`barrierDismissible: false`）；信息预览类**可**关闭
- 弹窗最大宽度：Dialog ≤ 560px；BottomSheet 高度 ≤ 屏幕 85%
- 弹窗圆角：统一 `AppRadius.xl`（16dp）
- 弹窗进入动画：`fadeIn` + `scaleUp`（200ms），系统默认即可，不自定义

### 2.11 暗色模式策略

**Phase 1 不实现暗色模式**。仅预留以下约束确保后续可快速接入：

1. 全部使用 `colorScheme.*` 语义色，**禁止硬编码 `Color(0xFFxxxxxx)`**
2. `AppColors` 中的常量仅用于 `buildAppTheme()` 赋值，Widget 层不直接引用
3. 后续实现时只需增加 `buildDarkAppTheme()` 并在 `MaterialApp` 中设置 `darkTheme` 即可

---

## 三、认证模块页面

### 3.1 登录页 `LoginPage`

**路由**: `/login`  
**BLoC**: `AuthBloc`  
**API**: `POST /api/auth/login`

**布局结构**:

```
Scaffold(backgroundColor: colorScheme.surface)
└── Center
    └── ConstrainedBox(maxWidth: 400)
        └── Card(elevation: 2)
            └── Padding(all: 32)
                └── Column(mainAxisSize: min)
                    ├── Logo + "PropOS" 标题
                    ├── SizedBox(h: 32)
                    ├── TextFormField(邮箱, keyboardType: email)
                    ├── SizedBox(h: 16)
                    ├── TextFormField(密码, obscureText: true)
                    ├── SizedBox(h: 8)
                    ├── Align(right): TextButton("忘记密码？")
                    ├── SizedBox(h: 24)
                    ├── FilledButton.icon("登 录", width: double.infinity)
                    └── 错误提示 AnimatedSwitcher
```

**交互流程**:

```
用户输入邮箱+密码 → 点击"登录"
  → BLoC emit(AuthLoading)
  → 调用 POST /api/auth/login
  ├── 成功 → 存储 JWT → emit(AuthAuthenticated) → GoRouter 跳转 /dashboard
  ├── INVALID_CREDENTIALS → 显示"用户名或密码错误"
  ├── ACCOUNT_LOCKED → 显示"账号已锁定至 {locked_until}"
  ├── ACCOUNT_FROZEN → 显示"账号已冻结"（二房东）
  └── 网络错误 → 显示"网络连接失败，请重试"
```

**特殊逻辑**:
- 二房东账号 `must_change_password == true` 时，登录成功后强制跳转修改密码页
- 密码输入框支持切换明文/密文 `suffixIcon: IconButton(眼睛图标)`

### 3.2 修改密码页 `ChangePasswordPage`

**路由**: 从头像菜单打开，或二房东首登强制跳转  
**API**: `POST /api/auth/change-password`

**布局结构**:

```
Scaffold
└── Center
    └── ConstrainedBox(maxWidth: 400)
        └── Card
            └── Column
                ├── 标题 "修改密码"
                ├── TextFormField(旧密码)
                ├── TextFormField(新密码, 含密码强度指示条)
                ├── TextFormField(确认新密码)
                ├── 密码要求说明文本（8位+大小写+数字）
                └── FilledButton("确认修改")
```

**校验规则**:
- 新密码 ≥ 8 位，含大小写字母 + 数字
- 新密码 ≠ 旧密码
- 两次输入一致

---

## 四、概览 Dashboard 模块

### 4.1 总览页 `DashboardPage`

**路由**: `/dashboard`  
**BLoC**: `DashboardBloc`  
**API**: `GET /api/assets/overview` + `GET /api/noi/summary` + `GET /api/contracts/wale` + `GET /api/alerts/unread`

**Web/桌面端布局**（≥ 1200px 三列网格，840~1200px 两列）:

```
Scaffold
└── SingleChildScrollView
    └── Padding(all: 24)
        └── Column
            ├── Text("运营概览", style: headlineMedium)
            ├── SizedBox(h: 16)
            │
            ├── ── 第一行：核心指标卡片 ──
            │   ResponsiveGridRow(columns: 4)
            │   ├── MetricCard(label: "总出租率", value: "87.5%", icon: 楼栋)
            │   ├── MetricCard(label: "当月 NOI", value: "¥1,234,567", icon: 钱袋)
            │   ├── MetricCard(label: "WALE(收入)", value: "2.35 年", icon: 日历)
            │   └── MetricCard(label: "WALE(面积)", value: "2.18 年", icon: 尺子)
            │
            ├── SizedBox(h: 24)
            │
            ├── ── 第二行：业态出租率分拆 ──
            │   ResponsiveGridRow(columns: 3)
            │   ├── PropertyTypeCard(type: "写字楼", total: 441, leased: 390, rate: "88.4%")
            │   ├── PropertyTypeCard(type: "商铺", total: 25, leased: 22, rate: "88.0%")
            │   └── PropertyTypeCard(type: "公寓", total: 173, leased: 148, rate: "85.5%")
            │
            ├── SizedBox(h: 24)
            │
            ├── ── 第三行：图表区 ──
            │   ResponsiveGridRow(columns: 2)
            │   ├── Card: NOI 近12月趋势折线图
            │   │   └── InkWell → 点击跳转 /dashboard/noi-detail
            │   └── Card: 收款进度环形图（本月应收 vs 实收）
            │
            ├── SizedBox(h: 24)
            │
            ├── ── 第四行：预警汇总 + 快捷入口 ──
            │   ResponsiveGridRow(columns: 2)
            │   ├── Card: 最近预警列表（最多显示 5 条）
            │   │   ├── ListTile(到期预警: 合同 XXX 将于 30 天内到期)
            │   │   ├── ListTile(逾期预警: 租户 XXX 租金逾期 7 天)
            │   │   └── TextButton("查看全部预警" → /settings/alerts)
            │   └── Card: 快捷操作网格
            │       ├── ActionChip("新建合同" → /contracts/new)
            │       ├── ActionChip("提交报修" → /workorders/new)
            │       ├── ActionChip("录入收款" → /finance/invoices)
            │       └── ActionChip("抄表录入" → /finance/meter-readings/new)
            │
            └── SizedBox(h: 24)
```

**移动端布局**（< 840px）: 卡片全部单列排列，图表区域 AspectRatio 16:10

### 4.2 NOI 明细页 `NoiDetailPage`

**路由**: `/dashboard/noi-detail`  
**BLoC**: `NoiDetailBloc`  
**API**: `GET /api/noi/summary` + `GET /api/noi/trend` + `GET /api/noi/breakdown` + `GET /api/noi/vacancy-loss`

**组件树**:

```
Scaffold
├── AppBar(title: "NOI 详情")
└── SingleChildScrollView
    └── Column
        ├── ── 视角切换 ──
        │   SegmentedButton: [应收视角] / [实收视角]
        │
        ├── ── 汇总卡片行 ──
        │   Row(3 cards)
        │   ├── MetricCard("PGI 潜在总收入", ¥xxx)
        │   ├── MetricCard("空置损失", -¥xxx, color: error)
        │   └── MetricCard("NOI 净营运收入", ¥xxx, color: primary)
        │
        ├── ── 业态 NOI 分拆表格 ──
        │   DataTable
        │   │ 列: 业态 | 收入 | 支出 | NOI | 出租率
        │   ├── Row: 写字楼 | ¥xxx | ¥xxx | ¥xxx | 88.4%
        │   ├── Row: 商铺   | ¥xxx | ¥xxx | ¥xxx | 88.0%
        │   └── Row: 公寓   | ¥xxx | ¥xxx | ¥xxx | 85.5%
        │
        ├── ── 近12月 NOI 趋势折线图 ──
        │   LineChart(data: monthlyNoi)
        │
        ├── ── 运营支出构成饼图 ──
        │   PieChart(data: expenseCategories)
        │
        └── ── 空置损失测算列表 ── (Should)
            ExpansionTile("空置损失明细")
            └── DataTable: 单元编号 | 面积 | 参考市场租金 | 月损失额
```

### 4.3 WALE 明细页 `WaleDetailPage`

**路由**: `/dashboard/wale-detail`  
**BLoC**: `WaleDetailBloc`  
**API**: `GET /api/contracts/wale` + `GET /api/contracts/wale/trend`(Should) + `GET /api/contracts/wale/waterfall`(Should)

**组件树**:

```
Scaffold
├── AppBar(title: "WALE 加权平均到期年数")
└── SingleChildScrollView
    └── Column
        ├── ── 汇总卡片 ──
        │   Row(2 cards)
        │   ├── MetricCard("收入加权 WALE", "2.35 年")
        │   └── MetricCard("面积加权 WALE", "2.18 年")
        │
        ├── ── 分维度 WALE 表格 ──
        │   DataTable
        │   │ groupBy 切换: [楼栋] / [业态]
        │   │ 列: 维度 | 收入加权 WALE | 面积加权 WALE | 在租合同数
        │   ├── Row: A座 | 2.50 年 | 2.30 年 | 180
        │   ├── Row: 商铺区 | 3.10 年 | 2.85 年 | 22
        │   └── Row: 公寓楼 | 1.20 年 | 1.15 年 | 148
        │
        ├── ── WALE 趋势折线图 ── (Should: S-02)
        │   LineChart(收入WALE + 面积WALE 双线)
        │
        └── ── 到期瀑布图 ── (Should: S-02)
            BarChart(x: 年份, y: 到期面积/租金)
```

### 4.4 KPI 考核看板 `KpiDashboardPage`

**路由**: `/dashboard/kpi`  
**BLoC**: `KpiDashboardBloc`  
**API**: `GET /api/kpi/schemes` + `GET /api/kpi/scores` + `GET /api/kpi/rankings` + `GET /api/kpi/trends`

**组件树**:

```
Scaffold
├── AppBar(title: "KPI 考核看板", actions: [导出按钮(Excel)])
└── SingleChildScrollView
    └── Column
        ├── ── 方案与周期选择器 ──
        │   Row
        │   ├── DropdownButton(方案列表, onChanged: → 切换方案)
        │   └── DropdownButton(评估周期: 2026Q1 / 2026-03 ...)
        │
        ├── ── 当前用户 KPI 总览 ── (员工视角)
        │   Card
        │   ├── Row: 总分 Text("87.5 分", headlineLarge) + StatusChip("排名 #3")
        │   ├── RadarChart(各指标雷达图, 含满分参考线)
        │   └── ExpansionPanelList(各指标明细)
        │       ├── Panel: K01 出租率 | 实际: 92% | 得分: 85 | 加权: 12.75
        │       ├── Panel: K02 收款及时率 | 实际: 96% | 得分: 93 | 加权: 13.95
        │       └── ...
        │
        ├── ── 排名榜 ── (管理层视角)
        │   Card(title: "排名榜")
        │   ├── SegmentedButton: [员工] / [部门]
        │   └── DataTable
        │       │ 列: 排名 | 姓名/部门 | 总分 | 较上期变化
        │       ├── Row: 🥇 张三 | 92.5 | ↑ +3.2
        │       ├── Row: 🥈 李四 | 89.1 | ↓ -1.5
        │       └── ...
        │
        ├── ── 趋势折线图 ──
        │   Card(title: "历史趋势")
        │   ├── LineChart(6~12个月 KPI 总分趋势)
        │   └── Row: 同比 +5.2% | 环比 +1.3%
        │
        └── ── 申诉入口 ──
            Card
            ├── 快照状态: frozen / recalculated
            ├── 申诉窗口剩余: X 天
            └── OutlinedButton("提交申诉" → /settings/kpi/appeal)
```

### 4.5 KPI 方案详情 `KpiSchemeDetailPage`

**路由**: `/dashboard/kpi/scheme/:schemeId`  
**BLoC**: `KpiSchemeDetailBloc`  
**API**: `GET /api/kpi/schemes/:id` + `GET /api/kpi/schemes/:id/metrics` + `GET /api/kpi/schemes/:id/targets`

**组件树**:

```
Scaffold
├── AppBar(title: 方案名称)
└── SingleChildScrollView
    └── Column
        ├── ── 方案基本信息 ──
        │   Card
        │   ├── Row: 名称 | 评估周期（月度/季度/年度） | 有效期
        │   └── Row: 适用对象数量 | 创建时间
        │
        ├── ── 指标配置表 ──
        │   DataTable
        │   │ 列: 指标编号 | 指标名称 | 方向 | 权重 | 满分标准 | 及格标准
        │   ├── Row: K01 | 出租率 | 正向↑ | 15% | ≥95% | ≥85%
        │   ├── Row: K03 | 租户集中度 | 反向↓ | 10% | ≤40% | ≤60%
        │   └── ...
        │   Footer: 权重合计: 100%
        │
        └── ── 绑定对象列表 ──
            DataTable
            │ 列: 类型 | 名称 | 部门
            ├── Row: 员工 | 张三 | 租务部
            └── Row: 部门 | 物业运营部 | —
```

---

## 五、资产模块页面

### 5.1 资产概览页 `AssetOverviewPage`

**路由**: `/assets`  
**BLoC**: `AssetOverviewBloc`  
**API**: `GET /api/assets/overview` + `GET /api/buildings`

**组件树**:

```
Scaffold
├── AppBar(title: "资产管理", actions: [导入按钮, 导出按钮])
└── SingleChildScrollView
    └── Column
        ├── ── 三业态汇总卡片 ── (Should: S-01)
        │   ResponsiveGridRow(columns: 3)
        │   ├── PropertyTypeCard(写字楼: 441套, 出租率 88.4%)
        │   ├── PropertyTypeCard(商铺: 25套, 出租率 88.0%)
        │   └── PropertyTypeCard(公寓: 173套, 出租率 85.5%)
        │
        ├── SizedBox(h: 24)
        │
        └── ── 楼栋列表 ──
            ListView.builder
            └── BuildingCard(for each building)
                ├── Row
                │   ├── Column(crossAxisAlignment: start)
                │   │   ├── Text(buildingName, style: titleLarge)
                │   │   └── Text("共 X 层 | NLA: X m²", style: bodyMedium)
                │   └── Chip(propertyType 业态标签)
                ├── LinearProgressIndicator(value: 出租率, color: primary)
                └── InkWell → 点击跳转 /assets/building/:buildingId
```

### 5.2 楼栋详情页 `BuildingDetailPage`

**路由**: `/assets/building/:buildingId`  
**BLoC**: `BuildingDetailBloc`  
**API**: `GET /api/buildings/:id` + `GET /api/floors?building_id=`

**组件树**:

```
Scaffold
├── AppBar(title: 楼栋名称)
└── SingleChildScrollView
    └── Column
        ├── ── 楼栋信息卡片 ──
        │   Card
        │   └── GridView(2列)
        │       ├── InfoRow("楼栋名称", building.name)
        │       ├── InfoRow("业态", building.property_type)
        │       ├── InfoRow("总楼层", building.total_floors)
        │       ├── InfoRow("GFA", "${building.gfa} m²")
        │       ├── InfoRow("NLA", "${building.nla} m²")
        │       └── InfoRow("出租率", "${building.occupancy_rate}%")
        │
        └── ── 楼层列表 ──
            ListView.builder
            └── FloorListTile(for each floor)
                ├── Leading: Text(floor.floor_number, style: titleMedium)
                ├── Title: "共 X 个单元"
                ├── Subtitle: 出租率进度条
                ├── Trailing: IconButton(查看楼层图)
                └── onTap → /assets/building/:bid/floor/:fid
```

### 5.3 楼层图页 `FloorMapPage`

**路由**: `/assets/building/:buildingId/floor/:floorId`  
**BLoC**: `FloorMapBloc`  
**API**: `GET /api/floors/:id` + `GET /api/floors/:id/heatmap`

**组件树**:

```
Scaffold
├── AppBar
│   ├── Title: "X层 楼层图"
│   └── Actions:
│       ├── ToggleButton(穿透模式 开/关) ← 开启后热区悬浮显示终端租客
│       └── DropdownButton(业态筛选: 全部/写字楼/商铺/公寓)
│
└── Stack
    ├── ── SVG 楼层图 ──
    │   InteractiveViewer(缩放 + 平移)
    │   └── SvgPicture.string(svgContent)
    │       └── 热区元素 data-unit-id → GestureDetector
    │           ├── onTap → 展开底部详情面板
    │           └── onHover(Web) → Tooltip 悬浮
    │
    ├── ── 状态色块图例 ── (Positioned 右上角)
    │   Card(elevation: 2)
    │   └── Column
    │       ├── LegendItem(🟢 已租, colorScheme.secondary)
    │       ├── LegendItem(🟡 即将到期, colorScheme.tertiary)
    │       ├── LegendItem(🔴 空置, colorScheme.error)
    │       └── LegendItem(⚪ 非可租, colorScheme.outlineVariant)
    │
    └── ── 底部详情面板 ── (点击热区后弹出)
        DraggableScrollableSheet
        └── Card
            ├── ListTile(title: "单元 501", subtitle: "写字楼 | 120 m²")
            ├── Row: StatusChip(已租) + Text("租户: 张三科技")
            ├── Row: Text("月租金: ¥9,600") + Text("到期日: 2027-03-15")
            └── Row
                ├── OutlinedButton("查看详情" → /assets/.../unit/:unitId)
                └── OutlinedButton("查看合同" → /contracts/:contractId)
```

**交互流程**:

```
页面加载 → 请求楼层图 SVG + 热区数据
  → 渲染 SVG 底图 + 按 unit.current_status 动态着色
  → 用户缩放/平移浏览
  → 点击某单元热区
    → 请求该单元简要信息
    → 弹出底部面板展示详情
    → 可跳转单元详情或关联合同
```

### 5.4 单元详情页 `UnitDetailPage`

**路由**: `/assets/building/:bid/floor/:fid/unit/:unitId`  
**BLoC**: `UnitDetailBloc`  
**API**: `GET /api/units/:id` + `GET /api/renovations?unit_id=`

**组件树**:

```
Scaffold
├── AppBar(title: "单元 {unit_number}", actions: [编辑按钮])
└── SingleChildScrollView
    └── Column
        ├── ── 状态标签行 ──
        │   Row: StatusChip(current_status) + Chip(property_type)
        │
        ├── ── 基本信息卡片 ──
        │   Card("基本信息")
        │   └── GridView(2列)
        │       ├── InfoRow("单元编号", unit.unit_number)
        │       ├── InfoRow("建筑面积", "${unit.gfa} m²")
        │       ├── InfoRow("套内面积", "${unit.nia} m²")
        │       ├── InfoRow("朝向", unit.orientation)
        │       ├── InfoRow("层高", "${unit.floor_height} m")
        │       ├── InfoRow("装修状态", unit.renovation_status)
        │       ├── InfoRow("参考市场租金", "¥${unit.market_rent_reference}/m²/月")
        │       └── InfoRow("前序单元", unit.predecessor_unit_ids)  // 拆分/合并时显示
        │
        ├── ── 业态扩展字段 ── (根据 property_type 动态展示)
        │   Card("业态信息")
        │   └── 写字楼: 工位数 + 分隔间数
        │     / 商铺: 门面宽度 + 临街面 + 层高
        │     / 公寓: 卧室数 + 独立卫生间
        │
        ├── ── 当前租赁信息 ── (仅 status=leased 时显示)
        │   Card("当前租赁")
        │   ├── ListTile(租户名称, 合同编号)
        │   ├── Row: 月租金 | 到期日 | 剩余天数
        │   └── TextButton("查看合同详情")
        │
        └── ── 改造记录 ──
            Card("改造记录")
            ├── ListView(renovations)
            │   └── ListTile(改造类型 | 日期 | 造价)
            │       └── onTap → 改造详情页
            └── FilledButton.icon("新增改造记录")
```

### 5.5 Excel 批量导入页 `UnitImportPage`

**路由**: `/assets/import`  
**BLoC**: `UnitImportBloc`  
**API**: `POST /api/imports` (含 `dry_run` 模式)

**组件树**:

```
Scaffold
├── AppBar(title: "资产批量导入")
└── Stepper(type: StepperType.horizontal)
    ├── Step 1: "选择文件"
    │   ├── DropdownButton(数据类型: 单元台账 / 历史合同 / 子租赁)
    │   ├── FilePicker(accept: .xlsx, .xls)
    │   ├── TextButton("下载导入模板")
    │   └── Text("注意: 单元台账导入采用整批回滚模式")
    │
    ├── Step 2: "预校验"
    │   ├── FilledButton("执行试导入 (dry_run)")
    │   └── 校验结果展示:
    │       ├── 成功: "共 639 条，校验通过 635 条，错误 4 条"
    │       ├── 错误列表 DataTable
    │       │   │ 列: 行号 | 字段 | 错误原因
    │       │   ├── Row: 第 45 行 | unit_number | 编号重复
    │       │   └── Row: 第 102 行 | gfa | 面积不能为空
    │       └── TextButton("下载错误报告 Excel")
    │
    └── Step 3: "确认导入"
        ├── Text("确认将 635 条数据写入数据库？")
        ├── 导入批次号: BATCH-2026-04-08-001
        ├── FilledButton("确认导入")
        └── 进度展示:
            ├── LinearProgressIndicator
            └── Text("导入中... 420/635")
```

**交互流程**:

```
选择文件 → Step 1 完成
  → 点击"执行试导入"
    → POST /api/imports { dry_run: true }
    → 展示校验结果（成功数/错误数/错误明细）
    → 用户修正 Excel 后可重新上传
  → 校验全通过 → 点击"确认导入"
    → POST /api/imports { dry_run: false }
    → 显示进度 → 完成
    → 显示导入批次号 → 可跳转查看批次历史
```

---

## 六、租务与合同模块页面

### 6.1 合同列表页 `ContractListPage`

**路由**: `/contracts`  
**BLoC**: `ContractListBloc`  
**API**: `GET /api/contracts`

**组件树**:

```
Scaffold
├── AppBar(title: "合同管理", actions: [新建合同按钮])
└── Column
    ├── ── 筛选栏 ──
    │   Wrap(spacing: 12)
    │   ├── DropdownButton(状态: 全部/报价中/执行中/即将到期/已终止...)
    │   ├── DropdownButton(业态: 全部/写字楼/商铺/公寓)
    │   ├── DropdownButton(楼栋: 全部/A座/商铺区/公寓楼)
    │   ├── TextField(搜索: 合同编号/租户名称)
    │   └── IconButton(重置筛选)
    │
    └── ── 合同数据表 ──
        ProposDataTable
        │ 列: 合同编号 | 租户 | 业态 | 单元 | 月租金 | 状态 | 到期日 | 操作
        ├── Row → onTap → /contracts/:contractId
        │   ├── Cell: "HT-2026-001"
        │   ├── Cell: "张三科技有限公司"
        │   ├── Cell: Chip("写字楼")
        │   ├── Cell: "501, 502"（多单元以逗号分隔）
        │   ├── Cell: "¥19,200/月"
        │   ├── Cell: StatusChip("执行中", color: secondary)
        │   ├── Cell: "2027-03-15"
        │   └── Cell: IconButton(更多操作 ▾)
        │       ├── MenuItem("续签") → /contracts/:id/renew
        │       ├── MenuItem("终止") → /contracts/:id/terminate
        │       └── MenuItem("查看押金") → /contracts/:id/deposits
        └── 底部分页栏
```

### 6.2 合同新建/编辑页 `ContractFormPage`

**路由**: `/contracts/new` 或 `/contracts/:contractId/edit`  
**BLoC**: `ContractFormCubit`  
**API**: `POST /api/contracts` / `PATCH /api/contracts/:id`

**组件树**:

```
Scaffold
├── AppBar(title: "新建合同" / "编辑合同", actions: [保存])
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── Section: 租户信息 ──
            │   SectionHeader("租户信息")
            │   ├── SearchableDropdown(租户选择, API: /api/tenants)
            │   └── TextButton.icon("新建租户" → 打开 TenantFormPage)
            │
            ├── ── Section: 合同基本信息 ──
            │   SectionHeader("合同基本信息")
            │   ├── TextFormField(合同编号, 自动生成可修改)
            │   ├── Row
            │   │   ├── DatePicker(起租日)
            │   │   └── DatePicker(到期日)
            │   ├── Row
            │   │   ├── TextFormField(免租天数)
            │   │   └── TextFormField(装修期天数)
            │   ├── DropdownButton(付款周期: 月付/季付/半年付/年付)
            │   └── Row
            │       ├── SwitchListTile(含税: tax_inclusive)
            │       └── TextFormField(适用税率 %, enabled: tax_inclusive)
            │
            ├── ── Section: 单元绑定（M:N）──
            │   SectionHeader("关联单元")
            │   ├── UnitSelectorTable(可多选)
            │   │   │ 列: ☑ | 单元编号 | 楼层 | 面积 | 计费面积(可编辑) | 单价(可编辑)
            │   │   ├── Row: ☑ 501 | 5F | 120m² | [120] | [¥80]
            │   │   └── Row: ☑ 502 | 5F | 100m² | [100] | [¥80]
            │   ├── Footer: 合计计费面积: 220 m² | 月租金合计: ¥17,600
            │   └── OutlinedButton.icon("添加单元")
            │
            ├── ── Section: 押金信息 ──
            │   SectionHeader("押金")
            │   ├── TextFormField(押金金额)
            │   └── Text("押金将在合同签约后自动创建记录")
            │
            ├── ── Section: 商铺营业额分成 ── (仅 property_type=retail 时显示)
            │   SectionHeader("营业额分成")
            │   ├── TextFormField(保底月租金)
            │   └── TextFormField(分成比例 %)
            │
            └── ── Section: 附件上传 ──
                SectionHeader("合同附件")
                ├── FileUploadArea(accept: .pdf, maxFiles: 10)
                └── ListView(已上传附件列表)
```

### 6.3 合同详情页 `ContractDetailPage`

**路由**: `/contracts/:contractId`  
**BLoC**: `ContractDetailBloc`  
**API**: `GET /api/contracts/:id` + `GET /api/contracts/:id/escalation-phases` + `GET /api/contracts/:id/attachments`

**组件树**:

```
Scaffold
├── AppBar(title: "合同详情", actions: [编辑, 更多操作])
└── DefaultTabController(length: 5)
    ├── TabBar: [基本信息] [递增规则] [押金] [子租赁] [附件]
    └── TabBarView
        ├── ── Tab 1: 基本信息 ──
        │   SingleChildScrollView
        │   └── Column
        │       ├── Row: StatusChip(合同状态) + Chip(业态) + Chip(含税/不含税)
        │       ├── Card("合同信息")
        │       │   └── GridView(2列)
        │       │       ├── InfoRow("合同编号", contract.contract_number)
        │       │       ├── InfoRow("租户", contract.tenant_name)
        │       │       ├── InfoRow("起租日", contract.start_date)
        │       │       ├── InfoRow("到期日", contract.end_date)
        │       │       ├── InfoRow("月租金(含税)", "¥{amount_with_tax}")
        │       │       ├── InfoRow("月租金(不含税)", "¥{amount_without_tax}")
        │       │       ├── InfoRow("付款周期", contract.payment_cycle)
        │       │       ├── InfoRow("免租天数", contract.free_rent_days)
        │       │       └── InfoRow("终止类型", contract.termination_type) // 已终止时显示
        │       │
        │       ├── Card("关联单元")
        │       │   └── DataTable
        │       │       │ 列: 单元编号 | 楼层 | 计费面积 | 单价
        │       │       ├── Row: 501 | 5F | 120 m² | ¥80/m²/月
        │       │       └── Row: 502 | 5F | 100 m² | ¥80/m²/月
        │       │
        │       ├── Card("续签链")
        │       │   └── Timeline(合同链: 原合同 → 续签1 → 续签2 ...)
        │       │
        │       └── ── 操作按钮区 ──
        │           Row
        │           ├── FilledButton("续签" → /contracts/:id/renew)
        │           ├── OutlinedButton("终止" → /contracts/:id/terminate)
        │           └── OutlinedButton("租金预测" → /contracts/:id/rent-forecast) (Should)
        │
        ├── ── Tab 2: 递增规则 ──
        │   EscalationPhaseList
        │   ├── TimelineItem(阶段1: 第1~2年, 固定租金 ¥80/m²)
        │   ├── TimelineItem(阶段2: 第3~4年, 每年递增 5%)
        │   ├── TimelineItem(阶段3: 第5年起, CPI 挂钩)
        │   └── OutlinedButton("编辑递增规则" → /contracts/:id/escalation)
        │
        ├── ── Tab 3: 押金 ──
        │   DepositList(contractId)
        │   ├── StatusChip("已收取 ¥35,200")
        │   ├── DataTable(交易流水)
        │   │   │ 列: 时间 | 类型 | 金额 | 余额 | 操作人 | 原因
        │   │   ├── Row: 2026-01-15 | 收取 | +¥35,200 | ¥35,200 | 财务A
        │   │   └── Row: 2026-06-01 | 冲抵 | -¥5,000 | ¥30,200 | 欠费冲抵
        │   └── Row(操作按钮): [冻结] [冲抵] [退还] [转移]
        │
        ├── ── Tab 4: 子租赁 ── (仅二房东主合同显示)
        │   SubleaseListForContract
        │   ├── DataTable
        │   │   │ 列: 单元 | 终端租客 | 月租金 | 入住状态 | 审核状态
        │   └── OutlinedButton("新增子租赁")
        │
        └── ── Tab 5: 附件 ──
            AttachmentList
            ├── ListTile(合同正本.pdf, 2.3MB, 上传于 2026-01-10)
            ├── ListTile(补充协议.pdf, 1.1MB, 上传于 2026-03-20)
            └── FilledButton.icon("上传附件")
```

### 6.4 合同终止页 `ContractTerminatePage`

**路由**: `/contracts/:contractId/terminate`  
**BLoC**: `ContractTerminateCubit`  
**API**: `POST /api/contracts/:id/terminate`

**组件树**:

```
Scaffold
├── AppBar(title: "合同终止")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 合同概要（只读）──
            │   Card: 合同编号 + 租户 + 起止日期 + 月租金
            │
            ├── ── 终止信息 ──
            │   DropdownButton(终止类型)
            │   ├── "租户提前退租"
            │   ├── "协商提前终止"
            │   └── "业主单方解约"
            │   DatePicker(终止日期)
            │   TextFormField(终止原因, maxLines: 3)
            │
            ├── ── 违约金 & 押金处理 ──
            │   TextFormField(违约金金额, prefix: "¥")
            │   Card("押金处理")
            │   ├── Text("当前押金余额: ¥30,200")
            │   ├── TextFormField(扣除金额)
            │   └── Text("预计退还: ¥{remainder}")
            │
            ├── ── 影响预览 ──
            │   Card("终止影响", color: warning)
            │   ├── • 将有 X 张未出账账单被自动取消
            │   ├── • 关联单元将恢复为空置状态
            │   ├── • WALE 中该合同剩余租期归零
            │   └── • 递增规则将被关闭
            │
            └── FilledButton("确认终止", color: error)
                └── ProposConfirmDialog.danger(title: "终止合同", message: "终止后未出账账单将自动取消，此操作不可撤销。")
```

### 6.5 递增规则配置页 `EscalationConfigPage`

**路由**: `/contracts/:contractId/escalation`  
**BLoC**: `EscalationConfigCubit`  
**API**: `PUT /api/contracts/:id/escalation-phases`

**组件树**:

```
Scaffold
├── AppBar(title: "递增规则配置", actions: [套用模板, 保存])
└── SingleChildScrollView
    └── Column
        ├── ── 模板选择 ── (可选)
        │   OutlinedButton("从模板套用")
        │   └── BottomSheet: 模板列表 → 选择 → 自动填入各阶段
        │
        ├── ── 递增阶段列表 ──
        │   ReorderableListView
        │   └── EscalationPhaseCard(for each phase)
        │       ├── Row
        │       │   ├── Text("阶段 {n}")
        │       │   ├── DateRangePicker(阶段起止)
        │       │   └── IconButton(删除阶段)
        │       ├── DropdownButton(递增类型)
        │       │   ├── "固定比例递增" → TextFormField(百分比)
        │       │   ├── "固定金额递增" → TextFormField(金额/m²)
        │       │   ├── "阶梯式递增" → 阶梯表编辑器
        │       │   ├── "CPI 挂钩递增" → TextFormField(CPI 年份 + 涨幅)
        │       │   ├── "每N年递增" → TextFormField(间隔年数 + 涨幅)
        │       │   └── "免租后基准调整" → TextFormField(基准价)
        │       └── 生效后展示: "预计第X年月租: ¥YYY"
        │
        ├── OutlinedButton.icon("+ 添加阶段")
        │
        └── ── 租金预测预览 ── (实时计算)
            Card("全生命周期租金预测")
            └── DataTable
                │ 列: 年份 | 月租金 | 年化租金 | 较上期涨幅
                ├── Row: 2026 | ¥17,600 | ¥211,200 | —
                └── Row: 2027 | ¥18,480 | ¥221,760 | +5.0%
```

### 6.6 租客列表页 `TenantListPage`

**路由**: `/tenants`  
**BLoC**: `TenantListBloc`  
**API**: `GET /api/tenants`

**组件树**:

```
Scaffold
├── AppBar(title: "租客管理", actions: [新建租客])
└── Column
    ├── ── 筛选栏 ──
    │   Row
    │   ├── TextField(搜索: 名称/证件号后4位)
    │   ├── DropdownButton(信用评级: 全部/A/B/C)
    │   └── DropdownButton(类型: 企业/个人)
    │
    └── ProposDataTable
        │ 列: 名称 | 类型 | 证件号(脱敏) | 信用评级 | 在租合同数 | 联系人
        └── Row → onTap → /tenants/:tenantId
            ├── Cell: "张三科技有限公司"
            ├── Cell: "企业"
            ├── Cell: "****5678"
            ├── Cell: StatusChip("A 优质", color: secondary)
            ├── Cell: "2"
            └── Cell: "王经理 ***1234"
```

### 6.7 租客详情页 `TenantDetailPage`

**路由**: `/tenants/:tenantId`  
**BLoC**: `TenantDetailBloc`  
**API**: `GET /api/tenants/:id`

**组件树**:

```
Scaffold
├── AppBar(title: "租客详情", actions: [编辑])
└── SingleChildScrollView
    └── Column
        ├── ── 基本信息 ──
        │   Card
        │   └── GridView(2列)
        │       ├── InfoRow("名称", tenant.name)
        │       ├── InfoRow("类型", tenant.type)
        │       ├── InfoRow("证件号", "****5678" + IconButton(🔓 查看完整))
        │       │   └── 点击 → 弹出密码二次验证 → POST /api/tenants/:id/unmask
        │       ├── InfoRow("联系人", tenant.contact_name)
        │       ├── InfoRow("联系电话", "***1234" + IconButton(🔓))
        │       └── InfoRow("信用评级", StatusChip("A"))
        │
        ├── ── 信用评级面板 ── (Should: S-06)
        │   Card("信用评级详情")
        │   ├── Row: 当前评级 A | 评级日期 2026-04-01
        │   ├── Text("过去12个月逾期 0 次")
        │   └── LineChart(评级历史趋势)
        │
        ├── ── 租赁历史 ──
        │   Card("租赁历史")
        │   └── DataTable
        │       │ 列: 合同编号 | 单元 | 起止日期 | 状态
        │       └── Row → 点击跳转合同详情
        │
        └── ── 关联工单 ──
            Card("报修工单")
            └── DataTable(最近工单列表)
```

### 6.8 押金管理页 `DepositListPage`

**路由**: `/contracts/:contractId/deposits`  
**BLoC**: `DepositListBloc`  
**API**: `GET /api/contracts/:id/deposits` + `GET /api/deposits/:id/transactions`

**组件树**:

```
Scaffold
├── AppBar(title: "押金管理")
└── Column
    ├── ── 押金汇总卡片 ──
    │   Card
    │   ├── Row: 押金总额 ¥35,200 | 当前余额 ¥30,200 | 状态 StatusChip("已收取")
    │   └── Row(操作按钮)
    │       ├── FilledButton("冻结") → POST /api/deposits/:id/freeze
    │       ├── OutlinedButton("冲抵") → ProposConfirmDialog.withInput(title: "押金冲抵", fields: [金额, 原因])
    │       ├── OutlinedButton("退还") → POST /api/deposits/:id/refund
    │       └── OutlinedButton("转移至续签合同") → POST /api/deposits/:id/transfer
    │
    └── ── 交易流水 ──
        Card("交易流水")
        └── DataTable
            │ 列: 时间 | 类型 | 金额 | 余额 | 操作人 | 原因
            ├── Row: 2026-01-15 | 收取 | +¥35,200 | ¥35,200 | 财务A | 初始收取
            ├── Row: 2026-06-01 | 冲抵 | -¥5,000 | ¥30,200 | 财务B | 欠费冲抵
            └── ...
```

### 6.9 合同续签页 `ContractRenewPage`

**路由**: `/contracts/:contractId/renew`  
**BLoC**: `ContractRenewCubit`  
**API**: `POST /api/contracts/:id/renew`

**组件树**:

```
Scaffold
├── AppBar(title: "续签合同")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 原合同信息（只读） ──
            │   Card("原合同概要")
            │   └── GridView(2列)
            │       ├── InfoRow("合同编号", parent.contract_number)
            │       ├── InfoRow("租户", parent.tenant_name)
            │       ├── InfoRow("单元", parent.units)
            │       ├── InfoRow("原到期日", parent.end_date)
            │       └── InfoRow("当前月租", "¥{parent.monthly_rent}")
            │
            ├── ── 续签参数 ──
            │   Card("续签条款")
            │   ├── DatePicker(新起始日, 默认=原到期日+1天)
            │   ├── DatePicker(新到期日)
            │   ├── TextFormField(新月租金, prefix: "¥")
            │   ├── DropdownButton(递增规则: 延用原合同/重新配置)
            │   │   └── 选"重新配置" → 展开内联 EscalationConfigWidget
            │   └── TextFormField(续签备注)
            │
            ├── ── 押金处理 ──
            │   Card("押金处理")
            │   ├── RadioGroup
            │   │   ├── "原押金自动转入续签合同"
            │   │   ├── "退还原押金 + 重新收取"
            │   │   └── "补差额"
            │   └── 选"补差额" → TextFormField(差额金额)
            │
            └── FilledButton("提交续签")
                └── ProposConfirmDialog.confirm(title: "确认续签", message: "将基于原合同生成新合同，原合同状态变为已续签。")
```

**交互流程**:

```
从合同列表/详情 → 点击"续签"
  → 自动填充原合同信息
  → 填写新条款（起止日期、租金、递增规则、押金处理）
  → 校验: 新起始日 ≥ 原到期日、月租金 > 0、到期日 > 起始日
  → 点击"提交续签"
    → POST /api/contracts/:id/renew { new_start, new_end, monthly_rent, escalation, deposit_mode }
    → 成功 → ProposToast.success("续签合同已创建")
    → 原合同状态 → renewed，新合同状态 → pending
    → 跳转新合同详情页
```

### 6.10 押金新增页 `DepositFormPage`

**路由**: `/contracts/:contractId/deposits/new`  
**BLoC**: `DepositFormCubit`  
**API**: `POST /api/contracts/:id/deposits`

**组件树**:

```
Scaffold
├── AppBar(title: "新增押金")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 合同信息（只读） ──
            │   Card
            │   └── Row: 合同编号 | 租户名称 | 当前押金余额
            │
            ├── ── 押金信息 ──
            │   TextFormField(押金金额, prefix: "¥", validator: > 0)
            │   DropdownButton(押金类型: 租赁押金/装修押金/履约押金)
            │   DatePicker(收取日期, 默认=今天)
            │   DropdownButton(收款方式: 银行转账/现金/支票/POS)
            │   TextFormField(银行流水号)
            │   TextFormField(备注)
            │
            └── FilledButton("确认收取")
                └── 成功 → ProposToast.success("押金已收取") → 返回押金列表
```

### 6.11 租客新增/编辑页 `TenantFormPage`

**路由**: `/tenants/new` 或 `/tenants/:tenantId/edit`  
**BLoC**: `TenantFormCubit`  
**API**: `POST /api/tenants` / `PATCH /api/tenants/:id`

**组件树**:

```
Scaffold
├── AppBar(title: context.isEdit ? "编辑租客" : "新建租客")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 基本信息 ──
            │   TextFormField(租客名称, validator: required)
            │   DropdownButton(租客类型: 企业/个人)
            │   TextFormField(统一社会信用代码/身份证号, validator: format)
            │   └── ⚠️ 加密存储，API 层脱敏显示
            │
            ├── ── 联系人 ──
            │   TextFormField(联系人姓名)
            │   TextFormField(联系电话, keyboardType: phone)
            │   └── ⚠️ 加密存储，API 层脱敏显示
            │   TextFormField(邮箱, validator: email)
            │
            ├── ── 开票信息 ──（可选）
            │   TextFormField(开票抬头)
            │   TextFormField(税号)
            │   TextFormField(开户行)
            │   TextFormField(银行账号)
            │
            └── FilledButton(context.isEdit ? "保存" : "创建租客")
                └── 成功 → ProposToast.success → 跳转租客详情页
```

---

## 七、财务模块页面

### 7.1 财务概览页 `FinanceOverviewPage`

**路由**: `/finance`  
**BLoC**: `FinanceOverviewBloc`  
**API**: `GET /api/noi/summary` + `GET /api/invoices?status=overdue`

**组件树**:

```
Scaffold
├── AppBar(title: "财务管理")
└── SingleChildScrollView
    └── Column
        ├── ── NOI 汇总卡片 ──
        │   ResponsiveGridRow(columns: 4)
        │   ├── MetricCard("本月应收", "¥2,345,678")
        │   ├── MetricCard("本月实收", "¥2,100,000")
        │   ├── MetricCard("收款率", "89.5%")
        │   └── MetricCard("NOI", "¥1,234,567")
        │
        ├── ── 快捷入口 ──
        │   ResponsiveGridRow(columns: 4)
        │   ├── ActionCard("账单管理" → /finance/invoices)
        │   ├── ActionCard("收支管理" → /finance/expenses)
        │   ├── ActionCard("水电抄表" → /finance/meter-readings)
        │   └── ActionCard("营业额申报" → /finance/turnover-reports)
        │
        ├── ── 逾期账单警示 ──
        │   Card("逾期账单", headerColor: error)
        │   └── DataTable(最近逾期账单 top 10)
        │       │ 列: 租户 | 单元 | 费项 | 金额 | 逾期天数
        │       └── Row: 张三科技 | 501 | 租金 | ¥9,600 | 15天
        │
        └── ── 收款进度 ──
            Card("本月收款进度")
            └── LinearProgressIndicator(value: 89.5%)
```

### 7.2 账单列表页 `InvoiceListPage`

**路由**: `/finance/invoices`  
**BLoC**: `InvoiceListBloc`  
**API**: `GET /api/invoices`

**组件树**:

```
Scaffold
├── AppBar(title: "账单管理", actions: [导出Excel, 手工触发生成])
└── Column
    ├── ── 筛选栏 ──
    │   Wrap
    │   ├── DropdownButton(状态: 全部/已出账/已核销/逾期/已作废)
    │   ├── DropdownButton(费项: 全部/租金/物管费/水电/分成)
    │   ├── DropdownButton(楼栋)
    │   ├── DropdownButton(业态)
    │   ├── DateRangePicker(账期范围)
    │   └── TextField(租户名称搜索)
    │
    └── ProposDataTable
        │ 列: 账单号 | 租户 | 费项 | 含税金额 | 不含税金额 | 状态 | 到期日 | 操作
        └── Row → onTap → /finance/invoices/:invoiceId
            └── 操作列:
                ├── IconButton("核销" → 跳转收款表单)
                └── IconButton("作废" → 确认弹窗)
```

### 7.3 账单详情页 `InvoiceDetailPage`

**路由**: `/finance/invoices/:invoiceId`  
**BLoC**: `InvoiceDetailBloc`  
**API**: `GET /api/invoices/:id` + `GET /api/invoices/:id/items`

**组件树**:

```
Scaffold
├── AppBar(title: "账单详情")
└── SingleChildScrollView
    └── Column
        ├── StatusChip(账单状态)
        │
        ├── ── 账单基本信息 ──
        │   Card
        │   └── GridView(2列)
        │       ├── InfoRow("账单号", invoice.invoice_number)
        │       ├── InfoRow("租户", invoice.tenant_name)
        │       ├── InfoRow("合同", invoice.contract_number)
        │       ├── InfoRow("账期", invoice.billing_period)
        │       ├── InfoRow("含税金额", "¥{amount_with_tax}")
        │       ├── InfoRow("不含税金额", "¥{amount_without_tax}")
        │       ├── InfoRow("已收金额", "¥{paid_amount}")
        │       ├── InfoRow("未收余额", "¥{outstanding}")
        │       ├── InfoRow("到期日", invoice.due_date)
        │       └── InfoRow("发票状态", invoice.invoice_status)
        │
        ├── ── 费项明细 ──
        │   Card("费项明细")
        │   └── DataTable
        │       │ 列: 费项类型 | 说明 | 金额
        │       ├── Row: 租金 | 501号 120m² × ¥80 | ¥9,600
        │       ├── Row: 物管费 | 120m² × ¥15 | ¥1,800
        │       └── Footer: 合计: ¥11,400
        │
        ├── ── 核销记录 ──
        │   Card("收款核销记录")
        │   └── DataTable
        │       │ 列: 收款日期 | 收款方式 | 核销金额 | 操作人
        │       └── Row: 2026-04-05 | 银行转账 | ¥9,600 | 财务A
        │
        └── ── 操作按钮 ──
            Row
            ├── FilledButton("录入收款" → /finance/invoices/:id/pay)
            ├── OutlinedButton("录入发票号")
            └── OutlinedButton("作废", color: error)
```

### 7.4 收款录入页 `PaymentFormPage`

**路由**: `/finance/invoices/:invoiceId/pay`  
**BLoC**: `PaymentFormCubit`  
**API**: `POST /api/payments`

**组件树**:

```
Scaffold
├── AppBar(title: "录入收款")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 收款信息 ──
            │   TextFormField(收款金额, prefix: "¥")
            │   DatePicker(到账日期)
            │   DropdownButton(收款方式: 银行转账/现金/支票/POS)
            │   TextFormField(银行流水号)
            │   TextFormField(备注)
            │
            ├── ── 核销分配 ──（一笔收款可分配到多张账单）
            │   Card("核销分配")
            │   ├── Text("默认按先到期先核销分配，可手工调整")
            │   └── DataTable(可编辑)
            │       │ 列: 账单号 | 费项 | 应收 | 本次核销(可编辑)
            │       ├── Row: INV-001 | 租金 | ¥9,600 | [¥9,600]
            │       ├── Row: INV-002 | 物管费 | ¥1,800 | [¥0]
            │       └── Footer: 本次核销合计: ¥9,600 | 剩余未分配: ¥0
            │
            └── FilledButton("确认收款")
```

**交互流程**:

```
输入收款金额 → 系统按"先到期先核销"自动分配各账单核销额
  → 财务可手工调整各账单核销金额
  → 校验: 各账单核销合计 ≤ 收款总额
  → 点击"确认收款"
    → POST /api/payments { amount, allocations: [...] }
    → 成功 → 账单状态自动更新(部分核销/已核销)
    → 返回账单列表
```

### 7.5 水电抄表页 `MeterReadingFormPage`

**路由**: `/finance/meter-readings/new`  
**BLoC**: `MeterReadingFormCubit`  
**API**: `POST /api/meter-readings`

**组件树**:

```
Scaffold
├── AppBar(title: "水电抄表录入")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── SearchableDropdown(单元选择, API: /api/units)
            ├── DropdownButton(表计类型: 水表/电表/燃气表)
            ├── TextFormField(抄表周期, hint: "2026-03")
            ├── Row
            │   ├── TextFormField(上期读数, readOnly: auto-fill from last record)
            │   └── TextFormField(本期读数)
            ├── ── 费用预览（实时计算）──
            │   Card("费用预览")
            │   ├── Text("用量: {current - previous} 度")
            │   ├── Text("单价: ¥{tier1_price}/度")
            │   ├── Text("阶梯部分: {excess} 度 × ¥{tier2_price}")
            │   └── Text("合计费用: ¥{total}", style: titleLarge)
            │
            └── FilledButton("确认提交")
                └── 提交后自动生成水电费账单
```

### 7.6 营业额申报页 `TurnoverReportListPage` / `TurnoverReportDetailPage`

**路由**: `/finance/turnover-reports` / `/finance/turnover-reports/:reportId`  
**BLoC**: `TurnoverReportBloc`  
**API**: `GET /api/turnover-reports` + `PATCH /api/turnover-reports/:id/approve|reject`

**列表页组件树**:

```
Scaffold
├── AppBar(title: "营业额申报管理")
└── Column
    ├── ── 筛选 ──
    │   Row
    │   ├── DropdownButton(状态: 全部/待审核/已通过/已退回)
    │   └── TextField(商户搜索)
    │
    └── ProposDataTable
        │ 列: 申报月 | 商户(合同) | 申报营业额 | 保底租金 | 分成额 | 状态 | 操作
        └── Row → 点击查看详情
            └── 操作: [通过] [退回]
```

**详情页组件树**:

```
Scaffold
├── AppBar(title: "申报详情")
└── Column
    ├── Card("申报信息")
    │   └── GridView
    │       ├── InfoRow("合同", contract_number)
    │       ├── InfoRow("申报月", report_month)
    │       ├── InfoRow("申报营业额", "¥{reported_revenue}")
    │       ├── InfoRow("分成比例", "{share_rate}%")
    │       ├── InfoRow("保底租金", "¥{min_guarantee_rent}")
    │       └── InfoRow("应收 = MAX(保底, 营业额×比例)", "¥{calculated}")
    │
    ├── Card("证明材料")
    │   └── ListView(附件列表，可下载)
    │
    └── Row(操作)
        ├── FilledButton("审核通过") → PATCH /approve
        └── OutlinedButton("退回", color: error) → ProposConfirmDialog.withInput(title: "退回申报", fields: [退回原因]) → PATCH /reject
```

### 7.7 费用列表页 `ExpenseListPage`

**路由**: `/finance/expenses`  
**BLoC**: `ExpenseListBloc`  
**API**: `GET /api/expenses`

**组件树**:

```
Scaffold
├── AppBar(title: "费用支出", actions: [FilledButton("新增费用")])
└── Column
    ├── ── 筛选栏 ──
    │   Row
    │   ├── DropdownButton(费用类型: 全部/物管费/维修费/公共能耗/保险/其他)
    │   ├── DateRangePicker(费用期间)
    │   ├── DropdownButton(楼栋)
    │   └── IconButton(重置)
    │
    ├── ── 费用汇总 ──
    │   Row
    │   ├── MetricCard("本月支出", "¥128,500", trend: "+3.2%")
    │   ├── MetricCard("本年累计", "¥1,542,000")
    │   └── MetricCard("OpEx 占比", "34.2%")
    │
    └── ProposDataTable
        │ 列: 费用编号 | 类型 | 金额 | 归属楼栋 | 发生日期 | 录入人 | 状态 | 操作
        └── Row → 点击查看详情
            └── 操作: [编辑] [作废]
```

### 7.8 费用录入页 `ExpenseFormPage`

**路由**: `/finance/expenses/new` 或 `/finance/expenses/:expenseId/edit`  
**BLoC**: `ExpenseFormCubit`  
**API**: `POST /api/expenses` / `PATCH /api/expenses/:id`

**组件树**:

```
Scaffold
├── AppBar(title: context.isEdit ? "编辑费用" : "新增费用")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── DropdownButton(费用类型, validator: required)
            │   ├── "物管费" / "维修费" / "公共能耗" / "保险" / "税费" / "其他"
            │
            ├── TextFormField(费用金额, prefix: "¥", validator: > 0)
            ├── DatePicker(发生日期, 默认=今天)
            ├── DropdownButton(归属楼栋, items: buildings)
            ├── TextFormField(供应商/对方名称)
            ├── TextFormField(摘要/说明, maxLines: 3)
            │
            ├── ── 附件 ──
            │   FilePickerButton("上传凭证", accept: [pdf, jpg, png], maxFiles: 5)
            │   └── 已上传文件列表(可删除)
            │
            └── FilledButton(context.isEdit ? "保存" : "提交费用")
                └── 成功 → ProposToast.success("费用已录入") → NOI 实时更新 OpEx
```

**交互说明**:

```
费用支出直接影响 NOI 计算: NOI = EGI - OpEx
  → 录入费用后，DashboardPage NOI 卡片自动更新
  → FinanceOverviewPage OpEx 分项自动累加
```

### 7.9 水电抄表列表页 `MeterReadingListPage`

**路由**: `/finance/meter-readings`  
**BLoC**: `MeterReadingListBloc`  
**API**: `GET /api/meter-readings`

**组件树**:

```
Scaffold
├── AppBar(title: "水电抄表记录", actions: [FilledButton("新增抄表")])
└── Column
    ├── ── 筛选栏 ──
    │   Row
    │   ├── DropdownButton(类型: 全部/电表/水表)
    │   ├── DropdownButton(楼栋)
    │   ├── DateRangePicker(抄表日期)
    │   └── TextField(单元搜索)
    │
    └── ProposDataTable
        │ 列: 抄表日期 | 单元 | 表类型 | 上期读数 | 本期读数 | 用量 | 费用 | 账单状态 | 操作
        └── Row
            ├── 费用: 根据阶梯单价自动计算
            ├── 账单状态: StatusChip(已生成/未生成)
            └── 操作: [详情] [编辑](仅未生成账单时)
```

**交互说明**:

```
点击"新增抄表" → 跳转 MeterReadingFormPage
点击 Row → 查看抄表明细（读数、阶梯计算过程、关联账单）
提交抄表后自动生成水电费账单 → 账单状态显示"已生成"
```

---

## 八、工单模块页面

### 8.1 工单列表页 `WorkOrderListPage`

**路由**: `/workorders`  
**BLoC**: `WorkOrderListBloc`  
**API**: `GET /api/workorders`

**组件树**:

```
Scaffold
├── AppBar(title: "工单管理")
├── FloatingActionButton.extended("报修")
│   └── 移动端: QR扫码入口 / 桌面端: 直接跳 WorkOrderFormPage
└── Column
    ├── ── 状态标签栏 ──
    │   SingleChildScrollView(scrollDirection: horizontal)
    │   └── Row(FilterChip 列表)
    │       ├── FilterChip("全部", selected: true)
    │       ├── FilterChip("已提交")
    │       ├── FilterChip("处理中")
    │       ├── FilterChip("待验收")
    │       ├── FilterChip("已完成")
    │       └── FilterChip("挂起")
    │
    └── ── 工单列表 ──
        ListView.builder
        └── WorkOrderCard(for each order)
            ├── Row
            │   ├── Column(crossAxisAlignment: start)
            │   │   ├── Text(order.title, style: titleMedium)
            │   │   └── Text("${building} ${floor} ${unit}", style: bodySmall)
            │   ├── Spacer
            │   ├── StatusChip(order.status)
            │   └── PriorityIndicator(order.priority)  // 🔴紧急/🟡一般
            ├── Row
            │   ├── Text("提报人: ${submitter}")
            │   ├── Text("处理人: ${assignee}")
            │   └── Text(timeAgo(order.submitted_at))
            └── onTap → /workorders/:orderId
```

### 8.2 工单提报页 `WorkOrderFormPage`

**路由**: `/workorders/new`  
**BLoC**: `WorkOrderFormCubit`  
**API**: `POST /api/workorders`

**组件树**:

```
Scaffold
├── AppBar(title: "提交报修")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 位置选择（级联）──
            │   DropdownButton(楼栋)
            │   DropdownButton(楼层, 依赖楼栋)
            │   DropdownButton(单元, 依赖楼层)
            │   // 扫码场景: 自动填充以上三项
            │
            ├── TextFormField(问题描述, maxLines: 5)
            ├── DropdownButton(问题类型: 水电/空调/门窗/网络/保洁/其他)
            ├── DropdownButton(紧急程度: 一般/紧急/非常紧急)
            │
            ├── ── 照片上传 ──
            │   ImagePickerGrid(maxImages: 5)
            │   └── Grid(children: [
            │       已选图片缩略图(可删除),
            │       AddPhotoButton(相机/相册)
            │   ])
            │
            └── FilledButton("提交工单")
```

**移动端扫码流程**:

```
点击 FAB "报修"
  ├── 移动端: 弹出选择 → [扫码报修] / [手动填报]
  │   └── 扫码 → QrScanPage → 解析 unit_id → 自动填充楼栋/楼层/单元
  └── 桌面端/Web: 直接跳转 WorkOrderFormPage（手动选择）
```

### 8.3 工单详情页 `WorkOrderDetailPage`

**路由**: `/workorders/:orderId`  
**BLoC**: `WorkOrderDetailBloc`  
**API**: `GET /api/workorders/:id`

**组件树**:

```
Scaffold
├── AppBar(title: "工单详情")
└── SingleChildScrollView
    └── Column
        ├── ── 状态 & 优先级 ──
        │   Row: StatusChip(status) + PriorityChip(priority)
        │
        ├── ── 基本信息 ──
        │   Card
        │   └── GridView(2列)
        │       ├── InfoRow("工单编号", order.order_number)
        │       ├── InfoRow("位置", "${building} ${floor} ${unit}")
        │       ├── InfoRow("问题类型", order.category)
        │       ├── InfoRow("提报人", order.submitter)
        │       ├── InfoRow("提报时间", order.submitted_at)
        │       ├── InfoRow("处理人", order.assignee)
        │       ├── InfoRow("预计完成", order.estimated_completion)
        │       └── InfoRow("SLA 状态", slaStatus)  // 超时标红
        │
        ├── ── 问题描述 ──
        │   Card: Text(order.description)
        │
        ├── ── 照片 ──
        │   Card("现场照片")
        │   └── GridView(photos, crossAxisCount: 3)
        │       └── GestureDetector → 全屏预览
        │
        ├── ── 维修成本 ── (completed 状态显示)
        │   Card("维修成本")
        │   ├── InfoRow("材料费", "¥{material_cost}")
        │   ├── InfoRow("人工费", "¥{labor_cost}")
        │   ├── InfoRow("合计", "¥{total_cost}")
        │   └── InfoRow("归口", "${building} / ${floor}")
        │
        ├── ── 操作时间线 ──
        │   Card("操作记录")
        │   └── Timeline
        │       ├── TimelineItem: 2026-04-08 10:00 张三提交工单
        │       ├── TimelineItem: 2026-04-08 10:30 李四审核派单 → 王五
        │       ├── TimelineItem: 2026-04-08 14:00 王五开始处理
        │       └── TimelineItem: 2026-04-08 17:00 王五提交完工
        │
        └── ── 操作按钮 ── (根据状态动态显示)
            Row
            ├── 已提交: FilledButton("审核派单") / OutlinedButton("拒绝")
            ├── 已派单: FilledButton("开始处理") / OutlinedButton("挂起")
            ├── 处理中: FilledButton("提交完工") / OutlinedButton("挂起")
            ├── 待验收: FilledButton("验收通过") / OutlinedButton("验收不通过，返工")
            └── 已完成(7天内): OutlinedButton("重开工单")
```

**审核派单交互流程**:

```
管理层点击 "审核派单"
  → BottomSheet
    ├── SearchableDropdown(指派处理人)
    ├── DateTimePicker(预计完成时间)
    └── FilledButton("确认派单")
  → PATCH /api/workorders/:id/approve { assignee_id, estimated_completion }
  → 成功 → 状态变为 approved → 推送通知处理人
```

### 8.4 扫码报修页 `QrScanPage`

**路由**: `/workorders/scan`  
**BLoC**: `QrScanCubit`  
**API**: `GET /api/units/by-qr/:qrCode`

> 仅移动端（Compact 断点）显示，桌面端/Web 隐藏该入口。

**组件树**:

```
Scaffold
├── AppBar(title: "扫码报修", leading: BackButton)
└── Column
    ├── ── 扫码区域 ── (flex: 3)
    │   MobileScanner(onDetect: (barcode) => cubit.lookup(barcode))
    │   └── 扫描框叠加层: Container(border: 2px dashed primary)
    │
    ├── ── 提示 ──
    │   Text("请扫描单元门牌上的二维码", style: bodyMedium, textAlign: center)
    │
    └── ── 手动输入备选 ──
        TextButton("手动输入单元编号")
        └── 点击 → BottomSheet
            ├── TextFormField(单元编号)
            └── FilledButton("查询") → GET /api/units?unit_number=xxx
```

**交互流程**:

```
打开相机 → 扫描 QR Code
  → 解析 unit_id
  → GET /api/units/by-qr/:qrCode
  → 成功 → 自动跳转 WorkOrderFormPage，预填：
      ├── building_id (已填, 只读)
      ├── floor_id (已填, 只读)
      └── unit_id (已填, 只读)
  → 识别失败 → ProposToast.error("无法识别二维码，请重试或手动输入")
```

---

## 九、二房东门户模块页面

> 独立于主导航骨架，使用精简布局，仅二房东角色可访问。

### 9.1 门户登录页 `SubLandlordPortalPage`

**路由**: `/sublease-portal`  
**API**: `POST /api/sublease-portal/login`

**组件树**:

```
Scaffold(backgroundColor: colorScheme.surface)
└── Center
    └── ConstrainedBox(maxWidth: 400)
        └── Card
            └── Column
                ├── Logo + "PropOS 二房东平台"
                ├── TextFormField(邮箱)
                ├── TextFormField(密码)
                ├── CheckboxListTile("我已阅读并确认数据填报声明")
                ├── FilledButton("登录")
                └── ── 特殊逻辑 ──
                    首次登录 must_change_password → 强制跳转改密页
```

### 9.2 单元填报列表页 `SubLandlordUnitListPage`

**路由**: `/sublease-portal/units`  
**BLoC**: `SubLandlordUnitListBloc`  
**API**: `GET /api/sublease-portal/units` + `GET /api/sublease-portal/subleases`

**组件树**:

```
Scaffold
├── AppBar
│   ├── Title: "我的单元"
│   └── Actions: [批量导入按钮, 退出登录]
└── Column
    ├── ── 填报进度卡片 ──
    │   Card
    │   ├── Text("填报截止日: 本月5日")
    │   ├── LinearProgressIndicator(已填报 / 总单元)
    │   └── Text("已填报 45/60 个单元")
    │
    └── ── 单元列表 ──
        ListView.builder
        └── UnitFillCard(for each unit)
            ├── Row
            │   ├── Text(unit.unit_number, style: titleMedium)
            │   ├── Text("${unit.area} m²")
            │   ├── StatusChip(fill_status: 已填报/未填报/退回待修改)
            │   └── StatusChip(review_status: 待审核/已通过/已退回)
            └── onTap → /sublease-portal/units/:unitId/fill
```

### 9.3 子租赁填报页 `SubleaseFillingPage`

**路由**: `/sublease-portal/units/:unitId/fill`  
**BLoC**: `SubleaseFillingCubit`  
**API**: `POST|PATCH /api/sublease-portal/subleases`

**组件树**:

```
Scaffold
├── AppBar(title: "单元 {unit_number} 填报")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 单元信息(只读) ──
            │   Card: 单元编号 | 面积 | 主合同到期日
            │
            ├── ── 入住状态 ──
            │   DropdownButton(已入住/已签约未入住/已退租/空置)
            │
            ├── ── 租客信息 ── (非空置时显示)
            │   TextFormField(终端租客名称)
            │   DropdownButton(类型: 企业/个人)
            │   TextFormField(联系人)
            │   TextFormField(联系电话)
            │   TextFormField(证件号, 可选)
            │
            ├── ── 租赁信息 ──
            │   Row
            │   ├── DatePicker(起租日)
            │   └── DatePicker(到期日, max: 主合同到期日)
            │   TextFormField(实际月租金, prefix: "¥")
            │   Text("自动计算单价: ¥{rent / area}/m²/月")
            │   TextFormField(入住人数, 仅公寓显示)
            │
            ├── TextFormField(备注, maxLines: 3)
            │
            ├── ── 审核状态面板 ── (退回时显示)
            │   Card(color: error.withOpacity(0.1))
            │   ├── Text("审核退回原因:")
            │   └── Text(reject_reason, style: bodyMedium)
            │
            └── Row
                ├── OutlinedButton("暂存草稿")  // review_status = draft
                └── FilledButton("提交审核")     // review_status = pending
                    └── 二次确认: "提交后数据将进入审核流程"
```

**交互流程**:

```
二房东打开单元填报页
  ├── 新单元: 空白表单
  ├── 已填报: 预填历史数据
  └── 被退回: 预填 + 显示退回原因
→ 填写租客信息 + 租赁信息
→ 选择 [暂存草稿] 或 [提交审核]
  ├── 暂存 → review_status = draft → 返回列表
  └── 提交 → review_status = pending → 等待内部审核
     → 审核通过 → 数据进入穿透看板
     → 审核退回 → 二房东可修改后重提
```

### 9.4 批量导入页 `SubleaseImportPage`

**路由**: `/sublease-portal/import`  
**BLoC**: `SubleaseImportBloc`  
**API**: `POST /api/sublease-portal/subleases/import`

**组件树**:

```
Scaffold
├── AppBar(title: "批量导入子租赁")
└── Column
    ├── OutlinedButton.icon("下载导入模板")
    ├── SizedBox(h: 24)
    ├── FileUploadArea(accept: .xlsx)
    ├── SizedBox(h: 16)
    ├── FilledButton("开始导入")
    └── ── 导入结果 ──
        Card
        ├── Text("成功: X 条 | 失败: Y 条")
        └── DataTable(错误明细: 行号 | 字段 | 原因)
```

---

## 十、系统设置模块页面

### 10.1 设置首页 `SettingsPage`

**路由**: `/settings`

**组件树**:

```
Scaffold
├── AppBar(title: "系统设置")
└── ListView
    ├── ListTile("用户管理" → /settings/users)
    ├── ListTile("组织架构" → /settings/org)
    ├── ListTile("KPI 方案管理" → /settings/kpi/schemes)
    ├── ListTile("递增模板管理" → /settings/escalation/templates)
    ├── ListTile("预警中心" → /settings/alerts)
    └── ListTile("审计日志" → /settings/audit-logs)
```

### 10.2 用户管理页 `UserManagementPage`

**路由**: `/settings/users`  
**BLoC**: `UserManagementBloc`  
**API**: `GET /api/users`

**组件树**:

```
Scaffold
├── AppBar(title: "用户管理", actions: [新建用户])
└── ProposDataTable
    │ 列: 姓名 | 邮箱 | 角色 | 部门 | 状态 | 上次登录 | 操作
    └── Row
        └── 操作: [编辑] [启/停用] [变更角色] [变更部门]
```

### 10.3 用户新建/编辑页 `UserFormPage`

**路由**: `/settings/users/new` 或 `/settings/users/:userId/edit`  
**BLoC**: `UserFormCubit`  
**API**: `POST /api/users` / `PATCH /api/users/:id`

> 仅 `super_admin` 可创建用户；`ops_manager` 可编辑同组织下用户。

**组件树**:

```
Scaffold
├── AppBar(title: context.isEdit ? "编辑用户" : "新建用户")
└── SingleChildScrollView
    └── Form
        └── Column
            ├── ── 基本信息 ──
            │   TextFormField(姓名, validator: required)
            │   TextFormField(邮箱, validator: email + unique)
            │   TextFormField(手机号, keyboardType: phone)
            │
            ├── ── 角色与权限 ──
            │   DropdownButton(角色, items: [super_admin, ops_manager, leasing_specialist, finance, frontline, sub_landlord])
            │   SearchableDropdown(所属部门, items: departments tree)
            │   └── 选 sub_landlord → 自动关联二房东门户权限
            │
            ├── ── 初始密码 ── (仅新建时显示)
            │   TextFormField(初始密码, obscureText: true)
            │   CheckboxListTile("首次登录强制修改密码", value: true, enabled: false)
            │
            └── FilledButton(context.isEdit ? "保存" : "创建用户")
                └── 成功 → ProposToast.success → 返回用户管理列表
```

### 10.4 组织架构管理页 `OrganizationManagePage`

**路由**: `/settings/org`  
**BLoC**: `OrganizationBloc`  
**API**: `GET /api/departments` + `GET/PUT /api/managed-scopes`

**组件树**:

```
Scaffold
├── AppBar(title: "组织架构", actions: [新建部门])
└── Row
    ├── ── 左侧: 部门树 ── (flex: 1)
    │   TreeView(departments)
    │   └── TreeNode(for each department)
    │       ├── Text(department.name)
    │       ├── Badge(下属员工数)
    │       ├── onTap → 右侧显示部门详情
    │       └── 右键菜单: [编辑] [新建子部门] [停用]
    │
    └── ── 右侧: 部门详情 & 管辖范围 ── (flex: 2)
        Column
        ├── Card("部门信息")
        │   └── 名称 | 层级 | 上级部门 | 状态
        │
        ├── Card("管辖范围配置")
        │   ├── Text("默认管辖范围（适用于部门下所有员工）")
        │   ├── CheckboxGroup(楼栋: [A座] [商铺区] [公寓楼])
        │   ├── CheckboxGroup(业态: [写字楼] [商铺] [公寓])
        │   └── FilledButton("保存范围")
        │
        └── Card("部门员工")
            └── DataTable
                │ 列: 姓名 | 角色 | 个人范围覆盖
                └── Row: 张三 | 租务专员 | [编辑个人范围]
```

### 10.5 KPI 方案管理页 `KpiSchemeListPage` / `KpiSchemeFormPage`

**路由**: `/settings/kpi/schemes` / `/settings/kpi/schemes/new`  
**BLoC**: `KpiSchemeManageBloc`  
**API**: `GET/POST /api/kpi/schemes`

**列表页**:

```
Scaffold
├── AppBar(title: "KPI 方案管理", actions: [新建方案])
└── ProposDataTable
    │ 列: 方案名称 | 评估周期 | 指标数 | 绑定对象数 | 有效期 | 状态
    └── Row → 点击进入方案详情编辑
```

**表单页 `KpiSchemeFormPage`**:

```
Scaffold
├── AppBar(title: "新建 KPI 方案")
└── Stepper(3步)
    ├── Step 1: "基本信息"
    │   ├── TextFormField(方案名称)
    │   ├── DropdownButton(评估周期: 月度/季度/年度)
    │   └── DateRangePicker(有效期)
    │
    ├── Step 2: "指标配置"
    │   └── DataTable(可编辑)
    │       │ 列: ☑ | 指标编号 | 名称 | 方向 | 权重(%) | 满分标准 | 及格标准
    │       ├── Row: ☑ K01 出租率 | 正向 | [15] | [95%] | [85%]
    │       ├── Row: ☑ K03 租户集中度 | 反向 | [10] | [40%] | [60%]
    │       └── Footer: 权重合计: {sum}% (必须=100%)
    │
    └── Step 3: "绑定对象"
        ├── SegmentedButton: [按部门] / [按员工]
        └── CheckboxList(部门/员工列表, 多选)
```

### 10.6 预警中心 `AlertCenterPage`

**路由**: `/settings/alerts`  
**BLoC**: `AlertCenterBloc`  
**API**: `GET /api/alerts`

**组件树**:

```
Scaffold
├── AppBar(title: "预警中心", actions: [全部已读, 补发预警])
└── Column
    ├── ── 筛选 ──
    │   Row
    │   ├── DropdownButton(类型: 全部/到期预警/逾期预警/押金提醒/填报提醒)
    │   ├── DropdownButton(状态: 全部/未读/已读)
    │   └── DateRangePicker(时间范围)
    │
    └── ListView.builder
        └── AlertListTile(for each alert)
            ├── Leading: Icon(alert_type 图标, color: 预警级别色)
            ├── Title: alert.message
            ├── Subtitle: alert.created_at + Text(关联合同/租户)
            ├── Trailing: 已读/未读标记
            └── onTap → 标记已读 + 跳转关联资源
```

### 10.7 递增模板管理页 `EscalationTemplateListPage`

**路由**: `/settings/escalation/templates`  
**BLoC**: `EscalationTemplateBloc`  
**API**: `GET /api/escalation-templates`

**组件树**:

```
Scaffold
├── AppBar(title: "递增规则模板", actions: [新建模板])
└── ProposDataTable
    │ 列: 模板名称 | 业态 | 阶段数 | 创建时间 | 状态 | 操作
    └── Row
        └── 操作: [编辑] [停用] [复制]
```

### 10.8 KPI 申诉页 `KpiAppealPage`

**路由**: `/settings/kpi/appeal`  
**BLoC**: `KpiAppealCubit`  
**API**: `POST /api/kpi/appeals` / `PATCH /api/kpi/appeals/:id/review`

**申诉提交表单**:

```
Scaffold
├── AppBar(title: "提交 KPI 申诉")
└── Form
    └── Column
        ├── ── 快照信息(只读) ──
        │   Card: 方案名称 | 周期 | 总分 | 冻结时间
        │
        ├── SectionHeader("申诉内容")
        ├── DropdownButton(申诉指标: K01/K02/...)
        ├── TextFormField(申诉理由, maxLines: 5)
        ├── FileUploadArea(证明材料, 可选)
        │
        ├── Text("申诉窗口剩余: {days} 天", color: warning)
        └── FilledButton("提交申诉")
```

**申诉审核页**（管理层视角）:

```
Scaffold
├── AppBar(title: "KPI 申诉审核")
└── ProposDataTable
    │ 列: 员工 | 方案 | 周期 | 申诉指标 | 状态 | 操作
    └── Row → 展开详情
        ├── 申诉理由 + 证明材料
        └── Row: FilledButton("批准重算") / OutlinedButton("驳回")
```

---

## 十一、响应式断点与布局策略

### 11.1 断点定义

| 断点 | 宽度范围 | 导航形式 | 布局列数 |
|------|---------|---------|---------|
| **Compact** | < 600px | BottomNavigationBar | 1 列 |
| **Medium** | 600~839px | BottomNavigationBar + Drawer | 1~2 列 |
| **Expanded** | 840~1199px | NavigationRail | 2 列 |
| **Large** | ≥ 1200px | NavigationRail (展开) | 2~4 列 |

### 11.2 组件响应策略

| 组件 | Compact | Expanded |
|------|---------|----------|
| `MetricCard` 行 | 2列 Grid | 4列 Grid |
| `DataTable` | 横向滚动 + 隐藏次要列 | 全列展示 |
| 表单 | 单列 | 双列 GridView |
| 详情页 Tab | Tab 滚动 | Tab 全部可见 |
| 图表 | 16:10 AspectRatio | 自适应高度 |
| 楼层图 | 全屏 InteractiveViewer | 左侧列表 + 右侧图 |
| 组织架构 | 单面板（树+详情切换） | 双面板（左树右详情） |

### 11.3 平台降级策略

| 功能 | 移动端(iOS/Android) | 桌面端(macOS/Windows) | Web |
|------|:------------------:|:-------------------:|:---:|
| QR 扫码报修 | ✅ `mobile_scanner` | ❌ → 手动填报 | ❌ → 手动填报 |
| 推送通知 | ✅ FCM | 应用内 Badge + 轮询 | 应用内 Badge + 轮询 |
| 相机拍照 | ✅ `image_picker` | ✅ | ⚠️ 基于浏览器 |
| 文件选取 | ✅ `file_picker` | ✅ | ✅ |

---

## 十二、状态色语义映射速查

### 12.0 Theme Token 色值对照（`buildAppTheme` 必须显式设定）

> `DEV_UI_SYNC_GUIDE.md` §7 中 `AppColors.warning` 定义为 `0xFFF57C00`，但未映射到 `colorScheme.tertiary`。
> 以下为修正后的完整映射，确保状态色系统与 Theme Token 不断裂：

| Token | Hex | 语义 | `AppColors` 常量 |
|-------|-----|------|------------------|
| `colorScheme.primary` | `#1976D2` | 蓝色系 — 主操作/进行中 | `AppColors.primary` |
| `colorScheme.primaryContainer` | `#BBDEFB` | 蓝色浅底 | `AppColors.primaryContainer` |
| `colorScheme.secondary` | `#388E3C` | 绿色系 — 成功/已完成 | `AppColors.secondary` |
| `colorScheme.secondaryContainer` | `#C8E6C9` | 绿色浅底（Toast success 背景） | `AppColors.secondaryContainer` |
| **`colorScheme.tertiary`** | **`#F57C00`** | **黄/橙色系 — 预警/待审核** | **`AppColors.warning`** |
| **`colorScheme.tertiaryContainer`** | **`#FFE0B2`** | **橙色浅底（Toast warning 背景）** | **`AppColors.warningContainer`** |
| `colorScheme.error` | `#D32F2F` | 红色系 — 错误/空置/逾期 | `AppColors.error` |
| `colorScheme.errorContainer` | `#FFCDD2` | 红色浅底（Toast error 背景） | `AppColors.errorContainer` |
| `colorScheme.surface` | `#FAFAFA` | 卡片/弹窗表面 | `AppColors.surface` |
| `colorScheme.outlineVariant` | `#9E9E9E` | 中性灰 — 停用/非可租 | `AppColors.unitNonLeasable` |

`buildAppTheme()` 中必须补充以下赋值（当前模板缺失）：

```dart
ColorScheme.light(
  primary:            AppColors.primary,
  primaryContainer:   AppColors.primaryContainer,
  secondary:          AppColors.secondary,
  secondaryContainer: AppColors.secondaryContainer,  // ← 新增
  tertiary:           AppColors.warning,              // ← 新增：关键修正
  tertiaryContainer:  AppColors.warningContainer,     // ← 新增
  error:              AppColors.error,
  errorContainer:     AppColors.errorContainer,       // ← 新增
  surface:            AppColors.surface,
  onSurface:          AppColors.onSurface,
  outlineVariant:     AppColors.unitNonLeasable,      // ← 新增
)
```

### 12.1 通用状态色

| 状态语义 | Theme Token | 适用场景 |
|---------|-------------|---------|
| 已租 / 已核销 / 已通过 / 已完成 | `colorScheme.secondary`（绿色系） | 单元已租、账单已核销、审核通过、工单完成 |
| 即将到期 / 预警 / 待审核 | `colorScheme.tertiary`（黄/橙色系） | 合同即将到期、逾期预警、待审核 |
| 空置 / 逾期 / 错误 / 已拒绝 | `colorScheme.error`（红色系） | 单元空置、账单逾期、审核退回 |
| 非可租 / 已作废 / 已停用 | `colorScheme.outlineVariant`（中性灰） | 非可租单元、作废账单、停用状态 |
| 执行中 / 处理中 / 草稿 | `colorScheme.primary`（蓝色系） | 合同执行中、工单处理中、草稿 |

### 12.2 合同状态色映射

| 状态 | 色彩 | 标签文案 |
|------|------|---------|
| `quoting` | `primary` | 报价中 |
| `pending_sign` | `tertiary` | 待签约 |
| `active` | `secondary` | 执行中 |
| `expiring_soon` | `tertiary` | 即将到期 |
| `expired` | `outlineVariant` | 已到期 |
| `renewed` | `secondary` | 已续签 |
| `terminated` | `error` | 已终止 |

### 12.3 账单状态色映射

| 状态 | 色彩 | 标签文案 |
|------|------|---------|
| `draft` | `primary` | 草稿 |
| `issued` | `tertiary` | 已出账 |
| `paid` | `secondary` | 已核销 |
| `overdue` | `error` | 逾期 |
| `cancelled` | `outlineVariant` | 已作废 |
| `exempt` | `outlineVariant` | 免租免单 |

### 12.4 工单状态色映射

| 状态 | 色彩 | 标签文案 |
|------|------|---------|
| `submitted` | `primary` | 已提交 |
| `approved` | `tertiary` | 已派单 |
| `in_progress` | `primary` | 处理中 |
| `pending_inspection` | `tertiary` | 待验收 |
| `completed` | `secondary` | 已完成 |
| `rejected` | `error` | 已拒绝 |
| `on_hold` | `outlineVariant` | 挂起 |

### 12.5 信用评级色映射

| 评级 | 色彩 | 标签文案 |
|------|------|---------|
| A | `secondary` | A 优质 |
| B | `tertiary` | B 一般 |
| C | `error` | C 风险 |

---

## 附录 A：页面清单与模块映射

| 页面名 | 路由 | 模块 | 优先级 | 泳道编号 |
|--------|------|------|--------|---------|
| `LoginPage` | `/login` | 认证 | Must | FE-02 |
| `ChangePasswordPage` | — | 认证 | Must | FE-02 |
| `DashboardPage` | `/dashboard` | 概览 | Must | FE-08 |
| `NoiDetailPage` | `/dashboard/noi-detail` | 概览 | Must | FE-08 |
| `WaleDetailPage` | `/dashboard/wale-detail` | 概览 | Must | FE-06 |
| `KpiDashboardPage` | `/dashboard/kpi` | KPI | Must | FE-13 |
| `KpiSchemeDetailPage` | `/dashboard/kpi/scheme/:id` | KPI | Must | FE-13 |
| `AssetOverviewPage` | `/assets` | 资产 | Should | FE-03 |
| `BuildingDetailPage` | `/assets/building/:id` | 资产 | Must | FE-03 |
| `FloorMapPage` | `/assets/.../floor/:id` | 资产 | Must | FE-04 |
| `UnitDetailPage` | `/assets/.../unit/:id` | 资产 | Must | FE-03 |
| `UnitImportPage` | `/assets/import` | 资产 | Must | FE-03 |
| `ContractListPage` | `/contracts` | 租务 | Must | FE-05 |
| `ContractFormPage` | `/contracts/new` | 租务 | Must | FE-05 |
| `ContractDetailPage` | `/contracts/:id` | 租务 | Must | FE-05 |
| `ContractTerminatePage` | `/contracts/:id/terminate` | 租务 | Must | FE-05 |
| `ContractRenewPage` | `/contracts/:id/renew` | 租务 | Must | FE-05 |
| `EscalationConfigPage` | `/contracts/:id/escalation` | 租务 | Must | FE-05 |
| `DepositListPage` | `/contracts/:id/deposits` | 租务 | Must | FE-05a |
| `DepositFormPage` | `/contracts/:id/deposits/new` | 租务 | Must | FE-05a |
| `TenantListPage` | `/tenants` | 租务 | Must | FE-05 |
| `TenantDetailPage` | `/tenants/:id` | 租务 | Must | FE-05 |
| `TenantFormPage` | `/tenants/new` | 租务 | Must | FE-05 |
| `FinanceOverviewPage` | `/finance` | 财务 | Must | FE-07 |
| `InvoiceListPage` | `/finance/invoices` | 财务 | Must | FE-07 |
| `InvoiceDetailPage` | `/finance/invoices/:id` | 财务 | Must | FE-07 |
| `PaymentFormPage` | `/finance/invoices/:id/pay` | 财务 | Must | FE-07 |
| `ExpenseListPage` | `/finance/expenses` | 财务 | Must | FE-07 |
| `ExpenseFormPage` | `/finance/expenses/new` | 财务 | Must | FE-07 |
| `MeterReadingListPage` | `/finance/meter-readings` | 财务 | Must | FE-07a |
| `MeterReadingFormPage` | `/finance/meter-readings/new` | 财务 | Must | FE-07a |
| `TurnoverReportListPage` | `/finance/turnover-reports` | 财务 | Must | FE-07b |
| `TurnoverReportDetailPage` | `/finance/turnover-reports/:id` | 财务 | Must | FE-07b |
| `WorkOrderListPage` | `/workorders` | 工单 | Must | FE-09 |
| `WorkOrderFormPage` | `/workorders/new` | 工单 | Must | FE-09 |
| `WorkOrderDetailPage` | `/workorders/:id` | 工单 | Must | FE-09 |
| `QrScanPage` | `/workorders/scan` | 工单 | Must | FE-09 |
| `SubLandlordPortalPage` | `/sublease-portal` | 二房东 | Must | FE-10 |
| `SubLandlordUnitListPage` | `/sublease-portal/units` | 二房东 | Must | FE-10 |
| `SubleaseFillingPage` | `/sublease-portal/units/:id/fill` | 二房东 | Must | FE-10 |
| `SubleaseImportPage` | `/sublease-portal/import` | 二房东 | Must | FE-10 |
| `SettingsPage` | `/settings` | 设置 | Must | FE-01 |
| `UserManagementPage` | `/settings/users` | 设置 | Must | FE-02 |
| `UserFormPage` | `/settings/users/new` | 设置 | Must | FE-02 |
| `OrganizationManagePage` | `/settings/org` | 设置 | Must | FE-13a |
| `KpiSchemeListPage` | `/settings/kpi/schemes` | KPI | Must | FE-13 |
| `KpiSchemeFormPage` | `/settings/kpi/schemes/new` | KPI | Must | FE-13 |
| `EscalationTemplateListPage` | `/settings/escalation/templates` | 设置 | Must | FE-05 |
| `AlertCenterPage` | `/settings/alerts` | 设置 | Must | FE-12 |
| `KpiAppealPage` | `/settings/kpi/appeal` | KPI | Must | FE-15 |

> **总计**: **50 个独立页面/视图**，覆盖 Phase 1 全部 Must 需求，正文规格覆盖率 100%。

---

## 附录 B：BLoC/Cubit 清单

| BLoC / Cubit | 对应页面 | 主要状态 |
|-------------|---------|---------|
| `AuthBloc` | 登录/注销/改密 | `Unauthenticated / Authenticated` |
| `DashboardBloc` | DashboardPage | `initial / loading / loaded(metrics) / error` |
| `NoiDetailBloc` | NoiDetailPage | `initial / loading / loaded(noiFull) / error` |
| `WaleDetailBloc` | WaleDetailPage | `initial / loading / loaded(waleData) / error` |
| `KpiDashboardBloc` | KpiDashboardPage | `initial / loading / loaded(scores, rankings, trends) / error` |
| `KpiSchemeDetailBloc` | KpiSchemeDetailPage | `initial / loading / loaded(scheme) / error` |
| `AssetOverviewBloc` | AssetOverviewPage | `initial / loading / loaded(buildings) / error` |
| `BuildingDetailBloc` | BuildingDetailPage | `initial / loading / loaded(building, floors) / error` |
| `FloorMapBloc` | FloorMapPage | `initial / loading / loaded(svg, heatmap) / error` |
| `UnitDetailBloc` | UnitDetailPage | `initial / loading / loaded(unit, renovations) / error` |
| `UnitImportBloc` | UnitImportPage | `initial / validating / validated(result) / importing / imported / error` |
| `ContractListBloc` | ContractListPage | `initial / loading / loaded(contracts, meta) / error` |
| `ContractFormCubit` | ContractFormPage | `initial / submitting / submitted / error` |
| `ContractDetailBloc` | ContractDetailPage | `initial / loading / loaded(contract) / error` |
| `ContractTerminateCubit` | ContractTerminatePage | `initial / submitting / terminated / error` |
| `EscalationConfigCubit` | EscalationConfigPage | `initial / loading / loaded(phases) / saving / saved / error` |
| `DepositListBloc` | DepositListPage | `initial / loading / loaded(deposits, transactions) / error` |
| `TenantListBloc` | TenantListPage | `initial / loading / loaded(tenants, meta) / error` |
| `TenantDetailBloc` | TenantDetailPage | `initial / loading / loaded(tenant) / error` |
| `FinanceOverviewBloc` | FinanceOverviewPage | `initial / loading / loaded(summary) / error` |
| `InvoiceListBloc` | InvoiceListPage | `initial / loading / loaded(invoices, meta) / error` |
| `InvoiceDetailBloc` | InvoiceDetailPage | `initial / loading / loaded(invoice, items) / error` |
| `PaymentFormCubit` | PaymentFormPage | `initial / submitting / submitted / error` |
| `MeterReadingFormCubit` | MeterReadingFormPage | `initial / calculating / submitting / submitted / error` |
| `TurnoverReportBloc` | TurnoverReportListPage | `initial / loading / loaded(reports) / error` |
| `WorkOrderListBloc` | WorkOrderListPage | `initial / loading / loaded(orders, meta) / error` |
| `WorkOrderFormCubit` | WorkOrderFormPage | `initial / submitting / submitted / error` |
| `WorkOrderDetailBloc` | WorkOrderDetailPage | `initial / loading / loaded(order) / error` |
| `QrScanCubit` | QrScanPage | `initial / scanning / matched(unit) / error` |
| `SubLandlordUnitListBloc` | SubLandlordUnitListPage | `initial / loading / loaded(units) / error` |
| `SubleaseFillingCubit` | SubleaseFillingPage | `initial / loading / loaded(sublease) / submitting / submitted / error` |
| `AlertCenterBloc` | AlertCenterPage | `initial / loading / loaded(alerts, meta) / error` |
| `UserManagementBloc` | UserManagementPage | `initial / loading / loaded(users, meta) / error` |
| `UserFormCubit` | UserFormPage | `initial / submitting / submitted / error` |
| `OrganizationBloc` | OrganizationManagePage | `initial / loading / loaded(tree, scopes) / error` |
| `KpiSchemeManageBloc` | KpiSchemeListPage | `initial / loading / loaded(schemes) / error` |
| `KpiAppealCubit` | KpiAppealPage | `initial / submitting / submitted / error` |
| `EscalationTemplateBloc` | EscalationTemplateListPage | `initial / loading / loaded(templates) / error` |
| `ContractRenewCubit` | ContractRenewPage | `initial / submitting / submitted / error` |
| `DepositFormCubit` | DepositFormPage | `initial / submitting / submitted / error` |
| `TenantFormCubit` | TenantFormPage | `initial / submitting / submitted / error` |
| `ExpenseListBloc` | ExpenseListPage | `initial / loading / loaded(expenses, meta) / error` |
| `ExpenseFormCubit` | ExpenseFormPage | `initial / submitting / submitted / error` |
| `MeterReadingListBloc` | MeterReadingListPage | `initial / loading / loaded(readings, meta) / error` |

---

*文档结束。如有疑问或需进一步细化单个页面交互（如表单校验规则、动画时序、无障碍标注），请联系前端负责人。*
