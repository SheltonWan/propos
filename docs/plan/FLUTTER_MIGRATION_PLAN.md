# 移动端技术栈迁移计划：uni-app → Flutter

> 版本：v1.0 | 日期：2026-04-20 | 状态：执行中

## 1. 背景

PropOS 移动端原采用 uni-app 4.x（Vue 3 + TypeScript + Vite）技术栈，一套代码覆盖 iOS / Android / HarmonyOS Next / 微信小程序 / H5。经评估决定切换至 **Flutter**，理由如下：

- Flutter 提供更优的原生渲染性能与一致的跨平台体验
- Dart 与后端技术栈（Dart + Shelf）统一语言，降低团队认知负担
- 华为已发布 Flutter HarmonyOS 分支，可满足 HarmonyOS Next 平台要求
- 微信小程序功能精简（仅扫码报修），决定放弃，简化架构

## 2. 关键决策

| 决策项 | 结论 |
|--------|------|
| 状态管理 | BLoC / Cubit（+ freezed 四态） |
| 路由方案 | go_router |
| HTTP 客户端 | dio |
| 依赖注入 | get_it |
| 代码生成 | freezed + json_serializable + build_runner |
| 项目目录 | 新建 `flutter_app/`，保留 `app/`（uni-app）不删除 |
| 微信小程序 | 放弃，Phase 1 范围移除 |
| HarmonyOS Next | Phase 1 必须支持（via flutter_harmony 分支，当前 Beta 阶段，已评估可行） |
| PC Admin | 不变，继续使用 Vue 3 + Element Plus（`admin/` 目录） |

## 3. Flutter 架构约定

```
flutter_app/
  lib/
    core/
      api/
        api_client.dart          # dio 封装（apiGet/apiPost/apiPatch/apiDelete）
        api_paths.dart           # API 路径常量
        api_exception.dart       # ApiException(code, message, statusCode)
      constants/
        business_rules.dart      # 业务规则常量（预警天数、逾期节点等）
        ui_constants.dart        # UI 展示常量（分页大小、动画时长等）
      theme/
        app_theme.dart           # Material 3 ColorScheme + Typography
      router/
        app_router.dart          # go_router 路由表 + 守卫
      di/
        injection.dart           # get_it 依赖注入注册
    features/
      <module>/
        domain/
          entities/              # 纯 Dart 实体类（freezed，无 Flutter SDK）
          repositories/          # 抽象接口（abstract class）
          usecases/              # 单一职责用例类
        data/
          models/                # freezed DTO + json_serializable
          repositories/          # Repository 实现，调用 ApiClient
        presentation/
          bloc/                  # BLoC/Cubit + freezed 四态 State
          pages/                 # Page ≤ 150 行
          widgets/               # 子 Widget ≤ 100 行
    shared/
      widgets/                   # 全局共享 Widget
      utils/                     # 工具函数
  test/                          # 与 lib/ 镜像的测试目录
  pubspec.yaml
```

**关键依赖**：

| 包名 | 版本约束 | 用途 |
|------|---------|------|
| `flutter_bloc` | ^8.x | 状态管理 |
| `freezed` | ^2.x | 不可变数据类 + sealed union |
| `json_serializable` | ^6.x | JSON 序列化 |
| `go_router` | ^14.x | 声明式路由 |
| `dio` | ^5.x | HTTP 客户端 |
| `get_it` | ^7.x | 依赖注入 |
| `intl` | latest | 日期格式化 |
| `flutter_dotenv` | latest | 环境变量 |

## 4. 文档更新范围

### 4.1 阶段一：核心 Copilot 配置（`.github/`）

> 最高优先级：Copilot 生成代码时的主要参照

| Step | 操作 | 文件 | 说明 |
|------|------|------|------|
| 1 | 重命名+重写 | `uniapp.instructions.md` → `flutter.instructions.md` | applyTo: `flutter_app/lib/**`；覆盖 BLoC/dio/go_router/colorScheme/get_it 全套规范 |
| 2 | 大幅修改 | `copilot-instructions.md` | 技术栈、目录结构、分层规则、色彩规范、常量管理、文件复杂度阈值全面替换 |
| 3 | 小幅修改 | `agents/feature-builder.agent.md` | Flutter 路径 `frontend/lib/` → `flutter_app/lib/`；必读文档引用更新 |
| 4 | 小幅修改 | `agents/compliance-reviewer.agent.md` | Flutter 检查路径更新为 `flutter_app/lib/features/` |
| 5 | 小幅修改 | `prompts/backend-module.prompt.md` | 移除 PAGE_SPEC uni-app 引用 |
| 6 | 小幅修改 | `prompts/security-and-test.prompt.md` | 移除 luch-request 安全检查项 |

