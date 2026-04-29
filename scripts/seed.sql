-- =============================================================================
-- PropOS Seed Data v1.1 — 全量集成测试数据集
-- 对应: SEED_DATA_SPEC.md v1.1 / data_model.md v1.5 / API_CONTRACT v1.7
-- 用途: 开发自测、API 联调、集成测试、WALE/NOI/KPI 验算
-- 执行方式: psql -U propos -d propos -f scripts/seed.sql
-- 执行前提: 已完成全部 DDL 迁移 (MIGRATION_DRAFT v1.7)
-- 安全说明: id_number/phone 字段使用 PLACEHOLDER_ENCRYPTED_值 占位，
--            生产环境必须替换为真实 AES-256-GCM 密文
-- =============================================================================

BEGIN;

DO $$
DECLARE
    -- =====================================================================
    -- Departments (6) — de 前缀
    -- =====================================================================
    v_dept_root         UUID := 'de000000-0000-4000-8000-000000000001'; -- D-ROOT  旭联实业
    v_dept_lease        UUID := 'de000000-0000-4000-8000-000000000002'; -- D-LEASE 租务部
    v_dept_fin          UUID := 'de000000-0000-4000-8000-000000000003'; -- D-FIN   财务部
    v_dept_ops          UUID := 'de000000-0000-4000-8000-000000000004'; -- D-OPS   物业运营部
    v_dept_lease_office UUID := 'de000000-0000-4000-8000-000000000005'; -- D-LEASE-OFFICE 写字楼组
    v_dept_lease_apt    UUID := 'de000000-0000-4000-8000-000000000006'; -- D-LEASE-APT   公寓组

    -- =====================================================================
    -- Users (8) — f0 前缀
    -- =====================================================================
    v_user_admin   UUID := 'f0000000-0000-4000-8000-000000000001'; -- U-ADMIN   管理员
    v_user_mgr     UUID := 'f0000000-0000-4000-8000-000000000002'; -- U-MGR     陈经理
    v_user_lease   UUID := 'f0000000-0000-4000-8000-000000000003'; -- U-LEASE   王五
    v_user_fin     UUID := 'f0000000-0000-4000-8000-000000000004'; -- U-FIN     李财务
    v_user_front   UUID := 'f0000000-0000-4000-8000-000000000005'; -- U-MAINT   赵师傅
    v_user_insp    UUID := 'f0000000-0000-4000-8000-000000000007'; -- U-INSP    周楼管
    v_user_view    UUID := 'f0000000-0000-4000-8000-000000000008'; -- U-VIEW    钱投资
    v_user_sublord UUID := 'f0000000-0000-4000-8000-000000000006'; -- U-SUBLORD 鼎盛物业
    v_user_wxt    UUID := 'f0000000-0000-4000-8000-000000000009'; -- U-WXT     万小通（超级管理员，电话: 19520723980）

    -- =====================================================================
    -- Buildings (3) — a0 前缀
    -- =====================================================================
    v_bld_office UUID := 'a0000000-0000-4000-8000-000000000001'; -- B-OFFICE 融创智汇大厦A座
    v_bld_retail UUID := 'a0000000-0000-4000-8000-000000000002'; -- B-RETAIL 商铺区
    v_bld_apt    UUID := 'a0000000-0000-4000-8000-000000000003'; -- B-APT    公寓楼

    -- =====================================================================
    -- Floors (11) — b0 前缀
    -- =====================================================================
    v_flr_o_b1  UUID := 'b0000000-0000-4000-8000-000000000001'; -- 融创智汇大厦A座 B1
    v_flr_o_1f  UUID := 'b0000000-0000-4000-8000-000000000002'; -- 融创智汇大厦A座 1F
    v_flr_o_6f  UUID := 'b0000000-0000-4000-8000-000000000003'; -- 融创智汇大厦A座 6F（首个有SVG楼层）
    v_flr_o_10f UUID := 'b0000000-0000-4000-8000-000000000004'; -- 融创智汇大厦A座 10F
    v_flr_o_22f UUID := 'b0000000-0000-4000-8000-000000000005'; -- 融创智汇大厦A座 22F（顶层/SVG覆盖至22F）
    v_flr_r_1f  UUID := 'b0000000-0000-4000-8000-000000000006'; -- 商铺区 1F
    v_flr_r_2f  UUID := 'b0000000-0000-4000-8000-000000000007'; -- 商铺区 2F
    v_flr_a_1f  UUID := 'b0000000-0000-4000-8000-000000000008'; -- 公寓楼 1F
    v_flr_a_3f  UUID := 'b0000000-0000-4000-8000-000000000009'; -- 公寓楼 3F
    v_flr_a_5f  UUID := 'b0000000-0000-4000-8000-000000000010'; -- 公寓楼 5F
    v_flr_a_8f  UUID := 'b0000000-0000-4000-8000-000000000011'; -- 公寓楼 8F

    -- =====================================================================
    -- Units (15 spec + 3 sublease virtual sub-units) — c0 前缀
    -- =====================================================================
    -- Office
    v_unit_10a    UUID := 'c0000000-0000-4000-8000-000000000001';
    v_unit_10b    UUID := 'c0000000-0000-4000-8000-000000000002';
    v_unit_10c    UUID := 'c0000000-0000-4000-8000-000000000003';
    v_unit_20a    UUID := 'c0000000-0000-4000-8000-000000000004';
    v_unit_lobby  UUID := 'c0000000-0000-4000-8000-000000000005'; -- 1-LOBBY 非可租
    -- Retail
    v_unit_s101   UUID := 'c0000000-0000-4000-8000-000000000006';
    v_unit_s102   UUID := 'c0000000-0000-4000-8000-000000000007';
    v_unit_s103   UUID := 'c0000000-0000-4000-8000-000000000008';
    v_unit_s201   UUID := 'c0000000-0000-4000-8000-000000000009';
    v_unit_scomm  UUID := 'c0000000-0000-4000-8000-000000000010'; -- S-COMMON 非可租
    -- Apartment
    v_unit_a301   UUID := 'c0000000-0000-4000-8000-000000000011';
    v_unit_a302   UUID := 'c0000000-0000-4000-8000-000000000012';
    v_unit_a303   UUID := 'c0000000-0000-4000-8000-000000000013';
    v_unit_a501   UUID := 'c0000000-0000-4000-8000-000000000014';
    v_unit_aelec  UUID := 'c0000000-0000-4000-8000-000000000015'; -- A-ELEC 非可租
    -- 2201 虚拟子单元（用于 subleases 行级隔离，避免触发 uq_sublease_active_unit）
    v_unit_20a01  UUID := 'c0000000-0000-4000-8000-000000000016'; -- 2201-01 旭日软件 100m²
    v_unit_20a02  UUID := 'c0000000-0000-4000-8000-000000000017'; -- 2201-02 星光广告  72m²
    v_unit_20a03  UUID := 'c0000000-0000-4000-8000-000000000018'; -- 2201-03 空置      268m²

    -- =====================================================================
    -- Tenants (6) — d0 前缀
    -- =====================================================================
    v_t_corp_a   UUID := 'd0000000-0000-4000-8000-000000000001'; -- T-CORP-A 明辉科技
    v_t_corp_b   UUID := 'd0000000-0000-4000-8000-000000000002'; -- T-CORP-B 百恒传媒
    v_t_corp_c   UUID := 'd0000000-0000-4000-8000-000000000003'; -- T-CORP-C 聚鑫餐饮
    v_t_ind_d    UUID := 'd0000000-0000-4000-8000-000000000004'; -- T-IND-D  张三
    v_t_sublord  UUID := 'd0000000-0000-4000-8000-000000000005'; -- T-SUBLORD 鼎盛物业
    v_t_corp_d   UUID := 'd0000000-0000-4000-8000-000000000006'; -- T-CORP-D 恒通贸易

    -- =====================================================================
    -- Contracts (4) — e0 前缀
    -- =====================================================================
    v_c_office UUID := 'e0000000-0000-4000-8000-000000000001'; -- C-OFFICE-01
    v_c_retail UUID := 'e0000000-0000-4000-8000-000000000002'; -- C-RETAIL-01
    v_c_apt    UUID := 'e0000000-0000-4000-8000-000000000003'; -- C-APT-01
    v_c_sub    UUID := 'e0000000-0000-4000-8000-000000000004'; -- C-SUB-MASTER

    -- =====================================================================
    -- Suppliers (3) — ab 前缀
    -- =====================================================================
    v_sup_001 UUID := 'ab000000-0000-4000-8000-000000000001'; -- SUP-001 顺达空调
    v_sup_002 UUID := 'ab000000-0000-4000-8000-000000000002'; -- SUP-002 鼎盛水电
    v_sup_003 UUID := 'ab000000-0000-4000-8000-000000000003'; -- SUP-003 安居锁业

    -- =====================================================================
    -- Deposits (4) — ad 前缀
    -- =====================================================================
    v_dep_001 UUID := 'ad000000-0000-4000-8000-000000000001'; -- DEP-001
    v_dep_002 UUID := 'ad000000-0000-4000-8000-000000000002'; -- DEP-002
    v_dep_003 UUID := 'ad000000-0000-4000-8000-000000000003'; -- DEP-003
    v_dep_004 UUID := 'ad000000-0000-4000-8000-000000000004'; -- DEP-004

    -- =====================================================================
    -- Invoices (8) — af 前缀
    -- =====================================================================
    v_inv_001 UUID := 'af000000-0000-4000-8000-000000000001'; -- INV-001 C-OFFICE 07租金
    v_inv_002 UUID := 'af000000-0000-4000-8000-000000000002'; -- INV-002 C-OFFICE 07物管
    v_inv_003 UUID := 'af000000-0000-4000-8000-000000000003'; -- INV-003 C-RETAIL 07租金
    v_inv_004 UUID := 'af000000-0000-4000-8000-000000000004'; -- INV-004 C-APT    07租金(逾期)
    v_inv_005 UUID := 'af000000-0000-4000-8000-000000000005'; -- INV-005 C-OFFICE 06免租折算
    v_inv_006 UUID := 'af000000-0000-4000-8000-000000000006'; -- INV-006 C-RETAIL 03免租
    v_inv_007 UUID := 'af000000-0000-4000-8000-000000000007'; -- INV-007 C-RETAIL 04免租
    v_inv_008 UUID := 'af000000-0000-4000-8000-000000000008'; -- INV-008 C-RETAIL 05免租

    -- =====================================================================
    -- Payments (3) — 9a 前缀
    -- =====================================================================
    v_pay_001 UUID := '9a000000-0000-4000-8000-000000000001'; -- PAY-001
    v_pay_002 UUID := '9a000000-0000-4000-8000-000000000002'; -- PAY-002
    v_pay_003 UUID := '9a000000-0000-4000-8000-000000000003'; -- PAY-003

    -- =====================================================================
    -- Work Orders (6) — bf 前缀
    -- =====================================================================
    v_wo_001 UUID := 'bf000000-0000-4000-8000-000000000001'; -- WO-001 空调维修
    v_wo_002 UUID := 'bf000000-0000-4000-8000-000000000002'; -- WO-002 水管漏水
    v_wo_003 UUID := 'bf000000-0000-4000-8000-000000000003'; -- WO-003 门锁更换
    v_wo_004 UUID := 'bf000000-0000-4000-8000-000000000004'; -- WO-004 环境噪音投诉
    v_wo_005 UUID := 'bf000000-0000-4000-8000-000000000005'; -- WO-005 公区卫生投诉
    v_wo_006 UUID := 'bf000000-0000-4000-8000-000000000006'; -- WO-006 合同到期验房

    -- =====================================================================
    -- KPI Metric Definitions (10) — cc 前缀
    -- =====================================================================
    v_km_k01 UUID := 'cc000000-0000-4000-8000-000000000001'; -- K01 出租率
    v_km_k02 UUID := 'cc000000-0000-4000-8000-000000000002'; -- K02 收款及时率
    v_km_k03 UUID := 'cc000000-0000-4000-8000-000000000003'; -- K03 租户集中度
    v_km_k04 UUID := 'cc000000-0000-4000-8000-000000000004'; -- K04 续约率
    v_km_k05 UUID := 'cc000000-0000-4000-8000-000000000005'; -- K05 工单响应时效
    v_km_k06 UUID := 'cc000000-0000-4000-8000-000000000006'; -- K06 空置周转天数
    v_km_k07 UUID := 'cc000000-0000-4000-8000-000000000007'; -- K07 NOI达成率
    v_km_k08 UUID := 'cc000000-0000-4000-8000-000000000008'; -- K08 逾期率
    v_km_k09 UUID := 'cc000000-0000-4000-8000-000000000009'; -- K09 租金递增执行率
    v_km_k10 UUID := 'cc000000-0000-4000-8000-000000000010'; -- K10 租户满意度

    -- =====================================================================
    -- KPI Schemes (2) — cd 前缀
    -- =====================================================================
    v_ks_001 UUID := 'cd000000-0000-4000-8000-000000000001'; -- KS-001 租务部考核方案2026Q3
    v_ks_002 UUID := 'cd000000-0000-4000-8000-000000000002'; -- KS-002 全员月度试行

    -- KPI Snapshot — ce 前缀
    v_snap_001 UUID := 'ce000000-0000-4000-8000-000000000001'; -- SNAP-001

    -- NOI Budget — cf 前缀
    v_noi_bud_001 UUID := 'cf000000-0000-4000-8000-000000000001'; -- BUD-001

    -- Subleases (3) — eb 前缀
    v_sl_001 UUID := 'eb000000-0000-4000-8000-000000000001'; -- SL-001 旭日软件
    v_sl_002 UUID := 'eb000000-0000-4000-8000-000000000002'; -- SL-002 星光广告
    v_sl_003 UUID := 'eb000000-0000-4000-8000-000000000003'; -- SL-003 空置

