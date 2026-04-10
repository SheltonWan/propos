# 为何 PC 管理后台（admin）与 uni-app 移动端独立维护

> **版本**: v1.0
> **日期**: 2026-04-10
> **背景**: uni-app 4.x 支持编译到 iOS / Android / HarmonyOS Next / 微信小程序 / H5，但 PropOS 仍选择为 PC 管理后台单独维护 `admin/` 项目（Vue 3 + Element Plus）。本文档说明此架构决策的原因。

---

## 一、决策结论

uni-app 的核心价值在于**一套代码覆盖四个移动端**（iOS / Android / HarmonyOS Next / 微信小程序），这一能力已被充分利用。PC 管理后台场景的 UI 密度、组件生态、交互范式与移动端差异过大，独立 `admin/` + Element Plus 是业界标准做法，也是维护成本最优解。

---

## 二、详细原因分析

### 2.1 UI 组件库完全不同

| 维度 | uni-app (`app/`) | admin (`admin/`) |
|------|------------------|------------------|
| 组件库 | **wot-design-uni** — 移动端触控优先 | **Element Plus** — 桌面端鼠标/键盘优先 |
| 布局模式 | 单列滚动、卡片堆叠 | 侧边栏 + 顶栏 + 多列表格 + 弹窗 |
| 核心交互组件 | ActionSheet、Picker、Tab | ElTable（排序/筛选/行展开）、ElForm（复杂校验）、ElTree、ElCascader |

wot-design-uni 没有桌面级数据表格；Element Plus 没有移动端适配。**两套组件库无法混用**，强行统一只会导致两边都做不好。

### 2.2 HTTP 客户端层不兼容

- uni-app 使用 **luch-request**（封装 `uni.request`，才能在小程序/原生 App 中运行）
- admin 使用 **axios**（纯浏览器 `XMLHttpRequest`/`fetch`）

uni-app 编译到 H5 时 `uni.request` 会 polyfill，但 axios 的拦截器链、refresh token subscriber queue 等模式更适合桌面端复杂场景（如并发请求 401 刷新排队）。

### 2.3 路由体系根本不同

| 维度 | uni-app | admin |
|------|---------|-------|
| 路由声明 | `pages.json` 声明式 | Vue Router 4 编程式 |
| 导航 API | `uni.navigateTo` / `uni.switchTab` | `router.push` / `router.replace` |
| 特性支持 | 受多端运行时约束 | 嵌套路由、命名视图、懒加载 |
| 鉴权守卫 | 读 Pinia store 中的 `role` 字段 | `router.beforeEach` 读 `localStorage.access_token` |

### 2.4 uni-app H5 输出是「移动 Web」而非「桌面 Web」

uni-app 编译出的 H5 本质是**移动端网页**：

- 视口按 750rpx 基准缩放
- 页面结构是单栈导航（类原生 push/pop）
- 无法原生支持侧边栏布局、多 Tab 同屏、数据表格横向滚动等桌面交互

要让它变成合格的 PC 管理后台，需要大量 `#ifdef H5` 条件编译，等于在 uni-app 里重写一个 admin，代码复杂度比维护两个独立项目高得多。

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

虽然两个前端是独立项目，但已最大化共享一致性：

| 共享点 | 说明 |
|--------|------|
| TypeScript 类型定义 | 信封格式 `ApiResponse<T>` 等结构一致 |
| 常量命名规范 | `api_paths.ts`、`business_rules.ts`、`ui_constants.ts` 各自维护但命名/结构对齐 |
| Pinia store 模式 | 都用 `defineStore(id, setup)` 风格，state 固定字段 `list/item/loading/error/meta` |
| 错误处理模式 | 统一 `ApiError(code, message, statusCode)` 包装 |
| 后端 API | 完全同一套 REST 接口 |

---

## 四、总结

| 方案 | 优点 | 缺点 |
|------|------|------|
| **合并为一套 uni-app**（不采用） | 仅维护一个代码库 | 组件库不兼容、H5 输出为移动 Web、条件编译爆炸、桌面体验差 |
| **独立 admin/ + Element Plus**（采用） | 各端最优体验、独立演进不互相拖累、社区生态成熟 | 需维护两个前端项目（但 store/type/常量模式已对齐，实际重复量很小） |

> 业界同类项目（飞书管理后台 + 飞书移动端、钉钉 PC + 钉钉 App）也均采用桌面端与移动端独立前端的架构。

---

*文档结束*
