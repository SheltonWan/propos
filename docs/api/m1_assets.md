# M1 资产模块 API 参考

> **权威来源**：本文档提炼自 [`docs/backend/API_CONTRACT_v1.7.md`](../backend/API_CONTRACT_v1.7.md) 第二章（§2.1–2.23）。  
> 字段级契约（类型、约束、枚举值）以 API_CONTRACT_v1.7.md 为准；本文档用于快速查阅。

---

## 通用约定

| 项目 | 规则 |
|------|------|
| 请求体格式 | `application/json`（除文件上传用 `multipart/form-data`） |
| 成功响应信封 | `{ "data": <payload>, "meta": {...} }`（`meta` 仅分页接口有） |
| 失败响应信封 | `{ "error": { "code": "SCREAMING_SNAKE_CASE", "message": "..." } }` |
| 分页参数 | `page`（从 1 起）+ `pageSize`（默认 20，最大 100） |
| 时间格式 | ISO 8601，UTC（`2026-04-05T08:00:00Z`） |
| 日期格式 | `YYYY-MM-DD`（仅日期字段） |

---

## 一、楼栋（Buildings）

### `GET /api/buildings` — 楼栋列表

**权限**: `assets.read`  
**分页**: 不分页（楼栋数量有限，< 10 栋）

