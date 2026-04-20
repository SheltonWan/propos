-- =============================================================================
-- Migration: 006_create_contracts
-- Description: 租务与合同管理（M2 模块）
--   tenants → contracts → contract_units（M:N）
--                       → contract_attachments
--                       → rent_escalation_phases
--   escalation_templates（递增规则库）
--   alerts（租期/账单预警触发记录）
-- 依赖: 001, 003, 004
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- 租客档案
-- -------------------------------------------------------------------------
CREATE TABLE tenants (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(200)  NOT NULL,
    tenant_type             tenant_type   NOT NULL DEFAULT 'corporate',
    -- 企业：统一社会信用代码；个人：身份证号（加密存储）
    id_number_encrypted     TEXT          NOT NULL, -- 加密：AES-256-GCM
    -- 联系人及联系方式
    contact_person          VARCHAR(100),
    contact_phone_encrypted TEXT,                   -- 加密：AES-256-GCM
    contact_email           VARCHAR(200),
    -- 企业专用
    legal_representative    VARCHAR(100),
    business_license_no     VARCHAR(100),
    registered_capital      NUMERIC(15,2),           -- 注册资本（元）
    -- 信用及黑名单（v1.5 新增）
    credit_rating           credit_rating,            -- A/B/C/D 信用评级
    credit_score            NUMERIC(5,2),             -- 信用打分（0-100）
    credit_updated_at       TIMESTAMPTZ,
    is_blacklisted          BOOLEAN       NOT NULL DEFAULT FALSE,
    blacklist_reason        TEXT,
    -- PIPL：合同终止满 3 年后应匿名化/删除个人信息
    data_retention_until    TIMESTAMPTZ,
    notes                   TEXT,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_type ON tenants(tenant_type);

-- -------------------------------------------------------------------------
-- 合同
-- -------------------------------------------------------------------------
CREATE TABLE contracts (
    id                   UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID            NOT NULL REFERENCES tenants(id),
    -- 合同编号（唯一，人工/系统生成）
    contract_no          VARCHAR(100)    UNIQUE NOT NULL,
    status               contract_status NOT NULL DEFAULT 'quoting',
    -- 合同期间
    start_date           DATE            NOT NULL,
    end_date             DATE            NOT NULL,
    -- 合同签订/生效日
    sign_date            DATE,
    effective_date       DATE,
    -- 计租模型（v1.5）
    pricing_model        pricing_model   NOT NULL DEFAULT 'area',
    -- base_monthly_rent：flat 模型下的整套月租；area 模型下可选填参考值
    base_monthly_rent    NUMERIC(12,2)   NOT NULL,
    -- area 模型：单元级单价在 contract_units.unit_price
    -- revenue 模型：保底租金
    min_guarantee_rent   NUMERIC(12,2),
    -- 营业额分成比例（revenue 模型，精度 4 位小数，如 0.0800 = 8%）
    revenue_share_rate   NUMERIC(5,4),
    -- 免租期（天数）
    free_rent_days       INTEGER         NOT NULL DEFAULT 0,
    free_rent_start_date DATE,
    free_rent_end_date   DATE,
    -- 押金
    deposit_amount       NUMERIC(12,2)   NOT NULL DEFAULT 0,
    deposit_months       NUMERIC(4,1),    -- 押金倍数（如 3、3.5 个月）
    -- 账期（每月几号出账）
    billing_day          SMALLINT        NOT NULL DEFAULT 5
                         CHECK (billing_day BETWEEN 1 AND 28),
    -- 税务（v1.5）
    tax_inclusive        BOOLEAN         NOT NULL DEFAULT FALSE,
    applicable_tax_rate  NUMERIC(5,4),   -- 如 0.09 = 9% 增值税
    -- 二房东标识
    is_sublease_master   BOOLEAN         NOT NULL DEFAULT FALSE,
    -- 合同终止信息（status = terminated 时填写）
    termination_type     termination_type,
    termination_date     DATE,
    early_exit_penalty   NUMERIC(12,2),  -- 提前退租违约金（元）
    termination_note     TEXT,
    -- 续约意向（v1.7）
    renewal_intent       renewal_intent,
    renewal_note         TEXT,
    -- 关联的续签合同
    renewed_by_contract_id UUID          REFERENCES contracts(id),
    -- 实际负责的租务专员
    responsible_user_id  UUID            REFERENCES users(id),
    notes                TEXT,
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_contract_dates CHECK (start_date <= end_date)
);

CREATE INDEX idx_contracts_tenant   ON contracts(tenant_id);
CREATE INDEX idx_contracts_status   ON contracts(status);
CREATE INDEX idx_contracts_end_date ON contracts(end_date);
CREATE INDEX idx_contracts_user     ON contracts(responsible_user_id) WHERE responsible_user_id IS NOT NULL;

-- -------------------------------------------------------------------------
-- 合同-单元关联（M:N）
-- 一个合同可租多个单元；area 模型下每个单元有独立单价
-- -------------------------------------------------------------------------
CREATE TABLE contract_units (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID          NOT NULL REFERENCES contracts(id),
    unit_id     UUID          NOT NULL REFERENCES units(id),
    -- area 模型下该单元的单价（元/m²/月）
    unit_price  NUMERIC(8,4),
    -- 面积锁定：签约时快照，防止后续单元面积变更影响历史合同
    billing_area_snapshot NUMERIC(10,2),
    UNIQUE (contract_id, unit_id)
);

CREATE INDEX idx_contract_units_contract ON contract_units(contract_id);
CREATE INDEX idx_contract_units_unit     ON contract_units(unit_id);

-- -------------------------------------------------------------------------
-- 合同附件（PDF、扫描件）
-- -------------------------------------------------------------------------
CREATE TABLE contract_attachments (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID        NOT NULL REFERENCES contracts(id),
    -- 文件存储路径：contracts/{contract_id}/{filename}
    file_path   TEXT        NOT NULL,
    -- 文件原始名称（展示用）
    file_name   VARCHAR(200) NOT NULL,
    file_size   INTEGER,                -- 字节数
    -- 附件类型：'contract'=主合同, 'appendix'=附件补充协议, 'id_scan'=证件扫描, 'other'
    file_type   VARCHAR(30) NOT NULL DEFAULT 'contract',
    uploaded_by UUID        REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attachments_contract ON contract_attachments(contract_id);

-- -------------------------------------------------------------------------
-- 租金递增阶段（实例化的递增计划，绑定具体合同）
-- -------------------------------------------------------------------------
CREATE TABLE rent_escalation_phases (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID            NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    -- 排序（第几期递增）
    phase_seq       SMALLINT        NOT NULL,
    escalation_type escalation_type NOT NULL,
    -- 适用期间
    effective_from  DATE            NOT NULL,
    effective_to    DATE            NOT NULL,
    -- 参数（依据类型不同）
    rate            NUMERIC(8,6),   -- 比例，如 0.03 = 3%
    fixed_amount    NUMERIC(10,2),  -- 固定金额
    -- 最终计算后的该阶段月租（snapshot，减少重复计算）
    resulting_monthly_rent NUMERIC(12,2),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (contract_id, phase_seq)
);

CREATE INDEX idx_escalation_contract ON rent_escalation_phases(contract_id);

-- -------------------------------------------------------------------------
-- 递增规则模板库（可复用的递增参数预设）
-- -------------------------------------------------------------------------
CREATE TABLE escalation_templates (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL,  -- 如 "标准 3% 年递增"
    escalation_type escalation_type NOT NULL,
    -- 参数
    rate            NUMERIC(8,6),
    fixed_amount    NUMERIC(10,2),
    interval_months SMALLINT,                  -- 每 N 个月递增一次
    description     TEXT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by      UUID            REFERENCES users(id),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------------------
-- 预警记录（系统定时任务触发写入，按类型去重）
-- -------------------------------------------------------------------------
CREATE TABLE alerts (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type  alert_type  NOT NULL,
    -- 关联合同或账单（多态引用，类型由 alert_type 决定）
    contract_id UUID        REFERENCES contracts(id),
    invoice_id  UUID,                       -- 引用 invoices.id，FK 延迟建立
    -- 推送目标角色（数组，如 ['leasing_specialist','operations_manager']）
    target_roles TEXT[]     NOT NULL DEFAULT '{}',
    -- 是否已推送通知
    is_notified BOOLEAN     NOT NULL DEFAULT FALSE,
    notified_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 同一合同/账单+类型组合仅保留最新记录
    UNIQUE (alert_type, contract_id)
);

CREATE INDEX idx_alerts_contract    ON alerts(contract_id) WHERE contract_id IS NOT NULL;
CREATE INDEX idx_alerts_type        ON alerts(alert_type);
CREATE INDEX idx_alerts_notified    ON alerts(is_notified) WHERE is_notified = FALSE;

COMMIT;
