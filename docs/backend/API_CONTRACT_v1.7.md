# PropOS 后端 API 契约文档 v1.7

> **版本**: v1.7  
> **日期**: 2026-04-08  
> **范围**: Phase 1 全端点 Request / Response 字段级定义  
> **依据**: API_INVENTORY v1.5 / data_model v1.5 / PRD v1.8 / ARCH v1.4  
> **信封协议**: 成功 `{ "data": <payload>, "meta"?: { "page", "pageSize", "total" } }` / 失败 `{ "error": { "code": "SCREAMING_SNAKE", "message": "..." } }`

---

## 通用约定

### 分页参数（适用于所有 GET 列表端点）

| 参数 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| `page` | integer | 否 | 1 | 页码（从 1 开始） |
| `pageSize` | integer | 否 | 20 | 每页条数（最大 100） |

### 分页响应 `meta`

```json
{ "page": 1, "pageSize": 20, "total": 639 }
```

### 通用错误码

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `UNAUTHORIZED` | 401 | 未登录或 Token 无效 |
| `FORBIDDEN` | 403 | 无操作权限 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION_ERROR` | 400 | 请求参数校验失败 |
| `CONFLICT` | 409 | 资源冲突（如重复创建） |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |

### 日期时间格式

- API 传输统一 ISO 8601：`2026-04-05T08:00:00Z`
- 日期字段（无时间）：`2026-04-05`

### 脱敏规则

- 证件号默认返回 `****XXXX`（末4位）
- 手机号默认返回 `***XXXX`（末4位）

---

## 一、认证与用户

### 1.1 `POST /api/auth/login` — 登录

**权限**: 公共

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 用户邮箱 |
| `password` | string | 是 | 密码（明文传输，HTTPS 保护） |

**Response 200** — `LoginResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | string | JWT access token |
| `refresh_token` | string | 刷新 token |
| `expires_in` | integer | access token 有效期（秒） |
| `user` | `UserBrief` | 当前用户基本信息 |

**`UserBrief`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 用户 ID |
| `name` | string | 姓名 |
| `email` | string | 邮箱 |
| `role` | string(enum) | 角色：`super_admin` / `operations_manager` / `leasing_specialist` / `finance_staff` / `maintenance_staff` / `property_inspector` / `report_viewer` / `sub_landlord` |
| `department_id` | string(uuid)? | 所属部门 ID |
| `must_change_password` | boolean | 是否需要强制改密（二房东首次登录） |

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVALID_CREDENTIALS` | 用户名或密码错误 |
| `ACCOUNT_LOCKED` | 登录失败达阈值，账号已锁定（附 `locked_until` 字段） |
| `ACCOUNT_DISABLED` | 账号已停用 |
| `ACCOUNT_FROZEN` | 二房东账号已冻结（主合同到期） |

---

### 1.2 `POST /api/auth/refresh` — 刷新 Token

**权限**: 已登录

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `refresh_token` | string | 是 | 当前 refresh token |

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | string | 新的 JWT access token |
| `refresh_token` | string | 新的 refresh token（轮换） |
| `expires_in` | integer | 有效期（秒） |

**错误码**

| 错误码 | 说明 |
|--------|------|
| `TOKEN_EXPIRED` | refresh token 已过期 |
| `TOKEN_REVOKED` | refresh token 已吊销（改密/冻结触发） |
| `SESSION_VERSION_MISMATCH` | session_version 不匹配（用户改密后旧 token 失效） |

---

### 1.3 `POST /api/auth/logout` — 注销

**权限**: 已登录

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `refresh_token` | string | 是 | 要吊销的 refresh token |

**Response 200**

```json
{ "data": { "message": "已注销" } }
```

---

### 1.4 `GET /api/auth/me` — 获取当前用户与权限

**权限**: 已登录

**Response 200** — `CurrentUser`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 用户 ID |
| `name` | string | 姓名 |
| `email` | string | 邮箱 |
| `role` | string(enum) | 角色 |
| `department_id` | string(uuid)? | 所属部门 ID |
| `department_name` | string? | 所属部门名称 |
| `permissions` | string[] | 权限列表（如 `["assets.read", "contracts.write"]`） |
| `bound_contract_id` | string(uuid)? | 二房东绑定的主合同 ID |
| `is_active` | boolean | 是否启用 |
| `last_login_at` | string(datetime)? | 上次登录时间 |

---

### 1.5 `GET /api/users` — 用户列表

**权限**: `super_admin`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `search` | string | 否 | 模糊搜索（姓名或邮箱，最大 100 字符） |
| `role` | string(enum) | 否 | 按角色过滤 |
| `department_id` | string(uuid) | 否 | 按部门过滤 |
| `is_active` | boolean | 否 | 按启停状态过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `UserSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 用户 ID |
| `name` | string | 姓名 |
| `email` | string | 邮箱 |
| `role` | string(enum) | 角色 |
| `department_id` | string(uuid)? | 所属部门 ID |
| `department_name` | string? | 所属部门名称 |
| `is_active` | boolean | 是否启用 |
| `last_login_at` | string(datetime)? | 上次登录时间 |
| `created_at` | string(datetime) | 创建时间 |

---

### 1.6 `GET /api/users/:id` — 用户详情

**权限**: `super_admin`

**Response 200** — `UserDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 用户 ID |
| `name` | string | 姓名 |
| `email` | string | 邮箱 |
| `role` | string(enum) | 角色 |
| `department_id` | string(uuid)? | 所属部门 ID |
| `department_name` | string? | 所属部门名称 |
| `is_active` | boolean | 是否启用 |
| `bound_contract_id` | string(uuid)? | 二房东绑定合同 |
| `failed_login_attempts` | integer | 登录失败次数 |
| `locked_until` | string(datetime)? | 锁定截止时间 |
| `password_changed_at` | string(datetime)? | 最近改密时间 |
| `last_login_at` | string(datetime)? | 上次登录时间 |
| `frozen_at` | string(datetime)? | 冻结时间 |
| `frozen_reason` | string? | 冻结原因 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 1.7 `POST /api/users` — 创建用户

**权限**: `super_admin`

**Request Body** — `UserCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 姓名（最大 100 字符） |
| `email` | string | 是 | 邮箱（唯一） |
| `password` | string | 是 | 初始密码（≥8位，含大小写+数字，≠用户名） |
| `role` | string(enum) | 是 | 角色 |
| `department_id` | string(uuid) | 否 | 所属部门（非二房东角色建议填写） |
| `bound_contract_id` | string(uuid) | 条件 | 二房东角色必填，绑定主合同 |

**Response 201** — `UserDetail`（同 1.6）

**错误码**

| 错误码 | 说明 |
|--------|------|
| `EMAIL_ALREADY_EXISTS` | 邮箱已被注册 |
| `PASSWORD_TOO_WEAK` | 密码不符合复杂度要求 |
| `BOUND_CONTRACT_REQUIRED` | 二房东角色必须绑定主合同 |
| `CONTRACT_NOT_SUBLEASE_MASTER` | 绑定的合同不是二房东主合同 |

---

### 1.8 `PATCH /api/users/:id` — 更新用户基本信息

**权限**: `super_admin`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 姓名 |
| `email` | string | 否 | 邮箱 |

**Response 200** — `UserDetail`

---

### 1.9 `PATCH /api/users/:id/status` — 启停用账号

**权限**: `super_admin`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `is_active` | boolean | 是 | `true`=启用，`false`=停用 |

**Response 200** — `UserDetail`

---

### 1.10 `PATCH /api/users/:id/role` — 变更角色

**权限**: `super_admin`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `role` | string(enum) | 是 | 新角色 |
| `bound_contract_id` | string(uuid) | 条件 | 变更为 `sub_landlord` 时必填 |

**Response 200** — `UserDetail`

> 变更角色触发审计日志；变更为/离开 `sub_landlord` 时需处理 `bound_contract_id`。

---

### 1.11 `PATCH /api/users/:id/department` — 变更员工所属部门

**权限**: `super_admin`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `department_id` | string(uuid) | 是 | 新部门 ID（必须存在且 `is_active=true`） |

**Response 200** — `UserDetail`

---

### 1.12 `POST /api/auth/change-password` — 修改密码

**权限**: 已登录

**Request Body** — `ChangePasswordRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `old_password` | string | 是 | 旧密码 |
| `new_password` | string | 是 | 新密码（≥8位，含大小写+数字，≠用户名） |

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | string | 新 access token |
| `refresh_token` | string | 新 refresh token |
| `expires_in` | integer | 有效期（秒） |

> 改密后 `session_version` 递增，旧 token 全部失效。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVALID_OLD_PASSWORD` | 旧密码不正确 |
| `PASSWORD_TOO_WEAK` | 新密码不符合复杂度要求 |
| `PASSWORD_SAME_AS_OLD` | 新密码不能与旧密码相同 |

---

### 1.13 `POST /api/auth/forgot-password` — 发送 OTP 验证码邮件

**权限**: 公共

> 安全说明：不论该邮箱是否存在于系统中，响应均为 200，防止用户名枚举攻击。
> 同一用户 5 分钟内最多发送 3 次，超出时后端静默忽略（仍返回 200，不暴露限频信息）。
> OTP 为 6 位数字，有效期 10 分钟，最多允许 5 次错误验证。

**Request Body** — `ForgotPasswordRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 申请重置的账号邮箱 |

**Response 200**

```json
{ "data": { "message": "若该邮箱已注册，验证码已发送至邮箱" } }
```

---

### 1.14 `POST /api/auth/reset-password` — 通过 OTP 验证码重置密码

**权限**: 公共

> OTP 来自发往注册邮箱的验证码，6 位数字，有效期 10 分钟，使用一次后立即失效。
> 重置成功后 `session_version` 递增，所有已登录会话的 JWT 全部失效。

**Request Body** — `ResetPasswordRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 用户邮箱（与申请 OTP 时一致） |
| `otp` | string | 是 | 邮件中收到的 6 位数字验证码 |
| `new_password` | string | 是 | 新密码（≥8位，含大小写+数字，≠旧密码） |

**Response 200**

