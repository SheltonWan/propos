# data_model v1.5 文档级联更新任务书

> **版本**: v1.0
> **日期**: 2026-04-13
> **触发源**: `docs/backend/data_model.md` v1.4 → v1.5
> **对应 PRD**: v1.8

---

## 一、变更背景

`data_model.md` 从 v1.4 升级到 v1.5，对齐前端原型 Mock 数据与后端数据模型之间的 22 处差异。核心变更如下：

| 变更项 | 变更类型 | 影响范围 |
|--------|---------|---------|
| `unit_status` 新增 `renovating` / `pre_lease` | 枚举扩展 | 资产模块、前端楼层色块、状态机 |
| 新增 `pricing_model` 枚举（area/flat/revenue） | 新枚举 + 字段 | 合同模块 DTO、API、迁移 |
| `credit_rating` 扩展至 A/B/C/D 四级 | 枚举扩展 | 租客模块、信用评级逻辑、测试 |
| 新增 `kpi_scheme_status` 枚举（draft/active/archived） | 新枚举，替换 `is_active` | KPI 方案管理、API、迁移 |
| 新增 `kpi_metric_category` 枚举（leasing/finance/service/growth） | 新枚举 + 字段 | KPI 指标库、前端分类展示 |
| KPI 指标从 K01-K10 扩充到 K01-K14 | Seed 数据 | KPI 考核、API、前端仪表盘 |
| `alerts` 新增 `target_roles user_role[]` | 新字段 | 通知推送逻辑、迁移脚本 |
| `units.ext_fields` SVG 热区坐标约定 | 文档约定 | 导入模板、前端渲染 |

---

## 二、迁移文件（先于文档更新）

在 `backend/migrations/` 下新建正式迁移文件 `20260413_v1.5_model_alignment.sql`，包含：

```sql
-- =====================================================
-- Migration: v1.5 数据模型对齐（对应 data_model v1.5）
-- Date: 2026-04-13
-- =====================================================

-- 1. 枚举扩展
ALTER TYPE unit_status ADD VALUE IF NOT EXISTS 'renovating';
ALTER TYPE unit_status ADD VALUE IF NOT EXISTS 'pre_lease';
ALTER TYPE credit_rating ADD VALUE IF NOT EXISTS 'D';

-- 2. 新增枚举类型
CREATE TYPE pricing_model AS ENUM ('area', 'flat', 'revenue');
CREATE TYPE kpi_scheme_status AS ENUM ('draft', 'active', 'archived');
CREATE TYPE kpi_metric_category AS ENUM ('leasing', 'finance', 'service', 'growth');

-- 3. 表结构变更
ALTER TABLE contracts
    ADD COLUMN pricing_model pricing_model NOT NULL DEFAULT 'area';
COMMENT ON COLUMN contracts.pricing_model IS
    'area=按面积计租; flat=整套月租; revenue=保底+分成';

ALTER TABLE kpi_metric_definitions
    ADD COLUMN category kpi_metric_category NOT NULL DEFAULT 'leasing';

-- kpi_schemes: is_active BOOLEAN → status kpi_scheme_status
ALTER TABLE kpi_schemes
    ADD COLUMN status kpi_scheme_status NOT NULL DEFAULT 'draft';
-- 迁移数据：is_active=true → 'active', is_active=false → 'archived'
UPDATE kpi_schemes SET status = CASE
    WHEN is_active = TRUE THEN 'active'::kpi_scheme_status
    ELSE 'archived'::kpi_scheme_status
END;
ALTER TABLE kpi_schemes DROP COLUMN is_active;

ALTER TABLE alerts
    ADD COLUMN target_roles user_role[];

-- 4. 回填 kpi_metric_definitions.category
UPDATE kpi_metric_definitions SET category = 'leasing'  WHERE code IN ('K01','K03','K04','K06','K09');
UPDATE kpi_metric_definitions SET category = 'finance'  WHERE code IN ('K02','K07','K08');
UPDATE kpi_metric_definitions SET category = 'service'  WHERE code IN ('K05','K10');

-- 5. 新增 K11-K14 Seed
INSERT INTO kpi_metric_definitions (code, name, category, default_full_score_threshold, default_pass_threshold, default_fail_threshold, higher_is_better, direction, source_module, is_manual_input)
VALUES
    ('K11', '预防性维修率',   'service', 0.90, 0.70, 0.50, TRUE,  'positive', 'workorders', FALSE),
    ('K12', '空置面积降幅',   'growth',  0.20, 0.10, 0,    TRUE,  'positive', 'assets',     FALSE),
    ('K13', '新签约面积（m²）','growth',  2000, 1000, 500,  TRUE,  'positive', 'contracts',  FALSE),
    ('K14', '续签率',         'leasing', 0.80, 0.60, 0.40, TRUE,  'positive', 'contracts',  FALSE);
```

