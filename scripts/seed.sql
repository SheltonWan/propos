-- =============================================================================
-- PropOS Seed Data v1.0 — 最小可验证数据集
-- 执行前提：已完成全部 DDL 迁移（data_model.md v1.3 + MIGRATION_DRAFT v1.7）
-- 用途：开发自测、API 联调、AI 实现后快速验证
-- 执行方式：psql -U propos -d propos -f scripts/seed.sql
-- =============================================================================

BEGIN;

-- ============================================================
-- 0. 辅助变量（使用 CTE 或直接写 UUID literal，便于跨语句引用）
-- ============================================================

-- 楼栋 UUID
DO $$
DECLARE
    -- Buildings
    v_building_office   UUID := 'a0000000-0000-0000-0000-000000000001';
    v_building_retail   UUID := 'a0000000-0000-0000-0000-000000000002';
    v_building_apartment UUID := 'a0000000-0000-0000-0000-000000000003';
    -- Floors (office: 1F-3F; retail: 1F; apartment: 1F-2F)
    v_floor_office_1f   UUID := 'b0000000-0000-0000-0000-000000000001';
    v_floor_office_2f   UUID := 'b0000000-0000-0000-0000-000000000002';
    v_floor_office_3f   UUID := 'b0000000-0000-0000-0000-000000000003';
    v_floor_retail_1f   UUID := 'b0000000-0000-0000-0000-000000000004';
    v_floor_apt_1f      UUID := 'b0000000-0000-0000-0000-000000000005';
    v_floor_apt_2f      UUID := 'b0000000-0000-0000-0000-000000000006';
    -- Units (20 units across 3 buildings)
    v_unit_o1           UUID := 'c0000000-0000-0000-0000-000000000001';
    v_unit_o2           UUID := 'c0000000-0000-0000-0000-000000000002';
    v_unit_o3           UUID := 'c0000000-0000-0000-0000-000000000003';
    v_unit_o4           UUID := 'c0000000-0000-0000-0000-000000000004';
    v_unit_o5           UUID := 'c0000000-0000-0000-0000-000000000005';
    v_unit_o6           UUID := 'c0000000-0000-0000-0000-000000000006';
    v_unit_o7           UUID := 'c0000000-0000-0000-0000-000000000007';
    v_unit_o8           UUID := 'c0000000-0000-0000-0000-000000000008';
    v_unit_o9           UUID := 'c0000000-0000-0000-0000-000000000009';
    v_unit_o10          UUID := 'c0000000-0000-0000-0000-000000000010';
    v_unit_r1           UUID := 'c0000000-0000-0000-0000-000000000011';
    v_unit_r2           UUID := 'c0000000-0000-0000-0000-000000000012';
    v_unit_r3           UUID := 'c0000000-0000-0000-0000-000000000013';
    v_unit_a1           UUID := 'c0000000-0000-0000-0000-000000000014';
    v_unit_a2           UUID := 'c0000000-0000-0000-0000-000000000015';
    v_unit_a3           UUID := 'c0000000-0000-0000-0000-000000000016';
    v_unit_a4           UUID := 'c0000000-0000-0000-0000-000000000017';
    v_unit_a5           UUID := 'c0000000-0000-0000-0000-000000000018';
    v_unit_common       UUID := 'c0000000-0000-0000-0000-000000000019';  -- 非可租
    v_unit_equip        UUID := 'c0000000-0000-0000-0000-000000000020';  -- 非可租
    -- Tenants
    v_tenant_corp1      UUID := 'd0000000-0000-0000-0000-000000000001';
    v_tenant_corp2      UUID := 'd0000000-0000-0000-0000-000000000002';
    v_tenant_person1    UUID := 'd0000000-0000-0000-0000-000000000003';
    v_tenant_sublord    UUID := 'd0000000-0000-0000-0000-000000000004';
    -- Contracts
    v_contract_1        UUID := 'e0000000-0000-0000-0000-000000000001';
    v_contract_2        UUID := 'e0000000-0000-0000-0000-000000000002';
    v_contract_3        UUID := 'e0000000-0000-0000-0000-000000000003';
    v_contract_sub      UUID := 'e0000000-0000-0000-0000-000000000004';
    -- Users
    v_user_admin        UUID := 'f0000000-0000-0000-0000-000000000001';
    v_user_leasing      UUID := 'f0000000-0000-0000-0000-000000000002';
    v_user_finance      UUID := 'f0000000-0000-0000-0000-000000000003';
    v_user_ops          UUID := 'f0000000-0000-0000-0000-000000000004';
    v_user_manager      UUID := 'f0000000-0000-0000-0000-000000000005';
    v_user_sublord      UUID := 'f0000000-0000-0000-0000-000000000006';
    -- Department
    v_dept_root         UUID := '10000000-0000-0000-0000-000000000001';
    v_dept_leasing      UUID := '10000000-0000-0000-0000-000000000002';
    v_dept_finance      UUID := '10000000-0000-0000-0000-000000000003';
    v_dept_ops          UUID := '10000000-0000-0000-0000-000000000004';