### 4.2 阶段二：架构 & 开发指南（`docs/`）

| Step | 操作 | 文件 | 说明 |
|------|------|------|------|
| 7 | 修改 | `docs/ARCH.md` | 技术栈表格、目录结构图、移除小程序描述 |
| 8 | 修改 | `docs/guide/DEV_KICKSTART.md` | Flutter 环境搭建替换 pnpm install |
| 9 | 修改 | `docs/guide/COPILOT_GUIDE.md` | instructions 映射表更新 |
| 10 | 修改 | `docs/guide/DEV_UI_SYNC_GUIDE.md` | wot-design-uni → Flutter Widget checklist |
| 11 | 修改 | `docs/guide/TOOLCHAIN_WORKFLOW_GUIDE.md` | `/uniapp-page` → `/flutter-feature` |
| 12 | 修改 | `docs/frontend/guide/WHY_SEPARATE_ADMIN.md` | 分离理由重写 |

### 4.3 阶段三：前端规格文档

| Step | 操作 | 文件 | 说明 |
|------|------|------|------|
| 13 | 新建 | `docs/frontend/PAGE_SPEC_FLUTTER_v1.9.md` | 替代 v1.8，wot-design-uni → Flutter Widget |
| 14 | 新建 | `docs/frontend/FLUTTER_EXPERT_GUIDE.md` | 替代 UNIAPP_EXPERT_GUIDE.md |
| 15 | 新建 | `docs/frontend/guide/FLUTTER_DEVELOPMENT_GUIDE.md` | 替代 UNIAPP_DEVELOPMENT_GUIDE.md |
| 16 | 修改 | `docs/frontend/PAGE_WIREFRAMES_v1.8.md` | 移除 wot-design-uni 引用 |

### 4.4 阶段四：计划 & 测试 & 报告

| Step | 操作 | 文件 | 说明 |
|------|------|------|------|
| 17 | 大幅修改 | `docs/plan/PROJECT_PLAN.md` | 全文 uni-app → Flutter |
| 18 | 小幅修改 | `docs/plan/ROLE_EXPANSION_PLAN.md` | "App uni-app" → "App Flutter" |
| 19 | 废弃标注 | `docs/miniprogram/PAGE_SPEC.md` | 文件头加废弃声明 |
| 20 | 修改 | `docs/test/REQUIREMENTS_VERIFICATION_CHECKLIST.md` | NF-05 标 Dropped |
| 21 | 修改 | `docs/test/REQUIREMENTS_VERIFICATION_WITH_GUIDE.md` | 移除 uni-app 测试描述 |
| 22 | 小幅修改 | `docs/report/FEASIBILITY_ANALYSIS.md` | 结论补充 Flutter 切换记录 |

## 5. 验证清单

- [ ] `.github/copilot-instructions.md` 中无 `uni-app`、`luch-request`、`wot-design-uni`、`pinia`、`pages.json` 字样
- [ ] `flutter.instructions.md` 存在且覆盖 BLoC 四态、go_router、dio、colorScheme 规范
- [ ] `agents/feature-builder.agent.md` 中所有 `frontend/lib/` 路径改为 `flutter_app/lib/`
- [ ] `docs/ARCH.md` 技术栈表格中 uni-app 行被 Flutter 替换
- [ ] `docs/miniprogram/PAGE_SPEC.md` 有废弃声明
- [ ] 全文搜索 `uni-app`/`uniapp`：仅出现在已废弃文件的历史声明中

## 6. 风险与缓解

| 风险 | 等级 | 缓解措施 |
|------|------|---------|
| HarmonyOS Flutter 分支成熟度有限 | 中 | Phase 1 iOS/Android 优先交付，HarmonyOS 并行开发，预留降级方案 |
| 放弃微信小程序影响租户报修 | 低 | 扫码报修可通过 H5 页面承载（Flutter Web 或独立 H5）|
| 团队 Flutter 学习曲线 | 中 | 架构规范先行，Copilot instructions 辅助生成标准代码 |
