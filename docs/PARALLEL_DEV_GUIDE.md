# PropOS 前后端并发开发指南

> **版本**: v1.0
> **日期**: 2026-04-05
> **适用范围**: Phase 1 全部模块（M1~M5）

---

## 一、核心原则：API Contract 先行

前后端并发开发的唯一前提是**先签订 API Contract**。Contract 是双方的接口约定，一旦确认即可独立开发，联调时只替换前端 Mock 实现，BLoC 与 UI 层零改动。

```
┌─────────────────────────────────────────────────────────┐
│                  每个模块启动前（1~2天）                   │
│                                                          │
│   后端输出 API Contract（JSON 字段名 + 类型 + 枚举值）     │
│          ↓                                               │
│   前端确认字段满足 UI 需求（可协商调整）                   │
│          ↓                                               │
│   Contract 冻结 → 并发开发开始                            │
└─────────────────────────────────────────────────────────┘
         ↓                              ↓
┌─────────────────┐          ┌──────────────────────┐
│    后端开发      │          │      前端开发          │
│  实现真实业务逻辑 │          │  基于 Mock 驱动 UI    │
│  数据库 Schema  │          │  BLoC + 页面 + 测试   │
└────────┬────────┘          └──────────┬───────────┘
         └──────────────┬───────────────┘
                        ↓
                    联调（替换 Mock → 真实 HTTP）
```

---

## 二、API Contract 规范

### 2.1 Contract 定义格式

每个模块的 API Contract 以 Markdown 表格 + JSON 示例呈现，存放于 `docs/api/` 目录（如 `docs/api/m1_assets.md`），**不产生 PDF，供开发期快速迭代**。

Contract 必须包含以下内容：

| 要素 | 说明 |
|------|------|
| 端点路径 + HTTP 方法 | `GET /api/units` |
| 请求参数（Query / Body） | 字段名、类型、是否必填、默认值 |
| 响应 JSON 示例 | 完整的成功响应结构 |
| 枚举值列表 | 所有 string 枚举的合法值 |
| 错误 code 列表 | 该端点可能返回的 `error.code` |

### 2.2 Contract 示例（M1 单元列表）

**端点**：`GET /api/units`

**请求参数**：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | int | 否 | 1 | 页码（从 1 开始） |
| `pageSize` | int | 否 | 20 | 每页数量（最大 100） |
| `buildingId` | string(UUID) | 否 | — | 按楼栋过滤 |
| `propertyType` | string | 否 | — | `office`\|`retail`\|`apartment` |
| `status` | string | 否 | — | `leased`\|`vacant`\|`expiring_soon`\|`non_leasable` |

**响应示例**：

```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "unitNo": "10A",
      "propertyType": "office",
      "grossArea": 120.5,
      "netArea": 105.0,
      "currentStatus": "leased",
      "floor": {
        "id": "uuid",
        "floorName": "10F",
        "floorNumber": 10
      },
      "building": {
        "id": "uuid",
        "name": "A座"
      },
      "currentContractId": "uuid-or-null",
      "daysUntilExpiry": 45,
      "svgHotzoneCoords": [{"x": 100, "y": 200}, {"x": 300, "y": 200}]
    }
  ],
  "meta": {
    "page": 1,
    "pageSize": 20,
    "total": 441
  }
}
```

**枚举值**：

| 字段 | 合法值 |
|------|--------|
| `propertyType` | `office` / `retail` / `apartment` |
| `currentStatus` | `leased` / `vacant` / `expiring_soon` / `non_leasable` |

**错误 code**：

| code | HTTP | 场景 |
|------|------|------|
| `BUILDING_NOT_FOUND` | 404 | `buildingId` 指定的楼栋不存在 |
| `INVALID_REQUEST` | 400 | 参数格式错误 |

### 2.3 Contract 变更规则

- Contract 冻结后，**后端不得单方面修改字段名或删除字段**；如需变更，必须与前端协商，前端确认后方可调整
- 新增字段（非 breaking change）无需协商，但需通知前端
- 枚举新增值视为非 breaking change；删除枚举值必须协商

---

## 三、后端开发工作流

### 3.1 阶段划分

```
阶段 A：输出 API Contract（同步前端）
阶段 B：实现路由骨架（Controller 空实现，可返回固定 Mock 数据供前端联调验证）
阶段 C：实现 Repository + Service 真实逻辑
阶段 D：集成测试 + 联调
```

### 3.2 路由骨架先行（阶段 B）

Contract 确认后，**优先建立可运行的路由骨架**，Controller 返回固定 JSON，前端可立即用真实 HTTP 替代 Mock：

```dart
// contracts/controllers/unit_controller.dart — 骨架阶段
Router get router {
  final r = Router();
  r.get('/api/units', _listUnits);
  r.get('/api/units/<id>', _getUnit);
  r.post('/api/units', _createUnit);
  return r;
}

Future<Response> _listUnits(Request request) async {
  // 阶段 B：返回固定 Mock，前端可先联调响应结构
  return Response.ok(jsonEncode({
    'data': [_mockUnit()],
    'meta': {'page': 1, 'pageSize': 20, 'total': 1},
  }), headers: {'content-type': 'application/json'});
}
```

