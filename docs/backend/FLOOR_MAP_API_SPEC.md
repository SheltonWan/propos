# Floor Map API 契约增补（v1.7+）

> **版本**：v1.0  
> **日期**：2026-04-30  
> **状态**：**预案文档（pending）** — 立项后需合并到 [API_CONTRACT_v1.7.md](./API_CONTRACT_v1.7.md) §2 资产模块  
> **关联**：[FLOOR_MAP_HYBRID_RENDERING_PLAN.md](./FLOOR_MAP_HYBRID_RENDERING_PLAN.md) §5  
> **错误码**：所有新增错误码须同步登记到 [ERROR_CODE_REGISTRY.md](./ERROR_CODE_REGISTRY.md)

---

## 0. 适用范围

本文档定义 **Floor Map v2 数据**（语义结构 + 单元 polygon）相关的 3 个新 API 端点，以及对现有楼层接口的字段扩展。所有响应严格遵循 PropOS 标准信封：成功 `{ data, meta? }` / 失败 `{ error: { code, message } }`。

---

## 1. 现有 `Floor` 资源字段扩展

### 1.1 数据库字段新增

```sql
ALTER TABLE floors
  ADD COLUMN render_mode VARCHAR(16) NOT NULL DEFAULT 'vector',
  ADD COLUMN floor_map_schema_version VARCHAR(8) NOT NULL DEFAULT '1.0',
  ADD COLUMN floor_map_updated_at TIMESTAMPTZ;
ALTER TABLE floors
  ADD CONSTRAINT chk_render_mode CHECK (render_mode IN ('vector', 'semantic'));
```

迁移文件命名遵循 [database-migration.instructions.md](../../.github/instructions/database-migration.instructions.md)。

### 1.2 `FloorSummary` 响应新增字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `render_mode` | `"vector" \| "semantic"` | 当前楼层渲染模式 |
| `floor_map_schema_version` | string | 当前 floor_map.json schema 版本（默认 `"1.0"`） |
| `floor_map_updated_at` | string(ISO 8601)? | 上次 floor_map 数据更新时间 |

`FloorDetail`（GET 单楼层）响应同步追加上述三字段。

---

## 2. 新增端点

### 2.1 `GET /api/floors/:floorId/structures/candidates`

获取自动抽取的候选结构项（用于 Admin 标注页"对比模式"）。

| 项 | 值 |
|---|---|
| 鉴权 | JWT |
| 权限 | `assets.read` |
| 限频 | 60 req/min/user |

**Path Params**

| 参数 | 类型 | 说明 |
|---|---|---|
| `floorId` | string(uuid) | 楼层 ID |

**Response 200** — `FloorMapCandidates`

```json
{
  "data": {
    "floor_id": "uuid",
    "schema_version": "2.0",
    "viewport": { "width": 1200, "height": 800 },
    "outline": { "type": "rect", "rect": { "x": 0, "y": 0, "w": 1200, "h": 800 } },
    "structures": [
      {
        "type": "elevator",
        "rect": { "x": 485, "y": 245, "w": 50, "h": 75 },
        "code": "E1",
        "source": "auto",
        "confidence": 1.0
      }
    ],
    "windows": [],
    "north": null,
    "extracted_at": "2026-04-30T08:00:00Z"
  }
}
```

**错误**

| code | HTTP | 说明 |
|---|---|---|
| `FLOOR_NOT_FOUND` | 404 | 楼层不存在 |
| `FLOOR_MAP_CANDIDATES_NOT_GENERATED` | 404 | 该楼层尚未运行抽取脚本 |

---

### 2.2 `PUT /api/floors/:floorId/structures`

提交人工审核后的最终结构数据，覆盖式更新。

| 项 | 值 |
|---|---|
| 鉴权 | JWT |
| 权限 | `assets.write` |
| 审计 | 必须记录到 `audit_logs`，action = `floor_map.structures.update` |
| 限频 | 30 req/min/user |

**Request Body** — `FloorMapStructuresUpdateRequest`

