# PropOS 微信小程序技术规格

> **版本**: v1.0  
> **日期**: 2026-04-08  
> **依据**: PRD v1.7（4.1 移动端报修）/ ARCH v1.2  
> **定位**: Phase 1 精简版 — 仅**扫码报修 + 状态查看**，不承担推送通知  

---

## 一、产品定位与约束

### 1.1 定位

微信小程序作为 Flutter App 的**轻量补充入口**，面向两类场景：
1. 未安装 Flutter App 的内部员工临时报修
2. 物业巡检时快速扫码定位单元后提报工单

### 1.2 能力边界

| 能力 | 小程序 | Flutter App |
|------|:------:|:----------:|
| 扫码报修 | ✅ | ✅ |
| 照片上传 | ✅（≤3张） | ✅（≤5张） |
| 紧急程度标记 | ✅ | ✅ |
| 工单状态查看 | ✅（只读） | ✅ |
| 工单状态推送 | ❌ | ✅（APNs/FCM） |
| CAD 楼层查看 | ❌ | ✅ |
| 工单派单/审核 | ❌ | ✅ |
| 验收/评价 | ❌ | ✅ |

### 1.3 技术约束

| 约束项 | 说明 |
|--------|------|
| 开发框架 | 微信原生小程序（WXML + WXSS + JS），不使用跨端框架 |
| 后端 API | 复用 PropOS 现有 REST API，不新建独立后端 |
| 认证方式 | 微信 `wx.login()` 获取 `code` → 后端 `/api/auth/wx-login` 换取 JWT |
| 数据范围 | 仅可访问自己提报的工单，不可查看他人数据 |
| 文件上传 | 使用 `wx.chooseMedia()` + `wx.uploadFile()` 上传至 `POST /api/files/upload` |

---

## 二、页面规格

### 2.1 页面清单

| 页面路径 | 页面名称 | 说明 |
|---------|---------|------|
| `pages/index/index` | 首页 | 登录 + 入口选择 |
| `pages/scan/scan` | 扫码报修 | 扫码 → 识别单元 → 报修表单 |
| `pages/report/report` | 报修表单 | 填写工单详情 |
| `pages/orders/orders` | 我的工单 | 已提报工单列表 |
| `pages/detail/detail` | 工单详情 | 查看单条工单状态与进度 |

### 2.2 页面流程

```
首页
 ├─ [扫码报修] → 扫码页(调用摄像头) → 识别成功 → 报修表单 → 提交成功 → 工单详情
 │                                    └─ 识别失败 → 手动选择楼栋/楼层/单元 → 报修表单
 └─ [我的工单] → 工单列表 → 点击单条 → 工单详情
```

---

## 三、页面详细设计

### 3.1 首页（`pages/index/index`）

**布局**:
```
┌─────────────────────────┐
│     PropOS 物业报修       │  ← 标题
│                         │
│  ┌─────────┐ ┌─────────┐ │
│  │  📷     │ │  📋     │ │
│  │ 扫码报修 │ │ 我的工单 │ │
│  └─────────┘ └─────────┘ │
│                         │
│  当前登录：赵前线         │  ← 用户信息
└─────────────────────────┘
```

**逻辑**:
1. `onLoad` 时检查本地缓存的 JWT 是否有效
2. 无有效 token → 调用 `wx.login()` 获取 `code` → `POST /api/auth/wx-login` 获取 JWT
3. 首次绑定需输入员工邮箱 + 密码完成关联

### 3.2 扫码报修（`pages/scan/scan`）

**功能**:
1. 调用 `wx.scanCode()` 扫描单元二维码
2. QR 码内容格式：`propos://unit/{unit_id}`
3. 扫码成功 → `GET /api/units/{unit_id}` 验证单元存在 → 携带 `unit_id` 跳转报修表单
4. 扫码失败或非 PropOS QR 码 → 显示提示，提供手动选择入口

**手动选择降级流程**:
1. 选择楼栋（`GET /api/buildings` → 下拉列表）
2. 选择楼层（`GET /api/floors?building_id=xxx` → 下拉列表）
3. 选择单元（`GET /api/units?floor_id=xxx&is_leasable=true` → 下拉列表）

### 3.3 报修表单（`pages/report/report`）

**接收参数**: `unit_id`（来自扫码或手动选择）

**表单字段**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| 单元信息 | 只读展示 | — | 显示楼栋+楼层+单元编号（不可修改） |
| 问题类型 | 选择器 | 是 | `水电维修/空调维修/门窗维修/网络故障/消防安全/清洁保洁/其他` |
| 问题描述 | 多行文本 | 是 | 最多 500 字 |
| 紧急程度 | 单选 | 是 | `一般 / 紧急 / 非常紧急` → `normal / urgent / critical` |
| 现场照片 | 图片选择 | 否 | 最多 3 张，单张 ≤ 5MB |

**提交流程**:
1. 表单校验通过
2. 如有照片，先逐张 `POST /api/files/upload` 获取 `file_path`
3. `POST /api/work-orders` 创建工单

**提交请求体**:
```json
{
  "unit_id": "uuid",
  "building_id": "uuid",
  "floor_id": "uuid",
  "category": "水电维修",
  "description": "10A 办公室右侧空调不制冷",
  "priority": "urgent",
  "photo_paths": ["workorders/uuid/0.jpg", "workorders/uuid/1.jpg"]
}
```

**提交成功**:
- 显示成功提示 + 工单编号
- 提供「查看工单」按钮跳转详情页

### 3.4 我的工单（`pages/orders/orders`）

**接口**: `GET /api/work-orders?reporter_user_id=me&page=1&pageSize=20`

