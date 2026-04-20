-- =============================================================================
-- Migration: 013_create_kpi
-- Description: KPI 考核体系核心表
--   kpi_metric_definitions（系统预定义 K01-K14 指标）
--   kpi_schemes（考核方案，状态：draft → active → archived）
--   kpi_scheme_metrics（方案-指标关联，权重合计 = 1.00 由 Service 层校验）
--   kpi_score_snapshots（评分快照）
--   kpi_score_snapshot_items（快照明细）
-- 依赖: 001, 002, 003
-- =============================================================================

BEGIN;

-- -------------------------------------------------------------------------
-- KPI 指标定义库（系统预设 K01-K14，不允许用户新增）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_metric_definitions (
    id                         UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 指标代码（K01 ~ K14），唯一
    code                       VARCHAR(10)      UNIQUE NOT NULL,
    name                       VARCHAR(100)     NOT NULL,
    description                TEXT,
    -- 指标分类（v1.5）
    category                   kpi_metric_category NOT NULL DEFAULT 'leasing',
    -- 默认评分阈值（各方案可在 kpi_scheme_metrics 中覆盖）
    default_full_score_threshold NUMERIC(10,4)  NOT NULL,  -- 满分阈值（如 0.95 = 95%）
    default_pass_threshold       NUMERIC(10,4)  NOT NULL,  -- 及格线
    default_fail_threshold       NUMERIC(10,4)  NOT NULL,  -- 不及格红线（0分起点）
    -- 方向：TRUE = 数值越高越好；FALSE = 数值越低越好（逾期率/空置天数）
    higher_is_better           BOOLEAN          NOT NULL DEFAULT TRUE,
    -- 方向标识（v1.7 冗余，与 higher_is_better 一致，便于前端展示）
    -- 'positive'=数值越高越好；'negative'=数值越低越好（线性插值逻辑翻转）
    direction                  VARCHAR(10)      NOT NULL DEFAULT 'positive'
                               CHECK (direction IN ('positive', 'negative')),
    -- 数据来源模块
    source_module              VARCHAR(50)      NOT NULL,  -- assets / contracts / finance / workorders
    -- 是否支持手动录入（K10 租户满意度）
    is_manual_input            BOOLEAN          NOT NULL DEFAULT FALSE,
    is_enabled                 BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at                 TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------------------
-- KPI 方案
-- -------------------------------------------------------------------------
CREATE TABLE kpi_schemes (
    id             UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 方案名称（如 '租务部考核方案 2026'）
    name           VARCHAR(200)      NOT NULL,
    period_type    kpi_period_type   NOT NULL,
    -- 方案有效期（旧方案数据保留，支持版本迭代）
    effective_from DATE              NOT NULL,
    effective_to   DATE,              -- NULL 表示持续有效
    -- 方案状态（v1.5 替换原 is_active BOOLEAN）
    status         kpi_scheme_status NOT NULL DEFAULT 'draft',
    -- 运行模式：'trial'=试运行（不影响正式考核）/ 'official'=正式
    scoring_mode   VARCHAR(20)       NOT NULL DEFAULT 'official'
                   CHECK (scoring_mode IN ('trial', 'official')),
    created_by     UUID              REFERENCES users(id),
    created_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

-- -------------------------------------------------------------------------
-- 方案-指标关联（权重合计 = 1.00 由 Service 层校验）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_scheme_metrics (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id   UUID         NOT NULL REFERENCES kpi_schemes(id) ON DELETE CASCADE,
    metric_id   UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    -- 权重（范围 0~1，精度 4 位小数）
    weight      NUMERIC(5,4) NOT NULL CHECK (weight > 0 AND weight <= 1),
    -- 本方案覆盖阈值（NULL 表示使用 kpi_metric_definitions 的默认值）
    full_score_threshold NUMERIC(10,4),
    pass_threshold       NUMERIC(10,4),
    fail_threshold       NUMERIC(10,4),
    UNIQUE (scheme_id, metric_id)
);

CREATE INDEX idx_scheme_metrics_scheme ON kpi_scheme_metrics(scheme_id);

-- -------------------------------------------------------------------------
-- KPI 打分快照（每次考核生成一条，冻结后触发7日申诉窗口）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_score_snapshots (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id         UUID        NOT NULL REFERENCES kpi_schemes(id),
    evaluated_user_id UUID        NOT NULL REFERENCES users(id),
    -- 评估时间段
    period_start      DATE        NOT NULL,
    period_end        DATE        NOT NULL,
    -- 汇总总分（0~100）
    total_score       NUMERIC(5,2) NOT NULL,
    -- 快照状态：'draft'=草稿中，'frozen'=已冻结（触发申诉），'recalculated'=已重算
    snapshot_status   VARCHAR(20) NOT NULL DEFAULT 'draft'
                      CHECK (snapshot_status IN ('draft', 'frozen', 'recalculated')),
    -- 冻结时间（申诉窗口 7 日从此时起算）
    frozen_at         TIMESTAMPTZ,
    calculated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by        UUID        REFERENCES users(id)
);

CREATE INDEX idx_kpi_snapshots_user   ON kpi_score_snapshots(evaluated_user_id);
CREATE INDEX idx_kpi_snapshots_scheme ON kpi_score_snapshots(scheme_id);
CREATE INDEX idx_kpi_snapshots_period ON kpi_score_snapshots(period_start, period_end);

-- -------------------------------------------------------------------------
-- 打分快照明细（每个指标一行）
-- -------------------------------------------------------------------------
CREATE TABLE kpi_score_snapshot_items (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id    UUID         NOT NULL REFERENCES kpi_score_snapshots(id) ON DELETE CASCADE,
    metric_id      UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    -- 快照时的权重（防止方案修改影响历史数据）
    weight         NUMERIC(5,4) NOT NULL,
    actual_value   NUMERIC(12,4),              -- 指标实际值
    score          NUMERIC(5,2) NOT NULL,       -- 本指标得分（0~100）
    weighted_score NUMERIC(5,2) NOT NULL,       -- 加权得分（score × weight × 100）
    -- 取数说明（便于下钻核查数据来源）
    source_note    TEXT
);

CREATE INDEX idx_snapshot_items_snapshot ON kpi_score_snapshot_items(snapshot_id);

COMMIT;