> **注意**：`ALTER TYPE ... ADD VALUE` 在 PostgreSQL 中不能在事务块内执行。部署时需确保这些语句在事务外运行，或拆分为独立迁移步骤。

---

## 三、文档更新清单

### 约定

- **版本号替换规则**：文档头部 `data_model v1.3` 或 `data_model v1.4` 统一替换为 `data_model v1.5`
- **API 文档版号**：`API_CONTRACT` / `API_INVENTORY` 保持 v1.7 不变，仅在内部标注 data_model v1.5 对齐
- **信用评级统一表述**：`A/B/C 三级` → `A/B/C/D 四级`；D 级定义为"12 个月内逾期 ≥6 次或单次 >30 天，需重点监控"
- **KPI 指标统一表述**：`K01~K10（10 个）` → `K01~K14（14 个）`；K11=预防性维修率、K12=空置面积降幅、K13=新签约面积、K14=续签率

---

### P0：核心后端规范（阻塞开发，优先更新）

#### P0-1. `docs/backend/API_CONTRACT_v1.7.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §合同 DTO（ContractResponse） | 新增字段 `pricing_model: string`（area/flat/revenue），位于 `property_type` 之后 |
| 3 | §租客 DTO（TenantResponse） | `credit_rating` 说明从 `A/B/C` → `A/B/C/D`，补充 D 级语义 |
| 4 | §KPI 方案 DTO（KpiSchemeResponse） | `is_active: boolean` → `status: string`（draft/active/archived）；删除 `is_active` 字段描述 |
| 5 | §KPI 指标 DTO（KpiMetricResponse） | 新增字段 `category: string`（leasing/finance/service/growth） |
| 6 | §KPI 指标端点总述 | `K01~K10` → `K01~K14`，补充 K11-K14 说明 |

#### P0-2. `docs/backend/API_INVENTORY_v1.7.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | KPI 手动录入端点 | 说明支持 K11-K14（K11 为系统自动计算，无需手动录入） |
| 3 | KPI 方案管理接口 | 新增 PATCH `/api/kpi/schemes/:id/status` 方案状态转换说明（draft→active→archived） |
| 4 | Changelog 节 | 新增 v1.5 增量条目 |

#### P0-3. `docs/backend/MIGRATION_DRAFT_v1.7.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | 新增 §v1.5 迁移脚本 | 完整引用本文档 §二 的 SQL 脚本 |
| 3 | 迁移顺序说明 | 在迁移顺序末尾追加 `004_v1.5_model_alignment.sql` |

#### P0-4. `docs/backend/SEED_DATA_SPEC.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.3` → `data_model v1.5` |
| 2 | §KPI 指标定义 Seed 表 | 从 K01-K10 扩充到 K01-K14，所有行补充 `category` 列 |
| 3 | §租客 Seed 数据 | 补充至少 1 条 `credit_rating = 'D'` 的示例租客 |
| 4 | §合同 Seed 数据 | 示例合同补充 `pricing_model` 字段值（含 area / flat / revenue 各一条） |

