---
applyTo: flutter_app/lib/**
description: "Use when writing or editing Flutter app code. Enforces BLoC pattern, go_router, dio API client, get_it DI, Material 3 theming, and Clean Architecture layers."
---

# Flutter 端编码规范（PropOS）

## 架构分层

```
flutter_app/lib/
  core/           # 全局基础设施（跨 feature 共享）
  features/       # 按业务模块划分，每个 feature 内含 domain/data/presentation
  shared/         # 共享 Widget 和工具函数
```

每个 feature 内部严格遵循 Clean Architecture 三层：

| 层 | 职责 | 依赖方向 |
|----|------|---------|
| domain | 实体、抽象 Repository、UseCase | 无外部依赖（纯 Dart） |
| data | DTO、Repository 实现、ApiClient 调用 | 依赖 domain 接口 |
| presentation | BLoC/Cubit、Page、Widget | 依赖 domain（通过 DI 获取 Repository） |

**铁律**：`presentation` 不得 import `data` 层；`domain` 不得 import `package:flutter`。

## API 层规则

- 所有 HTTP 请求**必须**通过 `core/api/api_client.dart` 导出的辅助方法：
  `apiGet<T>` / `apiGetList<T>` / `apiPost<T>` / `apiPatch<T>` / `apiDelete<T>`
- 禁止在 BLoC、Widget、Repository 实现中直接实例化 `Dio()` 或调用 `dio.get/post`
- API 路径**必须**从 `core/constants/api_paths.dart` 导入常量，禁止字符串字面量硬编码
- API 调用放在 `features/<module>/data/repositories/<name>_repository_impl.dart`

### ApiClient 封装签名

```dart
class ApiClient {
  final Dio _dio;

  Future<T> apiGet<T>(String path, {Map<String, dynamic>? queryParams, T Function(dynamic)? fromJson});
  Future<ApiListResponse<T>> apiGetList<T>(String path, {Map<String, dynamic>? queryParams, required T Function(dynamic) fromJson});
  Future<T> apiPost<T>(String path, {dynamic data, T Function(dynamic)? fromJson});
  Future<T> apiPatch<T>(String path, {dynamic data, T Function(dynamic)? fromJson});
  Future<void> apiDelete(String path);
}
```

### 响应信封解析

ApiClient 内部统一解包服务端信封 `{"data": ..., "meta": ...}`：
- 单对象接口：提取 `body['data']` 传给 `fromJson`
- 列表接口：提取 `body['data']`（数组）+ `body['meta']`（分页元信息）
- 错误响应：`DioException` 包装为 `ApiException(code, message, statusCode)`，不透传原始异常

## Mock 数据层规则

通过 `flutter_dotenv` 读取 `.env` 中 `FLUTTER_USE_MOCK=true/false` 控制。

- Mock 机制在 `core/api/mock/` 下实现，通过 `MockInterceptor` 拦截 Dio 请求
- **新增 API 模块时必须同步创建对应 mock**：`data/repositories/xxx_repository_impl.dart` 对应 `core/api/mock/xxx_mock.dart`
- Mock 数据返回符合信封格式 `{"data": ..., "meta": ...}`
- `FLUTTER_USE_MOCK=false` 时不加载 MockInterceptor
- 支持部分 mock + 部分真实混合（URL 未匹配则 fallthrough）

## 状态管理规则（BLoC / Cubit）

### State 四态（必须使用 freezed sealed union）

```dart
@freezed
sealed class XxxState with _$XxxState {
  const factory XxxState.initial() = _Initial;
  const factory XxxState.loading() = _Loading;
  const factory XxxState.loaded(List<Xxx> items, {PaginationMeta? meta}) = _Loaded;
  const factory XxxState.error(String message) = _Error;
}
```

### BLoC / Cubit 规则

- 使用 `flutter_bloc` 包；简单状态用 Cubit，复杂事件驱动用 Bloc
- **禁止**在 BLoC/Cubit 中 import `package:flutter/...` 或 `../data/...`
- 通过构造函数注入 domain 层的 `abstract Repository` 接口
- 错误处理：`catch (e) { emit(XxxState.error(e is ApiException ? e.message : '操作失败，请重试')); }`
- 日期计算注入 `Clock` 接口（来自 `package:clock`），禁止直接调用 `DateTime.now()`
- 文件超过 200 行 → 按子领域拆分为多个 Cubit

### PaginatedCubit 基类（列表模块必须继承）

所有分页列表 Cubit **必须**继承 `shared/bloc/paginated_cubit.dart` 中的 `PaginatedCubit<T>`，禁止在各 feature 中重复编写分页加载逻辑。

`PaginatedCubit<T>` 提供：
- `load({pageSize})` — 加载/重载第一页
- `loadMore()` — 追加下一页（无限滚动）
- `refresh()` — 下拉刷新（从第 1 页重载，保留 pageSize）

`PaginatedState<T>` 为 `@Freezed(genericArgumentFactories: true)` 泛型四态：
- `initial` / `loading` / `loaded(items, meta)` / `error(message)`

子类**只需实现 `fetchPage(page, pageSize)`** 即可：

```dart
class ContractListCubit extends PaginatedCubit<Contract> {
  final ContractRepository _repository;
  ContractListCubit(this._repository);

  @override
  Future<ApiListResponse<Contract>> fetchPage(int page, int pageSize) =>
      _repository.getContracts(page: page, pageSize: pageSize);
}
```

**禁止**在 feature 内自建 `XxxListState` 四态 + 手写分页逻辑，统一使用 `PaginatedCubit<T>`。
如需在列表基础上增加筛选/排序等额外行为，可在子类中添加方法并调用 `load()` 重载。

### Cubit 示例（非列表场景）

```dart
class ContractDetailCubit extends Cubit<ContractDetailState> {
  final ContractRepository _repository;

  ContractDetailCubit(this._repository) : super(const ContractDetailState.initial());

  Future<void> fetch(String id) async {
    emit(const ContractDetailState.loading());
    try {
      final contract = await _repository.getContractById(id);
      emit(ContractDetailState.loaded(contract));
    } catch (e) {
      emit(ContractDetailState.error(e is ApiException ? e.message : '加载失败，请重试'));
    }
  }
}
```

## Page / Widget 规则

- Page 和 Widget 通过 `BlocBuilder` / `BlocListener` / `BlocConsumer` 获取状态，**禁止**内联 HTTP 请求
- 状态渲染**必须**使用 `.when()` 或 `switch` pattern matching（Dart 3 sealed class），禁止散落 `if (state is Xxx)`
- 禁止在 Widget 中包含业务逻辑（日期计算、金额格式化等提取到 `shared/utils/`）
- 每个 Page 文件 ≤ 150 行；超限则将子区域提取到同 feature 的 `widgets/` 下独立组件
- 每个 Widget 文件 ≤ 100 行
- 获取 BLoC 实例：`context.read<XxxCubit>()` 触发事件；`context.watch<XxxCubit>().state` 监听状态

## 路由规则（go_router）

- 所有路由在 `core/router/app_router.dart` 中声明式定义
- 导航使用 `context.go('/path')` / `context.push('/path')` / `context.pop()`
- **禁止**使用 `Navigator.push` / `Navigator.pop`
- 路由守卫通过 `GoRouter.redirect` 实现，检查 JWT token 有效性
- 公开路由（login、forgot-password）标注 `// public: true` 注释
- 路由路径常量放 `core/router/route_paths.dart`

```dart
abstract class RoutePaths {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const assets = '/assets';
  static const contracts = '/contracts';
  static const contractDetail = '/contracts/:id';
  // ...
}
```

## 依赖注入规则（get_it）

- 所有依赖注册在 `core/di/injection.dart`，使用 `GetIt.instance`（别名 `getIt`）
- **禁止**在 Widget 或 Page 中直接 `new XxxRepository()` 或 `new XxxCubit()`
- BLoC/Cubit 通过 `BlocProvider(create: (_) => getIt<XxxCubit>())` 注入 Widget 树
- 注册顺序：ApiClient → Repository 接口绑定 → UseCase → BLoC/Cubit

```dart
void configureDependencies() {
  // Core
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio));

  // Feature: Contract
  getIt.registerLazySingleton<ContractRepository>(
    () => ContractRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerFactory<ContractListCubit>(
    () => ContractListCubit(getIt<ContractRepository>()),
  );
}
```

## 日期处理

- 使用 `intl` 包的 `DateFormat`：`DateFormat('yyyy-MM-dd').format(dateTime)`
- 业务计算（WALE、逾期天数）在后端完成，前端不做日期业务计算
- BLoC/Cubit 中需要当前时间时，通过注入 `Clock` 获取，禁止直接 `DateTime.now()`
- API 传输始终使用 ISO 8601 字符串，`DateTime.parse(isoString)` 解析

## 颜色 / 主题规范

**全局主题**定义在 `core/theme/app_theme.dart`，基于 Material 3 ColorScheme：

```dart
final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0071E3), // Apple Blue 主色
    brightness: Brightness.light,
  ),
  // ...
);
```

**颜色使用规则**：
- 所有颜色通过 `Theme.of(context).colorScheme.*` 获取
- **禁止** `Colors.green` / `Colors.red` / `Color(0xFFxxxxxx)` 等硬编码颜色
- 业务语义色映射：

| 状态 | ColorScheme token | 含义 |
|------|------------------|------|
| `leased` / `paid` | `colorScheme.primary` 或自定义 extension `success` | 已租 / 已核销 |
| `expiring_soon` / `warning` | `colorScheme.tertiary` 或自定义 extension `warning` | 即将到期 / 预警 |
| `vacant` / `overdue` / `error` | `colorScheme.error` | 空置 / 逾期 / 错误 |
| `non_leasable` | `colorScheme.outline` | 非可租区域 |

- 扩展语义色通过 `ThemeExtension<CustomColors>` 实现（success、warning 等 Material 3 未内置的语义色）

## 常量规则

| 类型 | 文件 |
|------|------|
| API 路径 | `core/constants/api_paths.dart` |
| 业务阈值 | `core/constants/business_rules.dart` |
| UI 常量 | `core/constants/ui_constants.dart` |
| 路由路径 | `core/router/route_paths.dart` |

禁止在业务代码中出现魔法数字（如直接写 `30`、`90` 天）或字符串路径（如直接写 `'/api/contracts'`）。

常量使用 Dart `abstract class`（无实例化）+ `static const` 字段：

```dart
abstract class BusinessRules {
  static const warningDays90 = 90;
  static const warningDays60 = 60;
  static const warningDays30 = 30;
  static const overdueTier1 = 1;
  static const overdueTier2 = 7;
  static const overdueTier3 = 15;
  static const kpiFullScoreThreshold = 0.95;
}
```

## Dart 代码规范

- `analysis_options.yaml` 启用 `strict-casts: true`、`strict-raw-types: true`、`strict-inference: true`
- 所有实体类使用 `@freezed`，DTO 使用 `@freezed` + `@JsonSerializable`
- 禁止 `dynamic` 类型（除 JSON 反序列化入口参数 `factory Xxx.fromJson(Map<String, dynamic> json)`）
- 命名：文件名 `snake_case.dart`，类名 `PascalCase`，变量/函数 `camelCase`，常量 `camelCase`（Dart 风格）或 `SCREAMING_SNAKE_CASE`（仅全局配置常量）
- Lint 规则集：`flutter_lints` + 自定义 `analysis_options.yaml`

## Domain 层规则

- **禁止** `import 'package:flutter/...'`（纯 Dart），可以 import `package:freezed_annotation`
- **所有 domain entity 必须使用 `@freezed`**，确保值相等（`==` / `hashCode`）、不可变、`copyWith` 和 `toString`；BLoC/Cubit 的 `emit` 去重依赖 `==`，缺少正确的值相等会导致状态比较隐患
- Repository 定义为 `abstract class`（仅接口签名，不含实现）
- UseCase 通过构造函数注入 Repository 接口，单一方法 `call()`
- **枚举不加 `@freezed`**（Dart 枚举自带值相等），保留手写 `fromString()` / `toServerString()` 方法

### Domain Entity @freezed 模板

**基础实体**（无自定义方法）：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract.freezed.dart';

@freezed
abstract class Contract with _$Contract {
  const factory Contract({
    required String id,
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
    @Default(false) bool isTerminated,
  }) = _Contract;
}
```

**含自定义方法的实体**（需要私有构造函数 `const XxxEntity._();`）：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_user.freezed.dart';

@freezed
abstract class CurrentUser with _$CurrentUser {
  const CurrentUser._(); // 必须声明，否则无法添加实例方法
  const factory CurrentUser({
    required String id,
    required String name,
    required List<String> permissions,
  }) = _CurrentUser;

  bool hasPermission(String permission) => permissions.contains(permission);
}
```

**注意事项**：
- `part 'xxx.freezed.dart';` 必须添加，运行 `dart run build_runner build` 生成
- domain entity **不加** `@JsonSerializable` / `fromJson`（JSON 序列化放 data 层 Model）
- data 层 Model 的 `toEntity()` 使用 factory 构造函数：`Contract(id: id, ...)`
- 引用 domain entity 的 freezed state（如 `AuthState.authenticated(CurrentUser user)`）中，**不要**对 entity 的 import 加 `show` 限定，否则 freezed 生成的 `$XxxCopyWith` 不可见

### Repository 接口模板

```dart
abstract class ContractRepository {
  Future<PaginatedResult<Contract>> getContracts({int page, int pageSize});
  Future<Contract> getContractById(String id);
}
```

## Data 层规则

- 使用注入的 `ApiClient` 发起请求，禁止直接 `Dio()`
- API 路径从 `ApiPaths` 常量获取，禁止硬编码字符串
- 解析 `body['data']` 信封字段，不直接解析 HTTP 响应体
- `DioException` 包装为 `ApiException`，不透传原始异常
- Model（DTO）使用 `@freezed` + `@JsonSerializable`，`factory fromJson` 反序列化

## 文件复杂度超限拆分策略

| 文件类型 | 超限信号 | 拆分策略 |
|---------|---------|---------|
| `*_cubit.dart` / `*_bloc.dart` > 200 行 | 方法超过 6 个，或 State 超过 5 个变体 | 按子领域拆分 Cubit |
| `*_page.dart` > 150 行 | Widget 树嵌套超过 4 层 | 将子区域提取到 `widgets/` 下独立组件 |
| `*_widget.dart` > 100 行 | 单个 build 方法超过 60 行 | 继续拆分为更小的组合 Widget |
| `*_repository_impl.dart` > 200 行 | API 方法超过 8 个 | 按子功能拆分 Repository 实现 |

## 平台适配

### HarmonyOS Next
- 使用 Flutter HarmonyOS 分支（`flutter_harmony`）编译
- 平台特定代码通过 `defaultTargetPlatform` 判断（`TargetPlatform.ohos`）
- HarmonyOS 特有 API 通过 platform channel 封装在 `core/platform/` 下

### iOS / Android
- 遵循 Flutter 标准构建流程
- 平台差异 UI 使用 `.adaptive` 构造函数（如 `Switch.adaptive`）

## 测试规则

- BLoC/Cubit **必须**有单元测试（`bloc_test` 包）
- Repository 实现有集成测试（mock Dio 验证 API 调用）
- 测试目录结构镜像 `lib/` 结构
- 命名：`xxx_test.dart`

## 错误处理约定

- Data 层：捕获 `DioException` → 抛出 `ApiException(code, message, statusCode)`
- BLoC 层：捕获 `ApiException` → emit `XxxState.error(e.message)`
- UI 层：`state.when(error: (msg) => ErrorWidget(message: msg))` 展示

```dart
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({required this.code, required this.message, required this.statusCode});
}
```
