# PropOS Phase 1 数据模型文档

> **版本**: v1.0
> **日期**: 2026-04-05
> **对应 PRD**: v1.5
> **范围**: Phase 1 五个核心模块

---

## 一、总览

### 1.1 实体关系层级

```
users                                               ← 公共：认证与角色
audit_logs                                          ← 公共：审计日志

buildings → floors → units                          ← M1 资产
                        └── renovation_records

tenants → contracts → contract_attachments          ← M2 租务
                   └── rent_escalation_phases
                   └── alerts
                   └── invoices → invoice_items
                                      └── payments
                   └── subleases (← units)          ← M5 二房东

expenses (→ buildings, units?)                      ← M3 财务支出
kpi_metric_definitions                              ← M3 KPI 指标库
kpi_schemes → kpi_scheme_metrics                   ← M3 KPI 方案
kpi_score_snapshots → kpi_score_snapshot_items     ← M3 KPI 快照

suppliers                                           ← M4 工单
work_orders (→ units, buildings, floors, users)    ← M4 工单
   └── work_order_photos
```

### 1.2 跨模块 FK 关系汇总

| 表 | 外键字段 | 引用表 | 说明 |
|----|---------|--------|------|
| `floors` | `building_id` | `buildings` | 楼层归属楼栋 |
| `units` | `floor_id`, `building_id` | `floors`, `buildings` | 单元归属楼层/楼栋 |
| `renovation_records` | `unit_id` | `units` | 改造记录归属单元 |
| `contracts` | `unit_id`, `tenant_id` | `units`, `tenants` | 合同绑定单元与租客 |
| `contracts` | `parent_contract_id` | `contracts` | 续签合同链 |
| `contract_attachments` | `contract_id` | `contracts` | 合同附件 |
| `rent_escalation_phases` | `contract_id` | `contracts` | 租金递增阶段 |
| `alerts` | `contract_id` | `contracts` | 预警记录归属合同 |
| `invoices` | `contract_id` | `contracts` | 账单归属合同 |
| `invoice_items` | `invoice_id` | `invoices` | 账单明细 |
| `payments` | `invoice_id` | `invoices` | 收款核销 |
| `expenses` | `building_id`, `unit_id`? | `buildings`, `units` | 运营支出归口 |
| `kpi_scheme_metrics` | `scheme_id`, `metric_id` | `kpi_schemes`, `kpi_metric_definitions` | 方案-指标关联 |
| `kpi_score_snapshots` | `scheme_id`, `evaluated_user_id` | `kpi_schemes`, `users` | 打分快照 |
| `kpi_score_snapshot_items` | `snapshot_id`, `metric_id` | `kpi_score_snapshots`, `kpi_metric_definitions` | 快照明细 |
| `work_orders` | `unit_id`, `floor_id`, `building_id` | `units`, `floors`, `buildings` | 工单定位 |
| `work_orders` | `reporter_user_id`, `assignee_user_id`, `supplier_id` | `users`, `users`, `suppliers` | 工单人员 |
| `work_order_photos` | `work_order_id` | `work_orders` | 工单照片 |
| `subleases` | `master_contract_id`, `unit_id` | `contracts`, `units` | 子租赁关联主合同与单元 |
| `subleases` | `reviewer_user_id`, `submitted_by_user_id` | `users`, `users` | 填报/审核人 |
| `audit_logs` | `user_id` | `users` | 操作人 |

---

## 二、PostgreSQL 自定义枚举类型

