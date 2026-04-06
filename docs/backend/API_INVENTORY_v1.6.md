# PropOS 后端 API 清单草案 v1.6

> 版本: v1.0
> 日期: 2026-04-06
> 范围: Phase 1 Must + 部分 Should
> 说明: 所有接口统一使用响应信封。成功为 `{ data, meta? }`，失败为 `{ error: { code, message } }`。分页参数统一为 `page` 和 `pageSize`，默认 20，最大 100。

---

## 一、认证与用户

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/auth/login | 登录并获取 access token | 公共 |
| POST | /api/auth/refresh | 刷新 token | 已登录 |
| POST | /api/auth/logout | 注销当前会话 | 已登录 |
| GET | /api/auth/me | 获取当前用户与权限 | 已登录 |
| POST | /api/users | 创建后台账号或二房东账号 | super_admin |
| PATCH | /api/users/:id/status | 启停用账号 | super_admin |
| PATCH | /api/users/:id/role | 变更角色 | super_admin |

### 认证接口备注

1. 登录失败达到阈值后返回 `ACCOUNT_LOCKED`。
2. 二房东账号首次登录需触发强制改密流程。
3. 主合同冻结或改密后，旧 token 应因 `session_version` 失效。

---

## 二、资产模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/buildings | 楼栋列表 | assets.read |
| POST | /api/buildings | 创建楼栋 | assets.write |
| GET | /api/buildings/:id | 楼栋详情 | assets.read |
| PATCH | /api/buildings/:id | 更新楼栋 | assets.write |
| GET | /api/floors | 楼层列表 | assets.read |
| POST | /api/floors | 创建楼层 | assets.write |
| GET | /api/floors/:id | 楼层详情 | assets.read |
| POST | /api/floors/:id/cad | 上传楼层图并触发转换 | assets.write |
| GET | /api/floors/:id/heatmap | 获取热区与状态色块 | assets.read |
| GET | /api/units | 单元分页列表 | assets.read |
| POST | /api/units | 创建单元 | assets.write |
| GET | /api/units/:id | 单元详情 | assets.read |
| PATCH | /api/units/:id | 更新单元 | assets.write |
| POST | /api/units/import | 批量导入单元 | assets.write |
| GET | /api/renovations | 改造记录列表 | assets.read |
| POST | /api/renovations | 新增改造记录 | assets.write |

---

## 三、租务与合同

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/tenants | 租客列表 | contracts.read |
| POST | /api/tenants | 创建租客 | contracts.write |
| GET | /api/tenants/:id | 租客详情 | contracts.read |
| PATCH | /api/tenants/:id | 更新租客 | contracts.write |
| GET | /api/contracts | 合同分页列表 | contracts.read |
| POST | /api/contracts | 创建合同 | contracts.write |
| GET | /api/contracts/:id | 合同详情 | contracts.read |
| PATCH | /api/contracts/:id | 更新合同 | contracts.write |
| POST | /api/contracts/:id/attachments | 上传合同附件 | contracts.write |
| POST | /api/contracts/:id/renew | 创建续签合同 | contracts.write |
| GET | /api/contracts/:id/escalation-phases | 查询递增阶段 | contracts.read |
| PUT | /api/contracts/:id/escalation-phases | 覆盖递增阶段配置 | contracts.write |
| GET | /api/contracts/wale | 查询 WALE，支持 `groupBy=portfolio|building|propertyType` | contracts.read |
| GET | /api/alerts | 预警列表 | alerts.read |
| POST | /api/alerts/replay | 按条件补发预警 | alerts.write |

---

