-- =============================================================================
-- Migration: 000_consolidated_schema
-- Description: 当前完整数据库 Schema 基线快照（合并 001-029 所有迁移）
--   适用场景：
--     1. 全新服务器初始化（第一个也是唯一的启动迁移）
--     2. setup_server.sh --reset-db 清库重建
--   未来增量变更：从 001_xxx.sql 重新开始编号。
--
-- 变量注入（必须通过 psql -v 传入，不得硬编码）：
--   :admin_email          — 超管登录邮箱
--   :admin_password_hash  — bcrypt hash（cost≥12）
--   :company_name         — 顶级企业名称（如 "贵司物业管理"）
--
-- 手动执行示例：
--   psql -U propos -d propos \
--        -v admin_email='admin@example.com' \
--        -v admin_password_hash='$2a$12$...' \
--        -v company_name='贵司物业管理' \
--        -v ON_ERROR_STOP=1 \
--        -f backend/migrations/000_consolidated_schema.sql
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. 扩展插件
-- ─────────────────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. 枚举类型（所有 ENUM 最终状态，含历史增量变更）
-- ─────────────────────────────────────────────────────────────────────────────

-- 物业业态（含 mixed：综合体，见原 024 迁移）
CREATE TYPE property_type AS ENUM (
    'office',     -- 写字楼
    'retail',     -- 商铺
    'apartment',  -- 公寓
    'mixed'       -- 综合体（一栋楼多种业态，仅用于 buildings/noi_budgets）
);

-- 单元出租状态
CREATE TYPE unit_status AS ENUM (
    'leased',        -- 已租
    'vacant',        -- 空置
    'expiring_soon', -- 即将到期（≤90天）
    'non_leasable',  -- 非可租（公共区域/设备间）
    'renovating',    -- 改造中
    'pre_lease'      -- 预租/意向锁定
);

-- 单元装修状态
CREATE TYPE unit_decoration AS ENUM (
    'blank',    -- 毛坯
    'simple',   -- 简装
    'refined',  -- 精装
    'raw'       -- 原始状态
);

-- 用户角色
CREATE TYPE user_role AS ENUM (
    'super_admin',         -- 超级管理员
    'operations_manager',  -- 运营管理层
    'leasing_specialist',  -- 租务专员
    'finance_staff',       -- 财务人员
    'maintenance_staff',   -- 维修技工
    'property_inspector',  -- 楼管巡检员
    'report_viewer',       -- 只读观察者（投资人/审计）
    'sub_landlord'         -- 二房东
);

-- 租客类型
CREATE TYPE tenant_type AS ENUM (
    'corporate',   -- 企业
    'individual'   -- 个人
);

-- 合同状态机
CREATE TYPE contract_status AS ENUM (
    'quoting',        -- 报价中
    'pending_sign',   -- 待签约
    'active',         -- 执行中
    'expiring_soon',  -- 即将到期（≤90天）
    'expired',        -- 已到期
    'renewed',        -- 已续签
    'terminated'      -- 已终止
);

-- 计租模型
CREATE TYPE pricing_model AS ENUM (
    'area',     -- 按面积计租（元/m²/月）
    'flat',     -- 整套月租
    'revenue'   -- 保底+分成
);

-- 租金递增类型
CREATE TYPE escalation_type AS ENUM (
    'fixed_rate',             -- 固定比例递增
    'fixed_amount',           -- 固定金额递增
    'step',                   -- 阶梯式递增
    'cpi',                    -- CPI 挂钩递增
    'periodic',               -- 每 N 年递增
    'base_after_free_period'  -- 免租后基准调整
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
    'draft',      -- 草稿（生成中）
    'issued',     -- 已出账
    'paid',       -- 已核销
    'overdue',    -- 逾期
    'cancelled',  -- 已作废
    'exempt'      -- 免租期免单
);

-- 账单费项类型
CREATE TYPE invoice_item_type AS ENUM (
    'rent',            -- 租金
    'management_fee',  -- 物管费
    'electricity',     -- 电费
    'water',           -- 水费
    'parking',         -- 停车费
    'storage',         -- 储藏室
    'revenue_share',   -- 营业额分成（商铺）
    'other'            -- 其他
);

-- 运营支出类目
CREATE TYPE expense_category AS ENUM (
    'utility_common',       -- 水电公摊
    'outsourced_property',  -- 外包物业费
    'repair',               -- 维修费
    'insurance',            -- 保险
    'tax',                  -- 税金
    'professional_service', -- 专业服务费（消防检测/电梯年检等）
    'other'                 -- 其他
);

-- 工单费用性质
CREATE TYPE cost_nature AS ENUM (
    'opex',   -- 经常性支出（汇入 NOI）
    'capex'   -- 资本性支出（不计入 NOI）
);

