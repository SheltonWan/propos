-- =============================================================================
-- Migration: 001_create_enums
-- Description: 创建所有 PostgreSQL 自定义枚举类型
--   包含 v1.5 / v1.7 / v1.8 全部 ENUM，直接以最终状态建立，无需增量 ALTER。
-- =============================================================================

BEGIN;

-- 物业业态
CREATE TYPE property_type AS ENUM (
    'office',     -- 写字楼
    'retail',     -- 商铺
    'apartment'   -- 公寓
);

-- 单元出租状态（含 v1.5 新增值 renovating / pre_lease）
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

-- 用户角色（v2.0 最终值，含 property_inspector / report_viewer）
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

-- 计租模型（v1.5）
CREATE TYPE pricing_model AS ENUM (
    'area',     -- 按面积计租（元/m²/月），单元级单价在 contract_units
    'flat',     -- 整套月租，base_monthly_rent 即总租金
    'revenue'   -- 保底+分成，配合 min_guarantee_rent / revenue_share_rate
);

-- 租金递增类型
CREATE TYPE escalation_type AS ENUM (
    'fixed_rate',             -- 固定比例递增
    'fixed_amount',           -- 固定金额递增（元/m²/月）
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

-- 运营支出类目（v1.8 新增 professional_service）
CREATE TYPE expense_category AS ENUM (
    'utility_common',       -- 水电公摊
    'outsourced_property',  -- 外包物业费
    'repair',               -- 维修费
    'insurance',            -- 保险
    'tax',                  -- 税金
    'professional_service', -- 专业服务费（消防检测/电梯年检等）
    'other'                 -- 其他
);

-- 工单费用性质（v1.8）
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

-- 子租赁审核状态（含 draft 草稿值）
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

-- KPI 方案状态（v1.5 替换原 is_active BOOLEAN）
CREATE TYPE kpi_scheme_status AS ENUM (
    'draft',     -- 草稿
    'active',    -- 生效中
    'archived'   -- 已归档
);

-- KPI 指标分类（v1.5）
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
    'monthly',   -- 每月
    'bimonthly'  -- 每两月
);

-- 营业额申报审核状态
CREATE TYPE turnover_approval_status AS ENUM (
    'pending',   -- 待审核
    'approved',  -- 已通过
    'rejected'   -- 已退回
);

-- 导入数据类别
CREATE TYPE import_data_type AS ENUM (
    'units',      -- 单元台账
    'contracts',  -- 合同数据
    'invoices'    -- 账单数据
);

-- 导入回滚状态
CREATE TYPE import_rollback_status AS ENUM (
    'committed',    -- 已提交入库
    'rolled_back'   -- 已回滚
);

-- 信用评级（A/B/C/D 四级）
CREATE TYPE credit_rating AS ENUM ('A', 'B', 'C', 'D');

-- 通知类型（v1.7）
CREATE TYPE notification_type AS ENUM (
    'contract_expiring',   -- 合同即将到期
    'invoice_overdue',     -- 账单逾期
    'workorder_assigned',  -- 工单已派单
    'workorder_completed', -- 工单已完成
    'approval_pending',    -- 待审批
    'system_alert',        -- 系统预警
    'kpi_published'        -- KPI 成绩已发布
);

-- 通知严重级别（v1.7）
CREATE TYPE notification_severity AS ENUM (
    'info',      -- 信息
    'warning',   -- 警告
    'critical'   -- 严重
);

-- 催收方式（v1.7）
CREATE TYPE dunning_method AS ENUM (
    'phone',   -- 电话催收
    'sms',     -- 短信催收
    'letter',  -- 函件催收
    'visit',   -- 上门催收
    'legal'    -- 法务催收
);

-- 审批类型（v1.7）
CREATE TYPE approval_type AS ENUM (
    'contract_termination', -- 合同终止
    'deposit_refund',       -- 押金退还
    'invoice_adjustment',   -- 账单调整
    'sublease_submission'   -- 子租赁提交
);

-- 审批状态（v1.7）
CREATE TYPE approval_status AS ENUM (
    'pending',   -- 待审批
    'approved',  -- 已通过
    'rejected'   -- 已拒绝
);

-- 续约意向（v1.7）
CREATE TYPE renewal_intent AS ENUM (
    'willing',    -- 愿意续租
    'undecided',  -- 未决定
    'unwilling'   -- 不续租
);

COMMIT;