```json
{ "data": { "message": "密码已重置，请使用新密码登录" } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `OTP_INVALID` | 验证码不存在、已使用，或输入错误 |
| `OTP_EXPIRED` | 验证码已过期（超过 10 分钟） |
| `RESET_PASSWORD_EXHAUSTED` | 验证码已失效（错误次数超过 5 次），请重新获取 |
| `PASSWORD_TOO_WEAK` | 新密码不符合复杂度要求 |
| `PASSWORD_SAME_AS_OLD` | 新密码不能与旧密码相同 |

---

## 一-A、组织架构管理

### 1A.1 `GET /api/departments` — 部门树列表

**权限**: `org.read`

**Response 200** — `DepartmentTree[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 部门 ID |
| `name` | string | 部门名称 |
| `parent_id` | string(uuid)? | 父部门 ID（顶级为 null） |
| `level` | integer | 层级（1~3） |
| `sort_order` | integer | 排序号 |
| `is_active` | boolean | 是否启用 |
| `children` | `DepartmentTree[]` | 子部门列表（嵌套结构） |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 1A.2 `POST /api/departments` — 创建部门

**权限**: `org.manage`

**Request Body** — `DepartmentCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 部门名称（最大 100 字符） |
| `parent_id` | string(uuid) | 否 | 父部门 ID（空=顶级） |
| `sort_order` | integer | 否 | 排序号（默认 0） |

**Response 201** — `DepartmentTree`（不含 children）

**错误码**

| 错误码 | 说明 |
|--------|------|
| `MAX_DEPTH_EXCEEDED` | 部门层级超过 3 级 |
| `PARENT_DEPARTMENT_NOT_FOUND` | 父部门不存在 |
| `PARENT_DEPARTMENT_INACTIVE` | 父部门已停用 |

---

### 1A.3 `PATCH /api/departments/:id` — 更新部门

**权限**: `org.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 部门名称 |
| `sort_order` | integer | 否 | 排序号 |
| `parent_id` | string(uuid) | 否 | 父部门 ID（变更父级需校验层级不超过 3） |

**Response 200** — `DepartmentTree`

---

### 1A.4 `DELETE /api/departments/:id` — 停用部门

**权限**: `org.manage`

> 逻辑删除，设 `is_active = false`。

**Response 200**

```json
{ "data": { "message": "部门已停用" } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `DEPARTMENT_HAS_ACTIVE_USERS` | 部门下有在职员工，无法停用 |
| `DEPARTMENT_HAS_ACTIVE_CHILDREN` | 部门下有活跃子部门 |

---

### 1A.5 `GET /api/managed-scopes` — 查询管辖范围

**权限**: `org.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `department_id` | string(uuid) | 否 | 按部门过滤 |
| `user_id` | string(uuid) | 否 | 按用户过滤 |

**Response 200** — `ManagedScopeConfig[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 范围记录 ID |
| `department_id` | string(uuid)? | 归属部门 |
| `user_id` | string(uuid)? | 归属用户（个人覆盖） |
| `building_id` | string(uuid)? | 管辖楼栋 |
| `building_name` | string? | 楼栋名称（join 返回） |
| `floor_id` | string(uuid)? | 管辖楼层 |
| `floor_name` | string? | 楼层名称 |
| `property_type` | string(enum)? | 管辖业态 |

---

### 1A.6 `PUT /api/managed-scopes` — 设置管辖范围

**权限**: `org.manage`

> 批量覆写：删除指定 `department_id` 或 `user_id` 的现有范围，重新写入。

**Request Body** — `ManagedScopeSetRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `department_id` | string(uuid) | 条件 | 目标部门（与 `user_id` 二选一） |
| `user_id` | string(uuid) | 条件 | 目标用户（个人覆盖，与 `department_id` 二选一） |
| `scopes` | `ScopeItem[]` | 是 | 新的管辖范围列表 |

**`ScopeItem`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 管辖楼栋 |
| `floor_id` | string(uuid) | 否 | 管辖楼层 |
| `property_type` | string(enum) | 否 | 管辖业态 |

**Response 200** — `ManagedScopeConfig[]`（覆写后的完整列表）

---

## 二、资产模块

### 2.1 `GET /api/buildings` — 楼栋列表

**权限**: `assets.read`

**Response 200** — `BuildingSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 楼栋 ID |
| `name` | string | 楼栋名称（如"A座"） |
| `property_type` | string(enum) | 主业态：`office` / `retail` / `apartment` |
| `total_floors` | integer | 总楼层数 |
| `gfa` | number | 总建筑面积（m²） |
| `nla` | number | 净可租面积（m²） |
| `address` | string? | 地址 |
| `built_year` | integer? | 建成年份 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

> 不分页（楼栋数量有限，<10）。

---

### 2.2 `POST /api/buildings` — 创建楼栋

**权限**: `assets.write`

**Request Body** — `BuildingCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 楼栋名称（最大 100 字符） |
| `property_type` | string(enum) | 是 | 主业态 |
| `total_floors` | integer | 是 | 总楼层数（>0） |
| `gfa` | number | 是 | 总建筑面积（m²，>0） |
| `nla` | number | 是 | 净可租面积（m²，>0） |
| `address` | string | 否 | 地址 |
| `built_year` | integer | 否 | 建成年份 |

**Response 201** — `BuildingSummary`

---

### 2.3 `GET /api/buildings/:id` — 楼栋详情

**权限**: `assets.read`

**Response 200** — `BuildingSummary`（同 2.1 单条）

---

### 2.4 `PATCH /api/buildings/:id` — 更新楼栋

**权限**: `assets.write`

**Request Body**（所有字段均可选）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 楼栋名称 |
| `property_type` | string(enum) | 否 | 主业态 |
| `total_floors` | integer | 否 | 总楼层数 |
| `gfa` | number | 否 | 总建筑面积 |
| `nla` | number | 否 | 净可租面积 |
| `address` | string | 否 | 地址 |
| `built_year` | integer | 否 | 建成年份 |

**Response 200** — `BuildingSummary`

---

### 2.5 `GET /api/floors` — 楼层列表

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
| `floor_number` | integer | 楼层号（负数=地下层） |
| `floor_name` | string? | 展示名（如"B1"、"10F"） |
| `svg_path` | string? | 当前生效 SVG 路径 |
| `png_path` | string? | 当前生效 PNG 路径 |
| `nla` | number? | 本层净可租面积（m²） |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 2.6 `POST /api/floors` — 创建楼层

**权限**: `assets.write`

**Request Body** — `FloorCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 是 | 所属楼栋 |
| `floor_number` | integer | 是 | 楼层号（负数=地下层，唯一约束 building+floor） |
| `floor_name` | string | 否 | 展示名 |
| `nla` | number | 否 | 本层净可租面积 |

**Response 201** — `FloorSummary`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `FLOOR_ALREADY_EXISTS` | 同一楼栋下楼层号已存在 |

---

### 2.7 `GET /api/floors/:id` — 楼层详情

**权限**: `assets.read`

**Response 200** — `FloorSummary`

---

### 2.8 `POST /api/floors/:id/cad` — 上传楼层图并触发转换

**权限**: `assets.write`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | .dwg 文件 |
| `version_label` | string | 是 | 版本标签（如"原始图纸""2026年改造后"） |

**Response 202** — 异步转换已触发

| 字段 | 类型 | 说明 |
|------|------|------|
| `floor_plan_id` | string(uuid) | 图纸版本记录 ID |
| `version_label` | string | 版本标签 |
| `status` | string | `converting`（转换中） |

> 转换完成后自动更新 `svg_path` / `png_path`，并设为 `is_current = true`。

---

### 2.9 `GET /api/floors/:id/heatmap` — 获取热区与状态色块

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

### 2.10 `GET /api/floors/:id/plans` — 楼层图纸版本列表

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

### 2.11 `PATCH /api/floor-plans/:id/set-current` — 设置当前生效版本

**权限**: `assets.write`

**Request Body**: 无

**Response 200** — `FloorPlanVersionDto`

---

### 2.12 `GET /api/units` — 单元分页列表

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `floor_id` | string(uuid) | 否 | 按楼层过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `current_status` | string(enum) | 否 | 按出租状态过滤 |
| `is_leasable` | boolean | 否 | 是否可租 |
| `archived` | boolean | 否 | 是否包含已归档单元（默认 false） |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

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

### 2.13 `POST /api/units` — 创建单元

**权限**: `assets.write`

**Request Body** — `UnitCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `floor_id` | string(uuid) | 是 | 所属楼层 |
| `building_id` | string(uuid) | 是 | 所属楼栋 |
| `unit_number` | string | 是 | 单元编号（同楼栋唯一，最大 50 字符） |
| `property_type` | string(enum) | 是 | 业态 |
| `gross_area` | number | 否 | 建筑面积（m²，>0） |
| `net_area` | number | 否 | 套内面积（m²，>0） |
| `orientation` | string | 否 | 朝向：`east` / `south` / `west` / `north` |
| `ceiling_height` | number | 否 | 层高（m） |
| `decoration_status` | string(enum) | 否 | 装修状态（默认 `blank`） |
| `is_leasable` | boolean | 否 | 是否可租（默认 true） |
| `ext_fields` | object | 否 | 业态扩展字段（见下方结构） |
| `market_rent_reference` | number | 否 | 参考市场租金 |
| `qr_code` | string | 否 | QR 码标识（唯一） |

**`ext_fields` 结构按业态**

| 业态 | 字段 |
|------|------|
| `office` | `{ "workstation_count": int?, "partition_count": int? }` |
| `retail` | `{ "frontage_width": number?, "street_facing": bool?, "retail_ceiling_height": number? }` |
| `apartment` | `{ "bedroom_count": int?, "en_suite_bathroom": bool? }` |

**Response 201** — `UnitDetail`

---

### 2.14 `GET /api/units/:id` — 单元详情

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

### 2.15 `PATCH /api/units/:id` — 更新单元

**权限**: `assets.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_number` | string | 否 | 单元编号 |
| `gross_area` | number | 否 | 建筑面积 |
| `net_area` | number | 否 | 套内面积 |
| `orientation` | string | 否 | 朝向 |
| `ceiling_height` | number | 否 | 层高 |
| `decoration_status` | string(enum) | 否 | 装修状态 |
| `is_leasable` | boolean | 否 | 是否可租 |
| `ext_fields` | object | 否 | 业态扩展字段 |
| `market_rent_reference` | number | 否 | 参考市场租金 |
| `predecessor_unit_ids` | string(uuid)[] | 否 | 前序单元 ID 列表（拆分/合并时设置） |
| `archived_at` | string(datetime) | 否 | 设置归档时间 |

**Response 200** — `UnitDetail`

---

### 2.16 `POST /api/units/import` — 批量导入单元

**权限**: `assets.write`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | Excel 文件（.xlsx） |
| `dry_run` | boolean | 否 | 仅校验不入库（默认 false） |

**Response 200** — `ImportBatchDetail`（见 §七）

---

### 2.17 `GET /api/renovations` — 改造记录列表

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

### 2.18 `POST /api/renovations` — 新增改造记录

**权限**: `assets.write`

**Request Body** — `RenovationCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 是 | 单元 ID |
| `renovation_type` | string | 是 | 改造类型（如"隔断改造""装修升级"） |
| `started_at` | string(date) | 是 | 开始日期 |
| `completed_at` | string(date) | 否 | 完成日期 |
| `cost` | number | 否 | 施工造价（元，≥0） |
| `contractor` | string | 否 | 施工方 |
| `description` | string | 否 | 描述 |

**Response 201** — `RenovationDetail`

---

### 2.19 `GET /api/renovations/:id` — 改造记录详情

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

### 2.20 `PATCH /api/renovations/:id` — 更新改造记录

**权限**: `assets.write`

**Request Body**（所有字段可选）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `renovation_type` | string | 否 | 改造类型 |
| `started_at` | string(date) | 否 | 开始日期 |
| `completed_at` | string(date) | 否 | 完成日期 |
| `cost` | number | 否 | 施工造价 |
| `contractor` | string | 否 | 施工方 |
| `description` | string | 否 | 描述 |

**Response 200** — `RenovationDetail`

---

### 2.21 `POST /api/renovations/:id/photos` — 上传改造照片

**权限**: `assets.write`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 照片文件（jpg/png） |
| `photo_stage` | string | 是 | `before` / `after` |

**Response 201**

| 字段 | 类型 | 说明 |
|------|------|------|
| `storage_path` | string | 存储路径 |
| `photo_stage` | string | 照片阶段 |

---

### 2.22 `GET /api/units/export` — 导出房源台账 Excel

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `property_type` | string(enum) | 否 | 按业态筛选（`office` / `retail` / `apartment`） |

**Response 200**: Excel 二进制流

```
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename="units_{property_type}.xlsx"
```

---

### 2.23 `GET /api/assets/overview` — 资产概览看板

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

## 三、租务与合同

### 3.1 `GET /api/tenants` — 租客列表

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `tenant_type` | string(enum) | 否 | `corporate` / `individual` |
| `credit_rating` | string | 否 | `A` / `B` / `C` / `D` |
| `keyword` | string | 否 | 搜索关键字（匹配 display_name） |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `TenantSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 租客 ID |
| `tenant_type` | string(enum) | 租客类型 |
| `display_name` | string | 名称 |
| `contact_person` | string? | 联系人 |
| `contact_phone_masked` | string? | 手机号（脱敏：`***XXXX`） |
| `credit_rating` | string? | 信用评级 |
| `overdue_count` | integer | 历史逾期次数 |
| `created_at` | string(datetime) | 创建时间 |

---

### 3.2 `POST /api/tenants` — 创建租客

**权限**: `contracts.write`

**Request Body** — `TenantCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `tenant_type` | string(enum) | 是 | `corporate` / `individual` |
| `display_name` | string | 是 | 名称（最大 200 字符） |
| `id_number` | string | 否 | 证件号（明文传入，服务端加密存储） |
| `contact_phone` | string | 否 | 手机号（明文传入，服务端加密存储） |
| `contact_person` | string | 条件 | 企业租客必填 |
| `contact_email` | string | 否 | 联系邮箱 |
| `emergency_contact_name` | string | 否 | 紧急联系人 |
| `emergency_contact_phone` | string | 否 | 紧急联系电话 |
| `notes` | string | 否 | 备注 |

**Response 201** — `TenantDetail`

---

### 3.3 `GET /api/tenants/:id` — 租客详情

**权限**: `contracts.read`

**Response 200** — `TenantDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 租客 ID |
| `tenant_type` | string(enum) | 租客类型 |
| `display_name` | string | 名称 |
| `id_number_masked` | string? | 证件号（脱敏：`****XXXX`） |
| `contact_phone_masked` | string? | 手机号（脱敏：`***XXXX`） |
| `contact_person` | string? | 联系人 |
| `contact_email` | string? | 联系邮箱 |
| `emergency_contact_name` | string? | 紧急联系人 |
| `emergency_contact_phone_masked` | string? | 紧急联系电话（脱敏） |
| `credit_rating` | string? | 信用评级（A/B/C/D） |
| `overdue_count` | integer | 历史逾期次数 |
| `times_overdue_past_12m` | integer | 12个月内逾期次数 |
| `max_single_overdue_days` | integer | 单次最长逾期天数 |
| `last_rating_date` | string(date)? | 最近评级日期 |
| `notes` | string? | 备注 |
| `data_retention_until` | string(datetime)? | 数据保留截止 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 3.4 `PATCH /api/tenants/:id` — 更新租客

**权限**: `contracts.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `display_name` | string | 否 | 名称 |
| `id_number` | string | 否 | 证件号（明文传入） |
| `contact_phone` | string | 否 | 手机号（明文传入） |
| `contact_person` | string | 否 | 联系人 |
| `contact_email` | string | 否 | 联系邮箱 |
| `emergency_contact_name` | string | 否 | 紧急联系人 |
| `emergency_contact_phone` | string | 否 | 紧急联系电话 |
| `notes` | string | 否 | 备注 |

**Response 200** — `TenantDetail`

---

### 3.5 `POST /api/tenants/:id/unmask` — 查看完整敏感信息

**权限**: `contracts.read`（需二次鉴权）

**Request Body** — `UnmaskRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `current_password` | string | 是 | 当前登录用户密码（二次鉴权） |

**Response 200** — `UnmaskResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id_number` | string? | 完整证件号 |
| `contact_phone` | string? | 完整手机号 |

> 每次调用写审计日志（`action="tenant.view_sensitive"`）。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVALID_PASSWORD` | 二次鉴权失败 |

---

### 3.6 `GET /api/contracts` — 合同分页列表

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string(enum) | 否 | 合同状态 |
| `property_type` | string(enum) | 否 | 业态 |
| `tenant_id` | string(uuid) | 否 | 租客 ID |
| `building_id` | string(uuid) | 否 | 楼栋 ID |
| `is_sublease_master` | boolean | 否 | 是否为二房东主合同 |
| `keyword` | string | 否 | 搜索（合同编号、租客名称） |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `ContractSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_id` | string(uuid) | 租客 ID |
| `tenant_name` | string | 租客名称 |
| `status` | string(enum) | 合同状态 |
| `property_type` | string(enum) | 业态 |
| `pricing_model` | string(enum) | 计租模型：`area` / `flat` / `revenue` |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `base_monthly_rent` | number | 基准月租金（元） |
| `tax_inclusive` | boolean | 是否含税 |
| `is_sublease_master` | boolean | 是否为二房东主合同 |
| `unit_count` | integer | 关联单元数 |
| `wale_contribution` | number? | WALE 贡献值（年，按收入加权口径，仅 `active` / `expiring_soon` 返回） |
| `days_until_expiry` | integer? | 距到期日剩余天数（负值=已过期） |
| `created_at` | string(datetime) | 创建时间 |

---

### 3.7 `POST /api/contracts` — 创建合同

**权限**: `contracts.write`

**Request Body** — `ContractCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_no` | string | 是 | 合同编号（唯一，最大 50 字符） |
| `tenant_id` | string(uuid) | 是 | 租客 ID |
| `property_type` | string(enum) | 是 | 业态 |
| `pricing_model` | string(enum) | 否 | 计租模型：`area`（默认）/ `flat` / `revenue` |
| `start_date` | string(date) | 是 | 起租日 |
| `end_date` | string(date) | 是 | 到期日（≥start_date） |
| `free_rent_days` | integer | 否 | 免租天数（默认 0） |
| `base_monthly_rent` | number | 是 | 基准月租金（元，>0） |
| `payment_cycle_months` | integer | 否 | 付款周期（月数，默认 1） |
| `management_fee_rate` | number | 否 | 物管费率（元/m²/月，默认 0） |
| `deposit_months` | integer | 否 | 押金月数（默认 2） |
| `deposit_amount` | number | 是 | 押金总额（元） |
| `tax_inclusive` | boolean | 否 | 含税标识（默认 true） |
| `applicable_tax_rate` | number | 否 | 适用税率（如 0.09，默认 0） |
| `revenue_share_enabled` | boolean | 否 | 是否启用营业额分成（默认 false） |
| `min_guarantee_rent` | number | 条件 | 保底租金（分成启用时必填） |
| `revenue_share_rate` | number | 条件 | 分成比例（如 0.08，分成启用时必填） |
| `parent_contract_id` | string(uuid) | 否 | 续签关联的父合同 |
| `is_sublease_master` | boolean | 否 | 是否为二房东主合同 |
| `contract_units` | `ContractUnitInput[]` | 是 | 关联单元列表（至少 1 项） |

**`ContractUnitInput`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 是 | 单元 ID |
| `billing_area` | number | 是 | 计费面积（m²，>0） |
| `unit_price` | number | 是 | 单价（元/m²/月，>0） |

**Response 201** — `ContractDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `CONTRACT_NO_ALREADY_EXISTS` | 合同编号已存在 |
| `UNIT_ALREADY_LEASED` | 单元已被其他合同占用 |
| `TENANT_NOT_FOUND` | 租客不存在 |
| `INVALID_CONTRACT_DATES` | 起租日不能晚于到期日 |

---

### 3.8 `GET /api/contracts/:id` — 合同详情

**权限**: `contracts.read`

**Response 200** — `ContractDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_id` | string(uuid) | 租客 ID |
| `tenant_name` | string | 租客名称 |
| `status` | string(enum) | 合同状态 |
| `property_type` | string(enum) | 业态 |
| `pricing_model` | string(enum) | 计租模型：`area` / `flat` / `revenue` |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `free_rent_days` | integer | 免租天数 |
| `free_rent_end_date` | string(date)? | 免租结束日 |
| `base_monthly_rent` | number | 基准月租金 |
| `payment_cycle_months` | integer | 付款周期月数 |
| `management_fee_rate` | number | 物管费率 |
| `deposit_months` | integer | 押金月数 |
| `deposit_amount` | number | 押金总额 |
| `tax_inclusive` | boolean | 含税标识 |
| `applicable_tax_rate` | number | 适用税率 |
| `revenue_share_enabled` | boolean | 分成启用 |
| `min_guarantee_rent` | number? | 保底租金 |
| `revenue_share_rate` | number? | 分成比例 |
| `parent_contract_id` | string(uuid)? | 父合同 ID |
| `is_sublease_master` | boolean | 二房东主合同标识 |
| `signed_pdf_path` | string? | 签约 PDF 路径 |
| `termination_type` | string(enum)? | 终止类型 |
| `terminated_at` | string(datetime)? | 终止处理时间 |
| `termination_date` | string(date)? | 实际终止日期 |
| `termination_reason` | string? | 终止原因 |
| `penalty_amount` | number? | 违约金 |
| `deposit_deduction_details` | string? | 押金扣除明细 |
| `contract_units` | `ContractUnitDetail[]` | 关联单元列表 |
| `deposit_summary` | `DepositInlineSummary?` | 押金摘要（聚合当前合同所有押金） |
| `renewal_chain` | `RenewalChainItem[]` | 续签合同链（从最老到最新排序，含自身） |
| `created_by` | string(uuid)? | 创建人 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

**`ContractUnitDetail`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `building_name` | string | 楼栋名称 |
| `floor_name` | string? | 楼层名称 |
| `billing_area` | number | 计费面积 |
| `unit_price` | number | 单价 |

**`DepositInlineSummary`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_amount` | number | 押金总额（元） |
| `current_balance` | number | 当前余额（元） |
| `status` | string | 聚合状态：`normal`（余额=总额） / `partial_deducted`（已部分冲抵） / `refunded`（已退还） |

**`RenewalChainItem`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `status` | string(enum) | 合同状态 |
| `is_current` | boolean | 是否为当前查看的合同 |

---

### 3.9 `PATCH /api/contracts/:id` — 更新合同

**权限**: `contracts.write`

> **可变更字段白名单**（不含 `contract_units`）

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `payment_cycle_months` | integer | 否 | 付款周期 |
| `management_fee_rate` | number | 否 | 物管费率 |
| `tax_inclusive` | boolean | 否 | 含税标识 |
| `applicable_tax_rate` | number | 否 | 适用税率 |
| `revenue_share_rate` | number | 否 | 分成比例 |
| `min_guarantee_rent` | number | 否 | 保底租金 |

**Response 200** — `ContractDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `CONTRACT_NOT_FOUND` | 合同不存在 |
| `CONTRACT_UNITS_NOT_PATCHABLE` | `contract_units` 不可通过此端点变更 |

---

### 3.10 `POST /api/contracts/:id/attachments` — 上传合同附件

**权限**: `contracts.write`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 附件文件（PDF 等） |
| `file_type` | string | 否 | `original` / `amendment` / `other`（默认 `original`） |

**Response 201** — `ContractAttachmentListItem`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 附件 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `file_type` | string | 文件类型 |
| `filename` | string | 文件名 |
| `storage_path` | string | 存储路径 |
| `file_size_kb` | integer? | 文件大小（KB） |
| `uploaded_by` | string(uuid)? | 上传人 |
| `created_at` | string(datetime) | 上传时间 |

---

### 3.11 `GET /api/contracts/:id/attachments` — 合同附件列表

**权限**: `contracts.read`

**Response 200** — `ContractAttachmentListItem[]`（同 3.10 结构）

---

### 3.12 `POST /api/contracts/:id/renew` — 创建续签合同

**权限**: `contracts.write`

**Request Body** — 同 `ContractCreateRequest`（§3.7），但系统自动设置 `parent_contract_id` 为当前合同 ID。

**Response 201** — `ContractDetail`

---

### 3.13 `POST /api/contracts/:id/terminate` — 合同提前终止

**权限**: `contracts.write`

**Request Body** — `TerminateContractRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `termination_type` | string(enum) | 是 | `tenant_early_exit` / `mutual_agreement` / `owner_termination` |
| `termination_date` | string(date) | 是 | 实际终止日期 |
| `penalty_amount` | number | 否 | 违约金（元，≥0） |
| `deposit_deduction_details` | string | 否 | 押金扣除明细描述 |
| `termination_reason` | string | 是 | 终止原因/解约依据 |

**Response 200** — `ContractDetail`

> 终止后自动：取消未来未生成账单、关闭递增规则、触发押金流程、WALE 剩余租期归零。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `CONTRACT_NOT_ACTIVE` | 合同非执行中状态，不可终止 |
| `TERMINATION_DATE_INVALID` | 终止日期不在合同有效期内 |

---

### 3.14 `GET /api/contracts/:id/escalation-phases` — 查询递增阶段

**权限**: `contracts.read`

**Response 200** — `EscalationPhaseDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 阶段 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `phase_order` | integer | 阶段顺序（从 1 开始） |
| `start_month` | integer | 起始月偏移（相对合同起租日） |
| `end_month` | integer? | 结束月偏移（null=延续至合同结束） |
| `escalation_type` | string(enum) | 递增类型 |
| `params` | object | 类型专属参数（JSONB） |
| `created_at` | string(datetime) | 创建时间 |

**`escalation_type` 枚举与 `params` 结构**

| 类型 | params 结构 |
|------|------------|
| `fixed_rate` | `{ "rate": 0.05, "interval_months": 12 }` |
| `fixed_amount` | `{ "amount_per_sqm": 3.0, "interval_months": 12 }` |
| `step` | `{ "steps": [{ "from_month": 0, "to_month": 23, "monthly_rent": 8000 }, ...] }` |
| `cpi` | `{ "interval_months": 12, "cpi_year_overrides": { "2027": 0.023 } }` |
| `periodic` | `{ "interval_years": 2, "rate": 0.08 }` |
| `base_after_free_period` | `{ "base_monthly_rent": 7500 }` |

---

### 3.15 `PUT /api/contracts/:id/escalation-phases` — 覆盖递增阶段配置

**权限**: `contracts.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `phases` | `EscalationPhaseInput[]` | 是 | 阶段列表（覆盖已有） |

**`EscalationPhaseInput`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `phase_order` | integer | 是 | 阶段顺序 |
| `start_month` | integer | 是 | 起始月偏移 |
| `end_month` | integer | 否 | 结束月偏移 |
| `escalation_type` | string(enum) | 是 | 递增类型 |
| `params` | object | 是 | 类型专属参数 |

**Response 200** — `EscalationPhaseDto[]`

---

### 3.16 `GET /api/contracts/wale` — WALE 双口径查询

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `groupBy` | string | 否 | 分组维度：`building` / `property_type`（空=组合级） |
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |

**Response 200** — `WaleResult`

| 字段 | 类型 | 说明 |
|------|------|------|
| `wale_income_weighted` | number | 收入加权 WALE（年） |
| `wale_area_weighted` | number | 面积加权 WALE（年） |
| `calculation_date` | string(date) | 计算基准日 |
| `contract_count` | integer | 参与计算的合同数 |
| `groups` | `WaleGroup[]`? | 分组详情（`groupBy` 非空时返回） |

**`WaleGroup`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_key` | string | 分组键（楼栋 ID 或业态） |
| `group_label` | string | 分组标签（楼栋名称或业态中文） |
| `wale_income_weighted` | number | 收入加权 WALE |
| `wale_area_weighted` | number | 面积加权 WALE |
| `contract_count` | integer | 合同数 |

---

### 3.17 `GET /api/alerts` — 预警列表

**权限**: `alerts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 否 | 按合同过滤 |
| `alert_type` | string(enum) | 否 | 按预警类型过滤 |
| `is_read` | boolean | 否 | 按已读状态过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `AlertItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 预警 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `alert_type` | string(enum) | 预警类型 |
| `triggered_at` | string(datetime) | 触发时间 |
| `is_read` | boolean | 是否已读 |
| `read_at` | string(datetime)? | 已读时间 |
| `notified_via` | string[] | 通知渠道列表 |
| `created_at` | string(datetime) | 创建时间 |

---

### 3.18 `GET /api/alerts/unread` — 未读预警数量

**权限**: `alerts.read`

**Response 200** — `AlertUnreadResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `count` | integer | 未读预警数量 |

---

### 3.19 `PATCH /api/alerts/:id/read` — 标记单条已读

**权限**: `alerts.read`

**Request Body**: 无

**Response 200** — `AlertItem`

---

### 3.20 `POST /api/alerts/read-all` — 批量标记全部已读

**权限**: `alerts.read`

**Request Body**: 无

**Response 200**

```json
{ "data": { "updated_count": 15 } }
```

---

### 3.21 `POST /api/alerts/replay` — 按条件补发预警

**权限**: `alerts.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 否 | 按合同过滤 |
| `alert_type` | string(enum) | 否 | 按预警类型 |
| `date_from` | string(date) | 否 | 日期范围起 |
| `date_to` | string(date) | 否 | 日期范围止 |

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `replayed_count` | integer | 补发数量 |

---

### 3.22 `GET /api/tenants/:id/contracts` — 租客关联合同列表

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string(enum) | 否 | 过滤合同状态 |

**Response 200** — `TenantContractItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `status` | string(enum) | 合同状态 |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `monthly_rent` | number | 月租金（元） |
| `unit_names` | string[] | 关联房间名称列表 |

---

### 3.23 `GET /api/tenants/:id/workorders` — 租客关联工单列表

**权限**: `workorders.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string(enum) | 否 | 工单状态过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `TenantWorkOrderItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 工单 ID |
| `order_no` | string | 工单编号 |
| `title` | string | 工单标题 |
| `category` | string(enum) | 工单类别 |
| `status` | string(enum) | 工单状态 |
| `priority` | string(enum) | 优先级 |
| `created_at` | string(datetime) | 创建时间 |
| `resolved_at` | string(datetime)? | 解决时间 |

---

### 3.24 `GET /api/tenants/:id/credit` — 租客信用评分详情与趋势

**权限**: `tenants.read`

**Response 200** — `TenantCreditDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `tenant_id` | string(uuid) | 租客 ID |
| `credit_rating` | string(enum) | 当前信用等级：`A` / `B` / `C` / `D` |
| `overdue_count` | integer | 累计逾期次数 |
| `times_overdue_past_12m` | integer | 近12个月逾期次数 |
| `max_single_overdue_days` | integer | 单次最长逾期天数 |
| `last_rating_date` | string(date) | 最近评级日期 |
| `trend` | CreditTrendPoint[] | 月度评分趋势（近12个月） |

**`CreditTrendPoint`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `month` | string | 月份标识（`2026-01`） |
| `score` | number | 当月信用评分（0~100） |
| `rating` | string(enum) | 当月信用等级 |

---

### 3.25 `GET /api/contracts/:id/chain` — 合同续约链

**权限**: `contracts.read`

> 返回同一租客 + 同一房间的历史续约合同链，按 start_date 升序。

**Response 200** — `ContractChainItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `monthly_rent` | number | 月租金（元） |
| `status` | string(enum) | 合同状态 |
| `is_current` | boolean | 是否为当前查看的合同 |

---

## 三-A、押金管理

### 3A.1 `GET /api/contracts/:id/deposits` — 合同关联押金列表

**权限**: `deposit.read`

**Response 200** — `DepositSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 押金 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `amount` | number | 押金金额（元） |
| `collection_date` | string(date) | 收取日期 |
| `status` | string(enum) | `collected` / `frozen` / `partially_credited` / `refunded` |
| `transferred_to_contract_id` | string(uuid)? | 转移目标合同 |
| `created_at` | string(datetime) | 创建时间 |

---

### 3A.2 `POST /api/contracts/:id/deposits` — 创建押金记录

**权限**: `deposit.write`

**Request Body** — `DepositCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `amount` | number | 是 | 押金金额（元，>0） |
| `collection_date` | string(date) | 是 | 收取日期 |
| `notes` | string | 否 | 备注 |

**Response 201** — `DepositDetail`

---

### 3A.3 `GET /api/deposits/:id` — 押金详情

**权限**: `deposit.read`

**Response 200** — `DepositDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 押金 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `amount` | number | 押金金额 |
| `collection_date` | string(date) | 收取日期 |
| `status` | string(enum) | 押金状态 |
| `last_status_change_at` | string(datetime)? | 最近状态变更时间 |
| `transferred_to_contract_id` | string(uuid)? | 转移目标合同 |
| `notes` | string? | 备注 |
| `created_by` | string(uuid)? | 创建人 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 3A.4 `POST /api/deposits/:id/freeze` — 冻结押金

**权限**: `deposit.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | 是 | 冻结原因 |

**Response 200** — `DepositDetail`

---

### 3A.5 `POST /api/deposits/:id/deduct` — 部分冲抵

**权限**: `deposit.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `amount` | number | 是 | 冲抵金额（>0，≤ 押金余额） |
| `reason` | string | 是 | 冲抵原因 |

**Response 200** — `DepositDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `DEDUCTION_EXCEEDS_BALANCE` | 冲抵金额超过押金余额 |

---

### 3A.6 `POST /api/deposits/:id/refund` — 退还押金

**权限**: `deposit.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | 是 | 退还原因 |

**Response 200** — `DepositDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `CONTRACT_HAS_OUTSTANDING_INVOICES` | 合同存在未结账单，无法退还 |

---

### 3A.7 `POST /api/deposits/:id/transfer` — 转移至续签合同

**权限**: `deposit.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `target_contract_id` | string(uuid) | 是 | 续签合同 ID |

**Response 200** — `DepositDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `TARGET_CONTRACT_NOT_RENEWAL` | 目标合同不是续签合同 |

---

### 3A.8 `GET /api/deposits/:id/transactions` — 押金交易流水

**权限**: `deposit.read`

**Response 200** — `DepositTransactionDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 流水 ID |
| `deposit_id` | string(uuid) | 押金 ID |
| `transaction_type` | string | `collection` / `freeze` / `deduction` / `refund` / `transfer` |
| `amount` | number | 操作金额 |
| `previous_status` | string(enum) | 变更前状态 |
| `new_status` | string(enum) | 变更后状态 |
| `reason` | string | 状态变更原因 |
| `approved_by` | string(uuid)? | 审批人 ID |
| `approved_by_name` | string? | 审批人姓名 |
| `created_by` | string(uuid) | 操作人 ID |
| `created_by_name` | string | 操作人姓名 |
| `created_at` | string(datetime) | 操作时间 |

---

## 三-B、租金递增模板

### 3B.1 `GET /api/escalation-templates` — 模板列表

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `is_active` | boolean | 否 | 按启用状态过滤 |

**Response 200** — `EscalationTemplateDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 模板 ID |
| `template_name` | string | 模板名称 |
| `property_type` | string(enum) | 业态 |
| `description` | string? | 描述 |
| `phases` | object[] | 阶段配置（JSONB） |
| `is_active` | boolean | 是否启用 |
| `created_by` | string(uuid)? | 创建人 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 3B.2 `POST /api/escalation-templates` — 创建模板

**权限**: `contracts.write`

**Request Body** — `EscalationTemplateCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `template_name` | string | 是 | 模板名称（最大 100 字符） |
| `property_type` | string(enum) | 是 | 业态 |
| `description` | string | 否 | 描述 |
| `phases` | `EscalationPhaseInput[]` | 是 | 阶段配置列表 |

**Response 201** — `EscalationTemplateDto`

---

### 3B.3 `GET /api/escalation-templates/:id` — 模板详情

**权限**: `contracts.read`

**Response 200** — `EscalationTemplateDto`

---

### 3B.4 `PATCH /api/escalation-templates/:id` — 更新模板

**权限**: `contracts.write`

**Request Body**（所有字段可选）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `template_name` | string | 否 | 模板名称 |
| `description` | string | 否 | 描述 |
| `phases` | `EscalationPhaseInput[]` | 否 | 阶段配置 |

**Response 200** — `EscalationTemplateDto`

---

### 3B.5 `DELETE /api/escalation-templates/:id` — 停用模板

**权限**: `contracts.write`

> 逻辑删除，设 `is_active = false`。

**Response 200**

```json
{ "data": { "message": "模板已停用" } }
```

---

### 3B.6 `POST /api/contracts/:id/apply-template` — 应用模板到合同

**权限**: `contracts.write`

**Request Body** — `ApplyTemplateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `template_id` | string(uuid) | 是 | 模板 ID |

**Response 200** — `EscalationPhaseDto[]`（应用后的合同递增阶段列表）

> 幂等操作：覆盖已有阶段。

---

## 三-C、合同租金预测与 WALE 趋势（Should）

### 3C.1 `GET /api/contracts/:id/rent-forecast` — 租金预测表

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `granularity` | string | 否 | `monthly`（默认）/ `yearly` |

**Response 200** — `RentForecastRow[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `period_start` | string(date) | 周期起始日 |
| `period_end` | string(date) | 周期结束日 |
| `monthly_rent` | number | 月租金（元） |
| `unit_price` | number | 单价（元/m²/月） |
| `escalation_type` | string(enum)? | 当期递增类型 |
| `escalation_rate` | number? | 当期递增比例/金额 |
| `is_free_period` | boolean | 是否免租期 |

---

### 3C.2 `GET /api/contracts/:id/rent-forecast/export` — 导出租金预测 Excel

**权限**: `contracts.read`

**Query 参数**: 同 3C.1

**Response 200**: Excel 二进制流

```
Content-Disposition: attachment; filename="rent_forecast_{contract_no}.xlsx"
```

---

### 3C.3 `GET /api/contracts/wale/trend` — WALE 历史趋势

**权限**: `contracts.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `groupBy` | string | 否 | `building` / `property_type` |
| `months` | integer | 否 | 回溯月数（默认 12） |

**Response 200** — `WaleTrendPoint[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | string(date) | 数据日期（月度快照） |
| `wale_income_weighted` | number | 收入加权 WALE |
| `wale_area_weighted` | number | 面积加权 WALE |
| `group_key` | string? | 分组键 |
| `group_label` | string? | 分组标签 |

---

### 3C.4 `GET /api/contracts/wale/waterfall` — 到期瀑布图

**权限**: `contracts.read`

**Response 200** — `WaleWaterfallItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `year` | integer | 到期年份 |
| `expiring_area` | number | 到期面积（m²） |
| `expiring_annual_rent` | number | 到期年化租金（元） |
| `contract_count` | integer | 到期合同数 |

---

### 3C.5 `GET /api/contracts/wale/dashboard` — WALE 综合看板

**权限**: `contracts.read`

> 汇总全局及各业态 WALE，返回 KPI 目标达成率、同比环比。

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |

**Response 200** — `WaleDashboard`

| 字段 | 类型 | 说明 |
|------|------|------|
| `overall_wale_income` | number | 全局收入加权 WALE（年） |
| `overall_wale_area` | number | 全局面积加权 WALE（年） |
| `target_wale` | number? | KPI 目标 WALE |
| `achievement_rate` | number? | 目标达成率（0~1） |
| `by_property_type` | WaleByType[] | 各业态明细 |
| `yoy_change` | number? | 同比变化率 |
| `mom_change` | number? | 环比变化率 |

**`WaleByType`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `property_type` | string(enum) | 业态类型 |
| `wale_income` | number | 收入加权 WALE |
| `wale_area` | number | 面积加权 WALE |
| `contract_count` | integer | 合同数 |
| `total_area` | number | 总面积（m²） |

---

### 3C.6 `GET /api/contracts/at-risk` — 到期风险合同列表

**权限**: `contracts.read`

> 返回距到期日 ≤ 指定天数且尚未续约的合同列表。

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `days_threshold` | integer | 否 | 到期天数阈值（默认 90） |
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `AtRiskContract[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `unit_names` | string[] | 关联房间 |
| `end_date` | string(date) | 到期日 |
| `days_until_expiry` | integer | 距到期天数 |
| `monthly_rent` | number | 月租金（元） |
| `annual_rent` | number | 年化租金（元） |
| `area` | number | 面积（m²） |
| `wale_contribution` | number | WALE 贡献值（年） |
| `renewal_intent` | string? | 续约意向：`willing` / `undecided` / `unwilling` / `null` |

---

## 四、财务与 NOI

### 4.1 `GET /api/invoices` — 账单分页列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 否 | 按合同过滤 |
| `status` | string(enum) | 否 | 账单状态 |
| `period_start` | string(date) | 否 | 账期起始日≥ |
| `period_end` | string(date) | 否 | 账期结束日≤ |
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `tenant_id` | string(uuid) | 否 | 按租客过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `InvoiceSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 账单 ID |
| `invoice_no` | string | 账单编号 |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `period_start` | string(date) | 账期起始 |
| `period_end` | string(date) | 账期结束 |
| `total_amount` | number | 应收总额 |
| `paid_amount` | number | 已收金额 |
| `outstanding_amount` | number | 未收金额 |
| `status` | string(enum) | 账单状态 |
| `due_date` | string(date) | 缴款截止日 |
| `days_overdue` | integer? | 逾期天数（未逾期为 `null`，逾期从 `due_date` 次日起计） |
| `invoice_issued` | boolean | 是否已开票 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.2 `POST /api/invoices/generate` — 手工触发账单生成

**权限**: `finance.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 否 | 指定合同（空=全部在租合同） |
| `period_start` | string(date) | 是 | 账期起始 |
| `period_end` | string(date) | 是 | 账期结束 |

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `generated_count` | integer | 生成账单数 |
| `skipped_count` | integer | 跳过数（已存在或免租） |
| `invoice_ids` | string(uuid)[] | 新生成的账单 ID |

---

### 4.3 `GET /api/invoices/export` — 导出账单 Excel

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period` | string | 否 | 账期标识（如 `2026-04`） |
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `property_type` | string(enum) | 否 | 按业态 |
| `tenant_id` | string(uuid) | 否 | 按租客 |

**Response 200**: Excel 二进制流

```
Content-Disposition: attachment; filename="invoices_{period}.xlsx"
```

---

### 4.4 `GET /api/invoices/:id` — 账单详情

**权限**: `finance.read`

**Response 200** — `InvoiceDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 账单 ID |
| `invoice_no` | string | 账单编号 |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `period_start` | string(date) | 账期起始 |
| `period_end` | string(date) | 账期结束 |
| `total_amount` | number | 应收总额 |
| `paid_amount` | number | 已收金额 |
| `outstanding_amount` | number | 未收金额 |
| `status` | string(enum) | 账单状态 |
| `billing_basis` | string | 计费基准：`contract` / `daily_prorated` / `fixed_total` |
| `tax_mode` | string | 税费模式：`net` / `gross` |
| `due_date` | string(date) | 缴款截止日 |
| `overdue_since` | string(date)? | 首次逾期日 |
| `invoice_issued` | boolean | 是否已开票 |
| `invoice_no_ext` | string? | 外部发票号 |
| `invoice_issued_at` | string(datetime)? | 开票时间 |
| `last_reminded_at` | string(datetime)? | 最近催收时间 |
| `reported_revenue` | number? | 本期申报营业额（商铺） |
| `created_by` | string(uuid)? | 创建人 |
| `items` | InvoiceItemInline[] | 费项明细（内联，省去独立请求；与 §4.5 结构一致） |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

**`InvoiceItemInline`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 费项 ID |
| `item_type` | string(enum) | 费项类型 |
| `description` | string? | 费项说明 |
| `quantity` | number? | 数量 |
| `unit` | string? | 单位 |
| `unit_price` | number? | 单价 |
| `amount` | number | 金额（元） |

---

### 4.5 `GET /api/invoices/:id/items` — 账单费项明细

**权限**: `finance.read`

**Response 200** — `InvoiceItemDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 费项 ID |
| `invoice_id` | string(uuid) | 账单 ID |
| `item_type` | string(enum) | 费项类型：`rent` / `management_fee` / `electricity` / `water` / `parking` / `storage` / `revenue_share` / `other` |
| `description` | string? | 费项说明 |
| `quantity` | number? | 数量 |
| `unit` | string? | 单位（`m²` / `kWh` / `月`） |
| `unit_price` | number? | 单价 |
| `amount` | number | 金额（元） |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.6 `PATCH /api/invoices/:id` — 更新账单

**权限**: `finance.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `invoice_no_ext` | string | 否 | 外部发票号 |
| `invoice_issued` | boolean | 否 | 标记已开票 |
| `invoice_issued_at` | string(datetime) | 否 | 开票时间 |
| `due_date` | string(date) | 否 | 修正到期日 |

**Response 200** — `InvoiceDetail`

---

### 4.7 `POST /api/invoices/:id/void` — 作废账单

**权限**: `finance.write`

**Request Body** — `InvoiceVoidRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | 是 | 作废原因 |

**Response 200** — `InvoiceDetail`（status 变为 `cancelled`）

> 作废后自动反冲对应收款核销分配，写审计日志。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVOICE_NOT_VOIDABLE` | 仅 `issued` 状态可作废 |

---

### 4.8 `POST /api/payments` — 新增收款

**权限**: `finance.write`

**Request Body** — `PaymentCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `paid_amount` | number | 是 | 收款总额（元，>0） |
| `paid_at` | string(datetime) | 是 | 实际到账时间 |
| `payment_method` | string | 否 | 收款方式（默认 `bank_transfer`）：`bank_transfer` / `cash` / `online` / `offset` |
| `reference_no` | string | 否 | 银行流水号 |
| `notes` | string | 否 | 备注 |
| `allocations` | `AllocationInput[]` | 是 | 核销分配（至少 1 项） |

**`AllocationInput`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `invoice_id` | string(uuid) | 是 | 账单 ID |
| `allocated_amount` | number | 是 | 分配金额（>0） |

**Response 201** — `PaymentDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `ALLOCATION_EXCEEDS_OUTSTANDING` | 分配金额超过账单未收余额 |
| `ALLOCATION_SUM_MISMATCH` | 分配总额 ≠ 收款总额 |

---

### 4.9 `GET /api/payments` — 收款记录列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `PaymentSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 收款 ID |
| `paid_amount` | number | 收款金额 |
| `paid_at` | string(datetime) | 到账时间 |
| `payment_method` | string | 收款方式 |
| `reference_no` | string? | 银行流水号 |
| `allocation_count` | integer | 核销分配笔数 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.10 `GET /api/payments/:id` — 收款与分配详情

**权限**: `finance.read`

**Response 200** — `PaymentDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 收款 ID |
| `paid_amount` | number | 收款金额 |
| `paid_at` | string(datetime) | 到账时间 |
| `payment_method` | string | 收款方式 |
| `reference_no` | string? | 银行流水号 |
| `received_by_user_id` | string(uuid)? | 核销人 ID |
| `received_by_name` | string? | 核销人姓名 |
| `notes` | string? | 备注 |
| `allocations` | `PaymentAllocationDto[]` | 核销分配列表 |
| `created_at` | string(datetime) | 创建时间 |

**`PaymentAllocationDto`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 分配 ID |
| `payment_id` | string(uuid) | 收款 ID |
| `invoice_id` | string(uuid) | 账单 ID |
| `invoice_no` | string | 账单编号 |
| `allocated_amount` | number | 分配金额 |
| `allocated_by_user_id` | string(uuid)? | 分配人 |
| `allocated_by_name` | string? | 分配人姓名 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.11 `PATCH /api/payments/:id/allocations` — 调整核销分配

**权限**: `finance.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `allocations` | `AllocationInput[]` | 是 | 新的核销分配（覆盖已有） |

**Response 200** — `PaymentDetail`

> 仅允许在未结账或未锁账期间调整。

---

### 4.12 `GET /api/expenses` — 运营支出列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `category` | string(enum) | 否 | 按类目过滤 |
| `date_from` | string(date) | 否 | 支出日期≥ |
| `date_to` | string(date) | 否 | 支出日期≤ |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `ExpenseSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 支出 ID |
| `building_id` | string(uuid) | 楼栋 ID |
| `building_name` | string | 楼栋名称 |
| `unit_id` | string(uuid)? | 单元 ID |
| `unit_number` | string? | 单元编号 |
| `work_order_id` | string(uuid)? | 关联工单 ID |
| `category` | string(enum) | 支出类目 |
| `description` | string | 描述 |
| `amount` | number | 金额（元） |
| `expense_date` | string(date) | 支出日期 |
| `vendor` | string? | 供应商 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.13 `POST /api/expenses` — 新增运营支出

**权限**: `finance.write`

**Request Body** — `ExpenseCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 是 | 楼栋 ID |
| `unit_id` | string(uuid) | 否 | 单元 ID |
| `work_order_id` | string(uuid) | 否 | 关联工单 |
| `category` | string(enum) | 是 | 支出类目：`utility_common` / `outsourced_property` / `repair` / `insurance` / `tax` / `other` |
| `description` | string | 是 | 描述 |
| `amount` | number | 是 | 金额（元，>0） |
| `expense_date` | string(date) | 是 | 支出日期 |
| `vendor` | string | 否 | 供应商名称 |
| `receipt_path` | string | 否 | 凭证路径 |

**Response 201** — `ExpenseSummary`

---

### 4.14 `PATCH /api/expenses/:id` — 更新运营支出

**权限**: `finance.write`

**Request Body**（所有字段可选）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `category` | string(enum) | 否 | 支出类目 |
| `description` | string | 否 | 描述 |
| `amount` | number | 否 | 金额 |
| `expense_date` | string(date) | 否 | 支出日期 |
| `vendor` | string | 否 | 供应商 |
| `receipt_path` | string | 否 | 凭证路径 |

**Response 200** — `ExpenseSummary`

---

### 4.15 `DELETE /api/expenses/:id` — 删除运营支出

**权限**: `finance.write`

> 限未关联工单的记录。

**Response 200**

```json
{ "data": { "message": "支出已删除" } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `EXPENSE_LINKED_TO_WORKORDER` | 该支出关联工单，不可删除 |

---

### 4.16 `GET /api/noi/summary` — NOI 汇总卡片

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period_year` | integer | 否 | 年份（默认当前年） |
| `period_month` | integer | 否 | 月份（默认当前月） |
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `property_type` | string(enum) | 否 | 按业态过滤 |
| `view` | string | 否 | `receivable`（应收，默认）/ `received`（实收） |

**Response 200** — `NoiSummary`

| 字段 | 类型 | 说明 |
|------|------|------|
| `period_year` | integer | 年份 |
| `period_month` | integer | 月份 |
| `pgi` | number | 潜在总收入（元） |
| `vacancy_loss` | number | 空置损失（元） |
| `other_income` | number | 其他收入（元） |
| `egi` | number | 有效总收入（元） |
| `opex` | number | 运营支出（元） |
| `noi` | number | 净营运收入（元） |
| `occupancy_rate` | number | 出租率（0~1） |
| `view` | string | 视角 |

---

### 4.17 `GET /api/noi/trend` — NOI 趋势

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `months` | integer | 否 | 回溯月数（默认 12） |
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `property_type` | string(enum) | 否 | 按业态 |

**Response 200** — `NoiTrendPoint[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `period_year` | integer | 年份 |
| `period_month` | integer | 月份 |
| `egi` | number | 有效总收入 |
| `opex` | number | 运营支出 |
| `noi` | number | NOI |

---

### 4.18 `GET /api/noi/breakdown` — 按楼栋或业态拆分 NOI

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period_year` | integer | 否 | 年份 |
| `period_month` | integer | 否 | 月份 |
| `groupBy` | string | 是 | `building` / `property_type` |

**Response 200** — `NoiBreakdownItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_key` | string | 分组键 |
| `group_label` | string | 分组标签 |
| `egi` | number | 有效总收入 |
| `opex` | number | 运营支出 |
| `noi` | number | NOI |
| `occupancy_rate` | number | 出租率 |

---

### 4.19 `GET /api/noi/vacancy-loss` — 空置损失测算

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `property_type` | string(enum) | 否 | 按业态 |

**Response 200** — `NoiVacancyLossItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `building_name` | string | 楼栋名称 |
| `property_type` | string(enum) | 业态 |
| `net_area` | number | 套内面积 |
| `market_rent_reference` | number? | 参考市场租金 |
| `estimated_monthly_loss` | number | 估算月损失（元） |
| `vacant_days` | integer | 空置天数 |

---

### 4.20 `GET /api/noi/budget` — NOI 预算列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period_year` | integer | 否 | 按年份过滤 |
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `property_type` | string(enum) | 否 | 按业态 |

**Response 200** — `NoiBudgetItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 预算 ID |
| `building_id` | string(uuid)? | 楼栋 ID |
| `building_name` | string? | 楼栋名称 |
| `property_type` | string(enum)? | 业态 |
| `period_year` | integer | 预算年份 |
| `period_month` | integer? | 预算月份（null=年度预算） |
| `budget_noi` | number | 预算 NOI（元） |
| `created_by` | string(uuid)? | 录入人 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.21 `POST /api/noi/budget` — 录入 NOI 预算

**权限**: `finance.write`

**Request Body** — `NoiBudgetCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 楼栋（与 property_type 至少填一项，均空=全局） |
| `property_type` | string(enum) | 否 | 业态 |
| `period_year` | integer | 是 | 预算年份 |
| `period_month` | integer | 否 | 预算月份（1~12，空=年度预算） |
| `budget_noi` | number | 是 | 预算 NOI（元） |

**Response 201** — `NoiBudgetItem`

---

### 4.22 `PATCH /api/noi/budget/:id` — 更新 NOI 预算

**权限**: `finance.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `budget_noi` | number | 否 | 预算 NOI（元） |

**Response 200** — `NoiBudgetItem`

---

### 4.23 `DELETE /api/noi/budget/:id` — 删除 NOI 预算

**权限**: `finance.write`

**Response 204** — 无内容

**错误码**

| 错误码 | 说明 |
|--------|------|
| `NOI_BUDGET_NOT_FOUND` | 预算记录不存在 |

---

### 4.24 `GET /api/invoices/:id/payments` — 账单收款记录

**权限**: `finance.read`

**Response 200** — `InvoicePaymentItem[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 收款记录 ID |
| `invoice_id` | string(uuid) | 账单 ID |
| `amount` | number | 收款金额（元） |
| `payment_method` | string(enum) | 收款方式：`bank_transfer` / `cash` / `pos` / `wechat` / `alipay` / `other` |
| `payment_date` | string(date) | 收款日期 |
| `reference_no` | string? | 流水号/凭证号 |
| `notes` | string? | 备注 |
| `created_by` | string(uuid) | 操作人 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.25 `GET /api/dunning-logs` — 催收记录列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `invoice_id` | string(uuid) | 否 | 按账单过滤 |
| `tenant_id` | string(uuid) | 否 | 按租客过滤 |
| `method` | string(enum) | 否 | 催收方式过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `DunningLogItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 催收记录 ID |
| `invoice_id` | string(uuid) | 关联账单 ID |
| `invoice_no` | string | 账单编号 |
| `tenant_name` | string | 租客名称 |
| `method` | string(enum) | 催收方式：`phone` / `sms` / `letter` / `visit` / `legal` |
| `content` | string | 催收内容摘要 |
| `result` | string? | 催收结果 |
| `dunning_date` | string(date) | 催收日期 |
| `created_by` | string(uuid) | 操作人 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4.26 `POST /api/dunning-logs` — 新增催收记录

**权限**: `finance.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `invoice_id` | string(uuid) | 是 | 关联账单 ID |
| `method` | string(enum) | 是 | 催收方式 |
| `content` | string | 是 | 催收内容 |
| `result` | string | 否 | 催收结果 |
| `dunning_date` | string(date) | 是 | 催收日期 |

**Response 201** — `DunningLogItem`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVOICE_NOT_FOUND` | 账单不存在 |
| `INVOICE_ALREADY_PAID` | 账单已全额核销，无需催收 |

---

## 四-A、水电抄表

### 4A.1 `GET /api/meter-readings` — 抄表记录列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 否 | 按单元过滤 |
| `meter_type` | string(enum) | 否 | `water` / `electricity` / `gas` |
| `reading_cycle` | string(enum) | 否 | `monthly` / `bimonthly` |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `MeterReadingSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 记录 ID |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `meter_type` | string(enum) | 表计类型 |
| `reading_cycle` | string(enum) | 抄表周期 |
| `previous_reading` | number | 上期读数 |
| `current_reading` | number | 本期读数 |
| `consumption` | number | 用量 |
| `cost_amount` | number | 费用（元） |
| `reading_date` | string(date) | 抄表日期 |
| `invoice_generated` | boolean | 是否已生成账单 |
| `created_at` | string(datetime) | 创建时间 |

---

### 4A.2 `POST /api/meter-readings` — 录入抄表读数

**权限**: `meterReading.write`

**Request Body** — `MeterReadingCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 是 | 单元 ID |
| `meter_type` | string(enum) | 是 | `water` / `electricity` / `gas` |
| `reading_cycle` | string(enum) | 否 | `monthly`（默认）/ `bimonthly` |
| `previous_reading` | number | 是 | 上期读数（≥0） |
| `current_reading` | number | 是 | 本期读数（> previous_reading） |
| `unit_price` | number | 是 | 单价（元/度或元/吨，>0） |
| `reading_date` | string(date) | 是 | 抄表日期 |
| `tiered_details` | object[] | 否 | 阶梯计价明细 |

**`tiered_details` 项结构**

| 字段 | 类型 | 说明 |
|------|------|------|
| `from` | number | 阶梯起始用量 |
| `to` | number | 阶梯结束用量 |
| `price` | number | 阶梯单价 |
| `amount` | number | 阶梯费用 |

**Response 201** — `MeterReadingDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `INVALID_READING` | current_reading ≤ previous_reading |

---

### 4A.3 `GET /api/meter-readings/:id` — 抄表详情

**权限**: `finance.read`

**Response 200** — `MeterReadingDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 记录 ID |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `meter_type` | string(enum) | 表计类型 |
| `reading_cycle` | string(enum) | 抄表周期 |
| `previous_reading` | number | 上期读数 |
| `current_reading` | number | 本期读数 |
| `consumption` | number | 用量 |
| `unit_price` | number | 单价 |
| `cost_amount` | number | 费用 |
| `tiered_details` | object[]? | 阶梯计价明细 |
| `reading_date` | string(date) | 抄表日期 |
| `recorded_by` | string(uuid)? | 抄表人 ID |
| `recorded_by_name` | string? | 抄表人姓名 |
| `invoice_generated` | boolean | 是否已生成账单 |
| `generated_invoice_id` | string(uuid)? | 生成的账单 ID |
| `created_at` | string(datetime) | 创建时间 |

---

### 4A.4 `PATCH /api/meter-readings/:id` — 修正抄表记录

**权限**: `meterReading.write`

> 限未生成账单前。

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `previous_reading` | number | 否 | 上期读数 |
| `current_reading` | number | 否 | 本期读数 |
| `unit_price` | number | 否 | 单价 |
| `reading_date` | string(date) | 否 | 抄表日期 |

**Response 200** — `MeterReadingDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `METER_READING_ALREADY_INVOICED` | 已生成账单，不可修正 |

---

### 4A.5 `POST /api/meter-readings/preview-allocation` — 水电费分摊预览

**权限**: `meterReading.write`

> 根据给定读数与公摊规则，预览费用分摊结果，不落库。前端用于确认后再生成账单。

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 是 | 楼栋 ID |
| `meter_type` | string(enum) | 是 | 表类型：`electricity` / `water` |
| `period` | string | 是 | 账期标识（如 `2026-04`） |
| `total_reading` | number | 是 | 总表读数 |
| `public_area_ratio` | number | 否 | 公区占比（默认按配置） |

**Response 200** — `AllocationPreview`

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_amount` | number | 总费用（元） |
| `public_area_amount` | number | 公区分摊（元） |
| `unit_allocations` | UnitAllocation[] | 各房间分摊明细 |

**`UnitAllocation`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `unit_id` | string(uuid) | 房间 ID |
| `unit_name` | string | 房间名称 |
| `tenant_name` | string? | 租客名称 |
| `area` | number | 面积（m²） |
| `ratio` | number | 分摊比例（0~1） |
| `amount` | number | 分摊金额（元） |

---

## 四-B、商铺营业额申报

### 4B.1 `GET /api/turnover-reports` — 营业额申报列表

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 否 | 按合同过滤 |
| `approval_status` | string(enum) | 否 | `pending` / `approved` / `rejected` |
| `report_month` | string(date) | 否 | 按申报月份（yyyy-mm-01） |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `TurnoverReportSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 申报 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `report_month` | string(date) | 申报月份 |
| `reported_revenue` | number | 申报营业额 |
| `calculated_share` | number | 计算分成额 |
| `approval_status` | string(enum) | 审核状态 |
| `is_amendment` | boolean | 是否补报/修正 |
| `created_at` | string(datetime) | 提交时间 |

---

### 4B.2 `POST /api/turnover-reports` — 提交营业额申报

**权限**: `finance.write`

**Request Body** — `TurnoverReportCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `contract_id` | string(uuid) | 是 | 合同 ID |
| `report_month` | string(date) | 是 | 申报月份（yyyy-mm-01） |
| `reported_revenue` | number | 是 | 申报营业额（元，≥0） |
| `supporting_docs` | string[] | 否 | 附件路径列表 |

**Response 201** — `TurnoverReportDetail`

---

### 4B.3 `GET /api/turnover-reports/:id` — 申报详情

**权限**: `finance.read`

**Response 200** — `TurnoverReportDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 申报 ID |
| `contract_id` | string(uuid) | 合同 ID |
| `contract_no` | string | 合同编号 |
| `tenant_name` | string | 租客名称 |
| `report_month` | string(date) | 申报月份 |
| `reported_revenue` | number | 申报营业额 |
| `revenue_share_rate` | number | 分成比例 |
| `base_rent` | number | 保底租金 |
| `calculated_share` | number | 计算分成额 |
| `approval_status` | string(enum) | 审核状态 |
| `reviewed_by` | string(uuid)? | 审核人 ID |
| `reviewed_by_name` | string? | 审核人姓名 |
| `reviewed_at` | string(datetime)? | 审核时间 |
| `rejection_reason` | string? | 退回原因 |
| `attachment_paths` | string[] | 附件路径 |
| `is_amendment` | boolean | 是否补报 |
| `original_report_id` | string(uuid)? | 原始申报 ID |
| `generated_invoice_id` | string(uuid)? | 生成的账单 ID |
| `dispute_note` | string? | 争议记录 |
| `submitted_by` | string(uuid)? | 提交人 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 4B.4 `PATCH /api/turnover-reports/:id/approve` — 审核通过

**权限**: `turnoverReview.approve`

**Request Body**: 无

**Response 200** — `TurnoverReportDetail`（status 变为 `approved`，自动生成分成账单）

---

### 4B.5 `PATCH /api/turnover-reports/:id/reject` — 审核退回

**权限**: `turnoverReview.approve`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `rejection_reason` | string | 是 | 退回原因 |

**Response 200** — `TurnoverReportDetail`

---

## 四-C、KPI 指标管理

### 4C.1 `GET /api/kpi/metrics` — KPI 指标定义库列表

**权限**: `kpi.view`

**Response 200** — `KpiMetricDefinitionDto[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 指标 ID |
| `code` | string | 指标编号（K01~K14） |
| `name` | string | 指标名称 |
| `description` | string? | 描述 |
| `default_full_score_threshold` | number | 默认满分阈值 |
| `default_pass_threshold` | number | 默认及格阈值 |
| `default_fail_threshold` | number | 默认不及格阈值 |
| `higher_is_better` | boolean | 是否越高越好 |
| `direction` | string | 方向：`positive` / `negative` |
| `source_module` | string | 数据来源模块 |
| `is_manual_input` | boolean | 是否手动录入 |
| `category` | string(enum) | 指标分类：`leasing` / `finance` / `service` / `growth` |
| `is_enabled` | boolean | 是否启用 |

---

### 4C.2 `PATCH /api/kpi/metrics/:id` — 启用/停用指标

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `is_enabled` | boolean | 是 | 启用/停用 |

**Response 200** — `KpiMetricDefinitionDto`

---

### 4C.3 `POST /api/kpi/metrics/:id/manual-input` — 录入手动指标值

**权限**: `kpi.manage`

> 仅 K10（租户满意度）。

**Request Body** — `ManualKpiInputRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period_start` | string(date) | 是 | 评估周期起始 |
| `period_end` | string(date) | 是 | 评估周期结束 |
| `value` | number | 是 | 指标值（如 92.5） |
| `target_user_id` | string(uuid) | 是 | 评估对象用户 ID |

**Response 200**

```json
{ "data": { "message": "手动指标值已录入" } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `METRIC_NOT_MANUAL_INPUT` | 该指标不支持手动录入 |

---

## 四-D、KPI 方案管理

### 4D.1 `GET /api/kpi/schemes` — KPI 方案列表

**权限**: `kpi.view`

**Response 200** — `KpiSchemeSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 方案 ID |
| `name` | string | 方案名称 |
| `period_type` | string(enum) | 评估周期：`monthly` / `quarterly` / `yearly` |
| `effective_from` | string(date) | 生效起始 |
| `effective_to` | string(date)? | 生效截止 |
| `status` | string(enum) | 方案状态：`draft` / `active` / `archived` |
| `scoring_mode` | string | `official` / `trial` |
| `created_at` | string(datetime) | 创建时间 |

---

### 4D.2 `POST /api/kpi/schemes` — 创建 KPI 方案

**权限**: `kpi.manage`

**Request Body** — `KpiSchemeCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 方案名称（最大 200 字符） |
| `period_type` | string(enum) | 是 | 评估周期 |
| `effective_from` | string(date) | 是 | 生效起始 |
| `effective_to` | string(date) | 否 | 生效截止（null=持续有效） |
| `scoring_mode` | string | 否 | `official`（默认）/ `trial` |

**Response 201** — `KpiSchemeDetail`

---

### 4D.3 `GET /api/kpi/schemes/:id` — KPI 方案详情

**权限**: `kpi.view`

**Response 200** — `KpiSchemeDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 方案 ID |
| `name` | string | 方案名称 |
| `period_type` | string(enum) | 评估周期 |
| `effective_from` | string(date) | 生效起始 |
| `effective_to` | string(date)? | 生效截止 |
| `status` | string(enum) | 方案状态：`draft` / `active` / `archived` |
| `scoring_mode` | string | 评分模式 |
| `metrics` | `KpiSchemeMetricConfig[]` | 方案指标列表 |
| `targets` | `KpiSchemeTargetConfig[]` | 绑定对象列表 |
| `created_by` | string(uuid)? | 创建人 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

**`KpiSchemeMetricConfig`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 关联 ID |
| `metric_id` | string(uuid) | 指标 ID |
| `metric_code` | string | 指标编号 |
| `metric_name` | string | 指标名称 |
| `weight` | number | 权重（0~1，所有权重之和 = 1） |
| `full_score_threshold` | number? | 满分阈值覆盖 |
| `pass_threshold` | number? | 及格阈值覆盖 |
| `fail_threshold` | number? | 不及格阈值覆盖 |

**`KpiSchemeTargetConfig`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 绑定 ID |
| `user_id` | string(uuid)? | 目标用户 ID |
| `user_name` | string? | 用户姓名 |
| `department_id` | string(uuid)? | 目标部门 ID |
| `department_name` | string? | 部门名称 |

---

### 4D.4 `PATCH /api/kpi/schemes/:id` — 更新方案基本信息

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 方案名称 |
| `period_type` | string(enum) | 否 | 评估周期 |
| `effective_from` | string(date) | 否 | 生效起始 |
| `effective_to` | string(date) | 否 | 生效截止 |
| `scoring_mode` | string | 否 | `official` / `trial` |

**Response 200** — `KpiSchemeDetail`

---

### 4D.5 `DELETE /api/kpi/schemes/:id` — 归档方案

**权限**: `kpi.manage`

> 将方案状态设为 `archived`，已有快照不受影响。

**Response 200**

```json
{ "data": { "message": "方案已归档" } }
```

---

### 4D.6 `GET /api/kpi/schemes/:id/metrics` — 方案指标列表

**权限**: `kpi.view`

**Response 200** — `KpiSchemeMetricConfig[]`

---

### 4D.7 `PUT /api/kpi/schemes/:id/metrics` — 覆盖方案指标配置

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `metrics` | `KpiSchemeMetricInput[]` | 是 | 指标配置列表（覆盖已有） |

**`KpiSchemeMetricInput`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `metric_id` | string(uuid) | 是 | 指标 ID |
| `weight` | number | 是 | 权重（0~1） |
| `full_score_threshold` | number | 否 | 满分阈值覆盖 |
| `pass_threshold` | number | 否 | 及格阈值覆盖 |
| `fail_threshold` | number | 否 | 不及格阈值覆盖 |

**Response 200** — `KpiSchemeMetricConfig[]`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `WEIGHT_SUM_NOT_ONE` | 权重之和 ≠ 1.00 |

---

### 4D.8 `GET /api/kpi/schemes/:id/targets` — 方案绑定对象列表

**权限**: `kpi.view`

**Response 200** — `KpiSchemeTargetConfig[]`

---

### 4D.9 `PUT /api/kpi/schemes/:id/targets` — 设置方案绑定对象

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `targets` | `KpiSchemeTargetInput[]` | 是 | 绑定对象列表（覆盖已有） |

**`KpiSchemeTargetInput`**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_id` | string(uuid) | 条件 | 目标用户（与 department_id 二选一） |
| `department_id` | string(uuid) | 条件 | 目标部门 |

**Response 200** — `KpiSchemeTargetConfig[]`

---

## 四-E、KPI 打分与快照

### 4E.1 `GET /api/kpi/scores` — KPI 快照列表

**权限**: `kpi.view`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scheme_id` | string(uuid) | 否 | 按方案过滤 |
| `evaluated_user_id` | string(uuid) | 否 | 按评估对象过滤 |
| `period_start` | string(date) | 否 | 评估周期起始 |
| `period_end` | string(date) | 否 | 评估周期结束 |
| `snapshot_status` | string | 否 | `draft` / `frozen` / `recalculated` |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `KpiScoreSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 快照 ID |
| `scheme_id` | string(uuid) | 方案 ID |
| `scheme_name` | string | 方案名称 |
| `evaluated_user_id` | string(uuid) | 评估对象 ID |
| `evaluated_user_name` | string | 评估对象姓名 |
| `period_start` | string(date) | 评估周期起始 |
| `period_end` | string(date) | 评估周期结束 |
| `total_score` | number | 总分（0~100） |
| `snapshot_status` | string | 快照状态 |
| `frozen_at` | string(datetime)? | 冻结时间 |
| `calculated_at` | string(datetime) | 计算时间 |

---

### 4E.2 `POST /api/kpi/scores/generate` — 触发 KPI 打分

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scheme_id` | string(uuid) | 是 | 方案 ID |
| `period_start` | string(date) | 是 | 评估周期起始 |
| `period_end` | string(date) | 是 | 评估周期结束 |

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `generated_count` | integer | 生成快照数 |
| `snapshot_ids` | string(uuid)[] | 快照 ID 列表 |

> 生成快照草稿（`snapshot_status='draft'`）。

---

### 4E.3 `POST /api/kpi/scores/recalculate` — 手工重算 KPI 快照

**权限**: `kpi.manage`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `snapshot_id` | string(uuid) | 是 | 要重算的快照 ID |

**Response 200** — `KpiScoreSnapshotDetail`

> 重算后 `snapshot_status` 变为 `recalculated`，不可再次申诉。保留重算审计记录。

---

### 4E.4 `GET /api/kpi/scores/:id` — KPI 快照详情

**权限**: `kpi.view`

**Response 200** — `KpiScoreSnapshotDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 快照 ID |
| `scheme_id` | string(uuid) | 方案 ID |
| `scheme_name` | string | 方案名称 |
| `evaluated_user_id` | string(uuid) | 评估对象 ID |
| `evaluated_user_name` | string | 评估对象姓名 |
| `period_start` | string(date) | 评估周期起始 |
| `period_end` | string(date) | 评估周期结束 |
| `total_score` | number | 总分 |
| `snapshot_status` | string | `draft` / `frozen` / `recalculated` |
| `frozen_at` | string(datetime)? | 冻结时间 |
| `calculated_at` | string(datetime) | 计算时间 |
| `created_by` | string(uuid)? | 创建人 |
| `items` | `KpiScoreSnapshotItemDto[]` | 指标明细列表 |

**`KpiScoreSnapshotItemDto`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 明细 ID |
| `metric_id` | string(uuid) | 指标 ID |
| `metric_code` | string | 指标编号 |
| `metric_name` | string | 指标名称 |
| `weight` | number | 权重 |
| `actual_value` | number? | 实际值 |
| `score` | number | 指标得分（0~100） |
| `weighted_score` | number | 加权得分 |
| `source_note` | string? | 取数说明 |

---

### 4E.5 `POST /api/kpi/scores/:id/freeze` — 冻结 KPI 快照

**权限**: `kpi.manage`

**Request Body**: 无

**Response 200** — `KpiScoreSnapshotDetail`（`snapshot_status` → `frozen`，`frozen_at` 填充）

> 冻结后触发申诉窗口 7 日计时。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `SNAPSHOT_NOT_DRAFT` | 仅 `draft` 状态可冻结 |

---

### 4E.6 `GET /api/kpi/rankings` — KPI 排名榜

**权限**: `kpi.view`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scheme_id` | string(uuid) | 是 | 方案 ID |
| `period_start` | string(date) | 是 | 评估周期起始 |
| `period_end` | string(date) | 是 | 评估周期结束 |
| `dimension` | string | 否 | `user`（默认）/ `department` |

**Response 200** — `KpiRankingResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `scheme_id` | string(uuid) | 方案 ID |
| `scheme_name` | string | 方案名称 |
| `period_start` | string(date) | 周期起始 |
| `period_end` | string(date) | 周期结束 |
| `rankings` | `RankingItem[]` | 排名列表 |

**`RankingItem`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `rank` | integer | 排名 |
| `user_id` | string(uuid)? | 用户 ID |
| `user_name` | string? | 用户姓名 |
| `department_id` | string(uuid)? | 部门 ID |
| `department_name` | string? | 部门名称 |
| `total_score` | number | 总分 |
| `snapshot_id` | string(uuid) | 快照 ID |

---

### 4E.7 `GET /api/kpi/trends` — KPI 历史趋势

**权限**: `kpi.view`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scheme_id` | string(uuid) | 是 | 方案 ID |
| `evaluated_user_id` | string(uuid) | 否 | 评估对象 |
| `months` | integer | 否 | 回溯月数（默认 12） |

**Response 200** — `KpiTrendResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `scheme_id` | string(uuid) | 方案 ID |
| `evaluated_user_id` | string(uuid)? | 评估对象 |
| `points` | `KpiTrendPoint[]` | 趋势数据点 |

**`KpiTrendPoint`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `period_start` | string(date) | 评估周期起始 |
| `period_end` | string(date) | 评估周期结束 |
| `total_score` | number | 总分 |
| `mom_change` | number? | 环比变化（百分点） |
| `yoy_change` | number? | 同比变化（百分点） |

---

### 4E.8 `GET /api/kpi/export` — 导出 KPI 评分报告 Excel

**权限**: `kpi.manage`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `scheme_id` | string(uuid) | 是 | 方案 ID |
| `period_start` | string(date) | 是 | 评估周期起始 |
| `period_end` | string(date) | 是 | 评估周期结束 |

**Response 200**: Excel 二进制流

```
Content-Disposition: attachment; filename="kpi_report_{scheme_name}_{period}.xlsx"
```

> Excel 包含：方案名、周期、评估对象、各指标实际值/得分/加权得分明细。

---

### 4E.9 `POST /api/kpi/appeals` — 提交 KPI 申诉

**权限**: `kpi.appeal`

**Request Body** — `KpiAppealCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `snapshot_id` | string(uuid) | 是 | 快照 ID |
| `reason` | string | 是 | 申诉理由 |

**Response 201**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 申诉 ID |
| `snapshot_id` | string(uuid) | 快照 ID |
| `appellant_id` | string(uuid) | 申诉人 ID |
| `reason` | string | 申诉理由 |
| `status` | string | `pending` |
| `created_at` | string(datetime) | 提交时间 |

**错误码**

| 错误码 | 说明 |
|--------|------|
| `APPEAL_WINDOW_CLOSED` | 超过冻结后 7 日申诉窗口 |
| `SNAPSHOT_NOT_FROZEN` | 仅 `frozen` 状态的快照可申诉 |
| `APPEAL_ALREADY_EXISTS` | 该快照已有未处理的申诉 |

---

### 4E.10 `GET /api/kpi/appeals` — 申诉列表

**权限**: `kpi.view`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string | 否 | `pending` / `approved` / `rejected` |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `KpiAppealItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 申诉 ID |
| `snapshot_id` | string(uuid) | 快照 ID |
| `appellant_id` | string(uuid) | 申诉人 ID |
| `appellant_name` | string | 申诉人姓名 |
| `reason` | string | 申诉理由 |
| `status` | string | 申诉状态 |
| `reviewer_id` | string(uuid)? | 审核人 |
| `reviewer_name` | string? | 审核人姓名 |
| `review_comment` | string? | 审核意见 |
| `reviewed_at` | string(datetime)? | 审核时间 |
| `created_at` | string(datetime) | 提交时间 |

---

### 4E.11 `PATCH /api/kpi/appeals/:id/review` — 审核申诉

**权限**: `kpi.manage`

**Request Body** — `KpiAppealReviewRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string | 是 | `approved` / `rejected` |
| `review_comment` | string | 否 | 审核意见 |

**Response 200** — `KpiAppealItem`

> 批准后自动触发重算对应快照。

---

## 五、工单模块

### 5.1 `GET /api/workorders` — 工单分页列表

**权限**: `workorders.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `work_order_type` | string(enum) | 否 | 工单类型：`repair` / `complaint` / `inspection` |
| `status` | string(enum) | 否 | 工单状态 |
| `priority` | string(enum) | 否 | 紧急程度 |
| `assignee_user_id` | string(uuid) | 否 | 按处理人 |
| `reporter_user_id` | string(uuid) | 否 | 按报修人 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `WorkOrderSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 工单 ID |
| `order_no` | string | 工单编号 |
| `work_order_type` | string(enum) | 工单类型：`repair` / `complaint` / `inspection` |
| `building_name` | string | 楼栋名称 |
| `floor_name` | string? | 楼层名称 |
| `unit_number` | string? | 单元编号 |
| `issue_type` | string | 问题类型 |
| `priority` | string(enum) | 紧急程度：`normal` / `urgent` / `critical` |
| `status` | string(enum) | 工单状态 |
| `reporter_name` | string | 报修人 |
| `assignee_name` | string? | 处理人 |
| `submitted_at` | string(datetime) | 提报时间 |
| `completed_at` | string(datetime)? | 完工时间 |

---

### 5.2 `POST /api/workorders` — 创建工单

**权限**: `workorders.write`

**Request Body** — `WorkOrderCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `work_order_type` | string(enum) | 否 | 工单类型（默认 `repair`）：`repair` / `complaint` / `inspection` |
| `building_id` | string(uuid) | 是 | 楼栋 ID |
| `floor_id` | string(uuid) | 否 | 楼层 ID |
| `unit_id` | string(uuid) | 否 | 单元 ID |
| `contract_id` | string(uuid) | 条件必填 | 关联合同 ID（`inspection` 类型必填） |
| `issue_type` | string | 是 | 问题类型（如"水电""空调""门窗""消防""其他"） |
| `priority` | string(enum) | 否 | 紧急程度（默认 `normal`） |
| `description` | string | 是 | 问题描述 |
| `source` | string | 否 | 来源（默认 `app`）：`app` / `mini_program` / `manual` |

**Response 201** — `WorkOrderDetail`

---

### 5.3 `GET /api/workorders/:id` — 工单详情

**权限**: `workorders.read`

**Response 200** — `WorkOrderDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 工单 ID |
| `order_no` | string | 工单编号 |
| `work_order_type` | string(enum) | 工单类型：`repair` / `complaint` / `inspection` |
| `building_id` | string(uuid) | 楼栋 ID |
| `building_name` | string | 楼栋名称 |
| `floor_id` | string(uuid)? | 楼层 ID |
| `floor_name` | string? | 楼层名称 |
| `unit_id` | string(uuid)? | 单元 ID |
| `unit_number` | string? | 单元编号 |
| `contract_id` | string(uuid)? | 关联合同 ID（`inspection` 类型必有） |
| `issue_type` | string | 问题类型 |
| `priority` | string(enum) | 紧急程度 |
| `description` | string | 问题描述 |
| `status` | string(enum) | 工单状态 |
| `reporter_user_id` | string(uuid) | 报修人 ID |
| `reporter_name` | string | 报修人姓名 |
| `assignee_user_id` | string(uuid)? | 处理人 ID |
| `assignee_name` | string? | 处理人姓名 |
| `supplier_id` | string(uuid)? | 供应商 ID |
| `supplier_name` | string? | 供应商名称 |
| `submitted_at` | string(datetime) | 提报时间 |
| `approved_at` | string(datetime)? | 审核时间 |
| `started_at` | string(datetime)? | 开始处理时间 |
| `completed_at` | string(datetime)? | 完工时间 |
| `expected_complete_at` | string(datetime)? | 预计完成时间 |
| `on_hold_reason` | string? | 挂起原因 |
| `rejected_reason` | string? | 拒绝原因 |
| `reopened_from_work_order_id` | string(uuid)? | 重开来源工单 |
| `material_cost` | number? | 材料费（仅 `repair` 类型） |
| `labor_cost` | number? | 人工费（仅 `repair` 类型） |
| `inspection_note` | string? | 验收备注 / 处理结论 / 查验结论 |
| `deposit_deduction_suggestion` | number? | 建议押金扣减金额（仅 `inspection` 类型） |
| `follow_up_work_order_id` | string(uuid)? | 跟进维修工单 ID（仅 `inspection` 类型） |
| `source` | string | 来源渠道 |
| `photos` | `WorkOrderPhotoDto[]` | 照片列表 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

**`WorkOrderPhotoDto`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 照片 ID |
| `photo_stage` | string | `before` / `after` |
| `storage_path` | string | 存储路径 |
| `sort_order` | integer | 排序 |
| `uploaded_by` | string(uuid)? | 上传人 |
| `created_at` | string(datetime) | 上传时间 |

---

### 5.4 `PATCH /api/workorders/:id/approve` — 审核/派单

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `assignee_user_id` | string(uuid) | 否 | 指定处理人 |
| `supplier_id` | string(uuid) | 否 | 指定供应商 |
| `expected_complete_at` | string(datetime) | 否 | 预计完成时间 |

**Response 200** — `WorkOrderDetail`

---

### 5.5 `PATCH /api/workorders/:id/reject` — 拒绝工单

**权限**: `workorders.write`

**Request Body** — `WorkOrderRejectRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `rejected_reason` | string | 是 | 拒绝原因 |

**Response 200** — `WorkOrderDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `WORKORDER_NOT_REJECTABLE` | 仅 `submitted` 或 `pending_inspection` 状态可拒绝 |

---

### 5.6 `PATCH /api/workorders/:id/start` — 开始处理

**权限**: `workorders.write`

**Request Body**: 无

**Response 200** — `WorkOrderDetail`

---

### 5.7 `PATCH /api/workorders/:id/hold` — 挂起工单

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `on_hold_reason` | string | 是 | 挂起原因 |
| `expected_resume_at` | string(datetime) | 否 | 预计恢复时间 |

**Response 200** — `WorkOrderDetail`

---

### 5.8 `PATCH /api/workorders/:id/complete` — 完工并录入成本

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `material_cost` | number | 否 | 材料费（元，≥0） |
| `labor_cost` | number | 否 | 人工费（元，≥0） |
| `inspection_note` | string | 否 | 完工备注 |

**Response 200** — `WorkOrderDetail`

---

### 5.9 `PATCH /api/workorders/:id/inspect` — 验收工单

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `inspection_note` | string | 否 | 验收备注 |

**Response 200** — `WorkOrderDetail`

---

### 5.10 `PATCH /api/workorders/:id/reopen` — 重开工单

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | 是 | 重开原因 |

**Response 200** — `WorkOrderDetail`（生成新工单，`reopened_from_work_order_id` 指向原工单）

**错误码**

| 错误码 | 说明 |
|--------|------|
| `REOPEN_WINDOW_CLOSED` | 已完成超过 7 天，不可重开 |

---

### 5.11 `POST /api/workorders/:id/photos` — 上传工单照片

**权限**: `workorders.write`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 照片文件 |
| `photo_stage` | string | 否 | `before`（默认）/ `after` |

**Response 201** — `WorkOrderPhotoDto`

---

### 5.12 `GET /api/suppliers` — 供应商列表

**权限**: `workorders.read`

**Response 200** — `SupplierSummary[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 供应商 ID |
| `name` | string | 供应商名称 |
| `category` | string? | 类别 |
| `contact_name` | string? | 联系人 |
| `contact_phone_masked` | string? | 联系电话（脱敏） |
| `rating` | number? | 综合评分（1.0–5.0，无评分时 `null`） |
| `completed_orders` | integer | 已完成工单数 |
| `avg_response_hours` | number? | 平均响应时长（小时） |
| `is_active` | boolean | 是否启用 |
| `created_at` | string(datetime) | 创建时间 |

---

### 5.13 `POST /api/suppliers` — 新增供应商

**权限**: `workorders.write`

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 供应商名称（最大 200 字符） |
| `category` | string | 否 | 类别（`plumbing` / `hvac` / `cleaning` / `locksmith` / `other`） |
| `contact_name` | string | 否 | 联系人 |
| `contact_phone` | string | 否 | 联系电话（明文传入，加密存储） |
| `address` | string | 否 | 地址 |
| `notes` | string | 否 | 备注 |

**Response 201** — `SupplierDetail`

---

### 5.14 `GET /api/suppliers/:id` — 供应商详情

**权限**: `workorders.read`

**Response 200** — `SupplierDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 供应商 ID |
| `name` | string | 名称 |
| `category` | string? | 类别 |
| `contact_name` | string? | 联系人 |
| `contact_phone_masked` | string? | 联系电话（脱敏） |
| `address` | string? | 地址 |
| `notes` | string? | 备注 |
| `is_active` | boolean | 是否启用 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 5.15 `PATCH /api/suppliers/:id` — 更新供应商信息

**权限**: `workorders.write`

**Request Body**（所有字段可选）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 否 | 名称 |
| `category` | string | 否 | 类别 |
| `contact_name` | string | 否 | 联系人 |
| `contact_phone` | string | 否 | 联系电话 |
| `address` | string | 否 | 地址 |
| `notes` | string | 否 | 备注 |
| `is_active` | boolean | 否 | 启用/停用 |

**Response 200** — `SupplierDetail`

---

### 5.16 `GET /api/workorders/cost-report` — 工单费用报表

**权限**: `workorders.read`

> 按时间段汇总工单费用，支持按楼栋、类别维度分组。

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `date_from` | string(date) | 否 | 开始日期 |
| `date_to` | string(date) | 否 | 结束日期 |
| `building_id` | string(uuid) | 否 | 按楼栋过滤 |
| `group_by` | string | 否 | 分组维度：`building` / `category` / `supplier`（默认 `category`） |

**Response 200** — `WorkOrderCostReport`

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_cost` | number | 总费用（元） |
| `total_orders` | integer | 总工单数 |
| `avg_cost_per_order` | number | 平均每单费用 |
| `groups` | CostGroup[] | 分组明细 |

**`CostGroup`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_key` | string | 分组键值（楼栋名/类别名/供应商名） |
| `group_id` | string(uuid)? | 分组实体 ID |
| `order_count` | integer | 工单数 |
| `total_cost` | number | 费用合计（元） |
| `ratio` | number | 费用占比（0~1） |

---

## 六、二房东穿透模块

### 6.1 `POST /api/sublease-portal/login` — 二房东门户登录

**权限**: 公共

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 邮箱 |
| `password` | string | 是 | 密码 |

**Response 200** — `LoginResponse`（同 §1.1，但 `user.role` 必为 `sub_landlord`）

> 首次登录需检查 `must_change_password`。

---

### 6.2 `GET /api/sublease-portal/units` — 当前二房东可填报单元列表

**权限**: `sublease.portal`

> Repository 层强制按 `bound_contract_id` 行级过滤。

**Response 200** — `SubleasePortalUnit[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `building_name` | string | 楼栋名称 |
| `floor_name` | string? | 楼层名称 |
| `property_type` | string(enum) | 业态 |
| `net_area` | number? | 套内面积 |
| `has_sublease` | boolean | 是否已有子租赁记录 |
| `current_occupancy_status` | string(enum)? | 当前入住状态 |

---

### 6.3 `GET /api/sublease-portal/subleases` — 已提交记录列表

**权限**: `sublease.portal`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `review_status` | string(enum) | 否 | `draft` / `pending` / `approved` / `rejected` |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `SubleaseSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 子租赁 ID |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `sub_tenant_name` | string | 终端租客名称 |
| `sub_tenant_type` | string(enum) | 租客类型 |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `monthly_rent` | number | 月租金 |
| `occupancy_status` | string(enum) | 入住状态 |
| `review_status` | string(enum) | 审核状态 |
| `created_at` | string(datetime) | 创建时间 |

---

### 6.4 `POST /api/sublease-portal/subleases` — 新增子租赁填报

**权限**: `sublease.portal`

**Request Body** — `SubleaseCreateRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `unit_id` | string(uuid) | 是 | 单元 ID（必须在主合同覆盖范围内） |
| `sub_tenant_name` | string | 是 | 终端租客名称（最大 200 字符） |
| `sub_tenant_type` | string(enum) | 是 | `corporate` / `individual` |
| `sub_tenant_contact_person` | string | 否 | 联系人 |
| `sub_tenant_id_number` | string | 否 | 证件号（明文传入，服务端加密存储） |
| `sub_tenant_phone` | string | 否 | 联系电话（明文传入，服务端加密存储） |
| `start_date` | string(date) | 是 | 子租赁起租日 |
| `end_date` | string(date) | 是 | 子租赁到期日（≤主合同到期日） |
| `monthly_rent` | number | 是 | 月租金（元，>0） |
| `occupancy_status` | string(enum) | 是 | `occupied` / `signed_not_moved` / `moved_out` / `vacant` |
| `occupant_count` | integer | 否 | 入住人数（公寓） |
| `notes` | string | 否 | 备注 |
| `review_status` | string(enum) | 否 | `draft`（暂存）/ `pending`（默认，直接提交审核） |

**Response 201** — `SubleaseDetail`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `UNIT_NOT_IN_MASTER_CONTRACT` | 单元不在主合同覆盖范围 |
| `SUBLEASE_END_EXCEEDS_MASTER` | 子租赁到期日超出主合同到期日 |
| `UNIT_ALREADY_SUBLEASED` | 同一单元已有在租记录 |

---

### 6.5 `POST /api/sublease-portal/subleases/import` — 批量导入子租赁

**权限**: `sublease.portal`

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | Excel 文件 |

**Response 200** — `ImportBatchDetail`（见 §七）

---

### 6.6 `GET /api/sublease-portal/subleases/:id` — 子租赁填报详情

**权限**: `sublease.portal`

> 行级隔离：仅可见自身主合同范围内数据。

**Response 200** — `SubleaseDetail`（见 §6.9 内部详情，但证件号/手机始终脱敏）

---

### 6.7 `PATCH /api/sublease-portal/subleases/:id` — 修改待审核或退回记录

**权限**: `sublease.portal`

**Request Body**: 同 `SubleaseCreateRequest`（所有字段可选），仅 `draft` 或 `rejected` 状态可修改。

**Response 200** — `SubleaseDetail`

---

### 6.8 `POST /api/sublease-portal/subleases/:id/submit` — 提交审核

**权限**: `sublease.portal`

> `draft → pending`

**Request Body**: 无

**Response 200** — `SubleaseDetail`（`review_status` 变为 `pending`）

---

### 6.8b `DELETE /api/sublease-portal/subleases/:id` — 删除草稿

**权限**: `sublease.portal`

> 仅限 `draft` 状态。

**Response 200**

```json
{ "data": { "message": "草稿已删除" } }
```

**错误码**

| 错误码 | 说明 |
|--------|------|
| `SUBLEASE_NOT_DRAFT` | 仅草稿可删除 |

---

### 6.9 `GET /api/subleases` — 内部子租赁分页列表

**权限**: `sublease.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `master_contract_id` | string(uuid) | 否 | 按主合同过滤 |
| `review_status` | string(enum) | 否 | 审核状态 |
| `occupancy_status` | string(enum) | 否 | 入住状态 |
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `SubleaseDetail[]`（带 `meta`）

---

### 6.10 `GET /api/subleases/:id` — 子租赁详情

**权限**: `sublease.read`

**Response 200** — `SubleaseDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 子租赁 ID |
| `master_contract_id` | string(uuid) | 主合同 ID |
| `master_contract_no` | string | 主合同编号 |
| `unit_id` | string(uuid) | 单元 ID |
| `unit_number` | string | 单元编号 |
| `building_name` | string | 楼栋名称 |
| `floor_name` | string? | 楼层名称 |
| `sub_tenant_name` | string | 终端租客名称 |
| `sub_tenant_type` | string(enum) | 租客类型 |
| `sub_tenant_contact_person` | string? | 联系人 |
| `sub_tenant_id_number_masked` | string? | 证件号（脱敏：`****XXXX`） |
| `sub_tenant_phone_masked` | string? | 联系电话（脱敏：`***XXXX`） |
| `start_date` | string(date) | 起租日 |
| `end_date` | string(date) | 到期日 |
| `monthly_rent` | number | 月租金 |
| `rent_per_sqm` | number? | 单价（元/m²/月） |
| `occupancy_status` | string(enum) | 入住状态 |
| `occupant_count` | integer? | 入住人数 |
| `review_status` | string(enum) | 审核状态 |
| `reviewer_user_id` | string(uuid)? | 审核人 |
| `reviewer_name` | string? | 审核人姓名 |
| `reviewed_at` | string(datetime)? | 审核时间 |
| `rejection_reason` | string? | 退回原因 |
| `version_no` | integer | 版本号 |
| `declared_for_month` | string(date)? | 申报月份 |
| `submission_channel` | string | 提交渠道 |
| `submitted_by_user_id` | string(uuid)? | 提交人 |
| `submitted_at` | string(datetime)? | 提交时间 |
| `notes` | string? | 备注 |
| `created_at` | string(datetime) | 创建时间 |
| `updated_at` | string(datetime) | 更新时间 |

---

### 6.11 `POST /api/subleases/:id/unmask` — 查看子租赁方完整敏感信息

**权限**: `sublease.read`（需二次鉴权）

**Request Body** — `UnmaskRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `current_password` | string | 是 | 当前登录用户密码 |

**Response 200** — `UnmaskResponse`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id_number` | string? | 完整证件号 |
| `contact_phone` | string? | 完整联系电话 |

> 审计日志：`action="sublease.view_sensitive"`。

---

### 6.12 `PATCH /api/subleases/:id/approve` — 审核通过

**权限**: `sublease.write`

**Request Body**: 无

**Response 200** — `SubleaseDetail`（`review_status` → `approved`）

---

### 6.13 `PATCH /api/subleases/:id/reject` — 退回

**权限**: `sublease.write`

**Request Body** — `SubleaseReviewRequest`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `rejection_reason` | string | 是 | 退回原因 |

**Response 200** — `SubleaseDetail`

---

### 6.14 `GET /api/subleases/dashboard` — 穿透基础看板

**权限**: `sublease.read`

**Response 200** — `SubleaseDashboard`

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_master_contracts` | integer | 二房东主合同数 |
| `total_units` | integer | 二房东覆盖总单元数 |
| `subleased_units` | integer | 已填报子租赁单元数 |
| `occupied_units` | integer | 已入住单元数 |
| `vacant_units` | integer | 空置单元数 |
| `penetration_occupancy_rate` | number | 穿透出租率（0~1） |
| `by_master_contract` | `MasterContractStats[]` | 按主合同分拆 |

**`MasterContractStats`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `master_contract_id` | string(uuid) | 主合同 ID |
| `master_contract_no` | string | 主合同编号 |
| `tenant_name` | string | 二房东名称 |
| `master_rent` | number | 主合同月租金 |
| `total_units` | integer | 覆盖单元数 |
| `subleased_units` | integer | 已填报数 |
| `occupied_units` | integer | 已入住数 |
| `avg_sub_rent_per_sqm` | number? | 终端平均单价 |
| `premium_rate` | number? | 溢价率 |

---

### 6.15 `GET /api/subleases/export` — 导出子租赁 Excel

**权限**: `sublease.read`

> 仅导出 `approved` 记录。

**Response 200**: Excel 二进制流

```
Content-Disposition: attachment; filename="subleases_export.xlsx"
```

---

## 七、数据导入与批次管理

### 7.1 `POST /api/imports` — 提交导入任务

**权限**: `assets.write` / `contracts.write`（依据 `data_type`）

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | Excel 文件 |
| `data_type` | string(enum) | 是 | `units` / `contracts` / `invoices` |
| `dry_run` | boolean | 否 | 仅校验不入库（默认 false） |

**Response 200** — `ImportBatchDetail`

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 批次 ID |
| `batch_name` | string | 批次名称 |
| `data_type` | string(enum) | 数据类别 |
| `total_records` | integer | 总记录数 |
| `success_count` | integer | 成功数 |
| `failure_count` | integer | 失败数 |
| `rollback_status` | string(enum) | `committed` / `rolled_back` |
| `is_dry_run` | boolean | 是否为试导入 |
| `error_details` | `ImportError[]`? | 错误明细 |
| `source_file_path` | string? | 源文件路径 |
| `created_by` | string(uuid)? | 操作人 |
| `created_at` | string(datetime) | 创建时间 |

**`ImportError`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `row` | integer | 错误行号 |
| `field` | string | 错误字段 |
| `error` | string | 错误描述 |

---

### 7.2 `GET /api/imports` — 导入批次列表

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `data_type` | string(enum) | 否 | 按数据类别过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `ImportBatchSummary[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 批次 ID |
| `batch_name` | string | 批次名称 |
| `data_type` | string(enum) | 数据类别 |
| `total_records` | integer | 总记录数 |
| `success_count` | integer | 成功数 |
| `failure_count` | integer | 失败数 |
| `rollback_status` | string(enum) | 回滚状态 |
| `is_dry_run` | boolean | 是否试导入 |
| `created_at` | string(datetime) | 创建时间 |

---

### 7.3 `GET /api/imports/:id` — 批次详情

**权限**: `assets.read`

**Response 200** — `ImportBatchDetail`（同 7.1）

---

### 7.4 `POST /api/imports/:id/rollback` — 按批次回滚

**权限**: `super_admin`

**Request Body**: 无

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `rolled_back_count` | integer | 回滚记录数 |

> 写审计日志。

**错误码**

| 错误码 | 说明 |
|--------|------|
| `BATCH_ALREADY_ROLLED_BACK` | 批次已回滚 |
| `BATCH_IS_DRY_RUN` | 试导入批次无需回滚 |

---

### 7.5 `GET /api/imports/:id/errors` — 获取错误行报告

**权限**: `assets.read`

**Response 200**: Excel 二进制流（含原始行号 + 错误字段 + 错误原因）

```
Content-Disposition: attachment; filename="import_errors_{batch_id}.xlsx"
```

---

## 八、运维与辅助接口

### 8.1 `GET /api/jobs/executions` — 定时任务执行列表

**权限**: `ops.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `job_name` | string | 否 | 按任务名过滤 |
| `status` | string | 否 | `running` / `success` / `failed` / `retry_scheduled` |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `JobExecutionItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 执行 ID |
| `job_name` | string | 任务名 |
| `job_scope` | string? | 任务范围 |
| `status` | string | 状态 |
| `retry_count` | integer | 重试次数 |
| `started_at` | string(datetime) | 开始时间 |
| `finished_at` | string(datetime)? | 结束时间 |
| `error_message` | string? | 错误信息 |
| `triggered_by_user_id` | string(uuid)? | 触发人 |
| `created_at` | string(datetime) | 创建时间 |

---

### 8.2 `POST /api/jobs/executions/:id/retry` — 手工重试失败任务

**权限**: `ops.write`

**Request Body**: 无

**Response 200** — `JobExecutionItem`

---

### 8.3 `GET /api/files/:path` — 代理下载文件

**权限**: 已登录

**Response 200**: 文件二进制流（Content-Type 根据文件类型动态设置）

---

### 8.4 `POST /api/files` — 通用文件上传

**权限**: 已登录

**Request**: `multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | binary | 是 | 文件 |

**Response 201**

| 字段 | 类型 | 说明 |
|------|------|------|
| `storage_path` | string | 存储路径 |
| `file_size_kb` | integer | 文件大小（KB） |
| `content_type` | string | MIME 类型 |

---

### 8.5 `GET /api/audit-logs` — 审计日志分页列表

**权限**: `super_admin`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `resource_type` | string | 否 | 资源类型过滤 |
| `resource_id` | string(uuid) | 否 | 资源 ID |
| `user_id` | string(uuid) | 否 | 操作人 |
| `created_at_from` | string(datetime) | 否 | 时间范围起 |
| `created_at_to` | string(datetime) | 否 | 时间范围止 |
| `page` | integer | 否 | 页码（默认 1） |
| `pageSize` | integer | 否 | 每页条数（默认 50，最大 200） |

**Response 200** — `AuditLogEntry[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 日志 ID |
| `user_id` | string(uuid) | 操作人 ID |
| `user_name` | string | 操作人姓名 |
| `action` | string | 操作类型（如 `contract.update`） |
| `resource_type` | string | 资源类型 |
| `resource_id` | string(uuid) | 资源 ID |
| `before_json` | object? | 变更前快照 |
| `after_json` | object? | 变更后快照 |
| `ip_address` | string? | 客户端 IP |
| `created_at` | string(datetime) | 操作时间 |

---

### 8.6 `GET /api/health` — 健康检查

**权限**: 公共

**Response 200**

```json
{
  "data": {
    "status": "ok",
    "version": "1.7.0",
    "database": "connected",
    "timestamp": "2026-04-08T08:00:00Z"
  }
}
```

---

## 八-A、通知系统

### 8A.1 `GET /api/notifications` — 通知列表

**权限**: 已认证（返回当前用户通知）

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `is_read` | boolean | 否 | 过滤已读/未读 |
| `type` | string(enum) | 否 | 通知类型过滤 |
| `severity` | string(enum) | 否 | 严重级别过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `NotificationItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 通知 ID |
| `type` | string(enum) | 通知类型：`contract_expiring` / `invoice_overdue` / `workorder_assigned` / `workorder_completed` / `approval_pending` / `system_alert` / `kpi_published` |
| `severity` | string(enum) | 严重级别：`info` / `warning` / `critical` |
| `title` | string | 通知标题 |
| `content` | string | 通知正文 |
| `is_read` | boolean | 是否已读 |
| `resource_type` | string? | 关联资源类型（`contract` / `invoice` / `workorder`） |
| `resource_id` | string(uuid)? | 关联资源 ID |
| `created_at` | string(datetime) | 创建时间 |

---

### 8A.2 `PATCH /api/notifications/:id/read` — 标记单条已读

**权限**: 已认证

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 通知 ID |
| `is_read` | boolean | `true` |

---

### 8A.3 `POST /api/notifications/read-all` — 全部标记已读

**权限**: 已认证

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `updated_count` | integer | 标记已读数量 |

---

### 8A.4 `GET /api/notifications/unread-count` — 未读数量

**权限**: 已认证

**Response 200**

| 字段 | 类型 | 说明 |
|------|------|------|
| `unread_count` | integer | 未读通知总数 |
| `by_severity` | object | 按级别统计 `{ "critical": 2, "warning": 5, "info": 10 }` |

---

## 八-B、审批队列

### 8B.1 `GET /api/approvals` — 待审批列表

**权限**: 已认证（返回当前用户待审批项）

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string(enum) | 否 | `pending` / `approved` / `rejected`（默认 `pending`） |
| `type` | string(enum) | 否 | 审批类型过滤 |
| `page` | integer | 否 | 页码 |
| `pageSize` | integer | 否 | 每页条数 |

**Response 200** — `ApprovalItem[]`（带 `meta`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string(uuid) | 审批记录 ID |
| `type` | string(enum) | 审批类型：`contract_termination` / `deposit_refund` / `invoice_adjustment` / `sublease_submission` |
| `status` | string(enum) | 审批状态：`pending` / `approved` / `rejected` |
| `title` | string | 审批标题 |
| `description` | string? | 描述/理由 |
| `resource_type` | string | 关联资源类型 |
| `resource_id` | string(uuid) | 关联资源 ID |
| `submitted_by` | string(uuid) | 提交人 ID |
| `submitted_by_name` | string | 提交人姓名 |
| `submitted_at` | string(datetime) | 提交时间 |
| `reviewed_by` | string(uuid)? | 审批人 ID |
| `reviewed_at` | string(datetime)? | 审批时间 |
| `review_comment` | string? | 审批意见 |

---

### 8B.2 `PATCH /api/approvals/:id` — 审批操作

**权限**: 按审批类型动态校验（如合同相关需 `contracts.approve`）

**Request Body**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `action` | string(enum) | 是 | `approve` / `reject` |
| `comment` | string | 否 | 审批意见 |

**Response 200** — `ApprovalItem`

**错误码**

| 错误码 | 说明 |
|--------|------|
| `APPROVAL_NOT_FOUND` | 审批记录不存在 |
| `APPROVAL_ALREADY_PROCESSED` | 审批已处理 |
| `APPROVAL_SELF_REVIEW` | 不允许审批自己提交的内容 |

---

## 九、首页看板聚合

### 9.1 `GET /api/dashboard/overview` — 首页概览卡片

**权限**: 已认证（按 JWT 角色裁剪返回字段）

> 不同角色看到不同卡片：  
> - `super_admin` / `operations_manager`：全部字段  
> - `leasing_specialist`：资产 + 合同部分  
> - `finance_staff`：财务 + 收缴率部分  
> - `maintenance_staff`：工单部分  
> - 其它角色：仅 `welcome_message`

**Response 200** — `DashboardOverview`

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_buildings` | integer? | 楼栋数 |
| `total_units` | integer? | 房间总数 |
| `total_area` | number? | 总面积（m²） |
| `occupancy_rate` | number? | 综合出租率（0~1） |
| `active_contracts` | integer? | 有效合同数 |
| `expiring_soon_contracts` | integer? | 即将到期合同数（90天内） |
| `wale` | number? | 全局 WALE（年） |
| `monthly_revenue` | number? | 本月应收（元） |
| `monthly_collected` | number? | 本月实收（元） |
| `collection_rate` | number? | 本月收缴率（0~1） |
| `overdue_amount` | number? | 逾期总额（元） |
| `overdue_invoices` | integer? | 逾期账单数 |
| `open_workorders` | integer? | 待处理工单数 |
| `avg_resolution_hours` | number? | 平均解决时长（小时） |
| `noi_current_month` | number? | 本月 NOI |
| `noi_budget_achievement` | number? | NOI 预算达成率(0~1) |
| `unread_notifications` | integer? | 未读通知数 |
| `pending_approvals` | integer? | 待审批数 |

> 值为 `null` 表示该角色无权查看该指标，前端不渲染对应卡片。

---

### 9.2 `GET /api/dashboard/revenue-trend` — 收入趋势

**权限**: `finance.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `months` | integer | 否 | 蓝看月数（默认 12） |
| `building_id` | string(uuid) | 否 | 按楼栋 |
| `property_type` | string(enum) | 否 | 按业态 |

**Response 200** — `RevenueTrendPoint[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `month` | string | 月份标识（`2026-01`） |
| `receivable` | number | 应收（元） |
| `collected` | number | 实收（元） |
| `collection_rate` | number | 收缴率（0~1） |
| `overdue` | number | 逾期额（元） |

---

### 9.3 `GET /api/dashboard/occupancy-trend` — 出租率趋势

**权限**: `assets.read`

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `months` | integer | 否 | 回看月数（默认 12） |
| `building_id` | string(uuid) | 否 | 按楼栋 |

**Response 200** — `OccupancyTrendPoint[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `month` | string | 月份标识 |
| `occupancy_rate` | number | 当月出租率（0~1） |
| `vacant_units` | integer | 空置房间数 |
| `vacant_area` | number | 空置面积（m²） |

---

## 附录 A：DTO 索引

| 序号 | DTO 名称 | 所属章节 | 说明 |
|------|---------|---------|------|
| 1 | `LoginResponse` | §1.1 | 登录响应（含 token + UserBrief） |
| 2 | `UserBrief` | §1.1 | 用户简要信息 |
| 3 | `CurrentUser` | §1.4 | 当前用户完整信息含权限 |
| 4 | `UserSummary` | §1.5 | 用户列表项 |
| 5 | `UserDetail` | §1.6 | 用户完整详情 |
| 6 | `UserCreateRequest` | §1.7 | 创建用户请求体 |
| 7 | `ChangePasswordRequest` | §1.12 | 改密请求体 |
| 8 | `DepartmentTree` | §1A.1 | 部门树节点（嵌套） |
| 9 | `DepartmentCreateRequest` | §1A.2 | 创建部门请求体 |
| 10 | `ManagedScopeConfig` | §1A.5 | 管辖范围配置 |
| 11 | `ManagedScopeSetRequest` | §1A.6 | 设置管辖范围请求体 |
| 12 | `BuildingSummary` | §2.1 | 楼栋信息 |
| 13 | `BuildingCreateRequest` | §2.2 | 创建楼栋请求体 |
| 14 | `FloorSummary` | §2.5 | 楼层信息 |
| 15 | `FloorCreateRequest` | §2.6 | 创建楼层请求体 |
| 16 | `FloorHeatmap` / `HeatmapUnit` | §2.9 | 热区与状态色块 |
| 17 | `FloorPlanVersionDto` | §2.10 | 楼层图纸版本 |
| 18 | `UnitSummary` | §2.12 | 单元列表项 |
| 19 | `UnitCreateRequest` | §2.13 | 创建单元请求体 |
| 20 | `UnitDetail` | §2.14 | 单元完整详情 |
| 21 | `RenovationDetail` | §2.19 | 改造记录详情 |
| 22 | `AssetOverview` / `PropertyTypeStats` | §2.23 | 资产概览看板 |
| 23 | `TenantSummary` | §3.1 | 租客列表项 |
| 24 | `TenantCreateRequest` | §3.2 | 创建租客请求体 |
| 25 | `TenantDetail` | §3.3 | 租客详情（含脱敏字段） |
| 26 | `UnmaskRequest` / `UnmaskResponse` | §3.5 | 脱敏还原 |
| 27 | `ContractSummary` | §3.6 | 合同列表项 |
| 28 | `ContractCreateRequest` / `ContractUnitInput` | §3.7 | 创建合同请求体 |
| 29 | `ContractDetail` / `ContractUnitDetail` | §3.8 | 合同完整详情 |
| 30 | `TerminateContractRequest` | §3.13 | 合同终止请求体 |
| 31 | `ContractAttachmentListItem` | §3.10 | 合同附件列表项 |
| 32 | `EscalationPhaseDto` / `EscalationPhaseInput` | §3.14 | 递增阶段 |
| 33 | `WaleResult` / `WaleGroup` | §3.16 | WALE 双口径 |
| 34 | `AlertItem` | §3.17 | 预警列表项 |
| 35 | `AlertUnreadResponse` | §3.18 | 未读预警数量 |
| 36 | `DepositSummary` / `DepositDetail` | §3A.1~3A.3 | 押金 |
| 37 | `DepositTransactionDto` | §3A.8 | 押金流水 |
| 38 | `EscalationTemplateDto` | §3B.1 | 递增模板 |
| 39 | `ApplyTemplateRequest` | §3B.6 | 应用模板请求体 |
| 40 | `RentForecastRow` | §3C.1 | 租金预测行 |
| 41 | `WaleTrendPoint` | §3C.3 | WALE 趋势数据点 |
| 42 | `WaleWaterfallItem` | §3C.4 | WALE 瀑布图项 |
| 43 | `InvoiceSummary` / `InvoiceDetail` | §4.1/4.4 | 账单 |
| 44 | `InvoiceItemDto` | §4.5 | 账单费项明细 |
| 45 | `InvoiceVoidRequest` | §4.7 | 作废账单请求体 |
| 46 | `PaymentCreateRequest` / `AllocationInput` | §4.8 | 收款请求体 |
| 47 | `PaymentDetail` / `PaymentAllocationDto` | §4.10 | 收款详情 |
| 48 | `ExpenseSummary` / `ExpenseCreateRequest` | §4.12/4.13 | 运营支出 |
| 49 | `NoiSummary` | §4.16 | NOI 汇总 |
| 50 | `NoiTrendPoint` | §4.17 | NOI 趋势 |
| 51 | `NoiBreakdownItem` | §4.18 | NOI 拆分 |
| 52 | `NoiVacancyLossItem` | §4.19 | 空置损失 |
| 53 | `NoiBudgetItem` / `NoiBudgetCreateRequest` | §4.20/4.21 | NOI 预算 |
| 54 | `MeterReadingDetail` / `MeterReadingCreateRequest` | §4A | 水电抄表 |
| 55 | `TurnoverReportDetail` / `TurnoverReportCreateRequest` | §4B | 营业额申报 |
| 56 | `KpiMetricDefinitionDto` | §4C.1 | KPI 指标 |
| 57 | `ManualKpiInputRequest` | §4C.3 | 手动指标录入 |
| 58 | `KpiSchemeDetail` / `KpiSchemeMetricConfig` / `KpiSchemeTargetConfig` | §4D.3 | KPI 方案 |
| 59 | `KpiScoreSnapshotDetail` / `KpiScoreSnapshotItemDto` | §4E.4 | KPI 快照 |
| 60 | `KpiRankingResponse` / `RankingItem` | §4E.6 | KPI 排名 |
| 61 | `KpiTrendResponse` / `KpiTrendPoint` | §4E.7 | KPI 趋势 |
| 62 | `KpiAppealCreateRequest` / `KpiAppealReviewRequest` | §4E.9/4E.11 | KPI 申诉 |
| 63 | `WorkOrderDetail` / `WorkOrderCreateRequest` | §5.2/5.3 | 工单 |
| 64 | `WorkOrderRejectRequest` | §5.5 | 工单拒绝 |
| 65 | `WorkOrderPhotoDto` | §5.3 | 工单照片 |
| 66 | `SupplierDetail` | §5.14 | 供应商详情 |
| 67 | `SubleasePortalUnit` | §6.2 | 二房东可填报单元 |
| 68 | `SubleaseCreateRequest` | §6.4 | 子租赁创建 |
| 69 | `SubleaseDetail` | §6.10 | 子租赁详情 |
| 70 | `SubleaseReviewRequest` | §6.13 | 子租赁审核 |
| 71 | `SubleaseDashboard` / `MasterContractStats` | §6.14 | 穿透看板 |
| 72 | `ImportBatchDetail` / `ImportError` | §7.1 | 导入批次 |
| 73 | `JobExecutionItem` | §8.1 | 任务执行记录 |
| 74 | `AuditLogEntry` | §8.5 | 审计日志 |
| 75 | `TenantContractItem` | §3.22 | 租客关联合同项 |
| 76 | `TenantWorkOrderItem` | §3.23 | 租客关联工单项 |
| 77 | `TenantCreditDetail` / `CreditTrendPoint` | §3.24 | 租客信用详情与趋势 |
| 78 | `ContractChainItem` | §3.25 | 合同续约链 |
| 79 | `WaleDashboard` / `WaleByType` | §3C.5 | WALE 综合看板 |
| 80 | `AtRiskContract` | §3C.6 | 到期风险合同 |
| 81 | `InvoiceItemInline` | §4.4 | 账单费项内联 |
| 82 | `DepositInlineSummary` | §3.8 | 合同详情押金摘要内联 |
| 83 | `RenewalChainItem` | §3.8 | 合同详情续约链内联 |
| 84 | `InvoicePaymentItem` | §4.24 | 账单收款记录 |
| 85 | `DunningLogItem` | §4.25 / §4.26 | 催收记录 |
| 86 | `NoiBudgetItem` | §4.21~4.23 | NOI 预算项 |
| 87 | `AllocationPreview` / `UnitAllocation` | §4A.5 | 水电费分摊预览 |
| 88 | `WorkOrderCostReport` / `CostGroup` | §5.16 | 工单费用报表 |
| 89 | `NotificationItem` | §8A.1 | 通知项 |
| 90 | `ApprovalItem` | §8B.1 | 审批项 |
| 91 | `DashboardOverview` | §9.1 | 首页概览看板 |
| 92 | `RevenueTrendPoint` | §9.2 | 收入趋势点 |
| 93 | `OccupancyTrendPoint` | §9.3 | 出租率趋势点 |

---

## 附录 B：枚举值速查表

| 枚举名 | 值 |
|--------|---|
| `property_type` | `office` / `retail` / `apartment` |
| `unit_status` | `leased` / `vacant` / `expiring_soon` / `non_leasable` |
| `unit_decoration` | `blank` / `simple` / `refined` / `raw` |
| `user_role` | `super_admin` / `operations_manager` / `leasing_specialist` / `finance_staff` / `maintenance_staff` / `property_inspector` / `report_viewer` / `sub_landlord` |
| `tenant_type` | `corporate` / `individual` |
| `contract_status` | `quoting` / `pending_sign` / `active` / `expiring_soon` / `expired` / `renewed` / `terminated` |
| `escalation_type` | `fixed_rate` / `fixed_amount` / `step` / `cpi` / `periodic` / `base_after_free_period` |
| `alert_type` | `lease_expiry_90` / `lease_expiry_60` / `lease_expiry_30` / `payment_overdue_1` / `payment_overdue_7` / `payment_overdue_15` / `monthly_expiry_summary` / `deposit_refund_reminder` |
| `invoice_status` | `draft` / `issued` / `paid` / `overdue` / `cancelled` / `exempt` |
| `invoice_item_type` | `rent` / `management_fee` / `electricity` / `water` / `parking` / `storage` / `revenue_share` / `other` |
| `expense_category` | `utility_common` / `outsourced_property` / `repair` / `insurance` / `tax` / `other` |
| `deposit_status` | `collected` / `frozen` / `partially_credited` / `refunded` |
| `termination_type` | `normal_expiry` / `tenant_early_exit` / `mutual_agreement` / `owner_termination` |
| `work_order_status` | `submitted` / `approved` / `in_progress` / `pending_inspection` / `completed` / `rejected` / `on_hold` |
| `work_order_priority` | `normal` / `urgent` / `critical` |
| `sublease_occupancy_status` | `occupied` / `signed_not_moved` / `moved_out` / `vacant` |
| `sublease_review_status` | `draft` / `pending` / `approved` / `rejected` |
| `kpi_period_type` | `monthly` / `quarterly` / `yearly` |
| `meter_type` | `water` / `electricity` / `gas` |
| `reading_cycle` | `monthly` / `bimonthly` |
| `turnover_approval_status` | `pending` / `approved` / `rejected` |
| `import_data_type` | `units` / `contracts` / `invoices` |
| `import_rollback_status` | `committed` / `rolled_back` |
| `payment_method` | `bank_transfer` / `cash` / `online` / `offset` |
| `snapshot_status` | `draft` / `frozen` / `recalculated` |
| `appeal_status` | `pending` / `approved` / `rejected` |
| `kpi_direction` | `positive` / `negative` |
| `notification_type` | `contract_expiring` / `invoice_overdue` / `workorder_assigned` / `workorder_completed` / `approval_pending` / `system_alert` / `kpi_published` |
| `notification_severity` | `info` / `warning` / `critical` |
| `approval_type` | `contract_termination` / `deposit_refund` / `invoice_adjustment` / `sublease_submission` |
| `approval_status` | `pending` / `approved` / `rejected` |
| `dunning_method` | `phone` / `sms` / `letter` / `visit` / `legal` |
| `credit_rating` | `A` / `B` / `C` / `D` |
| `renewal_intent` | `willing` / `undecided` / `unwilling` |

---

## 附录 C：全量错误码速查

| 错误码 | HTTP | 适用端点 |
|--------|------|---------|
| `INVALID_CREDENTIALS` | 401 | login |
| `ACCOUNT_LOCKED` | 423 | login |
| `ACCOUNT_DISABLED` | 403 | login |
| `ACCOUNT_FROZEN` | 403 | login |
| `TOKEN_EXPIRED` | 401 | refresh |
| `TOKEN_REVOKED` | 401 | refresh |
| `SESSION_VERSION_MISMATCH` | 401 | refresh |
| `INVALID_OLD_PASSWORD` | 400 | change-password |
| `PASSWORD_TOO_WEAK` | 400 | create user / change-password |
| `PASSWORD_SAME_AS_OLD` | 400 | change-password |
| `EMAIL_ALREADY_EXISTS` | 409 | create user |
| `BOUND_CONTRACT_REQUIRED` | 400 | create user (sub_landlord) |
| `CONTRACT_NOT_SUBLEASE_MASTER` | 400 | create user (sub_landlord) |
| `MAX_DEPTH_EXCEEDED` | 400 | departments |
| `PARENT_DEPARTMENT_NOT_FOUND` | 404 | departments |
| `PARENT_DEPARTMENT_INACTIVE` | 400 | departments |
| `DEPARTMENT_HAS_ACTIVE_USERS` | 409 | delete department |
| `DEPARTMENT_HAS_ACTIVE_CHILDREN` | 409 | delete department |
| `FLOOR_ALREADY_EXISTS` | 409 | create floor |
| `CONTRACT_NOT_FOUND` | 404 | contracts |
| `CONTRACT_NO_ALREADY_EXISTS` | 409 | create contract |
| `UNIT_ALREADY_LEASED` | 409 | create contract |
| `TENANT_NOT_FOUND` | 404 | create contract |
| `INVALID_CONTRACT_DATES` | 400 | create contract |
| `CONTRACT_UNITS_NOT_PATCHABLE` | 400 | patch contract |
| `CONTRACT_NOT_ACTIVE` | 400 | terminate |
| `TERMINATION_DATE_INVALID` | 400 | terminate |
| `INVALID_PASSWORD` | 400 | unmask |
| `DEDUCTION_EXCEEDS_BALANCE` | 400 | deposit deduct |
| `CONTRACT_HAS_OUTSTANDING_INVOICES` | 400 | deposit refund |
| `TARGET_CONTRACT_NOT_RENEWAL` | 400 | deposit transfer |
| `WEIGHT_SUM_NOT_ONE` | 400 | KPI scheme metrics |
| `INVOICE_NOT_VOIDABLE` | 400 | void invoice |
| `ALLOCATION_EXCEEDS_OUTSTANDING` | 400 | payment |
| `ALLOCATION_SUM_MISMATCH` | 400 | payment |
| `EXPENSE_LINKED_TO_WORKORDER` | 400 | delete expense |
| `INVALID_READING` | 400 | meter readings |
| `METER_READING_ALREADY_INVOICED` | 400 | patch meter reading |
| `METRIC_NOT_MANUAL_INPUT` | 400 | manual KPI input |
| `SNAPSHOT_NOT_DRAFT` | 400 | freeze snapshot |
| `APPEAL_WINDOW_CLOSED` | 400 | KPI appeal |
| `SNAPSHOT_NOT_FROZEN` | 400 | KPI appeal |
| `APPEAL_ALREADY_EXISTS` | 409 | KPI appeal |
| `WORKORDER_NOT_REJECTABLE` | 400 | reject workorder |
| `REOPEN_WINDOW_CLOSED` | 400 | reopen workorder |
| `UNIT_NOT_IN_MASTER_CONTRACT` | 400 | sublease |
| `SUBLEASE_END_EXCEEDS_MASTER` | 400 | sublease |
| `UNIT_ALREADY_SUBLEASED` | 409 | sublease |
| `SUBLEASE_NOT_DRAFT` | 400 | delete sublease draft |
| `BATCH_ALREADY_ROLLED_BACK` | 400 | import rollback |
| `BATCH_IS_DRY_RUN` | 400 | import rollback |
| `NOI_BUDGET_NOT_FOUND` | 404 | NOI budget |
| `INVOICE_ALREADY_PAID` | 400 | dunning |
| `APPROVAL_NOT_FOUND` | 404 | approvals |
| `APPROVAL_ALREADY_PROCESSED` | 400 | approvals |
| `APPROVAL_SELF_REVIEW` | 403 | approvals |