```json
{
  "schema_version": "2.0",
  "outline": { "type": "rect", "rect": { "x": 0, "y": 0, "w": 1200, "h": 800 } },
  "structures": [
    {
      "type": "core",
      "rect": { "x": 470, "y": 230, "w": 260, "h": 340 },
      "label": "核心筒",
      "source": "manual"
    },
    {
      "type": "elevator",
      "rect": { "x": 485, "y": 245, "w": 50, "h": 75 },
      "code": "E1",
      "source": "manual"
    },
    { "type": "column", "point": [10, 10], "source": "manual" }
  ],
  "windows": [
    { "side": "N", "offset": 30, "width": 30 }
  ],
  "north": { "x": 1140, "y": 60, "rotation_deg": 0 }
}
```

**字段约束**

| 字段 | 必填 | 校验 |
|---|---|---|
| `schema_version` | 是 | 必须 `"2.0"`（其他值返回 `FLOOR_MAP_SCHEMA_UNSUPPORTED`） |
| `outline.type` | 是 | `"rect"` 或 `"polygon"` |
| `outline.rect` 或 `outline.points` | 至少一个 | 二选一，与 `type` 对应 |
| `structures[].type` | 是 | 枚举见 [FLOOR_MAP_EXTRACTOR_SPEC.md](./FLOOR_MAP_EXTRACTOR_SPEC.md) §1 |
| `structures[].source` | 是 | 必须为 `"manual"`（PUT 端点不接收 `auto`） |
| `structures[].rect` 或 `point` | 视 type 定 | column 用 point，其他用 rect |
| `windows[].side` | 是 | `"N" \| "S" \| "E" \| "W"` |
| `north.rotation_deg` | 否 | `[-180, 180]` |
| 总 structures 数 | — | ≤ 200 |
| 总 windows 数 | — | ≤ 100 |

**坐标范围**：所有 `x/y/w/h/offset/width` 必须为整数像素，范围 `[0, viewport.width|height]`，超出返回 `FLOOR_MAP_COORDINATE_OUT_OF_RANGE`。

**Response 200** — `FloorMap`

返回完整的 `floor_map.json` 内容（含 `units[]`，因 unit polygon 由 `annotate_hotzone.py` 单独维护，PUT 端点不修改 units）。

**错误**

| code | HTTP | 说明 |
|---|---|---|
| `FLOOR_NOT_FOUND` | 404 | 楼层不存在 |
| `FLOOR_MAP_SCHEMA_UNSUPPORTED` | 400 | schema 版本不支持 |
| `FLOOR_MAP_COORDINATE_OUT_OF_RANGE` | 400 | 坐标越界 |
| `FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED` | 400 | 结构/窗洞数量超限 |
| `FLOOR_MAP_INVALID_STRUCTURE_TYPE` | 400 | type 不在枚举 |
| `FORBIDDEN` | 403 | 缺 `assets.write` 权限 |

---

### 2.3 `PATCH /api/floors/:floorId/render-mode`

切换楼层渲染模式（`vector` ↔ `semantic`）。

| 项 | 值 |
|---|---|
| 鉴权 | JWT |
| 权限 | `assets.write` |
| 审计 | 必须记录，action = `floor_map.render_mode.change` |
| 限频 | 10 req/min/user |

**Request Body**

```json
{ "render_mode": "semantic" }
```

**前置条件**：切换为 `semantic` 时，后端必须校验 `floor_map.json` 已包含：
- `outline` 非空
- `structures[]` 至少含一个 `core` 或 `corridor`（说明完成了基础人工审核）

不满足时返回 `FLOOR_MAP_NOT_READY_FOR_SEMANTIC`。切换回 `vector` 永远允许。

**Response 200**

```json
{
  "data": {
    "floor_id": "uuid",
    "render_mode": "semantic",
    "render_mode_changed_at": "2026-04-30T08:00:00Z",
    "changed_by": "user-uuid"
  }
}
```

**错误**

| code | HTTP | 说明 |
|---|---|---|
| `FLOOR_NOT_FOUND` | 404 | — |
| `FLOOR_MAP_NOT_READY_FOR_SEMANTIC` | 422 | 数据不完整，禁止切换 |
| `INVALID_RENDER_MODE` | 400 | 非枚举值 |
| `FORBIDDEN` | 403 | — |