```sql
-- 业态
CREATE TYPE property_type AS ENUM ('office', 'retail', 'apartment');

-- 单元出租状态
CREATE TYPE unit_status AS ENUM ('leased', 'vacant', 'expiring_soon', 'non_leasable');

-- 单元装修状态
CREATE TYPE unit_decoration AS ENUM ('blank', 'simple', 'refined', 'raw');

-- 用户角色
CREATE TYPE user_role AS ENUM (
    'super_admin',        -- 超级管理员
    'operations_manager', -- 运营管理层
    'leasing_specialist', -- 租务专员
    'finance_staff',      -- 财务人员
    'frontline_staff',    -- 前线员工
    'sub_landlord'        -- 二房东
);

-- 租客类型
CREATE TYPE tenant_type AS ENUM ('corporate', 'individual');

-- 合同状态机
CREATE TYPE contract_status AS ENUM (
    'quoting',         -- 报价中
    'pending_sign',    -- 待签约
    'active',          -- 执行中
    'expiring_soon',   -- 即将到期（≤90天）
    'expired',         -- 已到期
    'renewed',         -- 已续签
    'terminated'       -- 已终止
);

-- 租金递增类型
CREATE TYPE escalation_type AS ENUM (
    'fixed_rate',            -- 固定比例递增
    'fixed_amount',          -- 固定金额递增
    'step',                  -- 阶梯式递增
    'cpi',                   -- CPI 挂钩递增
    'periodic',              -- 每 N 年递增
    'base_after_free_period' -- 免租后基准调整
);

-- 预警类型
CREATE TYPE alert_type AS ENUM (
    'lease_expiry_90',          -- 到期预警 90 天
    'lease_expiry_60',          -- 到期预警 60 天
    'lease_expiry_30',          -- 到期预警 30 天
    'payment_overdue_1',        -- 逾期第 1 天
    'payment_overdue_7',        -- 逾期第 7 天
    'payment_overdue_15',       -- 逾期第 15 天
    'monthly_expiry_summary',   -- 月度到期汇总
    'deposit_refund_reminder'   -- 押金退还提醒（终止前 7 天）
);

-- 账单状态
CREATE TYPE invoice_status AS ENUM (
    'draft',     -- 草稿（生成中）
    'issued',    -- 已出账
    'paid',      -- 已核销
    'overdue',   -- 逾期
    'cancelled', -- 已作废
    'exempt'     -- 免租期免单
);

-- 账单费项类型
CREATE TYPE invoice_item_type AS ENUM (
    'rent',           -- 租金
    'management_fee', -- 物管费
    'electricity',    -- 电费
    'water',          -- 水费
    'parking',        -- 停车费
    'storage',        -- 储藏室
    'revenue_share',  -- 营业额分成（商铺）
    'other'           -- 其他
);

-- 运营支出类目
CREATE TYPE expense_category AS ENUM (
    'utility_common',      -- 水电公摊
    'outsourced_property', -- 外包物业费
    'repair',              -- 维修费
    'insurance',           -- 保险
    'tax',                 -- 税金
    'other'                -- 其他
);

-- 工单状态
CREATE TYPE work_order_status AS ENUM (
    'submitted',          -- 已提交
    'approved',           -- 已审核/派单
    'in_progress',        -- 处理中
    'pending_inspection', -- 待验收
    'completed',          -- 已完成
    'rejected',           -- 已拒绝
    'on_hold'             -- 挂起
);

-- 工单紧急程度
CREATE TYPE work_order_priority AS ENUM ('normal', 'urgent', 'critical');

-- 子租赁入住状态
CREATE TYPE sublease_occupancy_status AS ENUM (
    'occupied',           -- 已入住
    'signed_not_moved',   -- 已签约未入住
    'moved_out',          -- 已退租
    'vacant'              -- 空置
);

-- 子租赁审核状态
CREATE TYPE sublease_review_status AS ENUM (
    'pending',   -- 待审核
    'approved',  -- 已通过
    'rejected'   -- 已退回
);

-- KPI 评估周期
CREATE TYPE kpi_period_type AS ENUM ('monthly', 'quarterly', 'yearly');
```

---

## 三、公共基础表

### 3.1 users（用户）

```sql
CREATE TABLE users (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(100) NOT NULL,
    email            VARCHAR(255) UNIQUE NOT NULL,
    password_hash    TEXT        NOT NULL,            -- bcrypt hash
    role             user_role   NOT NULL,
    -- 二房东角色专用：绑定主合同（允许 NULL，非二房东角色为 NULL）
    -- FK: ALTER TABLE users ADD CONSTRAINT fk_users_contract
    --       FOREIGN KEY (bound_contract_id) REFERENCES contracts(id);
    bound_contract_id UUID,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    -- 主合同到期后二房东账号自动冻结
    frozen_at        TIMESTAMPTZ,
    frozen_reason    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_role       ON users(role);
CREATE INDEX idx_users_email      ON users(email);
CREATE INDEX idx_users_contract   ON users(bound_contract_id) WHERE bound_contract_id IS NOT NULL;
```

### 3.2 audit_logs（操作审计日志）

覆盖范围（架构约束 #4）：合同变更、账单核销、权限变更、二房东数据提交。

```sql
CREATE TABLE audit_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID        NOT NULL REFERENCES users(id),
    action        VARCHAR(100) NOT NULL, -- 'contract.update', 'invoice.write_off', 'user.role_change', 'sublease.submit'
    resource_type VARCHAR(50)  NOT NULL, -- 'contract', 'invoice', 'user', 'sublease'
    resource_id   UUID        NOT NULL,
    -- 变更前后快照（JSON）
    before_json   JSONB,
    after_json    JSONB,
    ip_address    INET,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_user        ON audit_logs(user_id);
CREATE INDEX idx_audit_resource    ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_created_at  ON audit_logs(created_at DESC);
```

---

## 四、M1 资产与空间可视化

### 4.1 buildings（楼栋）

