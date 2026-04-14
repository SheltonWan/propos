# PropOS 前端权限管理模块规划

| 元信息 | 值 |
|--------|------|
| 版本 | v1.0 |
| 日期 | 2026-04-13 |
| 依据 | PRD v1.8 · PAGE_SPEC v1.8（§10.2/10.3/10.4/10.9）· RBAC_MATRIX v2.0 · data_model v1.3 |
| 目标端 | `frontend/`（React + TSX 移动端演示 App） |
| 涉及角色 | 仅 `super_admin` 可操作 |

---

## 一、模块概述

在 `frontend/` React/TSX 移动优先演示 App 中新增「系统设置」子模块，包含以下页面：

| 页面 | 文件 | 路由 | 对应 PAGE_SPEC |
|------|------|------|---------------|
| 用户管理列表 | `UserManagement.tsx` | `/settings/users` | §10.2 |
| 用户新建/编辑 | `UserForm.tsx` | `/settings/users/new` · `/settings/users/:userId/edit` | §10.3 |
| 组织架构管理 | `OrgManagement.tsx` | `/settings/org` | §10.4 |
| 审计日志 | `AuditLog.tsx` | `/settings/audit-logs` | §10.9 |

**入口方式**：从 Profile 页「系统设置」分组进入，仅 `super_admin` 角色可见。

---

## 二、权限层扩展

### 2.1 新增 Permission

在 `auth/types.ts` 的 `Permission` 联合类型追加：

```typescript
| "users.manage"
```

### 2.2 ROLE_PERMISSIONS 变更

仅 `super_admin` 追加 `"users.manage"`，其他角色不变。

### 2.3 ROUTE_RULES 新增

| 路由正则 | 权限 | 允许角色 |
|---------|------|---------|
| `/^\/settings\/users\/new$/` | `users.manage` | `super_admin` |
| `/^\/settings\/users\/.+/` | `users.manage` | `super_admin` |
| `/^\/settings\/users$/` | `users.manage` | `super_admin` |
| `/^\/settings\/org$/` | `users.manage` | `super_admin` |
| `/^\/settings\/audit-logs$/` | `users.manage` | `super_admin` |

### 2.4 Layout TabBar 隐藏

`HIDE_TAB_PATTERNS` 追加 `/^\/settings/`，确保设置子页面不显示底部导航栏。

---

## 三、路由接入

在 `routes.tsx` 的 Layout children 中新增 5 条路由：

```
settings/users             → UserManagement
settings/users/new         → UserForm
settings/users/:userId/edit → UserForm
settings/org               → OrgManagement
settings/audit-logs        → AuditLog
```

---

## 四、Profile 入口

在 `pages/Profile.tsx` 的设置菜单区域末尾，新增「系统设置」分组：

- 仅当 `can("users.manage")` 时渲染
- 包含 3 个入口项：用户管理 / 组织架构 / 审计日志
- 使用 `ShieldCheck` / `Building2` / `ClipboardCheck` 图标
- 点击通过 `navigate()` 跳转对应路由

---

## 五、用户管理页 — UserManagement.tsx

### 5.1 页面结构

```
UserManagement
├── Header（深色渐变 indigo-800 → indigo-600）
│   ├── ← 返回按钮
│   ├── "用户管理" 标题
│   └── 摘要 chips（总人数 / 启用 / 禁用）
│
├── 搜索栏（实时过滤姓名/邮箱）
├── 筛选行
│   ├── 角色 select（全部 + 7 种内部角色）
│   └── 状态 select（全部 / 启用 / 停用）
│
├── 用户卡片列表
│   └── 每张卡片
│       ├── 左：头像首字母圆 + 角色色环
│       ├── 中：姓名 · 角色标签 · 部门 · 上次登录时间
│       ├── 右上：状态指示点（绿/灰）
│       └── 右下：三点菜单 → [编辑] [变更角色] [启/停用]
│
└── FAB（Portal）→ /settings/users/new
```

### 5.2 Mock 数据

扩展 `MOCK_USERS` 结构，增加字段：`department`、`email`、`phone`、`is_active`、`last_login_at`。inline 在文件顶部。

### 5.3 角色色彩映射

| 角色 | 标签色 | 含义 |
|------|-------|------|
| `super_admin` | 红色 danger | 最高权限 |
| `operations_manager` | 蓝色 primary | 运营管理 |
| `leasing_specialist` | 紫色 violet | 租务 |
| `finance_staff` | 绿色 success | 财务 |
| `maintenance_staff` | 橙色 warning | 维修 |
| `property_inspector` | 青色 cyan | 巡检 |
| `report_viewer` | 灰色 info | 只读 |
| `sub_landlord` | 粉色 pink | 二房东 |

---

## 六、用户表单页 — UserForm.tsx

### 6.1 页面结构