### 3.3 分层实现顺序（阶段 C）

```
models/（freezed 数据类 + Command 对象）
  ↓
repositories/（SQL 查询，从简单 SELECT 开始）
  ↓
services/（业务规则，调用 packages/ 计算库）
  ↓
controllers/（替换骨架 Mock → 真实 Service 调用）
```

### 3.4 后端开发检查清单

每个端点实现完成前确认：

- [ ] RBAC 中间件已在路由上注册（架构约束 #1）
- [ ] 二房东相关查询已在 Repository 层加行级隔离过滤（约束 #2）
- [ ] 加密字段 API 响应已脱敏（约束 #3）
- [ ] 变更操作已触发审计日志写入（约束 #4）
- [ ] Controller 未直接返回 `Response`，业务异常通过 `AppException` 抛出
- [ ] Service 方法只接受强类型 Command 对象，无 `Map<String, dynamic>` 参数

---

## 四、前端开发工作流

### 4.1 三阶段开发模式

```
阶段 1：Contract 确认后 → 建立 domain 层（freezed 类 + Repository 接口）
阶段 2：Mock 实现 → 建立 BLoC + 页面 UI（本地 Mock 驱动）
阶段 3：联调 → 替换 Mock Repository 为真实 HTTP 实现
```

### 4.2 阶段 1：domain 层（最先建立）

拿到 Contract JSON 示例后，立即定义 `freezed` 数据类和 Repository 抽象接口：

```dart
// features/assets/domain/unit.dart
@freezed
class Unit with _$Unit {
  const factory Unit({
    required String id,
    required String unitNo,
    required PropertyType propertyType,
    required double grossArea,
    double? netArea,
    required UnitStatus currentStatus,
    required FloorSummary floor,
    required BuildingSummary building,
    String? currentContractId,
    int? daysUntilExpiry,          // 计算字段，来自 API
    List<HotzonePoint>? svgHotzoneCoords,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
}

// features/assets/domain/unit_repository.dart
abstract class UnitRepository {
  Future<PagedResult<Unit>> listUnits({
    int page = 1,
    int pageSize = 20,
    String? buildingId,
    PropertyType? propertyType,
    UnitStatus? status,
  });

  Future<Unit> getUnit(String id);
}
```

### 4.3 阶段 2：Mock 实现（驱动 UI 开发）

在 `data/` 层建立 Mock 实现，**注册到 `get_it` 的开关控制**：

```dart
// features/assets/data/mock_unit_repository.dart
class MockUnitRepository implements UnitRepository {
  @override
  Future<PagedResult<Unit>> listUnits({
    int page = 1,
    int pageSize = 20,
    String? buildingId,
    PropertyType? propertyType,
    UnitStatus? status,
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    return PagedResult(
      items: List.generate(20, (i) => _mockUnit(i)),
      page: page,
      pageSize: pageSize,
      total: 100,
    );
  }

  Unit _mockUnit(int index) => Unit(
    id: 'mock-unit-$index',
    unitNo: '${10 + index}A',
    propertyType: PropertyType.office,
    grossArea: 120.0 + index * 5,
    currentStatus: index % 3 == 0 ? UnitStatus.vacant : UnitStatus.leased,
    floor: const FloorSummary(id: 'floor-1', floorName: '10F', floorNumber: 10),
    building: const BuildingSummary(id: 'building-1', name: 'A座'),
    daysUntilExpiry: index % 3 != 0 ? 30 + index : null,
  );
}
```

**DI 注册（`main.dart`）**：

```dart
// 开发期使用 Mock，联调时切换
const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

void setupDependencies() {
  if (useMock) {
    getIt.registerLazySingleton<UnitRepository>(() => MockUnitRepository());
  } else {
    getIt.registerLazySingleton<UnitRepository>(
      () => HttpUnitRepository(dio: getIt<Dio>()),
    );
  }
}
```

运行时通过 `--dart-define=USE_MOCK=true` 切换到 Mock 模式。

### 4.4 阶段 3：真实 HTTP 实现（联调）

后端路由骨架就绪后，补充 `HttpXxxRepository` 实现，替换 Mock：

```dart
// features/assets/data/http_unit_repository.dart
class HttpUnitRepository implements UnitRepository {
  final Dio _dio;
  HttpUnitRepository({required Dio dio}) : _dio = dio;

  @override
  Future<PagedResult<Unit>> listUnits({
    int page = 1,
    int pageSize = 20,
    String? buildingId,
    PropertyType? propertyType,
    UnitStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiPaths.units,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (buildingId != null) 'buildingId': buildingId,
          if (propertyType != null) 'propertyType': propertyType.name,
          if (status != null) 'status': status.name,
        },
      );
      final envelope = response.data as Map<String, dynamic>;
      final items = (envelope['data'] as List)
          .map((e) => Unit.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = envelope['meta'] as Map<String, dynamic>;
      return PagedResult(
        items: items,
        page: meta['page'] as int,
        pageSize: meta['pageSize'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);  // 统一包装，不透传 DioException
    }
  }
}
```