**列表项展示**:
```
┌─────────────────────────────┐
│ WO-20250801-001    🟡 处理中  │  ← 工单编号 + 状态标签
│ A座 10F 10A · 空调维修        │  ← 位置 + 类别
│ 2025-08-01 14:30 提交        │  ← 提交时间
└─────────────────────────────┘
```

**状态标签颜色**:

| 状态 | 中文 | 颜色 |
|------|------|------|
| submitted | 已提交 | 蓝色 |
| approved | 已派单 | 绿色 |
| in_progress | 处理中 | 黄色 |
| pending_inspection | 待验收 | 橙色 |
| completed | 已完成 | 灰色 |
| rejected | 已拒绝 | 红色 |
| on_hold | 挂起 | 灰色 |

**交互**:
- 下拉刷新
- 上拉加载更多
- 点击跳转详情

### 3.5 工单详情（`pages/detail/detail`）

**接口**: `GET /api/work-orders/{id}`

**展示内容**:
```
┌─────────────────────────────┐
│ 工单详情                      │
├─────────────────────────────┤
│ 工单编号：WO-20250801-001     │
│ 状态：🟡 处理中               │
│                             │
│ 📍 位置                      │
│ A座 10F 10A                  │
│                             │
│ 📋 问题信息                   │
│ 类型：空调维修                 │
│ 紧急程度：🔴 紧急             │
│ 描述：右侧空调不制冷...        │
│                             │
│ 📸 现场照片                   │
│ [图1] [图2]                  │
│                             │
│ 📅 时间线                     │
│ 2025-08-01 14:30 已提交       │
│ 2025-08-01 14:45 已派单       │
│   → 处理人：供应商-空调        │
│ 2025-08-01 16:00 处理中       │
│                             │
│ 💰 维修费用                   │
│ （处理完成后显示）             │
└─────────────────────────────┘
```

**交互**: 只读展示，无操作按钮（派单/验收等操作仅在 Flutter App 端或 Web 端）

---

## 四、API 子集

小程序仅调用以下后端 API：

| 方法 | 路径 | 用途 | 权限 |
|------|------|------|------|
| POST | /api/auth/wx-login | 微信登录换 JWT | 公共 |
| POST | /api/auth/wx-bindink | 首次绑定员工账号 | 公共 |
| GET | /api/auth/me | 获取当前用户信息 | 已登录 |
| GET | /api/buildings | 楼栋列表（手动选择用） | assets.read |
| GET | /api/floors | 楼层列表 | assets.read |
| GET | /api/units | 单元列表 | assets.read |
| GET | /api/units/:id | 单元详情（扫码后验证） | assets.read |
| POST | /api/work-orders | 提报工单 | workorders.write |
| GET | /api/work-orders | 我的工单列表 | workorders.read |
| GET | /api/work-orders/:id | 工单详情 | workorders.read |
| POST | /api/files/upload | 上传照片 | 已登录 |

### 4.1 微信登录接口（新增）

**`POST /api/auth/wx-login`**

**Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `code` | string | 是 | `wx.login()` 返回的临时登录凭证 |

**Response 200（已绑定账号）**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | string | JWT |
| `refresh_token` | string | 刷新 token |
| `expires_in` | integer | 有效期（秒） |
| `user` | UserBrief | 用户信息 |

**Response 200（未绑定账号）**:

```json
{
  "data": {
    "need_bindink": true,
    "wx_session_key": "encrypted_session_key"
  }
}
```

**`POST /api/auth/wx-bindink`**

**Request Body**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `wx_session_key` | string | 是 | 上一步返回的 session key |
| `email` | string | 是 | 员工邮箱 |
| `password` | string | 是 | 员工密码 |

**Response 200**: 同 `wx-login` 已绑定响应

---

## 五、数据缓存策略

| 数据 | 缓存策略 | 说明 |
|------|---------|------|
| JWT | `wx.setStorageSync` | 本地缓存，过期后自动 refresh |
| 楼栋/楼层列表 | 本地缓存 24h | 减少重复请求 |
| 工单列表 | 不缓存 | 每次进入页面重新请求 |

---

## 六、QR 码规格

| 属性 | 规格 |
|------|------|
| 编码格式 | QR Code（ISO 18004） |
| 内容格式 | `propos://unit/{unit_id}` |
| 纠错级别 | M（15%） |
| 最小尺寸 | 2cm × 2cm |
| 张贴位置 | 单元门牌旁或室内配电箱盖上 |
| 生成方式 | 后端批量生成（`GET /api/units/export-qrcodes`），输出 PDF 供打印 |

---

## 七、小程序配置

### app.json
```json
{
  "pages": [
    "pages/index/index",
    "pages/scan/scan",
    "pages/report/report",
    "pages/orders/orders",
    "pages/detail/detail"
  ],
  "window": {
    "navigationBarTitleText": "PropOS 物业报修",
    "navigationBarBackgroundColor": "#1976D2",
    "navigationBarTextStyle": "white"
  },
  "permission": {
    "scope.camera": {
      "desc": "用于扫描单元二维码快速定位报修位置"
    }
  }
}
```

### 域名配置

| 类型 | 域名 |
|------|------|
| request 合法域名 | `https://api.propos.example.com` |
| uploadFile 合法域名 | `https://api.propos.example.com` |

---

## 八、Phase 2 扩展预留

以下能力在 Phase 1 **不实现**，但设计时预留扩展空间：

| 功能 | Phase 2 计划 |
|------|-------------|
| 微信模板消息推送 | 工单状态变更时推送微信服务通知 |
| 缴费查询 | 查看当前待缴账单 |
| 在线缴费 | 对接微信支付 |
| 巡检打卡 | NFC/BLE 扫点 + 签到 |