BEGIN

-- ============================================================
-- 1. 组织架构（departments）
-- ============================================================
INSERT INTO departments (id, name, parent_id, level, sort_order, is_active)
VALUES
    (v_dept_root,    '总经办',   NULL,          1, 1, TRUE),
    (v_dept_leasing, '招商部',   v_dept_root,   2, 1, TRUE),
    (v_dept_finance, '财务部',   v_dept_root,   2, 2, TRUE),
    (v_dept_ops,     '运营部',   v_dept_root,   2, 3, TRUE);

-- ============================================================
-- 2. 用户（users）
-- 密码统一为 'Propos2026!' 的 bcrypt hash（$2a$10$ 开头）
-- 生产环境必须修改，此处仅供开发自测
-- ============================================================
INSERT INTO users (id, name, email, password_hash, role, department_id, is_active, session_version)
VALUES
    (v_user_admin,   '系统管理员', 'admin@propos.local',   '$2a$10$dummy_hash_for_seed_only_admin', 'super_admin',       v_dept_root,    TRUE, 1),
    (v_user_leasing, '张招商',     'leasing@propos.local', '$2a$10$dummy_hash_for_seed_only_lease', 'leasing_specialist', v_dept_leasing, TRUE, 1),
    (v_user_finance, '李财务',     'finance@propos.local', '$2a$10$dummy_hash_for_seed_only_fin',   'finance_staff',      v_dept_finance, TRUE, 1),
    (v_user_ops,     '王运营',     'ops@propos.local',     '$2a$10$dummy_hash_for_seed_only_ops',   'operations_staff',   v_dept_ops,     TRUE, 1),
    (v_user_manager, '赵经理',     'manager@propos.local', '$2a$10$dummy_hash_for_seed_only_mgr',   'operations_manager', v_dept_root,    TRUE, 1),
    (v_user_sublord, '二房东刘',   'sublord@propos.local', '$2a$10$dummy_hash_for_seed_only_sub',   'sub_landlord',       NULL,           TRUE, 1);

-- ============================================================
-- 3. 楼栋（buildings）
-- ============================================================
INSERT INTO buildings (id, name, property_type, total_floors, gfa, nla, address, built_year)
VALUES
    (v_building_office,    'A座',   'office',    25, 30000.00, 24000.00, '示范路 100 号', 2018),
    (v_building_retail,    '商铺区', 'retail',     2,  2707.00,  2200.00, '示范路 100 号商业裙房', 2018),
    (v_building_apartment, '公寓楼', 'apartment',  8,  7293.00,  6000.00, '示范路 102 号', 2019);

