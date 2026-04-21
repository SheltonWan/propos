-- =============================================================================
-- Migration: 019_add_deferred_foreign_keys
-- Description: 补全启动时无法建立的跨表 FK 约束（循环/乱序依赖）
--   1. users.department_id → departments
--      （departments 在 002 建立，users 在 003 建立，FK 此处补全）
--   2. users.bound_contract_id → contracts
--      （contracts 在 006 建立，users 在 003 建立，FK 此处补全）
--   3. expenses.work_order_id → work_orders
--      （work_orders 在 008 建立，expenses 在 007 建立，FK 此处补全）
--   4. work_orders.follow_up_work_order_id → work_orders（自引用）
--      （work_orders 在 008 建立时以兼容性考虑延迟处理，此处补全）
--   5. alerts.invoice_id → invoices
--      （alerts 在 006 建立，invoices 在 007 建立，FK 此处补全）
-- 依赖: 002, 003, 006, 007, 008
-- =============================================================================

BEGIN;

-- 1. users.department_id → departments
ALTER TABLE users
    ADD CONSTRAINT fk_users_department
    FOREIGN KEY (department_id) REFERENCES departments(id);

-- 2. users.bound_contract_id → contracts
ALTER TABLE users
    ADD CONSTRAINT fk_users_bound_contract
    FOREIGN KEY (bound_contract_id) REFERENCES contracts(id);

-- 3. expenses.work_order_id → work_orders
ALTER TABLE expenses
    ADD CONSTRAINT fk_expenses_work_order
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- 4. work_orders.follow_up_work_order_id → work_orders（自引用）
ALTER TABLE work_orders
    ADD CONSTRAINT fk_workorder_follow_up
    FOREIGN KEY (follow_up_work_order_id) REFERENCES work_orders(id);

-- 5. alerts.invoice_id → invoices
ALTER TABLE alerts
    ADD CONSTRAINT fk_alerts_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id);

COMMIT;