-- 工单类型
CREATE TYPE work_order_type AS ENUM (
    'repair',      -- 报修
    'complaint',   -- 投诉
    'inspection'   -- 退租验房
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
CREATE TYPE work_order_priority AS ENUM (
    'normal',   -- 普通
    'urgent',   -- 紧急
    'critical'  -- 极紧急
);

-- 子租赁入住状态
CREATE TYPE sublease_occupancy_status AS ENUM (
    'occupied',          -- 已入住
    'signed_not_moved',  -- 已签约未入住
    'moved_out',         -- 已退租
    'vacant'             -- 空置
);

-- 子租赁审核状态
CREATE TYPE sublease_review_status AS ENUM (
    'draft',     -- 草稿（二房东填报未提交）
    'pending',   -- 待审核
    'approved',  -- 已通过
    'rejected'   -- 已退回
);

-- KPI 评估周期
CREATE TYPE kpi_period_type AS ENUM (
    'monthly',    -- 月度
    'quarterly',  -- 季度
    'yearly'      -- 年度
);

-- KPI 方案状态
CREATE TYPE kpi_scheme_status AS ENUM (
    'draft',     -- 草稿
    'active',    -- 生效中
    'archived'   -- 已归档
);

-- KPI 指标分类
CREATE TYPE kpi_metric_category AS ENUM (
    'leasing',  -- 租务类
    'finance',  -- 财务类
    'service',  -- 服务类
    'growth'    -- 增长类
);

-- 押金状态
CREATE TYPE deposit_status AS ENUM (
    'collected',          -- 已收取
    'frozen',             -- 冻结中
    'partially_credited', -- 部分冲抵
    'refunded'            -- 已退还
);

-- 合同终止类型
CREATE TYPE termination_type AS ENUM (
    'normal_expiry',      -- 正常到期
    'tenant_early_exit',  -- 租户提前退租
    'mutual_agreement',   -- 协商提前终止
    'owner_termination'   -- 业主单方解约
);

-- 水电表类型
CREATE TYPE meter_type AS ENUM (
    'water',        -- 水表
    'electricity',  -- 电表
    'gas'           -- 气表
);

-- 抄表周期
CREATE TYPE reading_cycle AS ENUM (
    'monthly',    -- 每月
    'bimonthly'   -- 每两月
);

-- 营业额申报审核状态
CREATE TYPE turnover_approval_status AS ENUM (
    'pending',   -- 待审核
    'approved',  -- 已通过
    'rejected'   -- 已退回
);

-- 导入数据类别（含 users / departments，见原 022 迁移）
CREATE TYPE import_data_type AS ENUM (
    'units',       -- 单元台账
    'contracts',   -- 合同数据
    'invoices',    -- 账单数据
    'users',       -- 用户数据
    'departments'  -- 部门数据
);

-- 导入回滚状态
CREATE TYPE import_rollback_status AS ENUM (
    'committed',    -- 已提交入库
    'rolled_back'   -- 已回滚
);

-- 信用评级
CREATE TYPE credit_rating AS ENUM ('A', 'B', 'C', 'D');

-- 通知类型
CREATE TYPE notification_type AS ENUM (
    'contract_expiring',   -- 合同即将到期
    'invoice_overdue',     -- 账单逾期
    'workorder_assigned',  -- 工单已派单
    'workorder_completed', -- 工单已完成
    'approval_pending',    -- 待审批
    'system_alert',        -- 系统预警
    'kpi_published'        -- KPI 成绩已发布
);

-- 通知严重级别
CREATE TYPE notification_severity AS ENUM (
    'info',      -- 信息
    'warning',   -- 警告
    'critical'   -- 严重
);

-- 催收方式
CREATE TYPE dunning_method AS ENUM (
    'phone',   -- 电话催收
    'sms',     -- 短信催收
    'letter',  -- 函件催收
    'visit',   -- 上门催收
    'legal'    -- 法务催收
);

-- 审批类型
CREATE TYPE approval_type AS ENUM (
    'contract_termination', -- 合同终止
    'deposit_refund',       -- 押金退还
    'invoice_adjustment',   -- 账单调整
    'sublease_submission'   -- 子租赁提交
);

-- 审批状态
CREATE TYPE approval_status AS ENUM (
    'pending',   -- 待审批
    'approved',  -- 已通过
    'rejected'   -- 已拒绝
);

-- 续约意向
CREATE TYPE renewal_intent AS ENUM (
    'willing',    -- 愿意续租
    'undecided',  -- 未决定
    'unwilling'   -- 不续租
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. 组织架构
-- ─────────────────────────────────────────────────────────────────────────────

-- 三级组织架构树（公司级→部门级→小组级）
CREATE TABLE departments (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    -- 上级节点，NULL 表示顶级（公司级）
    parent_id   UUID         REFERENCES departments(id),
    -- 层级：1=公司级，2=部门级，3=小组级
    level       SMALLINT     NOT NULL CHECK (level BETWEEN 1 AND 3),
    sort_order  INTEGER      NOT NULL DEFAULT 0,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_departments_parent ON departments(parent_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. 用户、审计、令牌、任务日志
-- ─────────────────────────────────────────────────────────────────────────────

-- 用户账号（department_id / bound_contract_id FK 在文件末尾补全）
CREATE TABLE users (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  VARCHAR(100) NOT NULL,
    email                 VARCHAR(255) UNIQUE NOT NULL,
    password_hash         TEXT         NOT NULL,
    role                  user_role    NOT NULL,
    -- 所属部门（FK 延迟补全，见文件末尾）
    department_id         UUID,
    -- 绑定合同（仅 sub_landlord，FK 延迟补全，见文件末尾）
    bound_contract_id     UUID,
    is_active             BOOLEAN      NOT NULL DEFAULT TRUE,
    failed_login_attempts SMALLINT     NOT NULL DEFAULT 0,
    locked_until          TIMESTAMPTZ,
    password_changed_at   TIMESTAMPTZ,
    last_login_at         TIMESTAMPTZ,
    -- 会话版本号：改密/冻结后递增，旧 refresh_token 自动失效
    session_version       INTEGER      NOT NULL DEFAULT 1,
    frozen_at             TIMESTAMPTZ,
    frozen_reason         TEXT,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_role         ON users(role);
CREATE INDEX idx_users_email        ON users(email);
CREATE INDEX idx_users_department   ON users(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_users_contract     ON users(bound_contract_id) WHERE bound_contract_id IS NOT NULL;
CREATE INDEX idx_users_locked_until ON users(locked_until) WHERE locked_until IS NOT NULL;

-- 操作审计日志（覆盖：合同变更、账单核销、权限变更、二房东数据提交）
CREATE TABLE audit_logs (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         REFERENCES users(id),
    action      VARCHAR(50)  NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id   UUID         NOT NULL,
    before_data JSONB,
    after_data  JSONB,
    meta        JSONB,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_entity  ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_user    ON audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);

-- JWT 刷新令牌（Refresh Token 轮换）
CREATE TABLE refresh_tokens (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT         NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ  NOT NULL,
    revoked     BOOLEAN      NOT NULL DEFAULT FALSE,
    device_info TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user   ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash   ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_active ON refresh_tokens(user_id, revoked) WHERE revoked = FALSE;

-- 定时任务执行日志
CREATE TABLE job_execution_logs (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    job_name          VARCHAR(100) NOT NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'running',
    records_processed INTEGER,
    records_failed    INTEGER,
    error_message     TEXT,
    duration_ms       INTEGER,
    started_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    finished_at       TIMESTAMPTZ
);

CREATE INDEX idx_job_logs_name    ON job_execution_logs(job_name);
CREATE INDEX idx_job_logs_status  ON job_execution_logs(status);
CREATE INDEX idx_job_logs_started ON job_execution_logs(started_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. 资产与空间（buildings → floors → units，含所有历史 ALTER 内联）
-- ─────────────────────────────────────────────────────────────────────────────

-- 楼栋（最终状态：经 021 重命名/删列 + 025 新增 basement_floors）
CREATE TABLE buildings (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)  NOT NULL,
    property_type   property_type NOT NULL,
    -- 地理位置（address 021 改为可选）
    address         TEXT,
    -- 楼层数量
    total_floors    SMALLINT      NOT NULL CHECK (total_floors > 0),
    -- 地下层数（025 新增）
    basement_floors SMALLINT      NOT NULL DEFAULT 0 CHECK (basement_floors >= 0),
    -- 总建筑面积 GFA（021 由 gross_area 重命名）
    gfa             NUMERIC(10,2) NOT NULL CHECK (gfa > 0),
    -- 总可租面积 NLA（021 由 leasable_area 重命名）
    nla             NUMERIC(10,2) NOT NULL CHECK (nla > 0),
    -- 建成年份（021 由 year_built 重命名）
    built_year      SMALLINT,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
    -- 已删除：city / cover_image_path / is_active（021 删除）
);

-- 楼层（最终状态：经 021 重命名/删列 + 027 新增渲染字段）
CREATE TABLE floors (
    id                       UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id              UUID          NOT NULL REFERENCES buildings(id),
    floor_number             SMALLINT      NOT NULL,
    -- 楼层面积（021 由 floor_area 重命名）
    nla                      NUMERIC(10,2),
    -- 楼层名称（021 由 label 重命名）
    floor_name               VARCHAR(20),
    -- CAD 转换产出路径（021 新增）
    svg_path                 TEXT,
    png_path                 TEXT,
    -- 渲染模式：vector=矢量原图；semantic=语义渲染（027 新增）
    render_mode              VARCHAR(16)   NOT NULL DEFAULT 'vector'
                             CHECK (render_mode IN ('vector', 'semantic')),
    -- floor_maps schema 版本及最近保存时间（027 新增，用于乐观锁）
    floor_map_schema_version VARCHAR(8),
    floor_map_updated_at     TIMESTAMPTZ,
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, floor_number)
    -- 已删除：is_active（021 删除）
);

CREATE INDEX idx_floors_building ON floors(building_id);

-- 楼层图纸（最终状态：经 021 重构为单版本双路径）
CREATE TABLE floor_plans (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id      UUID        NOT NULL REFERENCES floors(id),
    -- 版本标签（021 替换原 version 整型）
    version_label VARCHAR(50) NOT NULL,
    -- 图纸路径（021 重构：原 storage_path 拆为 svg_path + png_path）
    svg_path      TEXT        NOT NULL,
    png_path      TEXT,
    is_current    BOOLEAN     NOT NULL DEFAULT TRUE,
    uploaded_by   UUID        REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 已删除：version / file_type / storage_path（021 删除）
);

CREATE INDEX idx_floor_plans_floor   ON floor_plans(floor_id);
-- 同楼层只允许一个 is_current=true 版本（021 改为唯一索引）
CREATE UNIQUE INDEX uq_floor_plan_current ON floor_plans(floor_id) WHERE is_current = TRUE;

-- 单元（最终状态：经 021 重命名/删列 + 029 gross_area 允许 NULL）
CREATE TABLE units (
    id                    UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id           UUID            NOT NULL REFERENCES buildings(id),
    floor_id              UUID            NOT NULL REFERENCES floors(id),
    -- 单元号（021 由 unit_no 重命名）
    unit_number           VARCHAR(50)     NOT NULL,
    -- 建筑面积（029 去 NOT NULL；CHECK 对 NULL 不触发）
    gross_area            NUMERIC(10,2)   CHECK (gross_area > 0),
    -- 标准使用面积（参考值）
    net_area              NUMERIC(10,2),
    -- 业态（021 新增，从楼栋继承）
    property_type         property_type   NOT NULL,
    -- 装修状态（021 由 decoration 重命名）
    decoration_status     unit_decoration NOT NULL DEFAULT 'blank',
    -- 出租状态（021 由 status 重命名）
    current_status        unit_status     NOT NULL DEFAULT 'vacant',
    -- 市场参考单价（元/m²/月）
    market_rent_reference NUMERIC(8,2),
    -- 前任单元 ID（切割/合并历史追溯）
    predecessor_unit_ids  UUID[],
    -- 归档时间（改建/拆除后归档）
    archived_at           TIMESTAMPTZ,
    -- 朝向（021 新增）
    orientation           VARCHAR(20),
    -- 层高（021 新增）
    ceiling_height        NUMERIC(4,2),
    -- 是否可租（021 新增）
    is_leasable           BOOLEAN         NOT NULL DEFAULT TRUE,
    -- 扩展字段（021 新增，含 SVG 热区坐标等）
    ext_fields            JSONB           NOT NULL DEFAULT '{}',
    -- 当前绑定合同（021 新增；FK 延迟补全，见文件末尾）
    current_contract_id   UUID,
    -- 二维码标识（021 新增）
    qr_code               VARCHAR(100),
    created_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- 021 更新唯一约束（原 building_id+floor_id+unit_no → building_id+unit_number）
    CONSTRAINT units_building_id_unit_number_key UNIQUE (building_id, unit_number),
    CONSTRAINT units_qr_code_key UNIQUE (qr_code)
    -- 已删除：billing_area / floor_plan_coords / notes（021 删除）
);

CREATE INDEX idx_units_building      ON units(building_id);
CREATE INDEX idx_units_floor         ON units(floor_id);
CREATE INDEX idx_units_status        ON units(current_status);
CREATE INDEX idx_units_property_type ON units(property_type);
CREATE INDEX idx_units_ext_fields    ON units USING GIN(ext_fields);

-- 改造记录（最终状态：经 021 重命名/新增列）
CREATE TABLE renovation_records (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id             UUID         NOT NULL REFERENCES units(id),
    -- 改造类型（021 由 record_type 重命名，VARCHAR(100)）
    renovation_type     VARCHAR(100),
    -- 描述（021 改为可选）
    description         TEXT,
    cost                NUMERIC(12,2),
    -- 改造期（021 由 start_date/end_date 重命名）
    started_at          DATE,
    completed_at        DATE,
    -- 照片（021 将原 photo_paths 拆为 before/after）
    before_photo_paths  TEXT[],
    after_photo_paths   TEXT[],
    -- 施工方（021 新增）
    contractor          VARCHAR(200),
    created_by          UUID         REFERENCES users(id),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
    -- 已删除：photo_paths（021 迁移至 before_photo_paths 后删除）
);

CREATE INDEX idx_renovation_unit ON renovation_records(unit_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. 管辖范围
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE user_managed_scopes (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID          REFERENCES departments(id),
    user_id       UUID          REFERENCES users(id),
    building_id   UUID          REFERENCES buildings(id),
    floor_id      UUID          REFERENCES floors(id),
    property_type property_type,
    CHECK (department_id IS NOT NULL OR user_id IS NOT NULL)
);

CREATE INDEX idx_managed_scopes_dept ON user_managed_scopes(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_managed_scopes_user ON user_managed_scopes(user_id)       WHERE user_id IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. 租务与合同
-- ─────────────────────────────────────────────────────────────────────────────

-- 租客档案
CREATE TABLE tenants (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(200)  NOT NULL,
    tenant_type             tenant_type   NOT NULL DEFAULT 'corporate',
    -- [加密存储] 企业：统一社会信用代码；个人：身份证号（AES-256-GCM）
    id_number_encrypted     TEXT          NOT NULL,
    contact_person          VARCHAR(100),
    -- [加密存储] 联系电话（AES-256-GCM）
    contact_phone_encrypted TEXT,
    contact_email           VARCHAR(200),
    legal_representative    VARCHAR(100),
    business_license_no     VARCHAR(100),
    registered_capital      NUMERIC(15,2),
    credit_rating           credit_rating,
    credit_score            NUMERIC(5,2),
    credit_updated_at       TIMESTAMPTZ,
    is_blacklisted          BOOLEAN       NOT NULL DEFAULT FALSE,
    blacklist_reason        TEXT,
    -- PIPL：合同终止满 3 年后匿名化/删除个人信息
    data_retention_until    TIMESTAMPTZ,
    notes                   TEXT,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_type ON tenants(tenant_type);

-- 合同
CREATE TABLE contracts (
    id                     UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID            NOT NULL REFERENCES tenants(id),
    contract_no            VARCHAR(100)    UNIQUE NOT NULL,
    status                 contract_status NOT NULL DEFAULT 'quoting',
    start_date             DATE            NOT NULL,
    end_date               DATE            NOT NULL,
    sign_date              DATE,
    effective_date         DATE,
    pricing_model          pricing_model   NOT NULL DEFAULT 'area',
    base_monthly_rent      NUMERIC(12,2)   NOT NULL,
    min_guarantee_rent     NUMERIC(12,2),
    revenue_share_rate     NUMERIC(5,4),
    free_rent_days         INTEGER         NOT NULL DEFAULT 0,
    free_rent_start_date   DATE,
    free_rent_end_date     DATE,
    deposit_amount         NUMERIC(12,2)   NOT NULL DEFAULT 0,
    deposit_months         NUMERIC(4,1),
    billing_day            SMALLINT        NOT NULL DEFAULT 5
                           CHECK (billing_day BETWEEN 1 AND 28),
    tax_inclusive          BOOLEAN         NOT NULL DEFAULT FALSE,
    applicable_tax_rate    NUMERIC(5,4),
    is_sublease_master     BOOLEAN         NOT NULL DEFAULT FALSE,
    termination_type       termination_type,
    termination_date       DATE,
    early_exit_penalty     NUMERIC(12,2),
    termination_note       TEXT,
    renewal_intent         renewal_intent,
    renewal_note           TEXT,
    renewed_by_contract_id UUID            REFERENCES contracts(id),
    responsible_user_id    UUID            REFERENCES users(id),
    notes                  TEXT,
    created_at             TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_contract_dates CHECK (start_date <= end_date)
);

CREATE INDEX idx_contracts_tenant   ON contracts(tenant_id);
CREATE INDEX idx_contracts_status   ON contracts(status);
CREATE INDEX idx_contracts_end_date ON contracts(end_date);
CREATE INDEX idx_contracts_user     ON contracts(responsible_user_id) WHERE responsible_user_id IS NOT NULL;

-- 合同-单元关联（M:N）
CREATE TABLE contract_units (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id           UUID          NOT NULL REFERENCES contracts(id),
    unit_id               UUID          NOT NULL REFERENCES units(id),
    unit_price            NUMERIC(8,4),
    billing_area_snapshot NUMERIC(10,2),
    UNIQUE (contract_id, unit_id)
);

CREATE INDEX idx_contract_units_contract ON contract_units(contract_id);
CREATE INDEX idx_contract_units_unit     ON contract_units(unit_id);

-- 合同附件
CREATE TABLE contract_attachments (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID         NOT NULL REFERENCES contracts(id),
    file_path   TEXT         NOT NULL,
    file_name   VARCHAR(200) NOT NULL,
    file_size   INTEGER,
    file_type   VARCHAR(30)  NOT NULL DEFAULT 'contract',
    uploaded_by UUID         REFERENCES users(id),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attachments_contract ON contract_attachments(contract_id);

-- 租金递增阶段
CREATE TABLE rent_escalation_phases (
    id                     UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id            UUID            NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    phase_seq              SMALLINT        NOT NULL,
    escalation_type        escalation_type NOT NULL,
    effective_from         DATE            NOT NULL,
    effective_to           DATE            NOT NULL,
    rate                   NUMERIC(8,6),
    fixed_amount           NUMERIC(10,2),
    resulting_monthly_rent NUMERIC(12,2),
    created_at             TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (contract_id, phase_seq)
);

CREATE INDEX idx_escalation_contract ON rent_escalation_phases(contract_id);

-- 递增规则模板库
CREATE TABLE escalation_templates (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL,
    escalation_type escalation_type NOT NULL,
    rate            NUMERIC(8,6),
    fixed_amount    NUMERIC(10,2),
    interval_months SMALLINT,
    description     TEXT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by      UUID            REFERENCES users(id),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- 预警记录（invoice_id FK 延迟补全，见文件末尾）
CREATE TABLE alerts (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type   alert_type  NOT NULL,
    contract_id  UUID        REFERENCES contracts(id),
    -- 引用 invoices.id，FK 延迟补全（invoices 在后面创建）
    invoice_id   UUID,
    target_roles TEXT[]      NOT NULL DEFAULT '{}',
    is_notified  BOOLEAN     NOT NULL DEFAULT FALSE,
    notified_at  TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (alert_type, contract_id)
);

CREATE INDEX idx_alerts_contract ON alerts(contract_id) WHERE contract_id IS NOT NULL;
CREATE INDEX idx_alerts_type     ON alerts(alert_type);
CREATE INDEX idx_alerts_notified ON alerts(is_notified) WHERE is_notified = FALSE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. 财务
-- ─────────────────────────────────────────────────────────────────────────────

-- 账单
CREATE TABLE invoices (
    id                 UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id        UUID           NOT NULL REFERENCES contracts(id),
    invoice_no         VARCHAR(100)   UNIQUE NOT NULL,
    billing_month      DATE           NOT NULL,
    status             invoice_status NOT NULL DEFAULT 'draft',
    total_amount       NUMERIC(12,2)  NOT NULL,
    paid_amount        NUMERIC(12,2)  NOT NULL DEFAULT 0,
    outstanding_amount NUMERIC(12,2)  GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    due_date           DATE           NOT NULL,
    paid_at            TIMESTAMPTZ,
    is_exempt          BOOLEAN        NOT NULL DEFAULT FALSE,
    created_by         UUID           REFERENCES users(id),
    voided_by          UUID           REFERENCES users(id),
    void_reason        TEXT,
    notes              TEXT,
    created_at         TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_contract ON invoices(contract_id);
CREATE INDEX idx_invoices_status   ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_month    ON invoices(billing_month);
CREATE INDEX idx_invoices_overdue  ON invoices(status, due_date) WHERE status = 'overdue';

-- 账单费项明细
CREATE TABLE invoice_items (
    id          UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID               NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type   invoice_item_type  NOT NULL,
    description VARCHAR(500),
    quantity    NUMERIC(12,4),
    unit_price  NUMERIC(10,4),
    amount      NUMERIC(12,2)      NOT NULL,
    sort_order  SMALLINT           NOT NULL DEFAULT 0
);

CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- 收款记录
CREATE TABLE payments (
    id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_no         VARCHAR(100) UNIQUE NOT NULL,
    tenant_id          UUID         NOT NULL REFERENCES tenants(id),
    amount             NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_method     VARCHAR(30)  NOT NULL DEFAULT 'bank_transfer',
    bank_reference     VARCHAR(200),
    payment_date       DATE         NOT NULL,
    allocation_status  VARCHAR(20)  NOT NULL DEFAULT 'pending'
                       CHECK (allocation_status IN ('pending', 'allocated', 'partial')),
    unallocated_amount NUMERIC(12,2) NOT NULL,
    recorded_by        UUID         REFERENCES users(id),
    notes              TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_date   ON payments(payment_date DESC);
CREATE INDEX idx_payments_status ON payments(allocation_status) WHERE allocation_status != 'allocated';

-- 收款-账单核销关联（M:N）
CREATE TABLE payment_allocations (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id       UUID          NOT NULL REFERENCES payments(id),
    invoice_id       UUID          NOT NULL REFERENCES invoices(id),
    allocated_amount NUMERIC(12,2) NOT NULL CHECK (allocated_amount > 0),
    allocated_by     UUID          REFERENCES users(id),
    allocated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE (payment_id, invoice_id)
);

CREATE INDEX idx_allocations_payment ON payment_allocations(payment_id);
CREATE INDEX idx_allocations_invoice ON payment_allocations(invoice_id);

-- 运营支出（work_order_id FK 延迟补全，见文件末尾）
CREATE TABLE expenses (
    id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id   UUID             NOT NULL REFERENCES buildings(id),
    unit_id       UUID             REFERENCES units(id),
    -- 引用 work_orders.id，FK 延迟补全（work_orders 在后面创建）
    work_order_id UUID,
    category      expense_category NOT NULL,
    description   TEXT             NOT NULL,
    amount        NUMERIC(12,2)    NOT NULL,
    expense_date  DATE             NOT NULL,
    vendor        VARCHAR(200),
    receipt_path  TEXT,
    cost_nature   cost_nature,
    created_by    UUID             REFERENCES users(id),
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_expenses_building  ON expenses(building_id);
CREATE INDEX idx_expenses_date      ON expenses(expense_date);
CREATE INDEX idx_expenses_category  ON expenses(category);
CREATE INDEX idx_expenses_workorder ON expenses(work_order_id) WHERE work_order_id IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. 工单
-- ─────────────────────────────────────────────────────────────────────────────

-- 供应商档案
CREATE TABLE suppliers (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(200) NOT NULL,
    category      VARCHAR(50),
    contact_name  VARCHAR(100),
    -- [加密存储] 联系电话（AES-256-GCM）
    contact_phone TEXT,
    address       TEXT,
    notes         TEXT,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 工单（follow_up_work_order_id FK 延迟补全，见文件末尾）
CREATE TABLE work_orders (
    id                              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    order_no                        VARCHAR(50)         UNIQUE NOT NULL,
    work_order_type                 work_order_type     NOT NULL DEFAULT 'repair',
    building_id                     UUID                NOT NULL REFERENCES buildings(id),
    floor_id                        UUID                REFERENCES floors(id),
    unit_id                         UUID                REFERENCES units(id),
    contract_id                     UUID                REFERENCES contracts(id),
    issue_type                      VARCHAR(100)        NOT NULL,
    priority                        work_order_priority NOT NULL DEFAULT 'normal',
    description                     TEXT                NOT NULL,
    status                          work_order_status   NOT NULL DEFAULT 'submitted',
    reporter_user_id                UUID                NOT NULL REFERENCES users(id),
    assignee_user_id                UUID                REFERENCES users(id),
    supplier_id                     UUID                REFERENCES suppliers(id),
    submitted_at                    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    approved_at                     TIMESTAMPTZ,
    started_at                      TIMESTAMPTZ,
    completed_at                    TIMESTAMPTZ,
    expected_complete_at            TIMESTAMPTZ,
    on_hold_reason                  TEXT,
    -- 来源重开工单
    reopened_from_work_order_id     UUID                REFERENCES work_orders(id),
    material_cost                   NUMERIC(10,2),
    labor_cost                      NUMERIC(10,2),
    cost_nature                     cost_nature,
    inspection_note                 TEXT,
    rejected_reason                 TEXT,
    deposit_deduction_suggestion    NUMERIC(10,2),
    -- 引用自身，FK 延迟补全（见文件末尾）
    follow_up_work_order_id         UUID,
    source                          VARCHAR(20)         NOT NULL DEFAULT 'app'
                                    CHECK (source IN ('app', 'mini_program', 'manual')),
    created_at                      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at                      TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workorders_building  ON work_orders(building_id);
CREATE INDEX idx_workorders_unit      ON work_orders(unit_id)          WHERE unit_id IS NOT NULL;
CREATE INDEX idx_workorders_status    ON work_orders(status);
CREATE INDEX idx_workorders_type      ON work_orders(work_order_type);
CREATE INDEX idx_workorders_reporter  ON work_orders(reporter_user_id);
CREATE INDEX idx_workorders_submitted ON work_orders(submitted_at DESC);
CREATE INDEX idx_workorders_contract  ON work_orders(contract_id)      WHERE contract_id IS NOT NULL;

-- 工单照片
CREATE TABLE work_order_photos (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    work_order_id UUID         NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
    photo_stage   VARCHAR(20)  NOT NULL DEFAULT 'before',
    storage_path  TEXT         NOT NULL,
    sort_order    SMALLINT     NOT NULL DEFAULT 0,
    uploaded_by   UUID         REFERENCES users(id),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workorder_photos_order ON work_order_photos(work_order_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. 押金
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE deposits (
    id                   UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id          UUID           NOT NULL REFERENCES contracts(id),
    deposit_amount       NUMERIC(12,2)  NOT NULL CHECK (deposit_amount > 0),
    paid_amount          NUMERIC(12,2)  NOT NULL DEFAULT 0,
    credited_amount      NUMERIC(12,2)  NOT NULL DEFAULT 0,
    refunded_amount      NUMERIC(12,2)  NOT NULL DEFAULT 0,
    balance              NUMERIC(12,2)  GENERATED ALWAYS AS
                         (paid_amount - credited_amount - refunded_amount) STORED,
    status               deposit_status NOT NULL DEFAULT 'collected',
    collected_date       DATE,
    refund_bank_name     VARCHAR(100),
    refund_account_no    VARCHAR(100),
    refund_account_name  VARCHAR(100),
    refund_requested_at  TIMESTAMPTZ,
    refund_approved_by   UUID           REFERENCES users(id),
    refund_approved_at   TIMESTAMPTZ,
    notes                TEXT,
    created_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_deposit_contract ON deposits(contract_id);
CREATE INDEX idx_deposits_status ON deposits(status);

-- 押金交易流水
CREATE TABLE deposit_transactions (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    deposit_id       UUID         NOT NULL REFERENCES deposits(id),
    transaction_type VARCHAR(20)  NOT NULL CHECK (transaction_type IN ('collect', 'credit', 'refund')),
    amount           NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    invoice_id       UUID         REFERENCES invoices(id),
    bank_reference   VARCHAR(200),
    transaction_date DATE         NOT NULL,
    created_by       UUID         REFERENCES users(id),
    notes            TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_deposit_txn_deposit ON deposit_transactions(deposit_id);
CREATE INDEX idx_deposit_txn_date    ON deposit_transactions(transaction_date DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. 水电气抄表
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE meter_readings (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id              UUID          NOT NULL REFERENCES units(id),
    meter_type           meter_type    NOT NULL,
    reading_cycle        reading_cycle NOT NULL DEFAULT 'monthly',
    current_reading      NUMERIC(12,2) NOT NULL,
    previous_reading     NUMERIC(12,2) NOT NULL,
    consumption          NUMERIC(12,2) NOT NULL,
    unit_price           NUMERIC(10,4) NOT NULL,
    cost_amount          NUMERIC(12,2) NOT NULL,
    -- 阶梯计价明细（可选）
    tiered_details       JSONB,
    reading_date         DATE          NOT NULL,
    recorded_by          UUID          REFERENCES users(id),
    invoice_generated    BOOLEAN       NOT NULL DEFAULT FALSE,
    generated_invoice_id UUID          REFERENCES invoices(id),
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meter_unit      ON meter_readings(unit_id);
CREATE INDEX idx_meter_date      ON meter_readings(reading_date DESC);
CREATE INDEX idx_meter_type      ON meter_readings(meter_type);
CREATE INDEX idx_meter_uninvoiced ON meter_readings(invoice_generated) WHERE invoice_generated = FALSE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. 商铺营业额申报
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE turnover_reports (
    id                   UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id          UUID                     NOT NULL REFERENCES contracts(id),
    report_month         DATE                     NOT NULL,
    reported_revenue     NUMERIC(12,2)            NOT NULL,
    revenue_share_rate   NUMERIC(5,4)             NOT NULL,
    base_rent            NUMERIC(12,2)            NOT NULL,
    calculated_share     NUMERIC(12,2)            NOT NULL,
    approval_status      turnover_approval_status NOT NULL DEFAULT 'pending',
    reviewed_by          UUID                     REFERENCES users(id),
    reviewed_at          TIMESTAMPTZ,
    rejection_reason     TEXT,
    attachment_paths     TEXT[],
    is_amendment         BOOLEAN                  NOT NULL DEFAULT FALSE,
    original_report_id   UUID                     REFERENCES turnover_reports(id),
    generated_invoice_id UUID                     REFERENCES invoices(id),
    dispute_note         TEXT,
    submitted_by         UUID                     REFERENCES users(id),
    created_at           TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ              NOT NULL DEFAULT NOW()
);

-- 同一合同同一月份仅一条正式申报（补报不受此约束）
CREATE UNIQUE INDEX uq_turnover_original
    ON turnover_reports(contract_id, report_month)
    WHERE is_amendment = FALSE;

CREATE INDEX idx_turnover_contract ON turnover_reports(contract_id);
CREATE INDEX idx_turnover_month    ON turnover_reports(report_month);
CREATE INDEX idx_turnover_status   ON turnover_reports(approval_status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. 二房东穿透管理
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE subleases (
    id                           UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
    master_contract_id           UUID                      NOT NULL REFERENCES contracts(id),
    unit_id                      UUID                      NOT NULL REFERENCES units(id),
    sub_tenant_name              VARCHAR(200)              NOT NULL,
    sub_tenant_type              tenant_type               NOT NULL DEFAULT 'corporate',
    sub_tenant_contact_person    VARCHAR(100),
    -- [加密存储] 终端租客证件号（AES-256-GCM）
    sub_tenant_id_number_encrypted TEXT,
    -- [加密存储] 终端租客联系电话（AES-256-GCM）
    sub_tenant_phone_encrypted   TEXT,
    start_date                   DATE                      NOT NULL,
    end_date                     DATE                      NOT NULL,
    monthly_rent                 NUMERIC(12,2)             NOT NULL,
    rent_per_sqm                 NUMERIC(8,4),
    occupancy_status             sublease_occupancy_status NOT NULL DEFAULT 'occupied',
    occupant_count               SMALLINT,
    review_status                sublease_review_status    NOT NULL DEFAULT 'pending',
    reviewer_user_id             UUID                      REFERENCES users(id),
    reviewed_at                  TIMESTAMPTZ,
    rejection_reason             TEXT,
    version_no                   INTEGER                   NOT NULL DEFAULT 1,
    declared_for_month           DATE,
    submission_channel           VARCHAR(20)               NOT NULL DEFAULT 'internal',
    submitted_by_user_id         UUID                      REFERENCES users(id),
    submitted_at                 TIMESTAMPTZ,
    truth_declared_at            TIMESTAMPTZ,
    notes                        TEXT,
    -- PIPL：个人信息保留截止时间（终止后 ≤ 3 年）
    data_retention_until         TIMESTAMPTZ,
    created_at                   TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    updated_at                   TIMESTAMPTZ               NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sublease_dates CHECK (start_date <= end_date)
);

-- 同一单元同一时间只允许一条已审核的在租/已签约记录
CREATE UNIQUE INDEX uq_sublease_active_unit
    ON subleases(unit_id)
    WHERE occupancy_status IN ('occupied', 'signed_not_moved')
      AND review_status = 'approved';

CREATE INDEX idx_subleases_master_contract ON subleases(master_contract_id);
CREATE INDEX idx_subleases_unit            ON subleases(unit_id);
CREATE INDEX idx_subleases_review_status   ON subleases(review_status);
CREATE INDEX idx_subleases_occupancy       ON subleases(occupancy_status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 14. KPI 考核体系
-- ─────────────────────────────────────────────────────────────────────────────

-- KPI 指标定义库（系统预设 K01-K14）
CREATE TABLE kpi_metric_definitions (
    id                          UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    code                        VARCHAR(10)         UNIQUE NOT NULL,
    name                        VARCHAR(100)        NOT NULL,
    description                 TEXT,
    category                    kpi_metric_category NOT NULL DEFAULT 'leasing',
    default_full_score_threshold NUMERIC(10,4)      NOT NULL,
    default_pass_threshold       NUMERIC(10,4)      NOT NULL,
    default_fail_threshold       NUMERIC(10,4)      NOT NULL,
    higher_is_better            BOOLEAN             NOT NULL DEFAULT TRUE,
    direction                   VARCHAR(10)         NOT NULL DEFAULT 'positive'
                                CHECK (direction IN ('positive', 'negative')),
    source_module               VARCHAR(50)         NOT NULL,
    is_manual_input             BOOLEAN             NOT NULL DEFAULT FALSE,
    is_enabled                  BOOLEAN             NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

-- KPI 考核方案
CREATE TABLE kpi_schemes (
    id             UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    name           VARCHAR(200)      NOT NULL,
    period_type    kpi_period_type   NOT NULL,
    effective_from DATE              NOT NULL,
    effective_to   DATE,
    status         kpi_scheme_status NOT NULL DEFAULT 'draft',
    scoring_mode   VARCHAR(20)       NOT NULL DEFAULT 'official'
                   CHECK (scoring_mode IN ('trial', 'official')),
    created_by     UUID              REFERENCES users(id),
    created_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

-- 方案-指标关联（权重合计=1.00 由 Service 层校验）
CREATE TABLE kpi_scheme_metrics (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id            UUID         NOT NULL REFERENCES kpi_schemes(id) ON DELETE CASCADE,
    metric_id            UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    weight               NUMERIC(5,4) NOT NULL CHECK (weight > 0 AND weight <= 1),
    full_score_threshold NUMERIC(10,4),
    pass_threshold       NUMERIC(10,4),
    fail_threshold       NUMERIC(10,4),
    UNIQUE (scheme_id, metric_id)
);

CREATE INDEX idx_scheme_metrics_scheme ON kpi_scheme_metrics(scheme_id);

-- KPI 打分快照
CREATE TABLE kpi_score_snapshots (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id         UUID         NOT NULL REFERENCES kpi_schemes(id),
    evaluated_user_id UUID         NOT NULL REFERENCES users(id),
    period_start      DATE         NOT NULL,
    period_end        DATE         NOT NULL,
    total_score       NUMERIC(5,2) NOT NULL,
    snapshot_status   VARCHAR(20)  NOT NULL DEFAULT 'draft'
                      CHECK (snapshot_status IN ('draft', 'frozen', 'recalculated')),
    frozen_at         TIMESTAMPTZ,
    calculated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        UUID         REFERENCES users(id)
);

CREATE INDEX idx_kpi_snapshots_user   ON kpi_score_snapshots(evaluated_user_id);
CREATE INDEX idx_kpi_snapshots_scheme ON kpi_score_snapshots(scheme_id);
CREATE INDEX idx_kpi_snapshots_period ON kpi_score_snapshots(period_start, period_end);

-- 打分快照明细
CREATE TABLE kpi_score_snapshot_items (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id    UUID         NOT NULL REFERENCES kpi_score_snapshots(id) ON DELETE CASCADE,
    metric_id      UUID         NOT NULL REFERENCES kpi_metric_definitions(id),
    weight         NUMERIC(5,4) NOT NULL,
    actual_value   NUMERIC(12,4),
    score          NUMERIC(5,2) NOT NULL,
    weighted_score NUMERIC(5,2) NOT NULL,
    source_note    TEXT
);

CREATE INDEX idx_snapshot_items_snapshot ON kpi_score_snapshot_items(snapshot_id);

-- KPI 方案绑定对象
CREATE TABLE kpi_scheme_targets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id     UUID NOT NULL REFERENCES kpi_schemes(id) ON DELETE CASCADE,
    user_id       UUID REFERENCES users(id),
    department_id UUID REFERENCES departments(id),
    CHECK (user_id IS NOT NULL OR department_id IS NOT NULL)
);

CREATE UNIQUE INDEX uq_scheme_target_user ON kpi_scheme_targets(scheme_id, user_id)       WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX uq_scheme_target_dept ON kpi_scheme_targets(scheme_id, department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_scheme_targets_scheme ON kpi_scheme_targets(scheme_id);
CREATE INDEX idx_scheme_targets_dept   ON kpi_scheme_targets(department_id) WHERE department_id IS NOT NULL;

-- KPI 申诉（快照冻结后 7 日内可提交）
CREATE TABLE kpi_appeals (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id    UUID        NOT NULL REFERENCES kpi_score_snapshots(id),
    appellant_id   UUID        NOT NULL REFERENCES users(id),
    reason         TEXT        NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewer_id    UUID        REFERENCES users(id),
    review_comment TEXT,
    reviewed_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kpi_appeals_snapshot ON kpi_appeals(snapshot_id);
CREATE INDEX idx_kpi_appeals_pending  ON kpi_appeals(status) WHERE status = 'pending';

-- ─────────────────────────────────────────────────────────────────────────────
-- 15. 批量导入
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE import_batches (
    id               UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_name       VARCHAR(200)           NOT NULL,
    data_type        import_data_type       NOT NULL,
    total_records    INTEGER                NOT NULL,
    success_count    INTEGER                NOT NULL DEFAULT 0,
    failure_count    INTEGER                NOT NULL DEFAULT 0,
    rollback_status  import_rollback_status NOT NULL DEFAULT 'committed',
    error_details    JSONB,
    is_dry_run       BOOLEAN                NOT NULL DEFAULT FALSE,
    source_file_path TEXT,
    created_by       UUID                   REFERENCES users(id),
    created_at       TIMESTAMPTZ            NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_import_batches_type   ON import_batches(data_type);
CREATE INDEX idx_import_batches_status ON import_batches(rollback_status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 16. OTP 密码重置
-- ─────────────────────────────────────────────────────────────────────────────

-- code_hash 存 SHA-256(OTP 明文)，明文仅在邮件中发送，不入库
CREATE TABLE password_reset_otps (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email           TEXT        NOT NULL,
    code_hash       TEXT        NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    failed_attempts INT         NOT NULL DEFAULT 0
);

CREATE INDEX idx_password_reset_otps_user_id ON password_reset_otps(user_id);
CREATE INDEX idx_password_reset_otps_email   ON password_reset_otps(email);

-- ─────────────────────────────────────────────────────────────────────────────
-- 17. NOI 预算
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE noi_budgets (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id   UUID          REFERENCES buildings(id),
    property_type property_type,
    period_year   SMALLINT      NOT NULL,
    period_month  SMALLINT      CHECK (period_month BETWEEN 1 AND 12),
    budget_noi    NUMERIC(14,2) NOT NULL,
    created_by    UUID          REFERENCES users(id),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_noi_budgets_building ON noi_budgets(building_id)    WHERE building_id IS NOT NULL;
CREATE INDEX idx_noi_budgets_type     ON noi_budgets(property_type)  WHERE property_type IS NOT NULL;
CREATE INDEX idx_noi_budgets_period   ON noi_budgets(period_year, period_month);

-- ─────────────────────────────────────────────────────────────────────────────
-- 18. 通知与催收
-- ─────────────────────────────────────────────────────────────────────────────

-- 站内通知
CREATE TABLE notifications (
    id            UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID                  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type          notification_type     NOT NULL,
    severity      notification_severity NOT NULL DEFAULT 'info',
    title         VARCHAR(200)          NOT NULL,
    content       TEXT                  NOT NULL,
    is_read       BOOLEAN               NOT NULL DEFAULT FALSE,
    resource_type VARCHAR(50),
    resource_id   UUID,
    created_at    TIMESTAMPTZ           NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_user_time   ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_type        ON notifications(type);

-- 催收记录
CREATE TABLE dunning_logs (
    id           UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id   UUID           NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    method       dunning_method NOT NULL,
    content      TEXT           NOT NULL,
    result       TEXT,
    dunning_date DATE           NOT NULL,
    created_by   UUID           NOT NULL REFERENCES users(id),
    created_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dunning_logs_invoice ON dunning_logs(invoice_id);
CREATE INDEX idx_dunning_logs_date    ON dunning_logs(dunning_date);

-- ─────────────────────────────────────────────────────────────────────────────
-- 19. CAD 导入任务
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE cad_import_jobs (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id    UUID         NOT NULL REFERENCES buildings(id),
    status         VARCHAR(20)  NOT NULL DEFAULT 'uploaded'
                   CHECK (status IN ('uploaded', 'splitting', 'done', 'failed')),
    dxf_path       TEXT         NOT NULL,
    prefix         VARCHAR(100) NOT NULL,
    matched_count  INTEGER      NOT NULL DEFAULT 0,
    unmatched_svgs JSONB        NOT NULL DEFAULT '[]'::jsonb,
    error_message  TEXT,
    created_by     UUID         REFERENCES users(id),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cad_import_jobs_building ON cad_import_jobs(building_id);
CREATE INDEX idx_cad_import_jobs_status   ON cad_import_jobs(status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 20. 楼层结构标注（Floor Map v2）
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE floor_maps (
    floor_id                UUID         PRIMARY KEY REFERENCES floors(id) ON DELETE CASCADE,
    schema_version          VARCHAR(8)   NOT NULL DEFAULT '2.0',
    viewport                JSONB,
    outline                 JSONB,
    -- 已确认结构数组（人工审核后的 source='manual' 记录）
    structures              JSONB        NOT NULL DEFAULT '[]'::jsonb,
    -- 窗洞数组
    windows                 JSONB        NOT NULL DEFAULT '[]'::jsonb,
    north                   JSONB,
    -- DXF 抽取生成的候选结构（供前端候选清单）
    candidates              JSONB,
    candidates_extracted_at TIMESTAMPTZ,
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by              UUID         REFERENCES users(id)
);

CREATE INDEX idx_floor_maps_updated_at ON floor_maps(updated_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 21. 延迟外键约束（循环/乱序依赖，此处所有表均已创建，统一补全）
-- ─────────────────────────────────────────────────────────────────────────────

-- users.department_id → departments
ALTER TABLE users
    ADD CONSTRAINT fk_users_department
    FOREIGN KEY (department_id) REFERENCES departments(id);

-- users.bound_contract_id → contracts（循环依赖：contracts.responsible_user_id → users）
ALTER TABLE users
    ADD CONSTRAINT fk_users_bound_contract
    FOREIGN KEY (bound_contract_id) REFERENCES contracts(id);

-- expenses.work_order_id → work_orders
ALTER TABLE expenses
    ADD CONSTRAINT fk_expenses_work_order
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- work_orders.follow_up_work_order_id → work_orders（自引用）
ALTER TABLE work_orders
    ADD CONSTRAINT fk_workorder_follow_up
    FOREIGN KEY (follow_up_work_order_id) REFERENCES work_orders(id);

-- alerts.invoice_id → invoices
ALTER TABLE alerts
    ADD CONSTRAINT fk_alerts_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 22. 种子数据（超管账号、组织架构、KPI 指标库）
-- ─────────────────────────────────────────────────────────────────────────────
-- 注意：admin_email / admin_password_hash / company_name 由 psql -v 注入，
--       不得硬编码在本文件中。

-- 顶级企业节点（level=1）
INSERT INTO departments (id, name, parent_id, level, sort_order)
VALUES (
    'de000000-0000-4000-8000-000000000001',
    :'company_name',
    NULL, 1, 0
)
ON CONFLICT (id) DO UPDATE
    SET name       = EXCLUDED.name,
        updated_at = NOW();

-- 三个初始部门（level=2，挂载至顶级企业节点）
INSERT INTO departments (id, name, parent_id, level, sort_order)
VALUES
    ('de000000-0000-4000-8000-000000000002', '租务部',     'de000000-0000-4000-8000-000000000001', 2, 10),
    ('de000000-0000-4000-8000-000000000003', '财务部',     'de000000-0000-4000-8000-000000000001', 2, 20),
    ('de000000-0000-4000-8000-000000000004', '物业运营部', 'de000000-0000-4000-8000-000000000001', 2, 30)
ON CONFLICT (id) DO NOTHING;

-- 超级管理员（首次登录后必须修改密码）
INSERT INTO users (id, name, email, password_hash, role, is_active)
VALUES (
    'f0000000-0000-4000-8000-000000000001',
    '系统管理员',
    :'admin_email',
    :'admin_password_hash',
    'super_admin',
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- KPI 指标库 K01-K14
INSERT INTO kpi_metric_definitions
    (id, code, name, category,
     default_full_score_threshold, default_pass_threshold, default_fail_threshold,
     higher_is_better, direction, source_module, is_manual_input)
VALUES
    ('cc000000-0000-4000-8000-000000000001', 'K01', '出租率',           'leasing', 0.95, 0.80, 0.60, TRUE,  'positive', 'assets',     FALSE),
    ('cc000000-0000-4000-8000-000000000002', 'K02', '收款及时率',        'finance', 0.95, 0.85, 0.70, TRUE,  'positive', 'finance',    FALSE),
    ('cc000000-0000-4000-8000-000000000003', 'K03', '租户集中度',        'leasing', 0.40, 0.55, 0.70, FALSE, 'negative', 'contracts',  FALSE),
    ('cc000000-0000-4000-8000-000000000004', 'K04', '续约率',            'leasing', 0.80, 0.60, 0.40, TRUE,  'positive', 'contracts',  FALSE),
    ('cc000000-0000-4000-8000-000000000005', 'K05', '工单响应时效',      'service', 24,   48,   72,   FALSE, 'negative', 'workorders', FALSE),
    ('cc000000-0000-4000-8000-000000000006', 'K06', '空置周转天数',      'leasing', 30,   60,   90,   FALSE, 'negative', 'assets',     FALSE),
    ('cc000000-0000-4000-8000-000000000007', 'K07', 'NOI 达成率',        'finance', 1.00, 0.85, 0.70, TRUE,  'positive', 'finance',    FALSE),
    ('cc000000-0000-4000-8000-000000000008', 'K08', '逾期率',            'finance', 0.05, 0.15, 0.20, FALSE, 'negative', 'finance',    FALSE),
    ('cc000000-0000-4000-8000-000000000009', 'K09', '租金递增执行率',    'leasing', 0.95, 0.85, 0.70, TRUE,  'positive', 'contracts',  FALSE),
    ('cc000000-0000-4000-8000-000000000010', 'K10', '租户满意度',        'service', 90,   75,   60,   TRUE,  'positive', 'workorders', TRUE),
    ('cc000000-0000-4000-8000-000000000011', 'K11', '预防性维修率',      'service', 0.90, 0.70, 0.50, TRUE,  'positive', 'workorders', FALSE),
    ('cc000000-0000-4000-8000-000000000012', 'K12', '空置面积降幅',      'growth',  0.20, 0.10, 0,    TRUE,  'positive', 'assets',     FALSE),
    ('cc000000-0000-4000-8000-000000000013', 'K13', '新签约面积',        'growth',  2000, 1000, 500,  TRUE,  'positive', 'contracts',  FALSE),
    ('cc000000-0000-4000-8000-000000000014', 'K14', '续签率',            'leasing', 0.80, 0.60, 0.40, TRUE,  'positive', 'contracts',  FALSE)
ON CONFLICT (id) DO NOTHING;

COMMIT;