---

### P1：业务需求与架构文档

#### P1-1. `docs/PRD.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §信用评级规则表 | A/B/C → A/B/C/D，补充 D 级定义行 |
| 2 | §KPI 指标表 | 从 10 指标扩充到 14 指标，补充 K11-K14 行 |

#### P1-2. `docs/ARCH.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §信用评级描述 | `A/B/C 三级` → `A/B/C/D 四级` |
| 2 | `credit_rating_service.dart` 注释 | `（A/B/C）` → `（A/B/C/D）` |
| 3 | §KPI 模块架构 | 指标引用扩至 K14；补充 `kpi_metric_category` 四分类说明 |

#### P1-3. `docs/PROJECT_PLAN.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §信用评级说明 | `A/B/C` → `A/B/C/D` |
| 3 | §M3 KPI 相关 | K01-K10 → K01-K14 |
| 4 | §kpi_metric_definitions 初始化 | 包含 K01-K14 |

#### P1-4. `docs/backend/RBAC_MATRIX.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §KPI 方案权限 | 补充方案状态转换操作权限（draft→active 需 operations_manager；active→archived 需 super_admin） |

#### P1-5. `docs/backend/NOTIFICATION_TEMPLATES.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §推送目标 | 补充 `target_roles` 广播模式说明：当 `target_user_id IS NULL AND target_roles IS NOT NULL` 时，按角色列表广播 |

#### P1-6. `docs/backend/NOTIFICATION_PUSH.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §推送逻辑 | 补充 `alerts.target_roles` 字段的分发机制：遍历 `target_roles` 数组，查询匹配角色的活跃用户，逐一创建推送记录 |

---

### P2：前端与辅助文档

#### P2-1. `docs/frontend/PAGE_SPEC_v1.8.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §租客列表页 - 信用评级过滤器 | Select 选项从 `全部/A/B/C` → `全部/A/B/C/D` |
| 2 | §KPI 方案管理页 | `is_active` 标签改为 `status` 枚举 Tag（draft=默认/active=success/archived=info） |
| 3 | §预警设置 | 补充 `target_roles` 多选组件说明 |

#### P2-2. `docs/frontend/PROTOTYPE_ENHANCEMENT_PLAN.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §信用评级面板 | `A/B/C` → `A/B/C/D` |

#### P2-3. `docs/frontend/PROTOTYPE_GAP_ANALYSIS.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §租客信用评级 | `A/B/C` → `A/B/C/D` |

#### P2-4. `docs/frontend/plan/FINANCE_GAP_IMPLEMENTATION_PLAN.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §Phase B KPI 系统 | 补充支持 K01-K14 指标清单及 `category` 分类 |

#### P2-5. `docs/frontend/plan/FRONTEND_PROTOTYPE_REVIEW_v1.8.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §KPIDashboard 条目 | 补充支持指标编号范围 K01-K14 |

#### P2-6. `docs/DEV_KICKSTART.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | §单元状态计算 | 补充 `renovating` / `pre_lease` 逻辑说明 |
| 2 | §KPI 引用 | `K01~K10` → `K01~K14` |

#### P2-7. `docs/PHASE1_IMPLEMENTATION_CHECKLIST_v1.7.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.3` → `data_model v1.5` |
| 2 | §信用评级 | `A/B/C` → `A/B/C/D` |
| 3 | §预警推送 | 补充 `target_roles` 字段 |

#### P2-8. `docs/PHASE1_SWIMLANE_PLAN_v1.7.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §预警 | 补充 `target_roles` |

#### P2-9. `docs/REQUIREMENTS_VERIFICATION_CHECKLIST.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | → `data_model v1.5` |
| 2 | §预警验证项 | 补充 `target_roles` |

#### P2-10. `docs/REQUIREMENTS_VERIFICATION_WITH_GUIDE.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | → `data_model v1.5` |
| 2 | §KPI 验证指标 M3-45~M3-54 | 扩充至 K01-K14（M3-55~M3-58 对应 K11-K14） |