BEGIN

-- ==========================================================================
-- §1  组织架构（departments）— 6 条，三级组织树
-- ==========================================================================
-- is_active 有 DDL 默认值 TRUE，无需显式插入
INSERT INTO departments (id, name, parent_id, level, sort_order)
VALUES
    (v_dept_root,         '旭联实业', NULL,           1, 1),
    (v_dept_lease,        '租务部',           v_dept_root,    2, 1),
    (v_dept_fin,          '财务部',           v_dept_root,    2, 2),
    (v_dept_ops,          '物业运营部',       v_dept_root,    2, 3),
    (v_dept_lease_office, '写字楼组',         v_dept_lease,   3, 1),
    (v_dept_lease_apt,    '公寓组',           v_dept_lease,   3, 2)
-- 019 已预置 v_dept_lease/fin/ops（parent_id=NULL），此处 UPDATE 补充父节点
ON CONFLICT (id) DO UPDATE SET
    parent_id  = EXCLUDED.parent_id,
    level      = EXCLUDED.level,
    sort_order = EXCLUDED.sort_order;

-- ==========================================================================
-- §2  用户（users）— 8 条
-- 密码统一为 'Propos2026!' 的 bcrypt hash（cost=10，开发占位）
-- 生产环境必须使用 cost≥12 的真实 hash 替换
-- bound_contract_id 在合同插入后通过 UPDATE 设置（规避临时循环依赖）
-- ==========================================================================
INSERT INTO users (id, name, email, password_hash, role, department_id, is_active, session_version)
VALUES
    (v_user_admin,   '管理员',           'admin@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'super_admin', v_dept_root, TRUE, 1),
    (v_user_mgr,     '陈经理',           'chen.mgr@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'operations_manager', v_dept_ops, TRUE, 1),
    (v_user_lease,   '王五',             'wang.lease@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'leasing_specialist', v_dept_lease_office, TRUE, 1),
    (v_user_fin,     '李财务',           'li.fin@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'finance_staff', v_dept_fin, TRUE, 1),
    (v_user_front,   '赵师傅',           'zhao.maint@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'maintenance_staff', v_dept_ops, TRUE, 1),
    (v_user_insp,    '周楼管',           'zhou.insp@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'property_inspector', v_dept_ops, TRUE, 1),
    (v_user_view,    '钱投资',           'qian.viewer@propos.local',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'report_viewer', v_dept_root, TRUE, 1),
    (v_user_sublord, '鼎盛物业有限公司', 'dingsheng@external.com',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'sub_landlord', NULL, TRUE, 1),
    -- 万小通 | 超级管理员 | 电话: 19520723980
    (v_user_wxt,     '万小通',           'smartv@qq.com',
     '$2a$10$YKdJkBpVBhzRnzJeA7EBOe8Klfyr0YgmGq3aTxMm3B3fjkuoF9NOC',
     'super_admin', v_dept_root, TRUE, 1)
-- v_user_admin 已由 019 用相同 UUID 预置，其余用户为 seed.sql 新增
ON CONFLICT (id) DO NOTHING;

-- ==========================================================================
-- §3  供应商（suppliers）— 3 条，先于工单插入
-- [安全] contact_phone 字段应存储 AES-256-GCM 密文，开发环境以原文占位
-- ==========================================================================
INSERT INTO suppliers (id, name, category, contact_name, contact_phone, is_active)
VALUES
    (v_sup_001, '顺达空调服务公司',   '空调维修', '张技工', '13800110001', TRUE),
    (v_sup_002, '鼎盛水电工程公司',   '水电维修', '李师傅', '13700220002', TRUE),
    (v_sup_003, '安居锁业有限公司',   '门锁安防', '王师傅', '13600330003', TRUE);

-- ==========================================================================
-- §4  楼栋（buildings）— 3 条
-- ==========================================================================
-- DDL 字段: gfa(建筑面积), nla(可租面积), address(NOT NULL)
INSERT INTO buildings (id, name, property_type, total_floors, gfa, nla, address)
VALUES
    (v_bld_office, '融创智汇大厦A座', 'office', 22, 30000.00, 25500.00, '深圳市南山区科苑路8号融创智汇大厦A座'),
    (v_bld_retail, '商铺区', 'retail',    2,  2707.00,  2300.00, '深圳市南山区科苑路8号商铺区'),
    (v_bld_apt,    '公寓楼', 'apartment', 8,  7300.00,  6200.00, '深圳市南山区科苑路8号公寓楼');

-- ==========================================================================
-- §5  楼层（floors）— 11 条（含三栋楼代表性楼层；融创智汇大厦A座 SVG 仅覆盖 6F-22F）
-- svg_path/png_path 由 CAD 转换工具写入，此处为 NULL 占位（需 UPDATE 填充）
-- ==========================================================================
-- DDL 字段: nla(楼层可租面积), floor_name(楼层名称如1F/B1)
INSERT INTO floors (id, building_id, floor_number, floor_name, nla)
VALUES
    -- 融创智汇大厦A座（B1设备层无NLA，1F大堂，6F/10F/22F为SVG代表楼层，共22层）
    (v_flr_o_b1,  v_bld_office, -1, 'B1',  NULL),
    (v_flr_o_1f,  v_bld_office,  1, '1F',  1200.00),
    (v_flr_o_6f,  v_bld_office,  6, '6F',  1350.00),
    (v_flr_o_10f, v_bld_office, 10, '10F', 1350.00),
    (v_flr_o_22f, v_bld_office, 22, '22F', 1200.00),
    -- 商铺区
    (v_flr_r_1f,  v_bld_retail,  1, '1F',  1150.00),
    (v_flr_r_2f,  v_bld_retail,  2, '2F',  1150.00),
    -- 公寓楼（1F 机房/管理室无平面图，3F/5F/8F 为住宅层）
    (v_flr_a_1f,  v_bld_apt,     1, '1F',  750.00),
    (v_flr_a_3f,  v_bld_apt,     3, '3F',  780.00),
    (v_flr_a_5f,  v_bld_apt,     5, '5F',  780.00),
    (v_flr_a_8f,  v_bld_apt,     8, '8F',  750.00);

-- ==========================================================================
-- §6  单元（units）— 15 spec + 3 虚拟子单元 = 18 条
-- [安全] 非可租单元标记 is_leasable=FALSE，防止误开合同
-- ==========================================================================
-- DDL 字段映射: unit_number(单元号), decoration_status(装修), current_status(状态)
-- property_type NOT NULL，按楼栋业态填入
INSERT INTO units (id, floor_id, building_id, unit_number,
                   gross_area, net_area,
                   decoration_status, current_status,
                   market_rent_reference, property_type)
VALUES
    -- 写字楼单元
    (v_unit_10a,   v_flr_o_10f, v_bld_office, '1001',
     320.00, 280.00, 'refined',  'leased',       120.00, 'office'),
    (v_unit_10b,   v_flr_o_10f, v_bld_office, '1002',
     160.00, 140.00, 'simple',   'leased',       110.00, 'office'),
    (v_unit_10c,   v_flr_o_10f, v_bld_office, '1003',
     85.00,  72.00,  'blank',    'vacant',        95.00, 'office'),
    (v_unit_20a,   v_flr_o_22f, v_bld_office, '2201',
     500.00, 440.00, 'refined',  'leased',       135.00, 'office'),
    (v_unit_lobby, v_flr_o_1f,  v_bld_office, '1-LOBBY',
     200.00, NULL,   'refined',  'non_leasable',   NULL, 'office'),
    -- 商铺单元
    (v_unit_s101,  v_flr_r_1f,  v_bld_retail, 'S101',
     120.00, 108.00, 'refined',  'leased',       250.00, 'retail'),
    (v_unit_s102,  v_flr_r_1f,  v_bld_retail, 'S102',
     80.00,  72.00,  'simple',   'vacant',       200.00, 'retail'),
    (v_unit_s103,  v_flr_r_1f,  v_bld_retail, 'S103',
     200.00, 180.00, 'blank',    'vacant',       280.00, 'retail'),
    (v_unit_s201,  v_flr_r_2f,  v_bld_retail, 'S201',
     150.00, 135.00, 'simple',   'vacant',       150.00, 'retail'),
    (v_unit_scomm, v_flr_r_1f,  v_bld_retail, 'S-COMMON',
     50.00,  NULL,   'refined',  'non_leasable',   NULL, 'retail'),
    -- 公寓单元
    (v_unit_a301,  v_flr_a_3f,  v_bld_apt,    'A301',
     45.00,  38.00,  'refined',  'vacant',      3500.00, 'apartment'),
    (v_unit_a302,  v_flr_a_3f,  v_bld_apt,    'A302',
     65.00,  55.00,  'refined',  'leased',      5200.00, 'apartment'),
    (v_unit_a303,  v_flr_a_3f,  v_bld_apt,    'A303',
     35.00,  28.00,  'simple',   'vacant',      2800.00, 'apartment'),
    (v_unit_a501,  v_flr_a_5f,  v_bld_apt,    'A501',
     90.00,  78.00,  'refined',  'vacant',      7500.00, 'apartment'),
    (v_unit_aelec, v_flr_a_1f,  v_bld_apt,    'A-ELEC',
     15.00,  NULL,   'raw',      'non_leasable',   NULL, 'apartment'),
    -- 2201 虚拟子单元（二房东拆分转租，PropOS 不直接管理出租）
    (v_unit_20a01, v_flr_o_22f, v_bld_office, '2201-01',
     100.00, 88.00,  'refined',  'non_leasable',   NULL, 'office'),
    (v_unit_20a02, v_flr_o_22f, v_bld_office, '2201-02',
     72.00,  64.00,  'refined',  'non_leasable',   NULL, 'office'),
    (v_unit_20a03, v_flr_o_22f, v_bld_office, '2201-03',
     268.00, 236.00, 'blank',    'non_leasable',   NULL, 'office');

-- ==========================================================================
-- §7  租客（tenants）— 6 条
-- [安全] id_number_encrypted / contact_phone_encrypted 使用开发占位值
--         生产环境必须替换为真实 AES-256-GCM (base64) 密文
-- ==========================================================================
-- DDL 字段: name(租客名称，非 display_name), 无 overdue_count 字段
INSERT INTO tenants (id, tenant_type, name,
                     id_number_encrypted, contact_phone_encrypted,
                     contact_person, credit_rating)
VALUES
    (v_t_corp_a, 'corporate', '明辉科技有限公司',
     'PLACEHOLDER_ENC_91440300MA5FKJ1234', 'PLACEHOLDER_ENC_13800001111',
     '王经理', 'A'),
    (v_t_corp_b, 'corporate', '百恒传媒有限公司',
     'PLACEHOLDER_ENC_91440300MA5GHK5678', 'PLACEHOLDER_ENC_13900002222',
     '李总', 'B'),
    (v_t_corp_c, 'corporate', '聚鑫餐饮连锁有限公司',
     'PLACEHOLDER_ENC_91440300MA5JLN9012', 'PLACEHOLDER_ENC_13700003333',
     '陈店长', 'A'),
    (v_t_ind_d,  'individual', '张三',
     'PLACEHOLDER_ENC_440305199001011234', 'PLACEHOLDER_ENC_13600004444',
     '张三', 'B'),
    (v_t_sublord,'corporate', '鼎盛物业管理有限公司',
     'PLACEHOLDER_ENC_91440300MA5ABC3456', 'PLACEHOLDER_ENC_13500005555',
     '赵总', 'A'),
    -- T-CORP-D: 恒通贸易有限公司，信用等级 D（高风险，暂无合同）
    (v_t_corp_d, 'corporate', '恒通贸易有限公司',
     'PLACEHOLDER_ENC_91440300MA5XYZ7890', 'PLACEHOLDER_ENC_13400006666',
     '周总', 'D');

-- ==========================================================================
-- §8  合同（contracts）— 4 条（含 WALE/NOI 验算基准数据）
-- ==========================================================================
-- DDL 无: property_type / payment_cycle_months / management_fee_rate /
--         revenue_share_enabled / created_by
-- responsible_user_id 对应 created_by 语义（可选）
INSERT INTO contracts (id, contract_no, tenant_id, status,
                       pricing_model,
                       start_date, end_date, free_rent_days, free_rent_end_date,
                       base_monthly_rent,
                       deposit_months, deposit_amount,
                       tax_inclusive, applicable_tax_rate,
                       min_guarantee_rent, revenue_share_rate,
                       is_sublease_master, responsible_user_id)
VALUES
    -- C-OFFICE-01: 明辉科技 写字楼 双单元（1001+1002）季付 +5%递增
    (v_c_office, 'HT-2025-OFFICE-001', v_t_corp_a, 'active',
     'area',
     '2025-06-01', '2028-05-31', 14, '2025-06-14',
     45500.00,
     3, 136500.00,
     FALSE, 0.0900,
     NULL, NULL,
     FALSE, v_user_lease),
    -- C-RETAIL-01: 聚鑫餐饮 商铺 保底+8%分成 免租3个月（pricing_model='revenue'）
    (v_c_retail, 'HT-2025-RETAIL-001', v_t_corp_c, 'active',
     'revenue',
     '2025-03-01', '2028-02-28', 92, '2025-05-31',
     24840.00,
     6, 149040.00,
     FALSE, 0.0500,
     24840.00, 0.0800,
     FALSE, v_user_lease),
    -- C-APT-01: 张三 公寓 整套月租 含税 无递增（pricing_model='flat'）
    (v_c_apt, 'HT-2025-APT-001', v_t_ind_d, 'active',
     'flat',
     '2025-07-01', '2026-06-30', 0, NULL,
     4761.90,
     2, 10000.00,
     TRUE, 0.0500,
     NULL, NULL,
     FALSE, v_user_lease),
    -- C-SUB-MASTER: 鼎盛物业 二房东整租 2201 2+8%递增
    (v_c_sub, 'HT-2024-OFFICE-SUB-001', v_t_sublord, 'active',
     'area',
     '2024-01-01', '2029-12-31', 0, NULL,
     41800.00,
     6, 250800.00,
     FALSE, 0.0900,
     NULL, NULL,
     TRUE, v_user_lease);

-- ==========================================================================
-- §9  合同-单元关联（contract_units）— 5 条
-- 注意: C-APT-01 公寓整套月租，unit_price 取不含税月租÷计费面积 (4761.90÷55=86.58)
-- ==========================================================================
-- DDL 字段: billing_area_snapshot(非 billing_area)
INSERT INTO contract_units (contract_id, unit_id, unit_price, billing_area_snapshot)
VALUES
    (v_c_office, v_unit_10a,  110.00, 280.00), -- 明辉科技 1001 280m² @110
    (v_c_office, v_unit_10b,  105.00, 140.00), -- 明辉科技 1002 140m² @105
    (v_c_retail, v_unit_s101, 230.00, 108.00), -- 聚鑫餐饮 S101 108m² @230(保底基准)
    (v_c_apt,    v_unit_a302,  86.58,  55.00), -- 张三 A302 整套，单价=4761.90÷55
    (v_c_sub,    v_unit_20a,   95.00, 440.00); -- 鼎盛物业 2201 440m² @95

-- ==========================================================================
-- §10  租金递增阶段（rent_escalation_phases）— 8 条
-- C-APT-01 短租不设递增
-- ==========================================================================
INSERT INTO rent_escalation_phases (id, contract_id, phase_seq,
                                    effective_from, effective_to,
                                    escalation_type, rate, fixed_amount)
VALUES
    -- C-OFFICE-01 混合分段：阶段1 免租后基准（月0-24）+ 阶段2 固定+5%（月24-36）
    ('6d000000-0000-4000-8000-000000000001', v_c_office, 1,
     '2025-06-01', '2027-05-31', 'base_after_free_period', NULL, NULL),
    ('6d000000-0000-4000-8000-000000000002', v_c_office, 2,
     '2027-06-01', '2028-05-31', 'fixed_rate', 0.050000, NULL),
    -- C-RETAIL-01 阶梯式三段（保底单价递增，fixed_amount 存阶段基准单价）
    ('6d000000-0000-4000-8000-000000000003', v_c_retail, 1,
     '2025-03-01', '2026-02-28', 'step', NULL, 230.00),
    ('6d000000-0000-4000-8000-000000000004', v_c_retail, 2,
     '2026-03-01', '2027-02-28', 'step', NULL, 250.00),
    ('6d000000-0000-4000-8000-000000000005', v_c_retail, 3,
     '2027-03-01', '2028-02-28', 'step', NULL, 270.00),
    -- C-SUB-MASTER 每2年递增8%
    ('6d000000-0000-4000-8000-000000000006', v_c_sub, 1,
     '2024-01-01', '2025-12-31', 'base_after_free_period', NULL, NULL),
    ('6d000000-0000-4000-8000-000000000007', v_c_sub, 2,
     '2026-01-01', '2027-12-31', 'periodic', 0.080000, NULL),
    ('6d000000-0000-4000-8000-000000000008', v_c_sub, 3,
     '2028-01-01', '2029-12-31', 'periodic', 0.080000, NULL);

-- ==========================================================================
-- §11  押金（deposits）— 4 条
-- ==========================================================================
-- DDL 字段: deposit_amount(合同约定额) + paid_amount(实收); 无 amount / created_by
INSERT INTO deposits (id, contract_id, deposit_amount, paid_amount, collected_date, status)
VALUES
    (v_dep_001, v_c_office, 136500.00, 136500.00, '2025-06-01', 'collected'),
    (v_dep_002, v_c_retail, 149040.00, 149040.00, '2025-03-01', 'collected'),
    (v_dep_003, v_c_apt,     10000.00,  10000.00, '2025-07-01', 'collected'),
    (v_dep_004, v_c_sub,    250800.00, 250800.00, '2024-01-01', 'collected');

-- ==========================================================================
-- §12  押金流水（deposit_transactions）— 4 条
-- 所有记录均为初始收取（collection），previous_status 与 new_status 均为 collected
-- （押金首次入账时无前续状态，使用 collected 表示已入账）
-- ==========================================================================
INSERT INTO deposit_transactions (id, deposit_id, transaction_type,
                                   amount, transaction_date,
                                   notes, created_by, created_at)
VALUES
    ('ae000000-0000-4000-8000-000000000001',
     v_dep_001, 'collect', 136500.00, '2025-06-01',
     'C-OFFICE-01 签约时收取押金（3个月）', v_user_lease, '2025-06-01 09:00:00+08'),
    ('ae000000-0000-4000-8000-000000000002',
     v_dep_002, 'collect', 149040.00, '2025-03-01',
     'C-RETAIL-01 签约时收取押金（6个月）', v_user_lease, '2025-03-01 09:00:00+08'),
    ('ae000000-0000-4000-8000-000000000003',
     v_dep_003, 'collect',  10000.00, '2025-07-01',
     'C-APT-01 签约时收取押金（2个月）',   v_user_lease, '2025-07-01 09:00:00+08'),
    ('ae000000-0000-4000-8000-000000000004',
     v_dep_004, 'collect', 250800.00, '2024-01-01',
     'C-SUB-MASTER 签约时收取押金（6个月）', v_user_lease, '2024-01-01 09:00:00+08');

-- ==========================================================================
-- §13  账单（invoices）— 8 条（含 WALE/NOI 验算核心数据）
-- ==========================================================================
-- outstanding_amount 是 GENERATED ALWAYS 列，不可显式插入
-- billing_basis/tax_mode/reported_revenue 不在 DDL 中，已移除；period_start/end → billing_month
INSERT INTO invoices (id, invoice_no, contract_id, billing_month,
                      total_amount, paid_amount,
                      status, due_date, created_by)
VALUES
    -- INV-001: C-OFFICE-01 2025-07 租金（已结清）
    (v_inv_001, 'INV-2025-07-001', v_c_office, '2025-07-01',
     49595.00, 49595.00, 'paid', '2025-07-10', v_user_fin),
    -- INV-002: C-OFFICE-01 2025-07 物管费（已结清）
    (v_inv_002, 'INV-2025-07-002', v_c_office, '2025-07-01',
     6867.00, 6867.00, 'paid', '2025-07-10', v_user_fin),
    -- INV-003: C-RETAIL-01 2025-07 租金（已出账，分成溢价 ¥3,160）
    (v_inv_003, 'INV-2025-07-003', v_c_retail, '2025-07-01',
     29400.00, 0.00, 'issued', '2025-07-10', v_user_fin),
    -- INV-004: C-APT-01 2025-07 租金（逾期）
    (v_inv_004, 'INV-2025-07-004', v_c_apt, '2025-07-01',
     5000.00, 0.00, 'overdue', '2025-07-31', v_user_fin),
    -- INV-005: C-OFFICE-01 2025-06 免租折算（已结清）
    -- 计费16天: 10A 280×110×16/30=16426.67 + 10B 140×105×16/30=7840.00 = 24266.67净
    -- 含税: 24266.67×1.09 = 26450.67
    (v_inv_005, 'INV-2025-06-001', v_c_office, '2025-06-01',
     26450.67, 26450.67, 'paid', '2025-06-20', v_user_fin),
    -- INV-006~008: C-RETAIL-01 免租期（3月/4月/5月，金额=0, 状态=exempt）
    (v_inv_006, 'INV-2025-03-001', v_c_retail, '2025-03-01',
     0.00, 0.00, 'exempt', '2025-03-31', v_user_fin),
    (v_inv_007, 'INV-2025-04-001', v_c_retail, '2025-04-01',
     0.00, 0.00, 'exempt', '2025-04-30', v_user_fin),
    (v_inv_008, 'INV-2025-05-001', v_c_retail, '2025-05-01',
     0.00, 0.00, 'exempt', '2025-05-31', v_user_fin);

-- ==========================================================================
-- §14  账单明细（invoice_items）— 8 条
-- amount 为不含税金额，INV-003 含保底+分成溢价两行
-- ==========================================================================
-- unit 列不在 DDL 中，已移除（量及单位信息保留在 description 中）
INSERT INTO invoice_items (id, invoice_id, item_type, description,
                           quantity, unit_price, amount)
VALUES
    -- INV-001: 两个单元分别计费
    ('2d000000-0000-4000-8000-000000000001',
     v_inv_001, 'rent', '1001租金（280m²×¥110/m²/月）',
     280.0000, 110.0000, 30800.00),
    ('2d000000-0000-4000-8000-000000000002',
     v_inv_001, 'rent', '1002租金（140m²×¥105/m²/月）',
     140.0000, 105.0000, 14700.00),
    -- INV-002: 物管费
    ('2d000000-0000-4000-8000-000000000003',
     v_inv_002, 'management_fee', '物管费（420m²×¥15/m²/月）',
     420.0000, 15.0000, 6300.00),
    -- INV-003: 保底租金 + 分成溢价
    ('2d000000-0000-4000-8000-000000000004',
     v_inv_003, 'rent', 'S101保底租金（108m²×¥230/m²/月）',
     108.0000, 230.0000, 24840.00),
    ('2d000000-0000-4000-8000-000000000005',
     v_inv_003, 'revenue_share',
     '7月营业额分成溢价（¥350,000×8%−¥24,840）',
     1.0000, NULL, 3160.00),
    -- INV-004: 公寓整套月租（含税折算不含税 5000÷1.05=4761.90）
    ('2d000000-0000-4000-8000-000000000006',
     v_inv_004, 'rent', 'A302整套月租（含税¥5,000，不含税¥4,761.90）',
     1.0000, NULL, 4761.90),
    -- INV-005: 免租后按日折算（16天/30天）
    ('2d000000-0000-4000-8000-000000000007',
     v_inv_005, 'rent',
     '1001 6月免租后折算（280m²×¥110×16÷30）',
     NULL, NULL, 16426.67),
    ('2d000000-0000-4000-8000-000000000008',
     v_inv_005, 'rent',
     '1002 6月免租后折算（140m²×¥105×16÷30）',
     NULL, NULL, 7840.00);

-- ==========================================================================
-- §15  收款核销（payments + payment_allocations）
-- ==========================================================================
-- DDL 字段: payment_no(UNIQUE NOT NULL), tenant_id(NOT NULL), amount, payment_date(DATE NOT NULL)
-- paid_amount→amount, paid_at(TIMESTAMPTZ)→payment_date(DATE), reference_no→bank_reference
-- received_by_user_id→recorded_by; allocation_status 需显式提供
INSERT INTO payments (id, payment_no, tenant_id, amount, payment_method,
                      bank_reference, payment_date,
                      allocation_status, unallocated_amount,
                      recorded_by, notes)
VALUES
    -- PAY-001: C-OFFICE-01 2025-07 租金+物管合并到账（已全额核销至 INV-001/002）
    (v_pay_001, 'PAY-2025-07-001', v_t_corp_a, 56462.00, 'bank_transfer',
     'BANK-TF-20250705-001', '2025-07-05',
     'allocated', 0.00,
     v_user_fin, 'C-OFFICE-01 2025年7月租金（¥49,595）+物管费（¥6,867）合并转账'),
    -- PAY-002: C-OFFICE-01 2025-06 免租折算到账（已全额核销至 INV-005）
    (v_pay_002, 'PAY-2025-06-001', v_t_corp_a, 26450.67, 'bank_transfer',
     'BANK-TF-20250630-001', '2025-06-30',
     'allocated', 0.00,
     v_user_fin, 'C-OFFICE-01 2025年6月免租后折算账单'),
    -- PAY-003: C-SUB-MASTER 2024-Q4 季付（含税简化，未与具体账单核销）
    (v_pay_003, 'PAY-2025-01-001', v_t_sublord, 125400.00, 'bank_transfer',
     'BANK-TF-20250105-001', '2025-01-05',
     'pending', 125400.00,
     v_user_fin, 'C-SUB-MASTER 2024年Q4季付款项');

-- allocated_by_user_id → allocated_by（DDL 字段名）
INSERT INTO payment_allocations (id, payment_id, invoice_id,
                                  allocated_amount, allocated_by)
VALUES
    -- PAY-001 分配至 INV-001 和 INV-002
    ('3d000000-0000-4000-8000-000000000001',
     v_pay_001, v_inv_001, 49595.00, v_user_fin),
    ('3d000000-0000-4000-8000-000000000002',
     v_pay_001, v_inv_002, 6867.00,  v_user_fin),
    -- PAY-002 分配至 INV-005
    ('3d000000-0000-4000-8000-000000000003',
     v_pay_002, v_inv_005, 26450.67, v_user_fin);

-- ==========================================================================
-- §16  运营支出（expenses）— 6 条，合计 ¥33,700（对应 NOI 验算 OpEx）
-- ==========================================================================
INSERT INTO expenses (id, building_id, category, description,
                      amount, expense_date, vendor, created_by)
VALUES
    ('fc000000-0000-4000-8000-000000000001',
     v_bld_office, 'utility_common',
     '公共区域水电费（走廊/电梯/大堂）',
     8500.00, '2025-07-31', NULL, v_user_fin),
    ('fc000000-0000-4000-8000-000000000002',
     v_bld_office, 'outsourced_property',
     '外包物业公司月度服务费',
     15000.00, '2025-07-31', '广州市鑫诚物业管理有限公司', v_user_fin),
    ('fc000000-0000-4000-8000-000000000003',
     v_bld_office, 'repair',
     'WO-001 空调维修结算（对应 SUP-001 顺达空调）',
     850.00, '2025-07-25', '顺达空调服务公司', v_user_fin),
    ('fc000000-0000-4000-8000-000000000004',
     v_bld_office, 'repair',
     '其他小修工单汇总',
     2350.00, '2025-07-31', NULL, v_user_fin),
    ('fc000000-0000-4000-8000-000000000005',
     v_bld_office, 'insurance',
     '财产险月度摊销',
     2000.00, '2025-07-31', NULL, v_user_fin),
    ('fc000000-0000-4000-8000-000000000006',
     v_bld_office, 'tax',
     '房产税月度摊销',
     5000.00, '2025-07-31', NULL, v_user_fin);

-- ==========================================================================
-- §17  工单（work_orders）— 6 条
-- ==========================================================================
INSERT INTO work_orders (id, order_no, building_id, floor_id, unit_id,
                         work_order_type, issue_type, priority, description, status,
                         reporter_user_id, supplier_id, contract_id,
                         submitted_at, completed_at,
                         material_cost, labor_cost, source)
VALUES
    -- WO-001: 1001 空调维修，已完工，费用记入 EXP-003
    (v_wo_001, 'WO-2025-07-001',
     v_bld_office, v_flr_o_10f, v_unit_10a,
     'repair', '空调维修', 'urgent',
     '1001 会议室空调制冷不足，噪音异常，需上门检修',
     'completed', v_user_front, v_sup_001, NULL,
     '2025-07-10 09:00:00+08', '2025-07-25 16:00:00+08',
     350.00, 500.00, 'app'),
    -- WO-002: A302 水管漏水，处理中
    (v_wo_002, 'WO-2025-07-002',
     v_bld_apt, v_flr_a_3f, v_unit_a302,
     'repair', '水管漏水', 'critical',
     'A302 卫生间水管漏水，已影响楼下 A202',
     'in_progress', v_user_front, v_sup_002, NULL,
     '2025-07-20 14:00:00+08', NULL,
     NULL, NULL, 'app'),
    -- WO-003: S101 门锁更换，待派单
    (v_wo_003, 'WO-2025-07-003',
     v_bld_retail, v_flr_r_1f, v_unit_s101,
     'repair', '门锁更换', 'normal',
     'S101 卷帘门电机故障，无法正常开启，需更换配件',
     'submitted', v_user_front, NULL, NULL,
     '2025-07-28 10:00:00+08', NULL,
     NULL, NULL, 'mini_program'),
    -- WO-004: 1001 环境噪音投诉，已处理完毕（归 U-INSP 周楼管）
    (v_wo_004, 'WO-2025-07-004',
     v_bld_office, v_flr_o_10f, v_unit_10a,
     'complaint', '环境噪音', 'normal',
     '1001 租户反映附近施工噪音影响办公，请协调处理',
     'completed', v_user_insp, NULL, NULL,
     '2025-07-15 09:00:00+08', '2025-07-18 17:00:00+08',
     NULL, NULL, 'app'),
    -- WO-005: A302 公区卫生投诉，处理中（归 U-INSP 周楼管）
    (v_wo_005, 'WO-2025-07-005',
     v_bld_apt, v_flr_a_3f, v_unit_a302,
     'complaint', '公区卫生', 'urgent',
     'A302 租户反映 3F 公共走廊卫生状况较差，请安排清洁',
     'in_progress', v_user_insp, NULL, NULL,
     '2025-07-22 10:00:00+08', NULL,
     NULL, NULL, 'mini_program'),
    -- WO-006: 1001 合同到期验房，待验收（归 U-INSP 周楼管，关联 C-OFFICE-01）
    (v_wo_006, 'WO-2025-07-006',
     v_bld_office, v_flr_o_10f, v_unit_10a,
     'inspection', '合同到期验房', 'normal',
     'C-OFFICE-01 合同到期前验房，待验收确认',
     'pending_inspection', v_user_insp, NULL, v_c_office,
     '2025-07-30 10:00:00+08', NULL,
     NULL, NULL, 'manual');

-- EXP-003 补充 work_order_id 关联（延迟 FK 已在 DDL 中配置为 DEFERRABLE）
UPDATE expenses
SET work_order_id = v_wo_001
WHERE id = 'fc000000-0000-4000-8000-000000000003';

-- ==========================================================================
-- §18  水电抄表（meter_readings）— 3 条
-- ==========================================================================
INSERT INTO meter_readings (id, unit_id, meter_type, reading_cycle,
                            current_reading, previous_reading, consumption,
                            unit_price, cost_amount, reading_date,
                            recorded_by, invoice_generated)
VALUES
    ('ca000000-0000-4000-8000-000000000001',
     v_unit_10a, 'electricity', 'monthly',
     13280.00, 12450.00, 830.00, 1.2000, 996.00,
     '2025-07-31', v_user_front, FALSE),
    ('ca000000-0000-4000-8000-000000000002',
     v_unit_10a, 'water', 'monthly',
     878.00, 856.00, 22.00, 5.6000, 123.20,
     '2025-07-31', v_user_front, FALSE),
    ('ca000000-0000-4000-8000-000000000003',
     v_unit_s101, 'electricity', 'monthly',
     10150.00, 8900.00, 1250.00, 1.2000, 1500.00,
     '2025-07-31', v_user_front, FALSE);

-- ==========================================================================
-- §19  预警记录（alerts）— 6 条（含重试样本 ALT-004）
-- is_read=FALSE 表示系统已发出但用户未阅读
-- ==========================================================================
-- DDL 字段: id, alert_type, contract_id, invoice_id, target_roles, is_notified, notified_at, created_at
-- triggered_at → created_at；is_read → is_notified；notified_via 已移除
INSERT INTO alerts (id, contract_id, alert_type, created_at,
                    is_notified, notified_at,
                    target_roles)
VALUES
    -- ALT-001: 公寓合同 90 天到期预警（已推送 in_app+email）
    ('cb000000-0000-4000-8000-000000000001',
     v_c_apt, 'lease_expiry_90', '2026-04-01 08:00:00+08',
     TRUE, '2026-04-01 08:00:00+08',
     ARRAY['leasing_specialist', 'operations_manager']),
    -- ALT-002: 60 天到期预警（尚未触发）
    ('cb000000-0000-4000-8000-000000000002',
     v_c_apt, 'lease_expiry_60', '2026-05-01 08:00:00+08',
     FALSE, NULL,
     ARRAY['leasing_specialist', 'operations_manager']),
    -- ALT-003: INV-004 逾期第 1 天（已推送 in_app）
    ('cb000000-0000-4000-8000-000000000003',
     v_c_apt, 'payment_overdue_1', '2025-08-01 08:00:00+08',
     TRUE, '2025-08-01 08:00:00+08',
     ARRAY['finance_staff', 'leasing_specialist']),
    -- ALT-004: INV-004 逾期第 7 天（已推送 in_app；retry_count 记录于 job_execution_logs）
    ('cb000000-0000-4000-8000-000000000004',
     v_c_apt, 'payment_overdue_7', '2025-08-07 08:00:00+08',
     TRUE, '2025-08-07 08:00:00+08',
     ARRAY['finance_staff', 'operations_manager']),
    -- ALT-005: 写字楼合同 90 天到期预警（未来触发）
    ('cb000000-0000-4000-8000-000000000005',
     v_c_office, 'lease_expiry_90', '2028-03-02 08:00:00+08',
     FALSE, NULL,
     ARRAY['leasing_specialist', 'operations_manager']),
    -- ALT-006: C-SUB-MASTER 押金退还提醒（合同终止前 7 天）
    ('cb000000-0000-4000-8000-000000000006',
     v_c_sub, 'deposit_refund_reminder', '2029-12-24 08:00:00+08',
     FALSE, NULL,
     ARRAY['finance_staff', 'operations_manager']);

-- ==========================================================================
-- §20  改造记录（renovation_records）— 3 条
-- ==========================================================================
-- DDL 字段: renovation_type(类型枚举), started_at/completed_at(时间戳)
INSERT INTO renovation_records (id, unit_id, renovation_type,
                                started_at, completed_at,
                                cost, description, created_by)
VALUES
    ('bc000000-0000-4000-8000-000000000001',
     v_unit_10a,  'renovation',
     '2024-03-01', '2024-05-15',
     180000.00, '精装修改造：交付前精装修，含隔断、地毯、灯具', v_user_admin),
    ('bc000000-0000-4000-8000-000000000002',
     v_unit_s103, 'renovation',
     '2023-11-01', '2024-01-31',
     85000.00, '结构改造：打通隔墙，扩大临街面，施工期单元空置', v_user_admin),
    ('bc000000-0000-4000-8000-000000000003',
     v_unit_a302, 'maintenance',
     '2025-05-15', '2025-06-30',
     12000.00, '基础翻新：签约前基础翻新，刷漆+更换洁具', v_user_front);

-- ==========================================================================
-- §21  商铺营业额申报（turnover_reports）— 4 条（对应 C-RETAIL-01 NOI 验算）
-- calculated_share = MAX(reported_revenue × rate - base_rent, 0)
-- ==========================================================================
INSERT INTO turnover_reports (id, contract_id, report_month,
                               reported_revenue, revenue_share_rate,
                               base_rent, calculated_share,
                               approval_status, reviewed_by, reviewed_at,
                               generated_invoice_id, submitted_by)
VALUES
    -- TR-001: 6月 MAX(20000,24840)→保底，分成额=0
    ('ec000000-0000-4000-8000-000000000001',
     v_c_retail, '2025-06-01',
     250000.00, 0.0800, 24840.00, 0.00,
     'approved', v_user_fin, '2025-07-05 10:00:00+08',
     NULL, v_user_sublord),
    -- TR-002: 7月 MAX(28000,24840)→分成溢价 ¥3,160，对应 INV-003
    ('ec000000-0000-4000-8000-000000000002',
     v_c_retail, '2025-07-01',
     350000.00, 0.0800, 24840.00, 3160.00,
     'approved', v_user_fin, '2025-08-05 10:00:00+08',
     v_inv_003, v_user_sublord),
    -- TR-003: 8月 MAX(24800,24840)→保底（边界 -¥40），分成额=0
    ('ec000000-0000-4000-8000-000000000003',
     v_c_retail, '2025-08-01',
     310000.00, 0.0800, 24840.00, 0.00,
     'approved', v_user_fin, '2025-09-05 10:00:00+08',
     NULL, v_user_sublord),
    -- TR-004: 9月 计算分成额=¥15,160（待审核）
    ('ec000000-0000-4000-8000-000000000004',
     v_c_retail, '2025-09-01',
     500000.00, 0.0800, 24840.00, 15160.00,
     'pending', NULL, NULL,
     NULL, v_user_sublord);

-- ==========================================================================
-- §22  子租赁（subleases）— 3 条（二房东穿透数据，2201 拆分转租）
-- unit_id 引用虚拟子单元（2201-01/02/03），规避 uq_sublease_active_unit 唯一约束
-- [安全] sub_tenant_id_number_encrypted/phone_encrypted 使用占位值
-- ==========================================================================
INSERT INTO subleases (id, master_contract_id, unit_id,
                       sub_tenant_name, sub_tenant_type,
                       monthly_rent, rent_per_sqm,
                       start_date, end_date,
                       occupancy_status, review_status,
                       reviewer_user_id, reviewed_at,
                       submission_channel, submitted_by_user_id, submitted_at,
                       version_no)
VALUES
    -- SL-001: 旭日软件 100m² @¥120/m²
    (v_sl_001, v_c_sub, v_unit_20a01,
     '旭日软件有限公司', 'corporate',
     12000.00, 120.0000,
     '2025-01-01', '2025-12-31',
     'occupied', 'approved',
     v_user_fin, '2024-12-25 10:00:00+08',
     'sub_landlord', v_user_sublord, '2024-12-20 10:00:00+08',
     1),
    -- SL-002: 星光广告 72m² @¥118/m²
    (v_sl_002, v_c_sub, v_unit_20a02,
     '星光广告有限公司', 'corporate',
     8500.00, 118.0556,
     '2025-03-01', '2026-02-28',
     'occupied', 'approved',
     v_user_fin, '2025-02-25 10:00:00+08',
     'sub_landlord', v_user_sublord, '2025-02-20 10:00:00+08',
     1),
    -- SL-003: 空置 268m²（尚未找到租客）
    (v_sl_003, v_c_sub, v_unit_20a03,
     '（空置）', 'corporate',
     0.00, 0.0000,
     '2025-01-01', '2025-12-31',
     'vacant', 'approved',
     v_user_fin, '2024-12-25 10:00:00+08',
     'internal', v_user_lease, '2024-12-25 10:00:00+08',
     1);

-- ==========================================================================
-- §23  KPI 指标定义（kpi_metric_definitions）— 10 条
-- 系统预定义，seed 后不可删除，管理员可启用/停用
-- 阈值依据 data_model.md §6.8 初始化数据表
-- ==========================================================================
-- category 为 NOT NULL，需显式提供（DDL 有 DEFAULT 'leasing' 但各指标 category 不同）
-- K01-K10 已由 019 用相同 UUID 预置，ON CONFLICT DO NOTHING 保持幂等
INSERT INTO kpi_metric_definitions (id, code, name, category, description,
                                     default_full_score_threshold,
                                     default_pass_threshold,
                                     default_fail_threshold,
                                     higher_is_better, direction,
                                     source_module, is_manual_input, is_enabled)
VALUES
    (v_km_k01, 'K01', '出租率', 'leasing',
     '期末可租单元中实际在租比例（面积口径）',
     0.9500, 0.8000, 0.6000, TRUE,  'positive', 'assets',     FALSE, TRUE),
    (v_km_k02, 'K02', '收款及时率', 'finance',
     '账单到期日前核销金额占应收总额比例',
     0.9500, 0.8500, 0.7000, TRUE,  'positive', 'finance',    FALSE, TRUE),
    (v_km_k03, 'K03', '租户集中度', 'leasing',
     'TOP3 租户租金占 PGI 比例（越低越好）',
     0.4000, 0.5500, 0.7000, FALSE, 'negative', 'contracts',  FALSE, TRUE),
    (v_km_k04, 'K04', '续约率', 'leasing',
     '到期合同中成功续约比例',
     0.8000, 0.6000, 0.4000, TRUE,  'positive', 'contracts',  FALSE, TRUE),
    (v_km_k05, 'K05', '工单响应时效', 'service',
     '工单从提交到首次响应平均小时数（越少越好）',
     24.0000, 48.0000, 72.0000, FALSE, 'negative', 'workorders', FALSE, TRUE),
    (v_km_k06, 'K06', '空置周转天数', 'leasing',
     '单元空置到新合同生效平均天数（越少越好）',
     30.0000, 60.0000, 90.0000, FALSE, 'negative', 'assets',    FALSE, TRUE),
    (v_km_k07, 'K07', 'NOI 达成率', 'finance',
     '实际 NOI ÷ 预算 NOI',
     1.0000, 0.8500, 0.7000, TRUE,  'positive', 'finance',    FALSE, TRUE),
    (v_km_k08, 'K08', '逾期率', 'finance',
     '逾期账单金额÷应收总额（越低越好）',
     0.0500, 0.1500, 0.2000, FALSE, 'negative', 'finance',    FALSE, TRUE),
    (v_km_k09, 'K09', '租金递增执行率', 'leasing',
     '实际执行递增合同占应递增合同比例',
     0.9500, 0.8500, 0.7000, TRUE,  'positive', 'contracts',  FALSE, TRUE),
    (v_km_k10, 'K10', '租户满意度', 'service',
     '满意度问卷平均分（0~100，手动录入）',
     90.0000, 75.0000, 60.0000, TRUE, 'positive', 'workorders', TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- ==========================================================================
-- §24  KPI 考核方案（kpi_schemes）— 2 条
-- ==========================================================================
INSERT INTO kpi_schemes (id, name, period_type,
                          effective_from, effective_to,
                          status, scoring_mode, created_by)
VALUES
    (v_ks_001, '租务部考核方案 2026Q3', 'quarterly',
     '2025-07-01', '2025-09-30', 'active',   'official', v_user_admin),
    (v_ks_002, '全员 KPI 月度试行方案', 'monthly',
     '2025-07-01', '2025-07-31', 'archived', 'trial',    v_user_admin);

-- ==========================================================================
-- §25  方案-指标关联（kpi_scheme_metrics）— 6 条（KS-001，权重合计 1.00）
-- ==========================================================================
INSERT INTO kpi_scheme_metrics (id, scheme_id, metric_id, weight,
                                  full_score_threshold, pass_threshold,
                                  fail_threshold)
VALUES
    ('dc000000-0000-4000-8000-000000000001', v_ks_001, v_km_k01, 0.2500, 0.9500, 0.8000, 0.6000),
    ('dc000000-0000-4000-8000-000000000002', v_ks_001, v_km_k02, 0.2000, 0.9500, 0.8000, 0.7000),
    ('dc000000-0000-4000-8000-000000000003', v_ks_001, v_km_k04, 0.1500, 0.8000, 0.6000, 0.4000),
    ('dc000000-0000-4000-8000-000000000004', v_ks_001, v_km_k06, 0.1500, 30.0000, 60.0000, 90.0000),
    ('dc000000-0000-4000-8000-000000000005', v_ks_001, v_km_k08, 0.1500, 0.0500, 0.1500, 0.2000),
    ('dc000000-0000-4000-8000-000000000006', v_ks_001, v_km_k09, 0.1000, 0.9500, 0.8000, 0.7000);
-- 权重验算: 0.25+0.20+0.15+0.15+0.15+0.10 = 1.00 ✓

-- ==========================================================================
-- §26  方案绑定对象（kpi_scheme_targets）— 2 条
-- ==========================================================================
INSERT INTO kpi_scheme_targets (id, scheme_id, user_id, department_id)
VALUES
    ('dd000000-0000-4000-8000-000000000001', v_ks_001, v_user_lease, NULL),     -- KST-001 王五个人
    ('dd000000-0000-4000-8000-000000000002', v_ks_001, NULL,         v_dept_lease); -- KST-002 租务部

-- ==========================================================================
-- §27  NOI 预算（noi_budgets）— 1 条（K07 验算基准）
-- K07 = 实际NOI ÷ 预算NOI = 77911.90 ÷ 80000 = 97.39%
-- ==========================================================================
INSERT INTO noi_budgets (id, building_id, period_year, period_month,
                         budget_noi, created_by)
VALUES
    (v_noi_bud_001, v_bld_office, 2025, 7, 80000.00, v_user_fin);

-- ==========================================================================
-- §28  管辖范围（user_managed_scopes）— 11 条
-- 部门默认(9条) + 员工个人覆盖(2条，U-LEASE 仅管 10F 和 22F)
-- ==========================================================================
INSERT INTO user_managed_scopes (id, department_id, user_id,
                                  building_id, floor_id)
VALUES
    -- 租务部：管辖三栋楼整栋
    ('4d000000-0000-4000-8000-000000000001', v_dept_lease, NULL, v_bld_office, NULL),
    ('4d000000-0000-4000-8000-000000000002', v_dept_lease, NULL, v_bld_retail, NULL),
    ('4d000000-0000-4000-8000-000000000003', v_dept_lease, NULL, v_bld_apt,    NULL),
    -- 财务部：管辖三栋楼整栋
    ('4d000000-0000-4000-8000-000000000004', v_dept_fin,   NULL, v_bld_office, NULL),
    ('4d000000-0000-4000-8000-000000000005', v_dept_fin,   NULL, v_bld_retail, NULL),
    ('4d000000-0000-4000-8000-000000000006', v_dept_fin,   NULL, v_bld_apt,    NULL),
    -- 物业运营部：管辖三栋楼整栋
    ('4d000000-0000-4000-8000-000000000007', v_dept_ops,   NULL, v_bld_office, NULL),
    ('4d000000-0000-4000-8000-000000000008', v_dept_ops,   NULL, v_bld_retail, NULL),
    ('4d000000-0000-4000-8000-000000000009', v_dept_ops,   NULL, v_bld_apt,    NULL),
    -- U-LEASE 王五：个人覆盖，仅管 融创智汇大厦A座 10F 和 22F（KPI 数据归集用）
    ('5d000000-0000-4000-8000-000000000001', NULL, v_user_lease, v_bld_office, v_flr_o_10f),
    ('5d000000-0000-4000-8000-000000000002', NULL, v_user_lease, v_bld_office, v_flr_o_22f);

-- ==========================================================================
-- §29  KPI 打分快照（kpi_score_snapshots + items + appeals）
-- 验算结果: 94.03 分（详见 SEED_DATA_SPEC §十/§二十四）
-- ==========================================================================
INSERT INTO kpi_score_snapshots (id, scheme_id, evaluated_user_id,
                                  period_start, period_end,
                                  total_score, snapshot_status, frozen_at,
                                  calculated_at, created_by)
VALUES
    (v_snap_001, v_ks_001, v_user_lease,
     '2025-07-01', '2025-09-30',
     94.03, 'frozen', '2025-10-01 08:00:00+08',
     '2025-10-01 08:00:00+08', v_user_admin);

INSERT INTO kpi_score_snapshot_items (id, snapshot_id, metric_id,
                                       weight, actual_value, score,
                                       weighted_score, source_note)
VALUES
    -- K01 出租率 91%: score=60+(0.91-0.80)/(0.95-0.80)×40=89.33
    ('5c000000-0000-4000-8000-000000000001',
     v_snap_001, v_km_k01, 0.2500, 0.9100, 89.33, 22.33,
     '60+(91%-80%)/(95%-80%)×40'),
    -- K02 收款及时率 98%: ≥满分，score=100
    ('5c000000-0000-4000-8000-000000000002',
     v_snap_001, v_km_k02, 0.2000, 0.9800, 100.00, 20.00,
     '≥满分标准95%'),
    -- K04 续约率 75%: score=60+(0.75-0.60)/(0.80-0.60)×40=90
    ('5c000000-0000-4000-8000-000000000003',
     v_snap_001, v_km_k04, 0.1500, 0.7500, 90.00, 13.50,
     '60+(75%-60%)/(80%-60%)×40'),
    -- K06 空置周转25天: ≤满分标准30天，score=100
    ('5c000000-0000-4000-8000-000000000004',
     v_snap_001, v_km_k06, 0.1500, 25.0000, 100.00, 15.00,
     '25天≤30天满分标准'),
    -- K08 逾期率 8%: 反向，score=60+(0.15-0.08)/(0.15-0.05)×40=88
    ('5c000000-0000-4000-8000-000000000005',
     v_snap_001, v_km_k08, 0.1500, 0.0800, 88.00, 13.20,
     '反向指标：60+(15%-8%)/(15%-5%)×40'),
    -- K09 递增执行率 100%: ≥满分，score=100
    ('5c000000-0000-4000-8000-000000000006',
     v_snap_001, v_km_k09, 0.1000, 1.0000, 100.00, 10.00,
     '≥满分标准95%');
-- 合计验算: 22.33+20.00+13.50+15.00+13.20+10.00 = 94.03 ✓

-- KPI 申诉（kpi_appeals）
INSERT INTO kpi_appeals (id, snapshot_id, appellant_id,
                          reason, status, created_at)
VALUES
    ('6c000000-0000-4000-8000-000000000001',
     v_snap_001, v_user_lease,
     'K01 出租率 91%，本季度 1003 单元 9 月已完成签约但系统未及时同步合同状态，'
     '实际出租率应为 93%，申请重算',
     'pending', '2025-10-05 10:00:00+08');

-- ==========================================================================
-- §30  二房东绑定合同（延迟 FK 约束在同一事务内满足）
-- ==========================================================================
UPDATE users
SET bound_contract_id = v_c_sub
WHERE id = v_user_sublord;

-- ==========================================================================
-- §31  验证汇总
-- ==========================================================================
RAISE NOTICE '========================================';
RAISE NOTICE 'PropOS Seed Data v1.1 载入完成';
RAISE NOTICE '  departments:              6';
RAISE NOTICE '  users:                    8';
RAISE NOTICE '  suppliers:                3';
RAISE NOTICE '  buildings:                3';
RAISE NOTICE '  floors:                  11';
RAISE NOTICE '  units:                   18 (15 spec + 3 sublease virtual)';
RAISE NOTICE '  tenants:                  6';
RAISE NOTICE '  contracts:                4';
RAISE NOTICE '  contract_units:           5';
RAISE NOTICE '  rent_escalation_phases:   8';
RAISE NOTICE '  deposits:                 4';
RAISE NOTICE '  deposit_transactions:     4';
RAISE NOTICE '  invoices:                 8';
RAISE NOTICE '  invoice_items:            8';
RAISE NOTICE '  payments:                 3';
RAISE NOTICE '  payment_allocations:      3';
RAISE NOTICE '  expenses:                 6  (OpEx合计 ¥33,700)';
RAISE NOTICE '  work_orders:              6';
RAISE NOTICE '  meter_readings:           3';
RAISE NOTICE '  alerts:                   6';
RAISE NOTICE '  renovation_records:       3';
RAISE NOTICE '  turnover_reports:         4';
RAISE NOTICE '  subleases:                3';
RAISE NOTICE '  kpi_metric_definitions:  10';
RAISE NOTICE '  kpi_schemes:              2';
RAISE NOTICE '  kpi_scheme_metrics:       6';
RAISE NOTICE '  kpi_scheme_targets:       2';
RAISE NOTICE '  noi_budgets:              1';
RAISE NOTICE '  user_managed_scopes:     11';
RAISE NOTICE '  kpi_score_snapshots:      1';
RAISE NOTICE '  kpi_score_snapshot_items: 6';
RAISE NOTICE '  kpi_appeals:              1';
RAISE NOTICE '----------------------------------------';
RAISE NOTICE '  WALE(收入口径) ≈ 3.27年  WALE(面积口径) ≈ 3.39年';
RAISE NOTICE '  NOI(2025-07)   ≈ ¥77,911.90';
RAISE NOTICE '  KPI(王五 2025Q3) = 94.03分';
RAISE NOTICE '  K07 NOI达成率  = 97.39%%';
RAISE NOTICE '========================================';

END;
$$;

COMMIT;
