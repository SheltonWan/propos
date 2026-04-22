---
mode: agent
description: 创建 Flutter feature 模块的 Clean Architecture 三层结构（domain + data + presentation）。Use when implementing any Flutter feature under flutter_app/lib/features/.
---

# Flutter Feature 三层实现规范

@file:docs/frontend/PAGE_SPEC_FLUTTER_v1.9.md
@file:docs/frontend/PAGE_WIREFRAMES_v1.8.md
@file:docs/backend/API_CONTRACT_v1.7.md
@file:.github/copilot-instructions.md
@file:flutter_app/lib/core/di/injection.dart
@file:flutter_app/lib/core/router/app_router.dart
@file:flutter_app/lib/core/constants/api_paths.dart
@file:flutter_app/lib/core/router/route_paths.dart

## 当前任务

{{TASK}}

## 目录约定

目标路径：`flutter_app/lib/features/<module>/`，必须包含：

```
domain/
  entities/            ← @freezed 纯 Dart 实体类，无 Flutter SDK import
  repositories/        ← abstract class，只定义方法签名，无实现

data/
  models/              ← @freezed + json_serializable DTO，含 fromJson / toEntity
  repositories/        ← 实现 domain 层 abstract class，调用 ApiClient

presentation/
  bloc/                ← Cubit/BLoC + State（@freezed 四态 sealed union）
  pages/               ← Page Widget，每文件 ≤ 150 行
  widgets/             ← 子 Widget，每文件 ≤ 100 行
```

同步创建：
```
flutter_app/lib/core/api/mock/<module>_mock.dart   ← Mock 拦截数据
test/features/<module>/                            ← bloc_test 单元测试
```

同步修改：
```
flutter_app/lib/core/di/injection.dart             ← 注册 Repository + Cubit
flutter_app/lib/core/router/app_router.dart        ← 添加路由
flutter_app/lib/core/constants/api_paths.dart      ← 添加 API 路径常量
flutter_app/lib/core/router/route_paths.dart       ← 添加路由路径常量
```

## 1. Domain 层

### Entities

- 每个实体使用 `@freezed` 不可变数据类（`part '*.freezed.dart'`）
- 文件命名：`<entity_name>.dart`（snake_case）
- **禁止** `import 'package:flutter/...'`，domain 层必须为纯 Dart
- 枚举值使用 `camelCase`，枚举类型使用 `PascalCase`
- 日期字段类型为 `DateTime`，注释标明 UTC 存储

### Repository 接口

- `abstract class XxxRepository` 定义方法签名，无任何实现
- 列表方法签名：`Future<ApiListResponse<Xxx>> getXxxList({required int page, required int pageSize, ...filters})`
- 单对象方法签名：`Future<Xxx> getXxxById(String id)`
- 写操作方法签名：`Future<Xxx> createXxx(XxxRequest request)` / `Future<Xxx> updateXxx(String id, XxxRequest request)` / `Future<void> deleteXxx(String id)`

## 2. Data 层

### DTO Models

- 每个 DTO 使用 `@freezed` + `@JsonSerializable`（`part '*.freezed.dart'`、`part '*.g.dart'`）
- 字段名 `camelCase`（对应服务端 `snake_case` 时使用 `@JsonKey(name: 'snake_case_name')`）
- 必须实现 `toEntity()` 方法，将 DTO 转为 domain 层实体，**不向外暴露 DTO 类型**
- 证件号 / 手机号字段添加注释 `// 脱敏：仅返回后 4 位`

### Repository 实现

- 文件名：`<module>_repository_impl.dart`，实现 domain 层 abstract class
- **所有 HTTP 调用**必须通过 `ApiClient` 的具名方法：
  - 单对象：`apiClient.apiGet<XxxModel>(path, fromJson: XxxModel.fromJson)`
  - 列表：`apiClient.apiGetList<XxxModel>(path, fromJson: XxxModel.fromJson)`
  - 写操作：`apiClient.apiPost/apiPatch/apiDelete(...)`
- API 路径**必须**使用 `ApiPaths.<constant>`，禁止字符串字面量
- 返回前调用 `.toEntity()` 转换，禁止向 domain/presentation 层传递 DTO 对象
- `DioException` 已由 `ApiClient` 包装为 `ApiException`，Repository 层不再 catch

## 3. 状态管理（BLoC / Cubit）

### 列表功能：必须继承 PaginatedCubit<T>