**Response 200** — `BuildingSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 楼栋 ID |
| `name` | string | 楼栋名称（如"A座"） |
| `property_type` | string(enum) | 主业态：`office` / `retail` / `apartment` / `mixed` |
| `total_floors` | integer | 地上层数 |
| `basement_floors` | integer | 地下层数（默认 0） |
| `gfa` | number | 总建筑面积（m²） |
| `nla` | number | 净可租面积（m²） |
| `address` | string? | 地址 |
| `built_year` | integer? | 建成年份 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### `POST /api/buildings` — 创建楼栋

**权限**: `assets.write`

**Request Body**

| 字段 | 类型 | 必填 | 约束 |
|------|------|------|------|
| `name` | string | 是 | 最大 100 字符 |
| `property_type` | string(enum) | 是 | `office`/`retail`/`apartment`/`mixed` |
| `total_floors` | integer | 是 | > 0，最大 200 |
| `basement_floors` | integer | 否 | ≥ 0，最大 20，默认 0 |
| `gfa` | number | 是 | > 0 |
| `nla` | number | 是 | > 0 |
| `address` | string | 否 | — |
| `built_year` | integer | 否 | — |

**Response 201** — `BuildingSummary`

---

### `GET /api/buildings/:id` — 楼栋详情

**权限**: `assets.read`  
**Response 200** — `BuildingSummary`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `BUILDING_NOT_FOUND` | 楼栋不存在 |

---

### `PATCH /api/buildings/:id` — 更新楼栋

**权限**: `assets.write`  
**Request Body**：所有字段均可选，字段同创建接口。

> `total_floors`/`basement_floors` 只可增不可减；增加时自动补齐缺失楼层行。

**Response 200** — `BuildingSummary`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `BUILDING_NOT_FOUND` | 楼栋不存在 |
| `BUILDING_FLOOR_DECREASE_NOT_ALLOWED` | 传入层数小于当前已有层数 |

---

### `DELETE /api/buildings/:id` — 删除楼栋

**权限**: `management`（`super_admin` / `operations_manager`）  
**业务规则**：有关联 units / workorders / invoices 时拒绝；删除成功后自动级联删除 floor_plans + floors。

**Response 200**

```json
{ "data": { "id": "<uuid>", "deleted": true } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `BUILDING_NOT_FOUND` | 楼栋不存在 |
| `BUILDING_HAS_UNITS` | 楼栋下仍有单元 |
| `BUILDING_HAS_WORKORDERS` | 楼栋下仍有工单 |
| `BUILDING_HAS_INVOICES` | 楼栋下仍有账单 |

---

## 二、楼层（Floors）

### `GET /api/floors` — 楼层列表

**权限**: `assets.read`  

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |

**Response 200** — `FloorSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 楼层 ID |
| `building_id` | string(uuid) | 所属楼栋 |
| `building_name` | string | 楼栋名称 |
| `floor_number` | integer | 楼层号（负数 = 地下层） |
| `floor_name` | string? | 展示名（如"B1"、"10F"） |
| `svg_path` | string? | 当前生效 SVG 路径 |
| `png_path` | string? | 当前生效 PNG 路径 |
| `nla` | number? | 本层净可租面积（m²） |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### `POST /api/floors` — 创建楼层

**权限**: `assets.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 是 | 所属楼栋 |
| `floor_number` | integer | 是 | 楼层号（负数 = 地下层，同楼栋唯一） |
| `floor_name` | string | 否 | 展示名 |
| `nla` | number | 否 | 本层净可租面积 |

**Response 201** — `FloorSummary`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `FLOOR_ALREADY_EXISTS` | 同一楼栋下楼层号已存在 |

---

### `GET /api/floors/:id` — 楼层详情

**权限**: `assets.read`  
**Response 200** — `FloorSummary`

---

### `POST /api/floors/:id/cad` — 上传楼层 CAD 图纸

**权限**: `assets.write`  
**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | .dwg 文件 |
| `version_label` | string | 是 | 版本标签（如"原始图纸""2026改造后"） |

**Response 202** — 异步转换已触发

| 字段 | 类型 | 说明 |
|------|------|------|
| `floor_plan_id` | string(uuid) | 图纸版本记录 ID |
| `version_label` | string | 版本标签 |
| `status` | string | `converting`（转换中） |

> 转换完成后自动更新楼层的 `svg_path` / `png_path`，并设为 `is_current = true`。

---

### `GET /api/floors/:id/heatmap` — 楼层热区状态色块

**权限**: `assets.read`  
**Response 200** — `FloorHeatmap`

| 字段 | 类型 | 说明 |
|------|------|------|
| `floor_id` | string(uuid) | 楼层 ID |
| `svg_path` | string? | 当前生效 SVG 路径 |
| `units` | `HeatmapUnit[]` | 单元热区列表 |

**`HeatmapUnit`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `current_status` | string(enum) | `leased` / `vacant` / `expiring_soon` / `non_leasable` |
| `property_type` | string(enum) | 业态 |
| `tenant_name` | string? | 当前租户名称（已租时返回） |
| `contract_end_date` | string(date)? | 合同到期日（已租时返回） |

---

### `GET /api/floors/:id/plans` — 楼层图纸版本列表

**权限**: `assets.read`  
**Response 200** — `FloorPlanVersionDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 图纸版本 ID |
| `floor_id` | string(uuid) | 楼层 ID |
| `version_label` | string | 版本标签 |
| `svg_path` | string | SVG 文件路径 |
| `png_path` | string? | PNG 文件路径 |
| `is_current` | boolean | 是否为当前生效版本 |
| `uploaded_by` | string(uuid)? | 上传人 ID |
| `uploaded_by_name` | string? | 上传人姓名 |
| `created_at` | string(datetime) | 上传时间 |

---

### `PATCH /api/floor-plans/:id/set-current` — 切换当前生效图纸版本

**权限**: `assets.write`  
**Request Body**: 无  
**Response 200** — `FloorPlanVersionDto`

---

## 三、单元（Units）

### `GET /api/units` — 单元分页列表

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `floor_id` | string(uuid) | 否 | 按楼层过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `current_status` | string(enum) | 否 | 按出租状态过滤 |
| `is_leasable` | boolean | 否 | 是否可租 |
| `archived` | boolean | 否 | 含已归档单元（默认 false） |
| `page` | integer | 否 | 页码（默认 1） |
| `pageSize` | integer | 否 | 每页条数（默认 20） |

**Response 200** — `UnitSummary[]`（带 `meta` 分页）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 单元 ID |
| `building_id` | string(uuid) | 楼栋 ID |
| `building_name` | string | 楼栋名称 |
| `floor_id` | string(uuid) | 楼层 ID |
| `floor_name` | string? | 楼层名称 |
| `unit_number` | string | 单元编号 |
| `property_type` | string(enum) | 业态 |
| `gross_area` | number? | 建筑面积（m²） |
| `net_area` | number? | 套内面积（m²） |
| `current_status` | string(enum) | 出租状态 |
| `is_leasable` | boolean | 是否可租 |
| `decoration_status` | string(enum) | 装修状态：`blank` / `simple` / `refined` / `raw` |
| `market_rent_reference` | number? | 参考市场租金（元/m²/月） |
| `archived_at` | string(datetime)? | 归档时间 |
| `created_at` | string(datetime) | 创建时间 |

---

### `POST /api/units` — 创建单元

**权限**: `assets.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `floor_id` | string(uuid) | 是 | 所属楼层 |
| `building_id` | string(uuid) | 是 | 所属楼栋 |
| `unit_number` | string | 是 | 单元编号（同楼栋唯一，最大 50 字符） |
| `property_type` | string(enum) | 是 | `office` / `retail` / `apartment` |
| `gross_area` | number | 否 | 建筑面积（m²，> 0） |
| `net_area` | number | 否 | 套内面积（m²，> 0） |
| `orientation` | string | 否 | `east` / `south` / `west` / `north` |
| `ceiling_height` | number | 否 | 层高（m） |
| `decoration_status` | string(enum) | 否 | 装修状态（默认 `blank`） |
| `is_leasable` | boolean | 否 | 是否可租（默认 true） |
| `ext_fields` | object | 否 | 业态扩展字段（见下方） |
| `market_rent_reference` | number | 否 | 参考市场租金 |
| `qr_code` | string | 否 | QR 码标识（全局唯一） |

**`ext_fields` 按业态**

| 业态 | 字段 |
|------|------|
| `office` | `{ "workstation_count": int?, "partition_count": int? }` |
| `retail` | `{ "frontage_width": number?, "street_facing": bool?, "retail_ceiling_height": number? }` |
| `apartment` | `{ "bedroom_count": int?, "en_suite_bathroom": bool? }` |

**Response 201** — `UnitDetail`

---

### `GET /api/units/:id` — 单元详情

**权限**: `assets.read`  
**Response 200** — `UnitDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 单元 ID |
| `building_id` | string(uuid) | 楼栋 ID |
| `building_name` | string | 楼栋名称 |
| `floor_id` | string(uuid) | 楼层 ID |
| `floor_name` | string? | 楼层名称 |
| `unit_number` | string | 单元编号 |
| `property_type` | string(enum) | 业态 |
| `gross_area` | number? | 建筑面积 |
| `net_area` | number? | 套内面积 |
| `orientation` | string? | 朝向 |
| `ceiling_height` | number? | 层高 |
| `decoration_status` | string(enum) | 装修状态 |
| `current_status` | string(enum) | 出租状态 |
| `is_leasable` | boolean | 是否可租 |
| `ext_fields` | object | 业态扩展字段 |
| `current_contract_id` | string(uuid)? | 当前绑定合同 |
| `qr_code` | string? | QR 码标识 |
| `market_rent_reference` | number? | 参考市场租金 |
| `predecessor_unit_ids` | string(uuid)[] | 前序单元 ID 列表 |
| `archived_at` | string(datetime)? | 归档时间 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### `PATCH /api/units/:id` — 更新单元

**权限**: `assets.write`  
**Request Body**：所有字段均可选，字段同创建接口（另加 `predecessor_unit_ids`、`archived_at`）。  
**Response 200** — `UnitDetail`

---

### `POST /api/units/import` — 批量导入单元

**权限**: `assets.write`  
**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | Excel 文件（.xlsx / .xls）或 CSV（UTF-8） |
| `dry_run` | boolean | 否 | 仅校验不入库（默认 false） |

**Response 200** — `ImportBatchDetail`（详见 §七）

---

### `GET /api/units/export` — 导出房源台账 Excel

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `property_type` | string(enum) | 否 | 按业态筛选 |

**Response 200** — Excel 二进制流

```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename="units_export.xlsx"
```

---

## 四、改造记录（Renovations）

### `GET /api/renovations` — 改造记录分页列表

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 否 | 按单元过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `RenovationSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 改造记录 ID |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `renovation_type` | string | 改造类型 |
| `started_at` | string(date) | 开始日期 |
| `completed_at` | string(date)? | 完成日期 |
| `cost` | number? | 施工造价（元） |
| `contractor` | string? | 施工方 |
| `created_at` | string(datetime) | 创建时间 |

---

### `POST /api/renovations` — 新增改造记录

**权限**: `assets.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 是 | 单元 ID |
| `renovation_type` | string | 是 | 改造类型（如"隔断改造"） |
| `started_at` | string(date) | 是 | 开始日期 |
| `completed_at` | string(date) | 否 | 完成日期 |
| `cost` | number | 否 | 施工造价（≥ 0） |
| `contractor` | string | 否 | 施工方 |
| `description` | string | 否 | 描述 |

**Response 201** — `RenovationDetail`

---

### `GET /api/renovations/:id` — 改造记录详情

**权限**: `assets.read`  
**Response 200** — `RenovationDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 改造记录 ID |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `renovation_type` | string | 改造类型 |
| `started_at` | string(date) | 开始日期 |
| `completed_at` | string(date)? | 完成日期 |
| `cost` | number? | 施工造价 |
| `contractor` | string? | 施工方 |
| `description` | string? | 描述 |
| `before_photo_paths` | string[] | 改造前照片路径列表 |
| `after_photo_paths` | string[] | 改造后照片路径列表 |
| `created_by` | string(uuid)? | 创建人 ID |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### `PATCH /api/renovations/:id` — 更新改造记录

**权限**: `assets.write`  
**Request Body**：所有字段均可选，字段同创建接口（除 `unit_id`）。  
**Response 200** — `RenovationDetail`

---

### `POST /api/renovations/:id/photos` — 上传改造照片

**权限**: `assets.write`  
**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 照片文件（jpg / png） |
| `photo_stage` | string | 是 | `before`（改造前）/ `after`（改造后） |

**Response 201**

| 字段 | 类型 | 说明 |
|------|------|------|
| `storage_path` | string | 文件存储路径 |
| `photo_stage` | string | 照片阶段 |

---

## 五、资产概览看板

### `GET /api/assets/overview` — 资产概览

**权限**: `assets.read`  
**Response 200** — `AssetOverview`

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_units` | integer | 总套数 |
| `total_leasable_units` | integer | 可租套数 |
| `total_occupancy_rate` | number | 总体出租率（0~1，小数） |
| `wale_income_weighted` | number | WALE 收入加权（年，保留 2 位小数） |
| `wale_area_weighted` | number | WALE 面积加权（年，保留 2 位小数） |
| `by_property_type` | `PropertyTypeStats[]` | 按业态分拆统计 |

**`PropertyTypeStats`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `property_type` | string(enum) | 业态 |
| `total_units` | integer | 总套数 |
| `leased_units` | integer | 已租套数 |
| `vacant_units` | integer | 空置套数 |
| `expiring_soon_units` | integer | 即将到期套数 |
| `occupancy_rate` | number | 出租率（0~1，小数） |
| `total_nla` | number | 总可租面积（m²） |
| `leased_nla` | number | 已租面积（m²） |

---

## 六、枚举值速查

| 枚举名 | 取值 |
|--------|------|
| `PropertyType` | `office` / `retail` / `apartment` / `mixed` |
| `UnitStatus` | `leased` / `vacant` / `expiring_soon` / `non_leasable` |
| `DecorationStatus` | `blank` / `simple` / `refined` / `raw` |
| `Orientation` | `east` / `south` / `west` / `north` |
| `PhotoStage` | `before` / `after` |

---

## 七、状态色语义映射

| 状态 | Admin tag type | 含义 |
|------|---------------|------|
| `leased` | `success` | 已租 |
| `expiring_soon` | `warning` | 即将到期 |
| `vacant` | `danger` | 空置 |
| `non_leasable` | `info` | 非可租区域 |

---

## 八、端点速查表

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | `/api/buildings` | `assets.read` | 楼栋列表 |
| POST | `/api/buildings` | `assets.write` | 创建楼栋 |
| GET | `/api/buildings/:id` | `assets.read` | 楼栋详情 |
| PATCH | `/api/buildings/:id` | `assets.write` | 更新楼栋 |
| DELETE | `/api/buildings/:id` | `management` | 删除楼栋 |
| GET | `/api/floors` | `assets.read` | 楼层列表 |
| POST | `/api/floors` | `assets.write` | 创建楼层 |
| GET | `/api/floors/:id` | `assets.read` | 楼层详情 |
| POST | `/api/floors/:id/cad` | `assets.write` | 上传 CAD |
| GET | `/api/floors/:id/heatmap` | `assets.read` | 热区色块 |
| GET | `/api/floors/:id/plans` | `assets.read` | 图纸版本列表 |
| PATCH | `/api/floor-plans/:id/set-current` | `assets.write` | 切换生效版本 |
| GET | `/api/units` | `assets.read` | 单元列表（分页） |
| POST | `/api/units` | `assets.write` | 创建单元 |
| GET | `/api/units/:id` | `assets.read` | 单元详情 |
| PATCH | `/api/units/:id` | `assets.write` | 更新单元 |
| POST | `/api/units/import` | `assets.write` | 批量导入 |
| GET | `/api/units/export` | `assets.read` | 导出 Excel |
| GET | `/api/renovations` | `assets.read` | 改造记录列表 |
| POST | `/api/renovations` | `assets.write` | 新增改造记录 |
| GET | `/api/renovations/:id` | `assets.read` | 改造记录详情 |
| PATCH | `/api/renovations/:id` | `assets.write` | 更新改造记录 |
| POST | `/api/renovations/:id/photos` | `assets.write` | 上传改造照片 |
| GET | `/api/assets/overview` | `assets.read` | 资产概览看板 |