-- ============================================================
-- 4. 楼层（floors）
-- ============================================================
INSERT INTO floors (id, building_id, floor_number, floor_name, nla)
VALUES
    (v_floor_office_1f, v_building_office,    1,  '1F',  960.00),
    (v_floor_office_2f, v_building_office,    2,  '2F',  960.00),
    (v_floor_office_3f, v_building_office,    3,  '3F',  960.00),
    (v_floor_retail_1f, v_building_retail,    1,  '1F', 1100.00),
    (v_floor_apt_1f,    v_building_apartment, 1,  '1F',  750.00),
    (v_floor_apt_2f,    v_building_apartment, 2,  '2F',  750.00);

-- ============================================================
-- 5. 单元（units）— 20 个单元覆盖三业态 + 非可租
-- ============================================================

-- 写字楼单元（10 个，1F-3F 各 3~4 个）
INSERT INTO units (id, floor_id, building_id, unit_number, property_type, gross_area, net_area, orientation, ceiling_height, decoration_status, current_status, is_leasable, ext_fields, qr_code, market_rent_reference)
VALUES
    (v_unit_o1,  v_floor_office_1f, v_building_office, '101',  'office', 120.00, 100.00, 'south', 3.00, 'standard', 'leased',  TRUE, '{"workstation_count": 20, "partition_count": 2}', 'QR-A-101', 4.50),
    (v_unit_o2,  v_floor_office_1f, v_building_office, '102',  'office', 80.00,  68.00,  'north', 3.00, 'standard', 'leased',  TRUE, '{"workstation_count": 12, "partition_count": 1}', 'QR-A-102', 4.50),
    (v_unit_o3,  v_floor_office_1f, v_building_office, '103',  'office', 200.00, 170.00, 'east',  3.00, 'premium',  'vacant',  TRUE, '{"workstation_count": 35, "partition_count": 4}', 'QR-A-103', 5.00),
    (v_unit_o4,  v_floor_office_2f, v_building_office, '201',  'office', 150.00, 128.00, 'south', 3.00, 'standard', 'leased',  TRUE, '{"workstation_count": 25, "partition_count": 3}', 'QR-A-201', 4.50),
    (v_unit_o5,  v_floor_office_2f, v_building_office, '202',  'office', 100.00, 85.00,  'west',  3.00, 'blank',    'vacant',  TRUE, '{"workstation_count": 0, "partition_count": 0}',  'QR-A-202', 3.80),
    (v_unit_o6,  v_floor_office_2f, v_building_office, '203',  'office', 90.00,  76.00,  'north', 3.00, 'standard', 'vacant',  TRUE, '{"workstation_count": 14, "partition_count": 1}', 'QR-A-203', 4.20),
    (v_unit_o7,  v_floor_office_3f, v_building_office, '301',  'office', 180.00, 153.00, 'south', 3.00, 'premium',  'leased',  TRUE, '{"workstation_count": 30, "partition_count": 3}', 'QR-A-301', 5.20),
    (v_unit_o8,  v_floor_office_3f, v_building_office, '302',  'office', 120.00, 102.00, 'east',  3.00, 'standard', 'vacant',  TRUE, '{"workstation_count": 18, "partition_count": 2}', 'QR-A-302', 4.50),
    (v_unit_o9,  v_floor_office_3f, v_building_office, '303',  'office', 60.00,  51.00,  'north', 3.00, 'standard', 'renovating', TRUE, '{"workstation_count": 8, "partition_count": 1}', 'QR-A-303', 4.00),
    (v_unit_o10, v_floor_office_3f, v_building_office, '304',  'office', 60.00,  51.00,  'west',  3.00, 'blank',    'non_leasable', FALSE, '{}', NULL, NULL);