```sql
CREATE TABLE buildings (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(100) NOT NULL,           -- 'A座', '商铺区', '公寓楼'
    property_type property_type NOT NULL,          -- 主业态（楼栋整体定性）
    total_floors  SMALLINT     NOT NULL,
    gfa           NUMERIC(10,2) NOT NULL,          -- 总建筑面积（m²）
    nla           NUMERIC(10,2) NOT NULL,          -- 净可租面积（m²）
    address       TEXT,
    built_year    SMALLINT,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

### 4.2 floors（楼层）

```sql
CREATE TABLE floors (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id   UUID         NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    floor_number  SMALLINT     NOT NULL,           -- 负数代表地下层（B1=-1）
    floor_name    VARCHAR(50),                     -- 展示名，如 'B1', '1F', '10F'
    -- CAD 转换后的文件路径（floors/{building_id}/{floor_id}.svg）
    svg_path      TEXT,
    png_path      TEXT,
    nla           NUMERIC(10,2),                   -- 本层净可租面积（m²）
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, floor_number)
);

CREATE INDEX idx_floors_building ON floors(building_id);
```

### 4.3 units（单元/房源）

单元是 PropOS 的核心资产原子，承载三业态差异化字段，通过 `ext_fields` JSONB 存储业态专属属性。

```sql
CREATE TABLE units (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id          UUID         NOT NULL REFERENCES floors(id),
    building_id       UUID         NOT NULL REFERENCES buildings(id),
    unit_number       VARCHAR(50)  NOT NULL,        -- 如 '10A', '501'
    property_type     property_type NOT NULL,
    -- 面积
    gross_area        NUMERIC(10,2),                -- 建筑面积（m²）
    net_area          NUMERIC(10,2),                -- 套内面积（m²）
    -- 基础属性
    orientation       VARCHAR(20),                  -- 朝向：'east', 'south', 'west', 'north'
    ceiling_height    NUMERIC(4,2),                 -- 层高（m）
    decoration_status unit_decoration NOT NULL DEFAULT 'blank',
    -- 出租状态（由 unit_service 根据合同状态实时计算，冗余存储用于快速查询）
    current_status    unit_status  NOT NULL DEFAULT 'vacant',
    -- 是否可租（非可租如公共区域、设备间）
    is_leasable       BOOLEAN      NOT NULL DEFAULT TRUE,
    -- 业态扩展字段（JSONB，结构见下方说明）
    ext_fields        JSONB        NOT NULL DEFAULT '{}',
    -- 当前绑定合同（冗余存储，提升楼层色块查询性能）
    current_contract_id UUID,
    -- QR 码标识（用于扫码报修）
    qr_code           VARCHAR(100) UNIQUE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, unit_number)
);