---

## 3. 现有端点行为变更

### 3.1 `GET /api/floors/:floorId`

响应体追加：
```jsonc
{
  "data": {
    /* 原有字段 */
    "render_mode": "vector",
    "floor_map_schema_version": "2.0",
    "floor_map_updated_at": "2026-04-30T08:00:00Z",
    "floor_map": { /* 完整 floor_map.json，按 schema v2 */ }
  }
}
```

`floor_map` 字段在 `render_mode="vector"` 时仍返回 v1 兼容结构（仅含 viewport / dxf_region / units），客户端按 `schema_version` 分支处理。

### 3.2 `GET /api/floors`（列表）

`FloorSummary` 不返回完整 `floor_map`（避免列表接口体积膨胀），仅返回 §1.2 三个新增字段。

---

## 4. RBAC 矩阵增补

新增到 [RBAC_MATRIX.md](./RBAC_MATRIX.md)：

| 端点 | super_admin | property_owner | property_manager | finance | maintenance | tenant | sublease |
|---|---|---|---|---|---|---|---|
| `GET /candidates` | ✓ | ✓ | ✓ | — | — | — | — |
| `PUT /structures` | ✓ | ✓ | ✓ | — | — | — | — |
| `PATCH /render-mode` | ✓ | ✓ | ✓ | — | — | — | — |

---

## 5. 错误码登记

需追加到 [ERROR_CODE_REGISTRY.md](./ERROR_CODE_REGISTRY.md) 的 M1 资产模块章节：

| code | HTTP | 说明 |
|---|---|---|
| `FLOOR_MAP_CANDIDATES_NOT_GENERATED` | 404 | 候选数据未生成（请先运行抽取脚本） |
| `FLOOR_MAP_SCHEMA_UNSUPPORTED` | 400 | floor_map schema 版本不被支持 |
| `FLOOR_MAP_COORDINATE_OUT_OF_RANGE` | 400 | 坐标超出 viewport 范围 |
| `FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED` | 400 | 结构或窗洞数量超过上限 |
| `FLOOR_MAP_INVALID_STRUCTURE_TYPE` | 400 | structures[].type 不在枚举内 |
| `FLOOR_MAP_NOT_READY_FOR_SEMANTIC` | 422 | 数据未达到切换语义模式的最低要求 |
| `INVALID_RENDER_MODE` | 400 | render_mode 不在枚举内 |

---

## 6. 数据存储

### 6.1 表结构

新增表 `floor_maps`（一对一关联 floors）：

```sql
CREATE TABLE floor_maps (
  floor_id UUID PRIMARY KEY REFERENCES floors(id) ON DELETE CASCADE,
  schema_version VARCHAR(8) NOT NULL DEFAULT '2.0',
  viewport JSONB NOT NULL,            -- { width, height }
  dxf_region JSONB,                   -- { min_x, min_y, max_x, max_y }（v1 兼容字段）
  outline JSONB,                      -- v2 字段
  structures JSONB NOT NULL DEFAULT '[]'::jsonb,
  windows JSONB NOT NULL DEFAULT '[]'::jsonb,
  north JSONB,
  candidates JSONB,                   -- 自动抽取的候选项快照（用于 GET candidates 端点）
  candidates_extracted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES users(id)
);
CREATE INDEX idx_floor_maps_updated_at ON floor_maps(updated_at);
```

### 6.2 `units` 表的 polygon 数据保持现状

`units.polygon` 字段（[`SVG_HOTZONE_SPEC.md`](./SVG_HOTZONE_SPEC.md) 已定义）继续作为单元几何源，**不迁移**到 `floor_maps.units` 字段；`GET /api/floors/:floorId` 响应组装时由后端 join 拼接。

---

## 7. 兼容性

| 客户端 | 行为 |
|---|---|
| 老版本（仅认 `schema_version="1.0"`） | 后端按 `Accept-Version` header 或前端查询参数 `?schema=v1` 降级返回 v1 结构 |
| 不支持 `render_mode` 字段的旧前端 | 字段忽略即可，不影响渲染 |
| 切换 `semantic` 后旧前端访问 | 旧前端仍按 vector 渲染（loads SVG），视觉上等价 |