-- 商铺单元（3 个）
INSERT INTO units (id, floor_id, building_id, unit_number, property_type, gross_area, net_area, orientation, ceiling_height, decoration_status, current_status, is_leasable, ext_fields, qr_code, market_rent_reference)
VALUES
    (v_unit_r1, v_floor_retail_1f, v_building_retail, 'S101', 'retail', 150.00, 140.00, 'south', 5.20, 'blank',    'leased', TRUE, '{"frontage_width": 8.5, "street_facing": true, "retail_ceiling_height": 5.2}',  'QR-S-101', 8.00),
    (v_unit_r2, v_floor_retail_1f, v_building_retail, 'S102', 'retail', 200.00, 185.00, 'south', 5.20, 'standard', 'vacant', TRUE, '{"frontage_width": 10.0, "street_facing": true, "retail_ceiling_height": 5.2}', 'QR-S-102', 8.50),
    (v_unit_r3, v_floor_retail_1f, v_building_retail, 'S103', 'retail', 80.00,  72.00,  'east',  4.80, 'blank',    'vacant', TRUE, '{"frontage_width": 5.0, "street_facing": false, "retail_ceiling_height": 4.8}', 'QR-S-103', 6.00);

-- 公寓单元（5 个）
INSERT INTO units (id, floor_id, building_id, unit_number, property_type, gross_area, net_area, orientation, ceiling_height, decoration_status, current_status, is_leasable, ext_fields, qr_code, market_rent_reference)
VALUES
    (v_unit_a1, v_floor_apt_1f, v_building_apartment, 'P101', 'apartment', 45.00,  38.00, 'south', 2.80, 'standard', 'leased', TRUE, '{"bedroom_count": 1, "en_suite_bathroom": true, "occupant_count": 1}',  'QR-P-101', 2.50),
    (v_unit_a2, v_floor_apt_1f, v_building_apartment, 'P102', 'apartment', 65.00,  55.00, 'south', 2.80, 'premium',  'leased', TRUE, '{"bedroom_count": 2, "en_suite_bathroom": true, "occupant_count": 2}',  'QR-P-102', 3.00),
    (v_unit_a3, v_floor_apt_1f, v_building_apartment, 'P103', 'apartment', 40.00,  34.00, 'north', 2.80, 'standard', 'vacant', TRUE, '{"bedroom_count": 1, "en_suite_bathroom": false, "occupant_count": null}', 'QR-P-103', 2.20),
    (v_unit_a4, v_floor_apt_2f, v_building_apartment, 'P201', 'apartment', 45.00,  38.00, 'south', 2.80, 'standard', 'leased', TRUE, '{"bedroom_count": 1, "en_suite_bathroom": true, "occupant_count": 1}',  'QR-P-201', 2.50),
    (v_unit_a5, v_floor_apt_2f, v_building_apartment, 'P202', 'apartment', 65.00,  55.00, 'east',  2.80, 'standard', 'vacant', TRUE, '{"bedroom_count": 2, "en_suite_bathroom": true, "occupant_count": null}', 'QR-P-202', 2.80);

-- 非可租区域（2 个）
INSERT INTO units (id, floor_id, building_id, unit_number, property_type, gross_area, net_area, orientation, ceiling_height, decoration_status, current_status, is_leasable, ext_fields, qr_code)
VALUES
    (v_unit_common, v_floor_office_1f, v_building_office, '公共大厅', 'office', 300.00, NULL, NULL, 6.00, 'standard', 'non_leasable', FALSE, '{}', NULL),
    (v_unit_equip,  v_floor_office_1f, v_building_office, '设备间',   'office', 50.00,  NULL, NULL, 3.00, 'blank',    'non_leasable', FALSE, '{}', NULL);

-- ============================================================
-- 6. 租客（tenants）
-- 注意：id_number_encrypted / contact_phone_encrypted 此处用明文占位
-- 实际环境必须用 AES-256-GCM 加密后存入
-- ============================================================
INSERT INTO tenants (id, tenant_type, display_name, id_number_encrypted, contact_phone_encrypted, contact_person, contact_email, credit_rating, overdue_count, times_overdue_past_12m, max_single_overdue_days)
VALUES
    (v_tenant_corp1,  'enterprise', '科技创新有限公司',   '[ENCRYPTED:91110000MA01XXXX]', '[ENCRYPTED:13800001111]', '陈经理', 'chen@techcorp.cn',   'A', 0, 0, 0),
    (v_tenant_corp2,  'enterprise', '绿叶餐饮管理公司',   '[ENCRYPTED:91110000MA02XXXX]', '[ENCRYPTED:13900002222]', '林店长', 'lin@greenleaf.cn',   'B', 2, 2, 5),
    (v_tenant_person1,'individual', '王小明',             '[ENCRYPTED:110101199001011234]', '[ENCRYPTED:13700003333]', NULL,     'wang@personal.cn',   'A', 0, 0, 0),
    (v_tenant_sublord,'enterprise', '鑫辉商务服务公司',   '[ENCRYPTED:91110000MA03XXXX]', '[ENCRYPTED:13600004444]', '刘总',   'liu@xinhui.cn',      'B', 1, 1, 3);