### 4.5 前端开发检查清单

每个 feature 完成前确认：

- [ ] `domain/` 层无任何 Flutter SDK import（纯 Dart）
- [ ] BLoC 通过构造函数注入 Repository **接口**，未直接实例化实现类
- [ ] `State` 使用 `freezed` sealed union，Widget 中全部用 `.when()` 渲染
- [ ] Widget 无 HTTP 调用、日期计算、业务判断
- [ ] 所有颜色 / 字号通过 `Theme.of(context)` 取值，无硬编码
- [ ] 状态色使用语义 Token（`secondary` / `tertiary` / `error` / `outlineVariant`）
- [ ] 常量已归入对应的常量文件，无魔法数字

---

## 五、联调流程

### 5.1 联调触发条件

满足以下两条即可开始联调，无需等后端全部完成：

1. 后端目标端点已部署到开发环境（哪怕仍返回 Mock 数据）
2. 前端 HTTP Repository 实现已完成

### 5.2 联调步骤

```
Step 1：后端部署到本地或开发服务器
         export DATABASE_URL=... JWT_SECRET=... （必填环境变量）
         dart run bin/server.dart

Step 2：前端切换到真实模式
         flutter run --dart-define=USE_MOCK=false

Step 3：逐端点验证
         ✓ 正常响应结构与 Contract 一致
         ✓ 分页参数有效
         ✓ 错误场景返回正确 error.code（前端 BLoC 按 code 处理）
         ✓ 加密字段已脱敏（仅显示后4位）
         ✓ 日期字段格式正确（ISO 8601 UTC）

Step 4：发现偏差时
         字段名不一致 → 后端修复（Contract 优先）
         字段缺失 → 协商后更新 Contract 再双端修复
         业务逻辑分歧 → 后端 Service 层修正
```

### 5.3 开发环境配置建议

| 角色 | 本地配置 |
|------|---------|
| 后端开发 | `.env` 文件注入环境变量，`dart run bin/server.dart` 启动 |
| 前端开发（Mock 阶段） | `flutter run --dart-define=USE_MOCK=true`，无需后端启动 |
| 前端开发（联调阶段） | `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:8080` |

---

## 六、分模块并发开发计划（Phase 1）

建议按以下顺序启动，每个模块均遵循"Contract 先行 → 双端并发 → 联调"流程：

| 模块 | Contract 依赖 | 推荐启动顺序 | 说明 |
|------|-------------|------------|------|
| M1 资产与空间 | 无 | **第1批** | 其他模块依赖 Unit/Building，须先完成 |
| Auth（登录鉴权） | 无 | **第1批** | BLoC 状态管理 + JWT 存储，须先完成 |
| M2 租务合同 | 依赖 M1 Unit | 第2批 | Contract 实体依赖 Unit 已存在 |
| M4 工单系统 | 依赖 M1 Unit | 第2批 | WorkOrder 定位依赖 Unit/Floor |
| M3 财务 NOI | 依赖 M2 Contract | 第3批 | Invoice 依赖 Contract |
| M5 二房东穿透 | 依赖 M1 + M2 | 第3批 | SubLease 依赖 Contract + Unit |

> **并发原则**：同批次内的模块前后端可完全并发；跨批次模块等上一批次的 **domain 层**（`freezed` 类 + Repository 接口）完成后即可启动，无需等待真实 API 完成。

---

## 七、常见问题

**Q：后端字段返回 `snake_case`，前端 `freezed` 用 `camelCase`，如何处理？**

后端 API 统一返回 `camelCase`（在 Controller 序列化时转换），不使用 `snake_case`。`freezed` 的 `@JsonKey` 只在少数特殊情况使用。

**Q：前端 Mock 数据与真实 API 响应结构不一致怎么办？**

以 Contract JSON 示例为准。Mock 数据必须严格按照 Contract 结构构造，发现不一致时优先修复 Mock（而不是等联调）。

**Q：后端某端点比预期晚完成，前端如何处理？**

前端保持 Mock 模式继续开发，对该端点的 `HttpXxxRepository` 可先留空实现（抛出 `UnimplementedError`），等后端就绪后直接补充实现即可。

**Q：多个开发者同时修改同一模块如何避免冲突？**

- 后端：按 `models → repositories → services → controllers` 顺序分工，单人负责一个子模块
- 前端：按 `domain → data → bloc → pages/widgets` 分工，`domain` 层优先由一人完成，其余层可并行

**Q：`env` 环境变量本地如何管理？**

后端根目录创建 `.env`（已加入 `.gitignore`），格式：

```bash
DATABASE_URL=postgres://user:pwd@localhost:5432/propos
JWT_SECRET=local-dev-secret-min-32-chars-long
JWT_EXPIRES_IN_HOURS=24
FILE_STORAGE_PATH=/tmp/propos_uploads
ENCRYPTION_KEY=0000000000000000000000000000000000000000000000000000000000000000
APP_PORT=8080
```

项目根目录提供 `.env.example`（含所有变量名，值填「示例占位符」），新成员克隆后复制 `.env.example` 为 `.env` 再填入真实值。