---

## 8. 灰度策略

| 阶段 | 范围 |
|---|---|
| Stage 1 | 仅在 dev 环境启用 v2 字段；生产仍返 v1 |
| Stage 2 | A 座 1 层楼试点，render_mode 默认 vector，手动切 1 个 floor 到 semantic |
| Stage 3 | A 座全栋启用 |
| Stage 4 | 全部楼栋启用 |

每个阶段必须通过 [TEST_PLAN.md](./TEST_PLAN.md) 中 M1 模块全部 e2e 测试。
# Floor Map Structures API 契约（增补稿）

> **版本**：v1.0（独立 spec，未合入 [API_CONTRACT_v1.7.md](./API_CONTRACT_v1.7.md) 主表，立项后再合并）  
> **关联**：[FLOOR_MAP_HYBRID_RENDERING_PLAN.md](./FLOOR_MAP_HYBRID_RENDERING_PLAN.md) §5、[FLOOR_MAP_EXTRACTOR_SPEC.md](./FLOOR_MAP_EXTRACTOR_SPEC.md)  
> **响应信封**：所有响应严格遵循 `{ data, meta } / { error }` 格式（[copilot-instructions.md "API 协议约定"](../../.github/copilot-instructions.md#api-协议约定)）

---

## 0. 端点总览

| 方法 | 路径 | 描述 | 权限 |
|---|---|---|---|
| GET | `/api/floors/:floorId/structures/candidates` | 拉取自动抽取的结构候选项（auto） | `assets.read` |
| GET | `/api/floors/:floorId/structures` | 拉取已确认的最终结构 + render_mode | `assets.read` |
| PUT | `/api/floors/:floorId/structures` | 提交人工审核后的最终 floor_map（覆盖写） | `assets.write` |
| PATCH | `/api/floors/:floorId/render-mode` | 切换 `vector` ↔ `semantic` | `assets.write` |

---

## 1. GET `/api/floors/:floorId/structures/candidates`

### 1.1 路径参数

| 名称 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `floorId` | UUID | ✅ | 楼层 ID |

### 1.2 响应

```jsonc
{
  "data": {
    "floor_id": "uuid",
    "schema_version": "2.0",
    "viewport": { "width": 1200, "height": 800 },
    "outline": { "type": "rect", "x": 0, "y": 0, "w": 1200, "h": 800 },
    "structures": [
      { "type": "core", "rect": {...}, "label": "核心筒", "source": "auto" },
      { "type": "elevator", "rect": {...}, "code": "E1", "source": "auto" }
    ],
    "windows": [{ "side": "N", "x": 30, "width": 30 }],
    "extracted_at": "2026-04-29T08:00:00Z",
    "extractor_version": "1.0"
  }
}
```

字段定义见 [floor_map.v2.schema.json](./schemas/floor_map.v2.schema.json)。

### 1.3 错误码

| code | HTTP | 含义 |
|---|---|---|
| `FLOOR_NOT_FOUND` | 404 | 楼层不存在 |
| `FLOOR_CANDIDATES_NOT_READY` | 409 | DXF 未上传或抽取尚未完成 |

### 1.4 实现约束

- **只读**端点，不得触发抽取流程（抽取由 DXF 上传后异步任务负责）
- 候选项**不写入 floors 表**，存于 `floor_map_candidates(floor_id, payload jsonb, extracted_at)`

---

## 2. GET `/api/floors/:floorId/structures`

### 2.1 响应

```jsonc
{
  "data": {
    "floor_id": "uuid",
    "render_mode": "semantic",
    "schema_version": "2.0",
    "viewport": {...},
    "outline": {...},
    "structures": [...],          // auto + manual 合并后的最终值
    "windows": [...],
    "north": { "x": 1140, "y": 60, "rotation_deg": 0 },
    "units": [...],               // 来自 hotzone 标注（已有数据源）
    "updated_at": "2026-04-29T08:00:00Z",
    "updated_by": "user_uuid"
  }
}
```

### 2.2 错误码

| code | HTTP | 含义 |
|---|---|---|
| `FLOOR_NOT_FOUND` | 404 | 楼层不存在 |
| `FLOOR_MAP_NOT_FOUND` | 404 | 楼层尚未做过结构标注 |

### 2.3 实现约束

- 返回值供前端 `FloorPlanSemanticView` 直接消费
- `units` 字段从现有 `unit_polygons` 表拼接，**不复制存储**

---

## 3. PUT `/api/floors/:floorId/structures`

### 3.1 请求体

```jsonc
{
  "schema_version": "2.0",
  "outline": { "type": "rect", "x": 0, "y": 0, "w": 1200, "h": 800 },
  "structures": [
    { "type": "core", "rect": {...}, "source": "auto" },
    { "type": "restroom", "rect": {...}, "gender": "M", "source": "manual" }
  ],
  "windows": [{ "side": "N", "x": 30, "width": 30 }],
  "north": { "x": 1140, "y": 60, "rotation_deg": 0 }
}
```

### 3.2 响应

```jsonc
{
  "data": {
    "floor_id": "uuid",
    "version": 3,                    // 写入后版本号自增
    "updated_at": "2026-04-29T08:00:00Z"
  }
}
```

### 3.3 校验规则（Service 层）

| 规则 | 错误码 | HTTP |
|---|---|---|
| schema 不通过 JSON Schema 校验 | `FLOOR_MAP_INVALID_SCHEMA` | 422 |
| 任何 rect 越出 outline | `FLOOR_MAP_RECT_OUT_OF_BOUNDS` | 422 |
| `outline.type` 与字段不匹配（rect+points 同时存在） | `FLOOR_MAP_INVALID_SCHEMA` | 422 |
| 同类 IoU > 0.7 | `FLOOR_MAP_DUPLICATE_STRUCTURE` | 422 |
| structures 数量 > 200 | `FLOOR_MAP_TOO_MANY_STRUCTURES` | 422 |
| windows 数量 > 200 | `FLOOR_MAP_TOO_MANY_WINDOWS` | 422 |

### 3.4 实现约束

- **覆盖写**：每次 PUT 全量替换 `floors.floor_map` 字段；版本号 `floors.floor_map_version` 自增
- **审计**：写入 `audit_log(action="floor_map.update", actor_id, floor_id, diff)`，diff 字段记录新增 / 修改 / 删除项
- **事务**：写库 + 审计在同一事务中
- **幂等**：客户端可在 header 带 `Idempotency-Key`（uuid），后端按 24h TTL 去重；可选实现

### 3.5 RBAC

- 必须通过 `assets.write` 中间件
- 二房东角色：禁止此端点（`tenant_user` / `sub_lessor` 在 RBAC 矩阵中无 `assets.write`）

---

## 4. PATCH `/api/floors/:floorId/render-mode`

### 4.1 请求体

```jsonc
{ "render_mode": "semantic" }   // "vector" | "semantic"
```

### 4.2 响应

```jsonc
{ "data": { "floor_id": "uuid", "render_mode": "semantic" } }
```

### 4.3 校验规则

| 规则 | 错误码 | HTTP |
|---|---|---|
| `render_mode` 不在枚举 | `FLOOR_RENDER_MODE_INVALID` | 422 |
| 切换到 `semantic` 但未做过结构标注 | `FLOOR_MAP_NOT_FOUND` | 404 |

### 4.4 实现约束

- 切换为 `semantic` 前必须确认 `floors.floor_map IS NOT NULL`
- 写审计 `audit_log(action="floor_map.render_mode_change", before, after)`

---

## 5. 错误码增补（待合入 [ERROR_CODE_REGISTRY.md](./ERROR_CODE_REGISTRY.md)）

| code | HTTP | 出现端点 | 含义 |
|---|---|---|---|
| `FLOOR_CANDIDATES_NOT_READY` | 409 | GET candidates | DXF 未上传或抽取未完成 |
| `FLOOR_MAP_NOT_FOUND` | 404 | GET / PATCH | 该楼层尚未提交过结构标注 |
| `FLOOR_MAP_INVALID_SCHEMA` | 422 | PUT | JSON Schema 校验失败 |
| `FLOOR_MAP_RECT_OUT_OF_BOUNDS` | 422 | PUT | 任意 rect 超出 outline 范围 |
| `FLOOR_MAP_DUPLICATE_STRUCTURE` | 422 | PUT | 同类 IoU > 0.7 |
| `FLOOR_MAP_TOO_MANY_STRUCTURES` | 422 | PUT | structures > 200 |
| `FLOOR_MAP_TOO_MANY_WINDOWS` | 422 | PUT | windows > 200 |
| `FLOOR_RENDER_MODE_INVALID` | 422 | PATCH | render_mode 枚举非法 |

错误码命名遵循 `SCREAMING_SNAKE_CASE`，前端按 `code` 做业务判断（[copilot-instructions.md](../../.github/copilot-instructions.md)）。

---

## 6. 数据库变更

### 6.1 新增字段

```sql
-- floors 表
ALTER TABLE floors ADD COLUMN render_mode VARCHAR(16) NOT NULL DEFAULT 'vector';
ALTER TABLE floors ADD COLUMN floor_map JSONB;
ALTER TABLE floors ADD COLUMN floor_map_version INTEGER NOT NULL DEFAULT 0;
ALTER TABLE floors ADD COLUMN floor_map_updated_at TIMESTAMPTZ;
ALTER TABLE floors ADD COLUMN floor_map_updated_by UUID REFERENCES users(id);

ALTER TABLE floors ADD CONSTRAINT chk_render_mode
  CHECK (render_mode IN ('vector', 'semantic'));

-- 候选项独立表（不污染 floors，可重新抽取）
CREATE TABLE floor_map_candidates (
  floor_id UUID PRIMARY KEY REFERENCES floors(id) ON DELETE CASCADE,
  payload JSONB NOT NULL,
  extractor_version VARCHAR(16) NOT NULL,
  extracted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 6.2 迁移规范

迁移脚本必须遵循 [database-migration.instructions.md](../../.github/instructions/database-migration.instructions.md)：
- 文件名 `migrations/2026XXXX_add_floor_map_v2.sql`
- TIMESTAMPTZ
- 加 `ROLLBACK` 段（同名 `_down.sql`）

---

## 7. 索引/性能

- `floor_map JSONB` 不建 GIN 索引（查询都通过 `floor_id` 直接定位）
- 候选项表写入频率低（每次 DXF 上传一次），无需分区

---

## 8. 安全审计要点

按 [security-checklist.instructions.md](../../.github/instructions/security-checklist.instructions.md)：

- ✅ IDOR：所有端点必须校验 `floorId` 属于当前用户可见的 building（已有 RBAC + tenant 过滤）
- ✅ 输入校验：JSON Schema 在 Controller 层执行（不可绕过）
- ✅ JSONB 大小限制：单次 PUT body 上限 256KB（在路由层 BodyLimit 中间件配置）
- ✅ 审计日志：4 个写端点全部记审计

---

## 9. 测试矩阵

| 场景 | 端点 | 期望 |
|---|---|---|
| 楼层无 DXF | GET candidates | 409 `FLOOR_CANDIDATES_NOT_READY` |
| 普通用户 PUT | PUT structures | 403 |
| rect 越界 | PUT structures | 422 `FLOOR_MAP_RECT_OUT_OF_BOUNDS` |
| 切换 semantic 但 floor_map=null | PATCH render-mode | 404 `FLOOR_MAP_NOT_FOUND` |
| 正常流程：上传→GET→PUT→PATCH→GET | 全 4 个 | 200 + 数据持久化 |

---

## 10. 实现顺序（给 Feature Builder）

1. 数据库 migration（§6）
2. Repository：`FloorMapRepository` 含 4 个方法
3. Service：`FloorMapService` 含 schema 校验 + IoU 检测 + 审计写入
4. Controller：4 个 handler，全部走 `error_handler.dart`
5. Flutter / Admin / uni-app 三端 ApiClient 增加方法（路径常量加到 `api_paths.{dart,ts}`）