#### P2-11. `docs/backend/IMPORT_TEMPLATE_SPEC.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.4` → `data_model v1.5` |
| 2 | §ext_fields 导入字段 | 补充 SVG 坐标字段（svg_x/svg_y/svg_w/svg_h）为可选导入列 |

#### P2-12. `docs/backend/TEST_PLAN.md`

| 序号 | 修改位置 | 修改内容 |
|------|---------|---------|
| 1 | 文档头版本引用 | `data_model v1.3` → `data_model v1.5` |
| 2 | §种子数据 | 补充 `credit_rating = 'D'` 的测试租客 |
| 3 | §KPI 测试用例 | 新增方案状态转换用例（draft→active→archived）；新增 K11-K14 指标计算用例 |

---

## 四、确认排除的文档

以下文档经审查不涉及 v1.5 变更，不需更新：

| 文档 | 排除原因 |
|------|---------|
| `SCHEDULED_TASKS.md` | 仅引用 ARCH 接口，不涉及枚举/字段 |
| `REVENUE_SHARE_SPEC.md` | 独立于 v1.5 变更项 |
| `CONTRACT_STATE_MACHINE.md` | 合同状态机枚举值未变 |
| `ERROR_CODE_REGISTRY.md` | 错误码独立定义，KPI 错误码已覆盖 |
| `FILE_UPLOAD_API.md` | 不涉及变更项 |
| `POSTGRES_USAGE_GUIDE.md` | 通用指南 |
| `DEPLOYMENT.md` / `CICD_PIPELINE.md` / `DEV_ENV_SETUP.md` | 运维部署层面 |
| `ROLE_EXPANSION_PLAN.md` | KPI 权限已覆盖 |
| `CAD_CONVERSION_SOP.md` | 已正确包含 `renovating` |
| `SVG_HOTZONE_SPEC.md` | 已正确包含 `renovating`，SVG 坐标约定在 data_model 层已定义 |
| `FEASIBILITY_ANALYSIS.md` | 已正确引用四级信用评级 |

---

## 五、执行策略与顺序

```
1. 创建正式迁移文件 backend/migrations/20260413_v1.5_model_alignment.sql
2. P0 四文档并行更新（无依赖）
3. P1 六文档更新（依赖 P0 确认 API 接口变更）
4. P2 十二文档批量更新
5. 统一生成 PDF：bash scripts/md_to_pdf.sh docs/backend/*.md docs/frontend/*.md docs/*.md
```

### 版本号批量替换

以下文件需将 `data_model v1.3` 或 `data_model v1.4` 替换为 `data_model v1.5`：

| 当前版本引用 | 文件 |
|------------|------|
| `v1.3` | SEED_DATA_SPEC, TEST_PLAN, REQUIREMENTS_VERIFICATION_CHECKLIST, REQUIREMENTS_VERIFICATION_WITH_GUIDE, PHASE1_IMPLEMENTATION_CHECKLIST_v1.7 |
| `v1.4` | API_CONTRACT_v1.7, API_INVENTORY_v1.7, MIGRATION_DRAFT_v1.7, RBAC_MATRIX, NOTIFICATION_TEMPLATES, IMPORT_TEMPLATE_SPEC, PROJECT_PLAN, PHASE1_SWIMLANE_PLAN_v1.7 |

---

## 六、验证清单

- [ ] 所有文档 `data_model` 版本引用均为 `v1.5`
- [ ] 信用评级相关内容全部包含 D 级
- [ ] KPI 指标相关内容全部包含 K01-K14
- [ ] KPI 方案 `is_active` 完全替换为 `status` 枚举
- [ ] 合同 DTO 包含 `pricing_model` 字段
- [ ] 预警 `target_roles` 在通知相关文档中均已说明
- [ ] 正式迁移 SQL 文件与 MIGRATION_DRAFT 一致
- [ ] 所有更新文档的 PDF 已重新生成
