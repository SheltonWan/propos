-- =============================================================================
-- Migration: 008_create_workorders
-- Description: 工单系统（M4 模块）
--   suppliers（供应商档案）
--   work_orders（含 work_order_type / cost_nature / contract_id / inspection 专用字段）
--   work_order_photos（工单照片）
-- 依赖: 001, 003, 004, 006
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 供应商档案
-- -------------------------------------------------------------------------
CREATE TABLE suppliers (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(200) NOT NULL,
    -- 供应商分类：'plumbing'=水电类, 'hvac'=空调, 'cleaning'=保洁, 'locksmith'=锁具, 'other'
    category      VARCHAR(50),
    contact_name  VARCHAR(100),
    -- 联系电话（加密：AES-256-GCM）
    contact_phone TEXT,                     -- 加密：AES-256-GCM
    address       TEXT,
    notes         TEXT,
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------------------
-- 工单
-- -------------------------------------------------------------------------
CREATE TABLE work_orders (
    id                   UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 工单编号（如 'WO-2026-04-001'，唯一）
    order_no             VARCHAR(50)         UNIQUE NOT NULL,
    -- 工单类型：repair=报修, complaint=投诉, inspection=退租验房
    work_order_type      work_order_type     NOT NULL DEFAULT 'repair',
    -- 位置信息
    building_id          UUID                NOT NULL REFERENCES buildings(id),
    floor_id             UUID                REFERENCES floors(id),
    unit_id              UUID                REFERENCES units(id),
    -- 关联合同（退租验房必填，其余可选）
    contract_id          UUID                REFERENCES contracts(id),
    -- 问题分类（见下方业务注释）
    issue_type           VARCHAR(100)        NOT NULL,
    priority             work_order_priority NOT NULL DEFAULT 'normal',
    description          TEXT                NOT NULL,
    status               work_order_status   NOT NULL DEFAULT 'submitted',
    -- 关联人员
    reporter_user_id     UUID                NOT NULL REFERENCES users(id),
    assignee_user_id     UUID                REFERENCES users(id),
    supplier_id          UUID                REFERENCES suppliers(id),
    -- 时间节点
    submitted_at         TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    approved_at          TIMESTAMPTZ,
    started_at           TIMESTAMPTZ,
    completed_at         TIMESTAMPTZ,
    expected_complete_at TIMESTAMPTZ,
    on_hold_reason       TEXT,
    -- 来源重开工单（重新开单时关联）
    reopened_from_work_order_id UUID         REFERENCES work_orders(id),
    -- 成本（完工后录入，仅 repair 类型适用）
    material_cost        NUMERIC(10,2),      -- 材料费（元）
    labor_cost           NUMERIC(10,2),      -- 人工费（元）
    -- 费用性质（v1.8）：opex / capex，NULL = 未标注或非 repair 类型
    cost_nature          cost_nature,
    -- 验收/处理结论（repair=验收备注；complaint=处理结论；inspection=查验结论）
    inspection_note      TEXT,
    rejected_reason      TEXT,
    -- 退租验房专用
    deposit_deduction_suggestion NUMERIC(10,2), -- 建议押金扣减金额（元）
    -- 查验后生成的维修工单（inspection → repair）；FK 自引用延迟建立
    follow_up_work_order_id UUID,
    -- 来源渠道
    source               VARCHAR(20)         NOT NULL DEFAULT 'app'
                         CHECK (source IN ('app', 'mini_program', 'manual')),
    created_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

-- issue_type 业务说明（Service 层校验）：
-- repair:     '水电','空调','门窗','消防','网络','电梯','其他'
-- complaint:  '服务态度','环境噪音','公区卫生','安全隐患','其他'
-- inspection: '合同到期验房','提前退租验房'

CREATE INDEX idx_workorders_building  ON work_orders(building_id);
CREATE INDEX idx_workorders_unit      ON work_orders(unit_id) WHERE unit_id IS NOT NULL;
CREATE INDEX idx_workorders_status    ON work_orders(status);
CREATE INDEX idx_workorders_type      ON work_orders(work_order_type);
CREATE INDEX idx_workorders_reporter  ON work_orders(reporter_user_id);
CREATE INDEX idx_workorders_submitted ON work_orders(submitted_at DESC);
CREATE INDEX idx_workorders_contract  ON work_orders(contract_id) WHERE contract_id IS NOT NULL;

-- -------------------------------------------------------------------------
-- 工单照片
-- -------------------------------------------------------------------------
CREATE TABLE work_order_photos (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    work_order_id  UUID        NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
    -- 拍摄时机：'before'=报修时, 'after'=完工后
    photo_stage    VARCHAR(20) NOT NULL DEFAULT 'before',
    -- 存储路径：workorders/{work_order_id}/{index}.jpg
    storage_path   TEXT        NOT NULL,
    sort_order     SMALLINT    NOT NULL DEFAULT 0,
    uploaded_by    UUID        REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workorder_photos_order ON work_order_photos(work_order_id);

COMMIT;