```
UserForm（独立路由，非底部弹出）
├── Header "新建用户" / "编辑用户"
│
├── Section 1: 基本信息
│   ├── 姓名 input
│   ├── 邮箱 input
│   └── 手机号 input
│
├── Section 2: 角色与权限
│   ├── 角色 select（8 种角色）
│   ├── 部门 select（mock 部门列表）
│   └── 绑定主合同 input（仅 role=sub_landlord 显示）
│
├── Section 3: 初始密码（仅新建模式）
│   ├── 密码 input（type=password）
│   └── ☑ 首次登录强制修改密码（disabled checked）
│
└── 底部操作栏
    ├── 取消 → navigate(-1)
    └── 保存/创建 → mock 保存 + navigate(-1)
```

### 6.2 模式判断

通过 `useParams()` 获取 `:userId`，存在时为编辑模式（预填字段），不存在时为新建模式。

---

## 七、组织架构页 — OrgManagement.tsx

### 7.1 页面结构

```
OrgManagement
├── Header "组织架构"
│
├── 部门树列表（3 级可折叠）
│   └── 每行
│       ├── 展开/收缩箭头（有子部门时）
│       ├── 部门名称
│       ├── 成员数 badge
│       └── [新建子部门] / [编辑]
│
└── 部门详情面板（选中时展开）
    ├── 部门信息：名称 / 层级 / 上级部门 / 状态
    ├── 管辖楼栋：A 座 / 商铺区 / 公寓楼（只读展示）
    └── 成员列表简表：姓名 / 角色
```

### 7.2 Mock 数据

3 级组织树，含 5~8 个部门节点。

---

## 八、审计日志页 — AuditLog.tsx

### 8.1 页面结构

```
AuditLog
├── Header "审计日志"
│
├── 筛选行
│   ├── 操作类型 select（全部 / 合同变更 / 账单核销 / 权限变更 / 二房东数据提交）
│   └── 操作人搜索 input
│
├── 日志时间线（按日分组）
│   └── 每条记录
│       ├── 操作时间（HH:mm）
│       ├── 操作人
│       ├── 类型标签（色块）
│       ├── 资源描述
│       └── IP 地址
│
└── "加载更多" 按钮（mock 分页）
```

### 8.2 类型色彩

| 操作类型 | 色彩 | 含义 |
|---------|------|------|
| 合同变更 | 橙色 warning | — |
| 账单核销 | 绿色 success | — |
| 权限变更 | 红色 danger | — |
| 二房东数据提交 | 紫色 violet | — |

### 8.3 Mock 数据

15~20 条审计记录，覆盖全部 4 种操作类型。

---

## 九、验收清单

| # | 验收项 | 预期结果 |
|---|--------|---------|
| 1 | super_admin 进入 Profile 页 | 可见「系统设置」分区及 3 个入口 |
| 2 | 其他角色进入 Profile 页 | 「系统设置」分区不渲染 |
| 3 | 非 super_admin 直接访问 `/settings/users` | 重定向到 `/` |
| 4 | 用户列表角色/状态筛选 | 联动过滤正常 |
| 5 | 用户列表搜索 | 实时过滤姓名/邮箱 |
| 6 | FAB → 新建用户表单 | 空表单，显示初始密码 Section |
| 7 | 编辑用户 | 预填字段，隐藏初始密码 Section |
| 8 | role=sub_landlord | UserForm 显示「绑定主合同」字段 |
| 9 | 启/停用操作 | 卡片状态点颜色联动 |
| 10 | 组织架构部门树 | 展开/收缩正常 |
| 11 | 选中部门 | 显示详情面板 |
| 12 | 审计日志筛选 | 类型/操作人过滤正常 |
| 13 | `/settings/*` 路由 | 底部 TabBar 不显示 |

---

## 十、涉及文件清单

### 新建文件（4 个）

| 文件 | 说明 |
|------|------|
| `frontend/src/app/pages/UserManagement.tsx` | 用户管理列表 |
| `frontend/src/app/pages/UserForm.tsx` | 用户新建/编辑 |
| `frontend/src/app/pages/OrgManagement.tsx` | 组织架构管理 |
| `frontend/src/app/pages/AuditLog.tsx` | 审计日志 |

### 修改文件（5 个）

| 文件 | 变更内容 |
|------|---------|
| `frontend/src/app/auth/types.ts` | 追加 `"users.manage"` Permission |
| `frontend/src/app/auth/permissions.ts` | ROLE_PERMISSIONS + ROUTE_RULES 扩展 |
| `frontend/src/app/routes.tsx` | 新增 5 条路由 |
| `frontend/src/app/Layout.tsx` | HIDE_TAB_PATTERNS 追加 `/settings/` |
| `frontend/src/app/pages/Profile.tsx` | 新增「系统设置」分组入口 |
