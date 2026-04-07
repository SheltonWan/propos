---
mode: agent
description: 创建 Flutter 前端的 UI 层（Pages + Widgets）。Use when building lib/features/<module>/presentation/pages/ or widgets/.
---

# Flutter UI 层实现规范

@file:docs/ARCH.md
@file:.github/copilot-instructions.md

## 当前任务

{{TASK}}

## 目录约定

```
presentation/
  pages/    ← 页面：顶层 Widget，只持有 BlocBuilder/BlocListener，无业务逻辑
  widgets/  ← 模块私有子组件，接受数据参数而非直接读 BLoC
```

## 强制约束

### 状态渲染
- **必须用 `.when()`**（或 `.map()`）分支渲染 State 变体，禁止 `if (state is XxxLoaded)` 散落判断
- `BlocBuilder` 提供 `buildWhen` 精确控制重建范围，避免不必要刷新

### 颜色与主题（最容易被违反）
- **禁止硬编码色值**（`Color(0xFF...)` / `Colors.green` / `Colors.red` 等）
- 颜色统一通过 `Theme.of(context).colorScheme` 取值：
  - `leased` / `paid` → `colorScheme.secondary`（绿色系）
  - `expiring_soon` / `warning` → `colorScheme.tertiary`（橙色系）
  - `vacant` / `overdue` / `error` → `colorScheme.error`（红色系）
  - `non_leasable` → `colorScheme.outlineVariant`（灰色）
- 字号/间距通过 `Theme.of(context).textTheme` 取，不写 `FontSize(14)`

### 常量
- 分页大小用 `kDefaultPageSize`（来自 `ui_constants.dart`），不写数字 `20`
- 路由路径用 `AppRoutes.xxx`（来自路由常量文件），不硬编码字符串

### 文件复杂度控制
- `*_page.dart` > 150 行 或 `build()` 嵌套超 4 层 → 将子区域提取到 `widgets/` 下的私有组件
- 页面只保留顶层组合，不内联大段 build 逻辑

### 平台适配
- 扫码功能：`PlatformUtils.supportsQrScan` 判断，桌面端隐藏扫码入口
- 所有 `Platform.isXxx` / `kIsWeb` 判断集中在 `lib/shared/platform_utils.dart`，页面层不散落

### 路由
- 使用 `go_router`，跳转用 `context.go()` / `context.push()`，不用 `Navigator.push()`

## 禁止事项

- Widget 中无 HTTP 调用、日期计算、业务判断
- 不在 Widget 中直接实例化 Repository 或 Service
- 不在 Widget 中调用 `DateTime.now()`
- 不覆盖为 Material 2 风格（保持 `useMaterial3: true`）
