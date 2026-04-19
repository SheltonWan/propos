# 为何 PC 管理后台（admin）与 Flutter 移动端独立维护

> **版本**: v1.1
> **日期**: 2026-04-13
> **背景**: Flutter 支持编译到 iOS / Android / HarmonyOS Next / Web / macOS / Windows，但 PropOS 仍选择为 PC 管理后台单独维护 `admin/` 项目（Vue 3 + Element Plus）。本文档说明此架构决策的原因。

---

## 一、决策结论

Flutter 的核心价值在于**一套代码覆盖三个移动平台**（iOS / Android / HarmonyOS Next），这一能力已被充分利用。PC 管理后台场景的 UI 密度、组件生态、交互范式与移动端差异过大，独立 `admin/` + Element Plus 是业界标准做法，也是维护成本最优解。

---

## 二、详细原因分析

### 2.1 UI 组件库与设计范式完全不同

| 维度 | Flutter App (`flutter_app/`) | admin (`admin/`) |
|------|------------------|------------------|
| 组件库 | **Material 3** — 移动端触控优先 | **Element Plus** — 桌面端鼠标/键盘优先 |
| 布局模式 | 单列滚动、卡片堆叠、BottomNavigationBar | 侧边栏 + 顶栏 + 多列表格 + 弹窗 |
| 核心交互组件 | BottomSheet、CupertinoPicker、TabBar | ElTable（排序/筛选/行展开）、ElForm（复杂校验）、ElTree、ElCascader |

Material 3 的 DataTable 在桌面级数据密度场景（639 条记录 + 筛选 + 批量操作）远不如 Element Plus 成熟；Element Plus 不运行在移动原生环境中。**两套组件库无法混用**，强行统一只会导致两边都做不好。

### 2.2 技术栈与语言生态完全不同

- Flutter App 使用 **Dart** 语言 + **dio** HTTP 客户端 + **flutter_bloc** 状态管理
- admin 使用 **TypeScript** 语言 + **axios** HTTP 客户端 + **Pinia** 状态管理

两端语言不同，代码无法直接共享。但通过保持 API 契约一致、常量命名规范对齐、状态管理模式对齐（四态 / setup 风格），最大化了开发体验的一致性。

### 2.3 路由体系根本不同

| 维度 | Flutter App | admin |
|------|---------|-------|
| 路由框架 | **go_router** 声明式 | **Vue Router 4** 编程式 |
| 导航 API | `context.go()` / `context.push()` | `router.push` / `router.replace` |
| 特性支持 | 嵌套路由、ShellRoute、深链接 | 嵌套路由、命名视图、懒加载 |
| 鉴权守卫 | `GoRouter.redirect` 读 AuthCubit 状态 | `router.beforeEach` 读 `localStorage.access_token` |

### 2.4 Flutter Web 输出并非最优桌面管理后台方案

Flutter 编译出的 Web 应用在管理后台场景存在劣势：

- CanvasKit 渲染引擎导致首屏加载体积较大（~2MB+）
- 文本选择、浏览器原生右键菜单、SEO 等 Web 特性体验不佳
- 大型数据表格的滚动性能和交互细节不如原生 DOM + CSS
- 开发者工具调试体验不如原生 Vue DevTools

要让 Flutter Web 变成合格的 PC 管理后台，需要大量 `Platform.isWeb` 条件分支和自定义 Widget，复杂度比维护两个独立项目高得多。

### 2.5 用户体验需求差异巨大

管理后台用户（超管、运营管理层、财务）的典型场景：

| 场景 | 信息密度 & 交互要求 |
|------|-------------------|
| NOI 实时看板 | 多图表并排、业态下钻 |
| 639 条账单批量操作 | 复杂表格筛选 + 批量核销 |
| KPI 仪表盘 | 雷达图 + 排名榜 + Excel 导出 |
| 合同录入 | 多单元绑定 + 递增规则配置器（多步表单） |

这些都是信息密度极高的桌面场景，与移动端的轻量卡片式交互是两种设计范式。

---

## 三、两端实际共享的部分

虽然两个前端是独立项目（Dart vs TypeScript），但已最大化共享一致性：

| 共享点 | 说明 |
|--------|------|
| 数据模型定义 | Flutter 使用 `@freezed` 不可变类，Admin 使用 TypeScript 接口，字段名与 API 契约一致 |
| 常量命名规范 | Flutter `api_paths.dart` / `business_rules.dart`，Admin `api_paths.ts` / `business_rules.ts`——各自维护但命名/结构对齐 |
| 状态管理模式 | Flutter 使用 BLoC/Cubit + freezed 四态，Admin 使用 Pinia setup 风格 + `list/item/loading/error/meta`——模式对齐 |
| 错误处理模式 | Flutter 统一 `ApiException(code, message, statusCode)`，Admin 统一 `ApiError(code, message, statusCode)` |
| 后端 API | 完全同一套 REST 接口，信封格式 `{ data, meta, error }` 统一 |

---

## 四、总结

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Flutter 全平台统一**（不采用） | 仅维护一套 Dart 代码 | Flutter Web 桌面表格体验差、首屏加载大、无 Element Plus 级组件生态、平台分支代码爆炸 |
| **独立 admin/ + Element Plus**（采用） | 各端最优体验、独立演进不互相拖累、社区生态成熟 | 需维护两个前端项目（但状态管理/常量/API 契约模式已对齐，实际重复量很小） |

> 业界同类项目（飞书管理后台 + 飞书移动端、钉钉 PC + 钉钉 App）也均采用桌面端与移动端独立前端的架构。

---

*文档结束*