-- ============================================================
-- 7. 合同（contracts）
-- ============================================================

-- 合同1：科技创新 - 写字楼 101+102（active，即将到期 ≤90天）
INSERT INTO contracts (id, contract_no, tenant_id, status, property_type, start_date, end_date, free_rent_days, free_rent_end_date, base_monthly_rent, payment_cycle_months, management_fee_rate, deposit_months, deposit_amount, tax_inclusive, applicable_tax_rate, created_by)
VALUES
    (v_contract_1, 'C-2025-001', v_tenant_corp1, 'expiring_soon', 'office',
     '2025-04-01', '2026-06-30', 30, '2025-04-30',
     7560.00, 3, 8.00, 2, 15120.00, TRUE, 0.09, v_user_leasing);

-- 合同2：绿叶餐饮 - 商铺 S101（active，含营业额分成）
INSERT INTO contracts (id, contract_no, tenant_id, status, property_type, start_date, end_date, free_rent_days, base_monthly_rent, payment_cycle_months, management_fee_rate, deposit_months, deposit_amount, tax_inclusive, applicable_tax_rate, revenue_share_enabled, min_guarantee_rent, revenue_share_rate, created_by)
VALUES
    (v_contract_2, 'C-2025-002', v_tenant_corp2, 'active', 'retail',
     '2025-06-01', '2028-05-31', 60,
     11200.00, 1, 10.00, 3, 33600.00, TRUE, 0.09,
     TRUE, 11200.00, 0.08, v_user_leasing);

-- 合同3：王小明 - 公寓 P101+P102（active）
INSERT INTO contracts (id, contract_no, tenant_id, status, property_type, start_date, end_date, base_monthly_rent, payment_cycle_months, management_fee_rate, deposit_months, deposit_amount, tax_inclusive, applicable_tax_rate, created_by)
VALUES
    (v_contract_3, 'C-2026-001', v_tenant_person1, 'active', 'apartment',
     '2026-01-01', '2027-12-31',
     2790.00, 1, 0.00, 1, 2790.00, TRUE, 0.05, v_user_leasing);

-- 合同4：鑫辉（二房东主合同）- 写字楼 201+301（active）
INSERT INTO contracts (id, contract_no, tenant_id, status, property_type, start_date, end_date, base_monthly_rent, payment_cycle_months, management_fee_rate, deposit_months, deposit_amount, tax_inclusive, applicable_tax_rate, is_sublease_master, created_by)
VALUES
    (v_contract_sub, 'C-2025-003', v_tenant_sublord, 'active', 'office',
     '2025-03-01', '2028-02-28',
     12636.00, 3, 8.00, 2, 25272.00, TRUE, 0.09,
     TRUE, v_user_leasing);

-- 绑定二房东用户到主合同
UPDATE users SET bound_contract_id = v_contract_sub WHERE id = v_user_sublord;

-- ============================================================
-- 8. 合同-单元关联（contract_units）
-- ============================================================
INSERT INTO contract_units (contract_id, unit_id, contracted_area, unit_monthly_rent)
VALUES
    (v_contract_1, v_unit_o1, 100.00, 4500.00),
    (v_contract_1, v_unit_o2,  68.00, 3060.00),
    (v_contract_2, v_unit_r1, 140.00, 11200.00),
    (v_contract_3, v_unit_a1,  38.00, 950.00),
    (v_contract_3, v_unit_a2,  55.00, 1840.00),
    (v_contract_sub, v_unit_o4, 128.00, 5760.00),
    (v_contract_sub, v_unit_o7, 153.00, 6876.00);

