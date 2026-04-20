-- =============================================================================
-- Migration: 007_create_finance
-- Description: 财务与 NOI（M3 模块）
--   invoices → invoice_items
--   payments → payment_allocations（多对多核销）
--   expenses（运营支出，work_order_id FK 延迟建立）
-- 依赖: 001, 003, 004, 006
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 账单
-- -------------------------------------------------------------------------
CREATE TABLE invoices (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID            NOT NULL REFERENCES contracts(id),
    -- 账单编号（如 'INV-2026-04-001'）
    invoice_no      VARCHAR(100)    UNIQUE NOT NULL,
    -- 账期月份（yyyy-mm-01 对齐到每月1日）
    billing_month   DATE            NOT NULL,
    status          invoice_status  NOT NULL DEFAULT 'draft',
    -- 金额
    total_amount    NUMERIC(12,2)   NOT NULL,   -- 合计（含各费项）
    paid_amount     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    outstanding_amount NUMERIC(12,2) GENERATED ALWAYS AS
                    (total_amount - paid_amount) STORED,
    -- 应收/截止日期
    due_date        DATE            NOT NULL,
    -- 实际收款/核销日期
    paid_at         TIMESTAMPTZ,
    -- 是否为免租期账单（自动豁免）
    is_exempt       BOOLEAN         NOT NULL DEFAULT FALSE,
    -- 账单关联人
    created_by      UUID            REFERENCES users(id),
    voided_by       UUID            REFERENCES users(id),
    void_reason     TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_contract   ON invoices(contract_id);
CREATE INDEX idx_invoices_status     ON invoices(status);
CREATE INDEX idx_invoices_due_date   ON invoices(due_date);
CREATE INDEX idx_invoices_month      ON invoices(billing_month);
CREATE INDEX idx_invoices_overdue    ON invoices(status, due_date)
    WHERE status = 'overdue';

-- -------------------------------------------------------------------------
-- 账单费项明细
-- -------------------------------------------------------------------------
CREATE TABLE invoice_items (
    id          UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID                NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type   invoice_item_type   NOT NULL,
    description VARCHAR(500),
    -- 数量/面积（计租时填计租面积，水电时填用量）
    quantity    NUMERIC(12,4),
    -- 单价（元/m²/月 或 元/度 等）
    unit_price  NUMERIC(10,4),
    amount      NUMERIC(12,2)       NOT NULL,   -- 本行合计（元）
    sort_order  SMALLINT            NOT NULL DEFAULT 0
);

CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- -------------------------------------------------------------------------
-- 收款记录（一笔收款可分配到多张账单）
-- -------------------------------------------------------------------------
CREATE TABLE payments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 收款流水号
    payment_no      VARCHAR(100) UNIQUE NOT NULL,
    -- 付款租客（通过合同间接关联）
    tenant_id       UUID        NOT NULL REFERENCES tenants(id),
    -- 收款金额（元）
    amount          NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    -- 支付方式：'bank_transfer'=银行转账, 'cash'=现金, 'wechat'=微信, 'alipay'=支付宝
    payment_method  VARCHAR(30) NOT NULL DEFAULT 'bank_transfer',
    -- 银行流水号
    bank_reference  VARCHAR(200),
    -- 付款日期
    payment_date    DATE        NOT NULL,
    -- 核销状态：'pending'=待分配, 'allocated'=已全部分配, 'partial'=部分分配
    allocation_status VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (allocation_status IN ('pending', 'allocated', 'partial')),
    -- 未分配余额（冗余，加速查询）
    unallocated_amount NUMERIC(12,2) NOT NULL,
    recorded_by     UUID        REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_date   ON payments(payment_date DESC);
CREATE INDEX idx_payments_status ON payments(allocation_status)
    WHERE allocation_status != 'allocated';

-- -------------------------------------------------------------------------
-- 收款-账单核销关联（M:N）
-- 一笔收款可分配到多张账单；一张账单也可接收多笔收款
-- -------------------------------------------------------------------------
CREATE TABLE payment_allocations (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id      UUID        NOT NULL REFERENCES payments(id),
    invoice_id      UUID        NOT NULL REFERENCES invoices(id),
    -- 本次分配金额（元）
    allocated_amount NUMERIC(12,2) NOT NULL CHECK (allocated_amount > 0),
    allocated_by    UUID        REFERENCES users(id),
    allocated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (payment_id, invoice_id)
);

CREATE INDEX idx_allocations_payment ON payment_allocations(payment_id);
CREATE INDEX idx_allocations_invoice ON payment_allocations(invoice_id);

-- -------------------------------------------------------------------------
-- 运营支出（OpEx / CapEx）
-- work_order_id FK 延迟建立（引用 work_orders，见 018）
-- -------------------------------------------------------------------------
CREATE TABLE expenses (
    id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id   UUID             NOT NULL REFERENCES buildings(id),
    -- 可选精确到单元（工单维修费用归口）
    unit_id       UUID             REFERENCES units(id),
    -- 可选关联工单（FK 在 018 延迟添加）
    work_order_id UUID,
    category      expense_category NOT NULL,
    description   TEXT             NOT NULL,
    amount        NUMERIC(12,2)    NOT NULL,
    expense_date  DATE             NOT NULL,
    vendor        VARCHAR(200),               -- 供应商/服务商名称
    -- 发票/收据凭证存储路径
    receipt_path  TEXT,
    -- 费用性质（v1.8 新增）：opex 计入 NOI，capex 不计
    cost_nature   cost_nature,
    created_by    UUID             REFERENCES users(id),
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_building  ON expenses(building_id);
CREATE INDEX idx_expenses_date      ON expenses(expense_date);
CREATE INDEX idx_expenses_category  ON expenses(category);
CREATE INDEX idx_expenses_workorder ON expenses(work_order_id)
    WHERE work_order_id IS NOT NULL;

COMMIT;