CREATE INDEX idx_units_floor        ON units(floor_id);
CREATE INDEX idx_units_building     ON units(building_id);
CREATE INDEX idx_units_status       ON units(current_status);
CREATE INDEX idx_units_type         ON units(property_type);
CREATE INDEX idx_units_ext_fields   ON units USING GIN(ext_fields);
```

**`ext_fields` JSONB 结构说明**

| 业态 | 字段结构 |
|------|---------|
| `office`（写字楼） | `{"workstation_count": 20, "partition_count": 3}` |
| `retail`（商铺） | `{"frontage_width": 8.5, "street_facing": true, "retail_ceiling_height": 5.2}` |
| `apartment`（公寓） | `{"bedroom_count": 2, "en_suite_bathroom": true, "occupant_count": null}` |

### 4.4 renovation_records（改造记录）

```sql
CREATE TABLE renovation_records (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id          UUID         NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    renovation_type  VARCHAR(100) NOT NULL, -- '隔断改造', '水电改造', '装修升级' 等
    started_at       DATE         NOT NULL,
    completed_at     DATE,
    cost             NUMERIC(12,2),          -- 施工造价（元）
    contractor       VARCHAR(200),           -- 施工方
    description      TEXT,
    -- 照片路径（renovations/{record_id}/{index}.jpg）
    -- 存储在 work_order_photos 之外的独立文件，路径约定见文件存储规范
    before_photo_paths TEXT[],              -- 改造前照片路径数组
    after_photo_paths  TEXT[],             -- 改造后照片路径数组
    created_by       UUID         REFERENCES users(id),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_renovation_unit ON renovation_records(unit_id);
```

---

## 五、M2 租务与合同管理

### 5.1 tenants（租客）

**安全约束**：`id_number_encrypted` 与 `contact_phone_encrypted` 使用 AES-256 加密存储，API 层默认返回脱敏值（后4位）。

```sql
CREATE TABLE tenants (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_type   tenant_type NOT NULL,
    -- 企业名称或个人姓名
    display_name  VARCHAR(200) NOT NULL,
    -- [加密存储] 企业：统一社会信用代码；个人：身份证号
    -- 存储值为 AES-256-GCM 密文（base64）
    id_number_encrypted    TEXT,       -- 加密：AES-256-GCM
    -- [加密存储] 主要联系电话
    contact_phone_encrypted TEXT,      -- 加密：AES-256-GCM
    -- 企业联系人姓名（企业租客必填）
    contact_person         VARCHAR(100),
    contact_email          VARCHAR(255),
    emergency_contact_name  VARCHAR(100),
    emergency_contact_phone TEXT,       -- 加密：AES-256-GCM
    -- 信用评级（系统自动计算：A/B/C）
    credit_rating   CHAR(1) CHECK (credit_rating IN ('A','B','C')),
    overdue_count   SMALLINT NOT NULL DEFAULT 0, -- 历史逾期次数（用于信用计算）
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_type ON tenants(tenant_type);
```

### 5.2 contracts（合同）

```sql
CREATE TABLE contracts (
    id                UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 合同编号（业务可读编号，格式如 'C-2026-001'）
    contract_no       VARCHAR(50)    UNIQUE NOT NULL,
    unit_id           UUID           NOT NULL REFERENCES units(id),
    tenant_id         UUID           NOT NULL REFERENCES tenants(id),
    status            contract_status NOT NULL DEFAULT 'pending_sign',
    property_type     property_type  NOT NULL, -- 冗余，与单元业态一致，便于聚合查询

    -- 合同期限
    start_date        DATE           NOT NULL,
    end_date          DATE           NOT NULL,
    -- 免租/装修期
    free_rent_days    SMALLINT       NOT NULL DEFAULT 0,
    free_rent_end_date DATE,                    -- 免租结束日（start_date + free_rent_days - 1）

    -- 租金
    base_monthly_rent  NUMERIC(12,2)  NOT NULL, -- 签约基准月租金（元）
    -- 付款周期（月数，如 1=月付, 3=季付, 6=半年付, 12=年付）
    payment_cycle_months SMALLINT     NOT NULL DEFAULT 1,
    -- 物管费（元/m²/月，公寓业态可为 0 表示含于租金）
    management_fee_rate  NUMERIC(8,4) NOT NULL DEFAULT 0,
    -- 押金（月数，押金总额 = 押金月数 × 月租金）
    deposit_months       SMALLINT     NOT NULL DEFAULT 2,
    deposit_amount       NUMERIC(12,2) NOT NULL,

    -- 商铺营业额分成（revenue_share_enabled=true 时有效）
    revenue_share_enabled  BOOLEAN    NOT NULL DEFAULT FALSE,
    min_guarantee_rent     NUMERIC(12,2),       -- 保底租金（元/月）
    revenue_share_rate     NUMERIC(5,4),        -- 分成比例（如 0.08 = 8%）

    -- 续签链
    parent_contract_id     UUID       REFERENCES contracts(id),
    is_sublease_master     BOOLEAN    NOT NULL DEFAULT FALSE, -- true 表示该合同是二房东主合同

    -- 合同 PDF 附件路径（contracts/{id}/signed.pdf）
    -- 详见 contract_attachments 表
    signed_pdf_path  TEXT,

    -- 合同终止信息
    terminated_at    TIMESTAMPTZ,
    termination_reason TEXT,
    -- 押金退还
    deposit_refunded_at TIMESTAMPTZ,
    deposit_refund_amount NUMERIC(12,2),

    created_by       UUID           REFERENCES users(id),
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_contract_dates CHECK (start_date <= end_date)
);

CREATE INDEX idx_contracts_unit     ON contracts(unit_id);
CREATE INDEX idx_contracts_tenant   ON contracts(tenant_id);
CREATE INDEX idx_contracts_status   ON contracts(status);
CREATE INDEX idx_contracts_end_date ON contracts(end_date) WHERE status IN ('active','expiring_soon');
CREATE INDEX idx_contracts_master   ON contracts(is_sublease_master) WHERE is_sublease_master = TRUE;
```

### 5.3 contract_attachments（合同附件）

```sql
CREATE TABLE contract_attachments (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id   UUID        NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    -- 文件类型：'original'=原合同, 'amendment'=补充协议, 'other'=其他
    file_type     VARCHAR(50) NOT NULL DEFAULT 'original',
    filename      VARCHAR(255) NOT NULL,
    -- 存储路径：contracts/{contract_id}/{filename}
    storage_path  TEXT        NOT NULL,
    file_size_kb  INTEGER,
    uploaded_by   UUID        REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attachments_contract ON contract_attachments(contract_id);
```

### 5.4 rent_escalation_phases（租金递增阶段）

每份合同可配置多个递增阶段，顺序执行。对应 `rent_escalation_engine` package 的输入结构。

```sql
CREATE TABLE rent_escalation_phases (
    id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id    UUID           NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    phase_order    SMALLINT       NOT NULL, -- 阶段顺序，从 1 开始
    -- 阶段起止（相对合同起租日的月数偏移，0 表示起租日当月）
    start_month    SMALLINT       NOT NULL DEFAULT 0,
    end_month      SMALLINT,              -- NULL 表示延续至合同结束
    escalation_type escalation_type NOT NULL,
    -- 类型专属参数（JSONB，结构见下方说明）
    params         JSONB          NOT NULL,
    created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    UNIQUE (contract_id, phase_order)
);

CREATE INDEX idx_escalation_contract ON rent_escalation_phases(contract_id);
```

**`params` JSONB 结构说明**

```jsonc
// fixed_rate：固定比例递增
{ "rate": 0.05, "interval_months": 12 }

// fixed_amount：固定金额递增（元/m²/月）
{ "amount_per_sqm": 3.0, "interval_months": 12 }

// step：阶梯式递增
{ "steps": [
    { "from_month": 0,  "to_month": 23, "monthly_rent": 8000 },
    { "from_month": 24, "to_month": 47, "monthly_rent": 9000 },
    { "from_month": 48, "to_month": null, "monthly_rent": 10000 }
]}

// cpi：CPI 挂钩递增
{ "interval_months": 12, "cpi_year_overrides": { "2027": 0.023, "2028": 0.031 } }

// periodic：每 N 年递增
{ "interval_years": 2, "rate": 0.08 }

// base_after_free_period：免租后基准调整
{ "base_monthly_rent": 7500 }
```

### 5.5 alerts（预警记录）

```sql
CREATE TABLE alerts (
    id           UUID       PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id  UUID       NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    alert_type   alert_type NOT NULL,
    -- 预警触发日期（调度任务写入）
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 是否已读/处理
    is_read      BOOLEAN    NOT NULL DEFAULT FALSE,
    read_by      UUID       REFERENCES users(id),
    read_at      TIMESTAMPTZ,
    -- 通知状态
    notified_via TEXT[],    -- ['in_app', 'email']
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_contract ON alerts(contract_id);
CREATE INDEX idx_alerts_unread   ON alerts(is_read, triggered_at DESC) WHERE is_read = FALSE;
```

---

## 六、M3 财务与 NOI

### 6.1 invoices（账单）

```sql
CREATE TABLE invoices (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 账单编号（如 'INV-2026-04-001'）
    invoice_no      VARCHAR(50)    UNIQUE NOT NULL,
    contract_id     UUID           NOT NULL REFERENCES contracts(id),
    -- 账期起止
    period_start    DATE           NOT NULL,
    period_end      DATE           NOT NULL,
    -- 应收总额（各费项之和）
    total_amount    NUMERIC(12,2)  NOT NULL,
    status          invoice_status NOT NULL DEFAULT 'issued',
    -- 发票信息
    invoice_issued  BOOLEAN        NOT NULL DEFAULT FALSE,
    invoice_no_ext  VARCHAR(100),             -- 外部发票号
    invoice_issued_at TIMESTAMPTZ,
    -- 逾期信息
    due_date        DATE           NOT NULL,  -- 缴款截止日
    overdue_since   DATE,                     -- 首次标记逾期日
    -- 催收记录
    last_reminded_at TIMESTAMPTZ,
    -- 商铺营业额（仅 revenue_share_enabled 合同使用）
    reported_revenue NUMERIC(12,2),           -- 本期申报营业额
    created_by      UUID           REFERENCES users(id),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_invoice_period CHECK (period_start <= period_end)
);

CREATE INDEX idx_invoices_contract   ON invoices(contract_id);
CREATE INDEX idx_invoices_status     ON invoices(status);
CREATE INDEX idx_invoices_due_date   ON invoices(due_date) WHERE status IN ('issued','overdue');
CREATE INDEX idx_invoices_period     ON invoices(period_start, period_end);
```

### 6.2 invoice_items（账单费项明细）

```sql
CREATE TABLE invoice_items (
    id          UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID              NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type   invoice_item_type NOT NULL,
    description VARCHAR(200),              -- 费项说明（如 '10月电费'）
    quantity    NUMERIC(10,4),             -- 数量（面积/度数/月数）
    unit        VARCHAR(20),               -- 单位（'m²', 'kWh', '月'）
    unit_price  NUMERIC(10,4),             -- 单价
    amount      NUMERIC(12,2)  NOT NULL,   -- 金额（元）
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);
```

### 6.3 payments（收款核销）

```sql
CREATE TABLE payments (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id     UUID        NOT NULL REFERENCES invoices(id),
    paid_amount    NUMERIC(12,2) NOT NULL,
    paid_at        TIMESTAMPTZ   NOT NULL, -- 实际到账时间（UTC）
    -- 核销方式：'bank_transfer', 'cash', 'online', 'offset'（冲抵）
    payment_method VARCHAR(50)  NOT NULL DEFAULT 'bank_transfer',
    reference_no   VARCHAR(100),            -- 银行流水号/交易单号
    -- 核销人
    written_off_by UUID        REFERENCES users(id),
    notes          TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_invoice ON payments(invoice_id);
```

### 6.4 expenses（运营支出）

支出关联楼栋（必填）和单元（可选，用于工单维修成本归口），自动汇入 NOI 运营支出端。

```sql
CREATE TABLE expenses (
    id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id   UUID             NOT NULL REFERENCES buildings(id),
    -- 可选关联至单元（工单维修费用精确归口）
    unit_id       UUID             REFERENCES units(id),
    -- 可选关联至工单（维修成本由工单触发）
    work_order_id UUID,            -- FK 延迟建立（引用 work_orders）
    category      expense_category NOT NULL,
    description   TEXT             NOT NULL,
    amount        NUMERIC(12,2)    NOT NULL,  -- 金额（元）
    expense_date  DATE             NOT NULL,
    vendor        VARCHAR(200),               -- 供应商/服务商名称
    -- 发票/收据凭证
    receipt_path  TEXT,                       -- 存储路径
    created_by    UUID             REFERENCES users(id),
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_building  ON expenses(building_id);
CREATE INDEX idx_expenses_date      ON expenses(expense_date);
CREATE INDEX idx_expenses_category  ON expenses(category);
CREATE INDEX idx_expenses_workorder ON expenses(work_order_id) WHERE work_order_id IS NOT NULL;
```

### 6.5 kpi_metric_definitions（KPI 指标定义库）

系统预定义 10 个指标（K01-K10），由初始化脚本 seed，不允许用户新增。

```sql
CREATE TABLE kpi_metric_definitions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(10) UNIQUE NOT NULL, -- 'K01' ~ 'K10'
    name                VARCHAR(100) NOT NULL,
    description         TEXT,
    -- 默认满分/及格/红线阈值（各方案可覆盖）
    default_full_score_threshold  NUMERIC(10,4) NOT NULL, -- 如 0.95（95%）
    default_pass_threshold        NUMERIC(10,4) NOT NULL, -- 及格线
    default_fail_threshold        NUMERIC(10,4) NOT NULL, -- 不及格红线（0分起点）
    -- 指标值越大越好（TRUE）还是越小越好（FALSE，如逾期率、空置周转天数）
    higher_is_better    BOOLEAN     NOT NULL DEFAULT TRUE,
    -- 数据来源模块
    source_module       VARCHAR(50) NOT NULL, -- 'assets', 'contracts', 'finance', 'workorders'
    -- 是否允许手动录入（K10 租户满意度）
    is_manual_input     BOOLEAN     NOT NULL DEFAULT FALSE,
    is_enabled          BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**初始化数据（Seed）**

| code | name | full_score | pass | fail | higher_is_better |
|------|------|-----------|------|------|-----------------|
| K01 | 出租率 | 0.95 | 0.80 | 0.60 | TRUE |
| K02 | 收款及时率 | 0.95 | 0.85 | 0.70 | TRUE |
| K03 | 租户集中度 | 0.40 | 0.55 | 0.70 | FALSE |
| K04 | 续约率 | 0.80 | 0.60 | 0.40 | TRUE |
| K05 | 工单响应时效（小时） | 24 | 48 | 72 | FALSE |
| K06 | 空置周转天数 | 30 | 60 | 90 | FALSE |
| K07 | NOI 达成率 | 1.00 | 0.85 | 0.70 | TRUE |
| K08 | 逾期率 | 0.05 | 0.10 | 0.20 | FALSE |
| K09 | 租金递增执行率 | 0.95 | 0.85 | 0.70 | TRUE |
| K10 | 租户满意度（手动）| 90 | 75 | 60 | TRUE |

### 6.6 kpi_schemes（KPI 方案）

```sql
CREATE TABLE kpi_schemes (
    id           UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(200)    NOT NULL, -- '租务部考核方案 2026'
    period_type  kpi_period_type NOT NULL,
    -- 方案有效期（支持版本迭代，旧方案数据保留）
    effective_from DATE          NOT NULL,
    effective_to   DATE,                   -- NULL 表示持续有效
    is_active    BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by   UUID            REFERENCES users(id),
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
```

### 6.7 kpi_scheme_metrics（方案-指标关联）

**业务约束**：同一方案下所有指标 `weight` 之和必须 = 1.00，在 Service 层校验。

```sql
CREATE TABLE kpi_scheme_metrics (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id   UUID         NOT NULL REFERENCES kpi_schemes(id) ON DELETE CASCADE,
    metric_id   UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    weight      NUMERIC(5,4) NOT NULL CHECK (weight > 0 AND weight <= 1),
    -- 本方案中覆盖默认阈值（NULL 表示使用 kpi_metric_definitions 的默认值）
    full_score_threshold NUMERIC(10,4),
    pass_threshold       NUMERIC(10,4),
    fail_threshold       NUMERIC(10,4),
    UNIQUE (scheme_id, metric_id)
);

CREATE INDEX idx_scheme_metrics_scheme ON kpi_scheme_metrics(scheme_id);
```

### 6.8 kpi_score_snapshots（KPI 打分快照）

```sql
CREATE TABLE kpi_score_snapshots (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id         UUID        NOT NULL REFERENCES kpi_schemes(id),
    evaluated_user_id UUID        NOT NULL REFERENCES users(id),
    -- 评估时间范围
    period_start      DATE        NOT NULL,
    period_end        DATE        NOT NULL,
    -- 汇总总分（0-100）
    total_score       NUMERIC(5,2) NOT NULL,
    calculated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        UUID        REFERENCES users(id)
);

CREATE INDEX idx_kpi_snapshots_user   ON kpi_score_snapshots(evaluated_user_id);
CREATE INDEX idx_kpi_snapshots_scheme ON kpi_score_snapshots(scheme_id);
CREATE INDEX idx_kpi_snapshots_period ON kpi_score_snapshots(period_start, period_end);
```

### 6.9 kpi_score_snapshot_items（打分快照明细）

```sql
CREATE TABLE kpi_score_snapshot_items (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id  UUID         NOT NULL REFERENCES kpi_score_snapshots(id) ON DELETE CASCADE,
    metric_id    UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    weight       NUMERIC(5,4) NOT NULL,           -- 快照时权重（防止方案修改影响历史）
    actual_value NUMERIC(12,4),                   -- 指标实际值
    score        NUMERIC(5,2) NOT NULL,            -- 本指标得分（0-100）
    weighted_score NUMERIC(5,2) NOT NULL,          -- 加权得分（score × weight × 100）
    source_note  TEXT                              -- 取数说明（便于下钻核查）
);

CREATE INDEX idx_snapshot_items_snapshot ON kpi_score_snapshot_items(snapshot_id);
```

---

## 七、M4 工单系统

### 7.1 suppliers（供应商）

```sql
CREATE TABLE suppliers (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(200) NOT NULL,
    -- 供应商类别：'plumbing'=水电, 'hvac'=空调, 'cleaning'=保洁, 'locksmith'=锁具, 'other'
    category      VARCHAR(50),
    contact_name  VARCHAR(100),
    contact_phone TEXT,        -- 加密：AES-256-GCM
    address       TEXT,
    notes         TEXT,
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 7.2 work_orders（工单）

```sql
CREATE TABLE work_orders (
    id                UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 工单编号（如 'WO-2026-04-001'）
    order_no          VARCHAR(50)       UNIQUE NOT NULL,
    -- 位置信息
    building_id       UUID              NOT NULL REFERENCES buildings(id),
    floor_id          UUID              REFERENCES floors(id),
    unit_id           UUID              REFERENCES units(id),
    -- 问题描述
    issue_type        VARCHAR(100)      NOT NULL, -- '水电', '空调', '门窗', '消防', '其他'
    priority          work_order_priority NOT NULL DEFAULT 'normal',
    description       TEXT              NOT NULL,
    status            work_order_status  NOT NULL DEFAULT 'submitted',
    -- 人员
    reporter_user_id  UUID              NOT NULL REFERENCES users(id),
    assignee_user_id  UUID              REFERENCES users(id),
    supplier_id       UUID              REFERENCES suppliers(id),
    -- 时间节点
    submitted_at      TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    approved_at       TIMESTAMPTZ,
    started_at        TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    -- 成本（完工后录入）
    material_cost     NUMERIC(10,2),    -- 材料费（元）
    labor_cost        NUMERIC(10,2),    -- 人工费（元）
    -- 成本是否已汇入 NOI 支出（由 expense 记录追踪）
    expense_id        UUID,             -- FK: REFERENCES expenses(id)
    -- 验收
    inspection_note   TEXT,
    rejected_reason   TEXT,
    -- 来源（报修渠道）
    source            VARCHAR(20) NOT NULL DEFAULT 'app', -- 'app', 'mini_program', 'manual'
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workorders_building  ON work_orders(building_id);
CREATE INDEX idx_workorders_unit      ON work_orders(unit_id) WHERE unit_id IS NOT NULL;
CREATE INDEX idx_workorders_status    ON work_orders(status);
CREATE INDEX idx_workorders_reporter  ON work_orders(reporter_user_id);
CREATE INDEX idx_workorders_submitted ON work_orders(submitted_at DESC);
```

### 7.3 work_order_photos（工单照片）

```sql
CREATE TABLE work_order_photos (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    work_order_id  UUID        NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
    -- 照片时机：'before'=报修时, 'after'=完工后
    photo_stage    VARCHAR(20) NOT NULL DEFAULT 'before',
    -- 存储路径：workorders/{work_order_id}/{index}.jpg
    storage_path   TEXT        NOT NULL,
    sort_order     SMALLINT    NOT NULL DEFAULT 0,
    uploaded_by    UUID        REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workorder_photos_order ON work_order_photos(work_order_id);
```

---

## 八、M5 二房东穿透管理

### 8.1 subleases（子租赁记录）

**行级隔离约束**（架构约束 #2）：`sublease_repository` 的所有查询必须在 WHERE 子句中附加 `master_contract_id IN (SELECT id FROM contracts WHERE tenant_id = $sub_landlord_tenant_id)` 过滤条件，Repository 层不得省略。

**安全约束**：`sub_tenant_id_number_encrypted` 与 `sub_tenant_phone_encrypted` 使用 AES-256 加密存储；API 响应默认返回脱敏值（后4位），查看完整信息需二次鉴权。

```sql
CREATE TABLE subleases (
    id                UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 关联二房东的主合同（is_sublease_master = TRUE）
    master_contract_id UUID                NOT NULL REFERENCES contracts(id),
    -- 具体单元（必须在主合同覆盖的面积范围内，业务层校验）
    unit_id            UUID                NOT NULL REFERENCES units(id),
    -- 终端租客信息
    sub_tenant_name    VARCHAR(200)         NOT NULL,
    sub_tenant_type    tenant_type          NOT NULL DEFAULT 'corporate',
    sub_tenant_contact_person VARCHAR(100),
    -- [加密存储] 终端租客证件号
    sub_tenant_id_number_encrypted TEXT,             -- 加密：AES-256-GCM
    -- [加密存储] 终端租客联系电话
    sub_tenant_phone_encrypted     TEXT,             -- 加密：AES-256-GCM

    -- 子租赁期限
    start_date         DATE                NOT NULL,
    end_date           DATE                NOT NULL,
    -- 实际月租金（终端租客支付给二房东的）
    monthly_rent       NUMERIC(12,2)       NOT NULL,
    -- 租金单价（元/m²/月），系统根据单元面积自动反算
    rent_per_sqm       NUMERIC(8,4),

    -- 入住状态
    occupancy_status   sublease_occupancy_status NOT NULL DEFAULT 'occupied',
    -- 公寓：实际入住人数
    occupant_count     SMALLINT,

    -- 审核流
    review_status      sublease_review_status NOT NULL DEFAULT 'pending',
    reviewer_user_id   UUID                REFERENCES users(id),
    reviewed_at        TIMESTAMPTZ,
    rejection_reason   TEXT,

    -- 填报信息（双通道）
    -- 'internal'=内部录入, 'sub_landlord'=二房东自助填报, 'excel_import'=批量导入
    submission_channel VARCHAR(20)          NOT NULL DEFAULT 'internal',
    submitted_by_user_id UUID               REFERENCES users(id),

    notes              TEXT,
    created_at         TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ          NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_sublease_dates CHECK (start_date <= end_date),
    -- 同一单元不可有两条在租记录
    CONSTRAINT uq_sublease_active_unit UNIQUE (unit_id, review_status)
        DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX idx_subleases_master_contract ON subleases(master_contract_id);
CREATE INDEX idx_subleases_unit            ON subleases(unit_id);
CREATE INDEX idx_subleases_review_status   ON subleases(review_status);
CREATE INDEX idx_subleases_occupancy       ON subleases(occupancy_status);
```

---

## 九、延迟建立的外键约束

以下 FK 存在循环依赖或建表顺序约束，需在所有表创建完成后执行：

```sql
-- users.bound_contract_id → contracts（二房东账号绑定主合同）
ALTER TABLE users
    ADD CONSTRAINT fk_users_bound_contract
    FOREIGN KEY (bound_contract_id) REFERENCES contracts(id)
    DEFERRABLE INITIALLY DEFERRED;

-- expenses.work_order_id → work_orders（维修成本关联工单）
ALTER TABLE expenses
    ADD CONSTRAINT fk_expenses_work_order
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id)
    DEFERRABLE INITIALLY DEFERRED;

-- work_orders.expense_id → expenses（工单关联支出记录）
ALTER TABLE work_orders
    ADD CONSTRAINT fk_work_orders_expense
    FOREIGN KEY (expense_id) REFERENCES expenses(id)
    DEFERRABLE INITIALLY DEFERRED;
```

---

## 十、索引策略汇总

| 场景 | 关键索引 |
|------|---------|
| 楼层色块渲染 | `units(floor_id, current_status)` |
| WALE 计算 | `contracts(status, end_date)` covering index |
| 逾期账单催收 | `invoices(status, due_date)` WHERE overdue |
| 二房东数据隔离 | `subleases(master_contract_id)` |
| 工单状态监控 | `work_orders(status, submitted_at DESC)` |
| KPI 快照历史 | `kpi_score_snapshots(evaluated_user_id, period_start)` |
| 审计日志查询 | `audit_logs(resource_type, resource_id)` |
| 单元扩展字段 | `units.ext_fields` GIN 索引（按业态过滤） |

---

## 十一、数据初始化顺序

```
1. 创建所有 ENUM 类型
2. buildings → floors → units
3. users（第一个超级管理员）
4. kpi_metric_definitions（seed K01~K10）
5. 延迟 FK 约束（ALTER TABLE）
6. 批量导入：639 套单元（Excel 导入工具）
7. 批量导入：楼层 CAD 转换（.dwg → svg_path/png_path）
```