```dart
/// [XxxListCubit] 只需实现 fetchPage，分页逻辑由基类管理。
class XxxListCubit extends PaginatedCubit<Xxx> {
  final XxxRepository _repository;
  XxxListCubit(this._repository);

  @override
  Future<ApiListResponse<Xxx>> fetchPage(int page, int pageSize) =>
      _repository.getXxxList(page: page, pageSize: pageSize);
}
```

- **禁止**自建 `XxxListState` 四态 + 手写分页逻辑
- `PaginatedCubit<T>` 来自 `shared/bloc/paginated_cubit.dart`，提供 `load()` / `loadMore()` / `refresh()`
- 如需筛选/排序，在子类添加字段并调用 `load()` 重载

### 非列表功能（详情、表单、操作）：标准四态 Cubit

```dart
@freezed
sealed class XxxDetailState with _$XxxDetailState {
  const factory XxxDetailState.initial() = _Initial;
  const factory XxxDetailState.loading() = _Loading;
  const factory XxxDetailState.loaded(Xxx item) = _Loaded;
  const factory XxxDetailState.error(String message) = _Error;
}

class XxxDetailCubit extends Cubit<XxxDetailState> {
  final XxxRepository _repository;
  XxxDetailCubit(this._repository) : super(const XxxDetailState.initial());

  Future<void> fetch(String id) async {
    emit(const XxxDetailState.loading());
    try {
      final item = await _repository.getXxxById(id);
      emit(XxxDetailState.loaded(item));
    } catch (e) {
      emit(XxxDetailState.error(e is ApiException ? e.message : '加载失败，请重试'));
    }
  }
}
```

### 通用规则
- **禁止** `import 'package:flutter/...'` 在 Cubit/State 文件中
- **禁止** `presentation` 层 import `data` 层（Cubit 只 import domain 层接口）
- Cubit 通过构造函数注入 domain 层 abstract repository，禁止直接实例化
- 文件超过 200 行时按子领域拆分为多个 Cubit

## 4. UI 层（Page / Widget）

### Cupertino 组件强制映射

| 替换前（禁止使用） | 替换后（必须使用） |
|-----------------|-----------------|
| `AppBar` | `CupertinoNavigationBar`（实现 `PreferredSizeWidget`） |
| `FilledButton` | `CupertinoButton.filled` |
| `TextButton` | `CupertinoButton` |
| `TextFormField` | `CupertinoTextFormField`（`shared/widgets/` 封装） |
| `Checkbox` | `CupertinoCheckbox` |
| `CircularProgressIndicator` | `CupertinoActivityIndicator` |
| `AlertDialog` | `showCupertinoDialog` + `CupertinoAlertDialog` |
| `PopupMenuButton` | `showCupertinoModalPopup` + `CupertinoActionSheet` |
| `Card` | `Container` + `BoxDecoration`（圆角 + 阴影） |
| `Icons.xxx` | `CupertinoIcons.xxx` |
| `NavigationBar` | `CupertinoTabBar` |

### 颜色规范

- 主色：`CupertinoTheme.of(context).primaryColor`
- 语义色（成功/警告/错误）：`Theme.of(context).colorScheme.*` 或 `ThemeExtension<CustomColors>`
- **禁止** `Colors.green` / `Color(0xFF...)` / 内联 `style:` 颜色硬编码

### 状态渲染

- **必须**使用 `.when()` 或 Dart 3 `switch` pattern matching 渲染状态
- **禁止**散落 `if (state is Xxx)` 判断

```dart
// 正确：
state.when(
  initial: () => const SizedBox.shrink(),
  loading: () => const CupertinoActivityIndicator(),
  loaded: (items, meta) => _buildList(items),
  error: (msg) => _ErrorView(message: msg),
);

// 禁止：
if (state is XxxStateLoaded) { ... }
```

### 页面规则

- Page 文件 ≤ 150 行；超限将子区域提取到同 feature 的 `widgets/` 下独立组件
- Widget 文件 ≤ 100 行
- Page 通过 `BlocProvider(create: (_) => getIt<XxxCubit>())` 挂载 Cubit
- **禁止**在 Page/Widget 中调用 `ApiClient`，**禁止** `Repository` 直接实例化
- `context.read<XxxCubit>()` 触发事件；`BlocBuilder` / `BlocListener` 监听状态
- 触发加载在 `initState` 或 `BlocProvider.create` 的 lambda 中完成
- 页面布局和组件树严格遵循 `PAGE_SPEC_FLUTTER_v1.9.md` 对应章节规格

## 5. 路由注册

- 在 `core/router/route_paths.dart` 添加新路由路径常量（`static const String xxx = '/xxx'`）
- 在 `core/router/app_router.dart` 添加路由声明：
  - 非 Tab 页面使用 `CupertinoPage` 作为 `pageBuilder`（支持 iOS 右滑返回动画）
  - Tab 页面已有 `StatefulShellRoute`，只需在对应分支中添加子路由