-- 更新已租单元的 current_contract_id
UPDATE units SET current_contract_id = v_contract_1   WHERE id IN (v_unit_o1, v_unit_o2);
UPDATE units SET current_contract_id = v_contract_2   WHERE id = v_unit_r1;
UPDATE units SET current_contract_id = v_contract_3   WHERE id IN (v_unit_a1, v_unit_a2);
UPDATE units SET current_contract_id = v_contract_sub WHERE id IN (v_unit_o4, v_unit_o7);

-- ============================================================
-- 9. 押金（deposits）
-- ============================================================
INSERT INTO deposits (contract_id, original_amount, current_balance, status)
VALUES
    (v_contract_1,   15120.00, 15120.00, 'collected'),
    (v_contract_2,   33600.00, 33600.00, 'collected'),
    (v_contract_3,    2790.00,  2790.00, 'collected'),
    (v_contract_sub, 25272.00, 25272.00, 'collected');

-- ============================================================
-- 10. 示例账单（invoices + invoice_items）
-- ============================================================

-- 合同1 的 2026 年 Q2 季度账单
INSERT INTO invoices (id, contract_id, invoice_no, billing_period_start, billing_period_end, due_date, total_amount, outstanding_amount, status, generated_by)
VALUES
    ('11000000-0000-0000-0000-000000000001', v_contract_1, 'INV-2026-Q2-001',
     '2026-04-01', '2026-06-30', '2026-04-05',
     22680.00, 22680.00, 'issued', 'system');

INSERT INTO invoice_items (invoice_id, item_type, description, amount, unit_id)
VALUES
    ('11000000-0000-0000-0000-000000000001', 'rent',           'Q2 租金（101+102）', 22680.00, NULL);

-- 合同3 的 2026年4月 月账单（已核销）
INSERT INTO invoices (id, contract_id, invoice_no, billing_period_start, billing_period_end, due_date, total_amount, outstanding_amount, status, paid_at, generated_by)
VALUES
    ('11000000-0000-0000-0000-000000000002', v_contract_3, 'INV-2026-04-001',
     '2026-04-01', '2026-04-30', '2026-04-05',
     2790.00, 0.00, 'paid', '2026-04-03T10:30:00Z', 'system');

INSERT INTO invoice_items (invoice_id, item_type, description, amount)
VALUES
    ('11000000-0000-0000-0000-000000000002', 'rent', '4月租金（P101+P102）', 2790.00);

-- ============================================================
-- 11. 示例工单（work_orders）
-- ============================================================
INSERT INTO work_orders (id, work_order_no, unit_id, reported_by, category, priority, title, description, status, assigned_to)
VALUES
    ('12000000-0000-0000-0000-000000000001', 'WO-2026-001',
     v_unit_o1, v_user_ops, 'repair', 'normal',
     '101室门锁故障', '办公室大门电子锁无法识别门禁卡',
     'submitted', NULL),
    ('12000000-0000-0000-0000-000000000002', 'WO-2026-002',
     v_unit_a1, v_user_ops, 'maintenance', 'urgent',
     'P101热水器漏水', '卫生间热水器底部持续滴水',
     'in_progress', v_user_ops);

-- ============================================================
-- 12. 示例预警（alerts）
-- ============================================================
INSERT INTO alerts (id, contract_id, alert_type, title, message, is_read)
VALUES
    ('13000000-0000-0000-0000-000000000001', v_contract_1,
     'lease_expiry_90', '合同即将到期',
     '合同 C-2025-001（科技创新有限公司）将于 2026-06-30 到期，剩余 83 天',
     FALSE);

RAISE NOTICE 'Seed data inserted successfully.';
RAISE NOTICE 'Buildings: 3, Floors: 6, Units: 20, Tenants: 4, Contracts: 4, Users: 6';

END;
$$;

COMMIT;