## 四、财务与 NOI

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/invoices | 账单分页列表 | finance.read |
| POST | /api/invoices/generate | 手工触发账单生成 | finance.write |
| GET | /api/invoices/:id | 账单详情 | finance.read |
| GET | /api/invoices/:id/items | 账单费项明细 | finance.read |
| POST | /api/payments | 新增收款主记录并分配核销 | finance.write |
| GET | /api/payments | 收款记录列表 | finance.read |
| GET | /api/payments/:id | 收款与分配详情 | finance.read |
| PATCH | /api/payments/:id/allocations | 调整核销分配 | finance.write |
| GET | /api/expenses | 运营支出列表 | finance.read |
| POST | /api/expenses | 新增运营支出 | finance.write |
| GET | /api/noi/summary | NOI 汇总卡片 | finance.read |
| GET | /api/noi/trend | NOI 趋势 | finance.read |
| GET | /api/noi/breakdown | 按楼栋或业态拆分 NOI | finance.read |
| GET | /api/kpi/schemes | KPI 试运行方案列表 | kpi.view |
| POST | /api/kpi/schemes | 创建 KPI 试运行方案 | kpi.manage |
| GET | /api/kpi/scores | KPI 快照列表 | kpi.view |
| POST | /api/kpi/scores/recalculate | 手工重算 KPI 快照 | kpi.manage |

### 财务接口备注

1. `POST /api/payments` 需要支持一笔收款分配到多张账单。
2. `PATCH /api/payments/:id/allocations` 仅允许在未结账或未锁账期间调整。
3. NOI 默认返回未税经营口径，需通过查询参数区分 `receivable` 和 `received` 视角。

---

## 五、工单模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/workorders | 工单分页列表 | workorders.read |
| POST | /api/workorders | 创建工单 | workorders.write |
| GET | /api/workorders/:id | 工单详情 | workorders.read |
| PATCH | /api/workorders/:id/approve | 审核/派单 | workorders.write |
| PATCH | /api/workorders/:id/start | 开始处理 | workorders.write |
| PATCH | /api/workorders/:id/hold | 挂起工单 | workorders.write |
| PATCH | /api/workorders/:id/complete | 完工并录入成本 | workorders.write |
| PATCH | /api/workorders/:id/inspect | 验收工单 | workorders.write |
| PATCH | /api/workorders/:id/reopen | 重开工单 | workorders.write |
| POST | /api/workorders/:id/photos | 上传工单照片 | workorders.write |
| GET | /api/suppliers | 供应商列表 | workorders.read |
| POST | /api/suppliers | 新增供应商 | workorders.write |

---

## 六、二房东穿透模块

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| POST | /api/sublease-portal/login | 二房东门户登录 | 公共 |
| GET | /api/sublease-portal/units | 获取当前二房东可填报单元列表 | sublease.portal |
| GET | /api/sublease-portal/subleases | 获取当前二房东已提交记录 | sublease.portal |
| POST | /api/sublease-portal/subleases | 新增子租赁填报 | sublease.portal |
| PATCH | /api/sublease-portal/subleases/:id | 修改待审核或退回记录 | sublease.portal |
| POST | /api/sublease-portal/subleases/import | 批量导入子租赁 | sublease.portal |
| GET | /api/subleases | 内部子租赁分页列表 | sublease.read |
| GET | /api/subleases/:id | 子租赁详情 | sublease.read |
| PATCH | /api/subleases/:id/approve | 审核通过 | sublease.write |
| PATCH | /api/subleases/:id/reject | 退回并填写原因 | sublease.write |
| GET | /api/subleases/dashboard | 穿透基础看板 | sublease.read |

### 二房东接口备注

1. 门户类接口除 RBAC 外，必须在 Repository 层追加主合同范围过滤。
2. 仅 `approved` 记录参与穿透看板和统计口径。
3. 查看完整证件号或手机号必须触发二次授权，不应在默认详情接口直接返回。

---

## 七、运维与辅助接口

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | /api/jobs/executions | 定时任务执行列表 | ops.read |
| POST | /api/jobs/executions/:id/retry | 手工重试失败任务 | ops.write |
| GET | /api/files/:path | 代理下载附件或图纸 | 已登录 |
| GET | /api/health | 健康检查 | 公共 |

---

## 八、建议优先冻结的 DTO

1. LoginResponse
2. Building / Floor / UnitSummary / UnitDetail
3. ContractDetail / EscalationPhaseDto
4. InvoiceDetail / PaymentCreateRequest / PaymentAllocationDto
5. WorkOrderDetail
6. SubleasePortalUnit / SubleaseDetail / SubleaseReviewRequest