- **禁止** `Navigator.push` / `Navigator.pop`，统一用 `context.go()` / `context.push()` / `context.pop()`
- Tab 可见性通过 `AuthCubit.state.role` 控制，权限不足时不渲染对应 Tab

## 6. 依赖注入（get_it）

在 `core/di/injection.dart` 的 `configureDependencies()` 中追加注册，**顺序不可颠倒**：

```dart
// 1. Repository（先于 Cubit）
getIt.registerLazySingleton<XxxRepository>(
  () => XxxRepositoryImpl(getIt<ApiClient>()),
);

// 2. Cubit / BLoC（registerFactory — 每次 BlocProvider.create 新建实例）
getIt.registerFactory<XxxListCubit>(
  () => XxxListCubit(getIt<XxxRepository>()),
);
getIt.registerFactory<XxxDetailCubit>(
  () => XxxDetailCubit(getIt<XxxRepository>()),
);
```

- **禁止**在 Widget/Page 内直接 `new XxxCubit(...)` 或 `new XxxRepositoryImpl(...)`
- Singleton 用于跨页面共享状态的 Cubit（如 `AuthCubit`）；普通功能 Cubit 一律 `registerFactory`

## 7. API 路径常量

在 `core/constants/api_paths.dart` 的 `abstract class ApiPaths` 中追加：

```dart
// Xxx 模块
static const String xxxList = '/api/xxx';
static const String xxxDetail = '/api/xxx/{id}';
```

- 路径格式遵循 `API_CONTRACT_v1.7.md` 中的端点定义
- 带路径参数的路径使用 `String.replaceFirst('{id}', id)` 替换，禁止字符串插值拼接路径前缀

## 8. Mock 数据

在 `core/api/mock/<module>_mock.dart` 中注册 URL 拦截，返回符合信封格式的假数据：

```dart
// <Module> Mock 数据拦截
// 列表接口
if (path == ApiPaths.xxxList) {
  return {
    'data': [ /* 至少 3 条样本数据，字段与 API_CONTRACT 一致 */ ],
    'meta': {'page': 1, 'pageSize': 20, 'total': 3},
  };
}
// 单对象接口
if (path.startsWith('/api/xxx/')) {
  return {
    'data': { /* 单条样本数据 */ },
  };
}
```

- Mock 数据字段名和类型**必须**与 `API_CONTRACT_v1.7.md` 一致，不得自创字段
- 在 `MockInterceptor` 的路由表中登记新增的 mock handler

## 9. 测试

在 `test/features/<module>/` 下创建：

- `<module>_cubit_test.dart`：使用 `bloc_test` 覆盖至少以下路径：
  - `load()` 成功路径：`emitsInOrder([loading, loaded])`
  - `load()` 失败路径（ApiException）：`emitsInOrder([loading, error])`
  - `refresh()` 重置到第 1 页（仅列表 Cubit）
- 测试中通过 `MockXxxRepository`（`package:mocktail`）隔离网络层

```dart
blocTest<XxxDetailCubit, XxxDetailState>(
  'fetch 成功时 emit loading → loaded',
  build: () => XxxDetailCubit(mockRepository),
  act: (cubit) => cubit.fetch('test-id'),
  expect: () => [
    const XxxDetailState.loading(),
    XxxDetailState.loaded(fakeXxx),
  ],
);
```

## 禁止事项（每条都必须检查）

- ❌ `presentation` 层 import `data` 层任何文件
- ❌ `domain` 层 import `package:flutter/...`
- ❌ Widget / Page 内直接调用 `ApiClient` 或实例化 Repository
- ❌ 在 Cubit 文件中 import `package:flutter/...`
- ❌ 状态渲染使用 `if (state is Xxx)` 代替 `.when()` / `switch`
- ❌ API 路径字符串字面量硬编码（必须用 `ApiPaths.xxx` 常量）
- ❌ 颜色硬编码（`Colors.xxx`、`Color(0xFF...)`）
- ❌ 使用 Material 组件代替 Cupertino 等价物（见映射表）
- ❌ 使用 `Navigator.push/pop`（必须用 `context.go/push/pop`）
- ❌ 自建 `XxxListState` 四态 + 手写分页逻辑（必须继承 `PaginatedCubit<T>`）
- ❌ 超前实现 Phase 2 功能（租户门户、门禁、电子签章等）
- ❌ 代码注释使用英文（所有注释统一用中文）
