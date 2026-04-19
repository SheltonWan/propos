# PropOS Phase 1 开发泳道计划 v1.7

> 版本: v1.5
> 日期: 2026-04-13
> 依据文档: PRD v1.8 / ARCH v1.5 / data_model v1.5 / Phase 1 实施清单 v1.7(v1.5) / API_CONTRACT v1.8
> 目标: 将 Must / Should 任务按后端、Flutter、数据初始化三条泳道展开，便于并行实施。

---

## 一、泳道划分原则

1. 后端泳道优先解决规则、权限、审计、任务调度和数据落库。
2. Flutter 泳道优先保证关键录入、查询、审核和看板页面可用。
3. 数据初始化泳道优先准备模板、清洗规则、样本数据和验收口径。
4. 任何跨泳道任务都必须明确前置依赖和交付接口。

---

## 二、后端泳道

| 阶段 | 任务编号 | 任务 | 前置依赖 | 输出 |
|------|---------|------|---------|------|
| B1 | BE-01 | 完成认证、RBAC、错误处理、审计中间件 | 无 | 基础服务骨架 |
| B1 | BE-02 | 落库 users、assets、contracts、contract_units 基础表 | 无 | 可执行迁移脚本（001~004） |
| B1 | BE-03 | 落库 finance、workorders、subleases、kpi 表 | BE-02 | 迁移脚本（005~006, 010~011） |
| B1 | BE-03a | 落库 deposits、meter_readings、turnover_reports、import_batches 表（v1.7） | BE-02 | 迁移脚本（007~009, 012） |
| B1 | BE-04 | 建立 job runner、执行日志、失败重试机制 | BE-01 | 任务框架 |
| B2 | BE-05 | 资产台账 CRUD 与导入 API（含 import_batches 跟踪） | BE-02, BE-03a | buildings/floors/units 接口 |
| B2 | BE-06 | CAD 转换调度与图纸元数据 API（含 `floor_plans` 多版本管理） | BE-02 | 图纸上传/查询/版本切换接口 |
| B2 | BE-07 | 租客（含信用评级）、合同（含多单元/含税/终止）、附件、状态机 API | BE-02 | contracts/tenants 接口 |
| B2 | BE-07a | 押金管理 API（v1.7 新增） | BE-07 | deposits CRUD + 状态流转 |
| B2 | BE-08 | 递增规则持久化（含 `escalation_templates` 模板保存/应用）与 WALE 双口径计算 API | BE-07 | escalation/wale/templates 接口 |
| B3 | BE-09 | 自动账单生成任务与 invoice API | BE-07, BE-08, BE-04 | invoices 接口 |
| B3 | BE-09a | 水电抄表与自动计费 API（v1.7 新增） | BE-09, BE-03a | meter_readings 接口 |
| B3 | BE-09b | 营业额申报与审核 API（v1.7 新增） | BE-09, BE-03a | turnover_reports 接口 |
| B3 | BE-10 | payments + payment_allocations 核销 API | BE-09 | payment 接口 |
| B3 | BE-11 | NOI 聚合 API（不含税口径，含 Margin/OpEx Ratio/预算接口）（v1.8 增强） | BE-09, BE-10 | NOI 看板接口 |
| B4 | BE-12 | work order 状态机、SLA、成本归口 API | BE-03 | workorders 接口 |
| B4 | BE-13 | sublease 门户 API、审核流（含 `draft` 草稿暂存）、版本留痕 | BE-03, BE-07 | subleases 接口 |
| B4 | BE-14 | 二房东行级隔离与会话安全控制（含 HTTPS/TLS/密码复杂度） | BE-13, BE-01 | 门户安全闭环 |
| B5 | BE-15 | 预警（含 `target_user_id` 定向推送）、催收、填报提醒、信用评级重算任务 | BE-04, BE-07, BE-09, BE-13 | 可追溯消息任务 |
| B5 | BE-15a | 通知系统 CRUD + 未读数聚合 API（v1.8 新增） | BE-01, BE-02 | notifications CRUD + 标记已读/全部已读接口 |
| B5 | BE-15b | 通用审批队列 API（v1.8 新增） | BE-01, BE-15a | approvals CRUD + approve/reject + 禁止自审自批 |
| B5 | BE-15c | 催收记录管理 API（v1.8 新增） | BE-01, BE-09 | dunning_logs CRUD + 催收提醒通知触发 |
| B4 | BE-16a | 组织架构管理 API（departments CRUD + 管辖范围配置） | BE-01, BE-02 | departments + user_managed_scopes 接口 |
| B5 | BE-16 | KPI 正式考核评分 API + 自动冻结（含正向/反向指标方向） | BE-11, BE-16a | KPI 考核接口 |
| B5 | BE-17 | KPI 申诉 API + 审核重算 | BE-16 | 申诉闭环 |
| B5 | BE-18 | KPI 排名/趋势/同比环比 API | BE-16 | 排名接口 |
| B5 | BE-19 | KPI Excel 导出 | BE-18 | 导出接口 |

---

## 三、Flutter 泳道

| 阶段 | 任务编号 | 任务 | 前置依赖 | 输出 |
|------|---------|------|---------|------|
| F1 | FE-01 | 建立主题、路由、DI、鉴权骨架 | 无 | App 壳层 |
| F1 | FE-02 | 登录页、权限路由守卫、错误态基建 | FE-01, BE-01 | 鉴权闭环 |
| F2 | FE-03 | 资产台账列表、详情（含 market_rent_reference）、导入页（含批次跟踪） | FE-01, BE-05 | 资产模块基础页面 |
| F2 | FE-04 | 楼层图查看、热区状态渲染与多版本图纸切换 | FE-03, BE-06 | 图纸可视化页面 |
| F2 | FE-05 | 租客（含信用评级展示）、合同（含多单元选择/含税标识/终止操作/初始状态 `quoting`）、附件、递增规则表单页（含模板选用） | FE-01, BE-07, BE-08 | 合同录入闭环 |
| F2 | FE-05a | 押金管理页面（v1.7 新增） | FE-05, BE-07a | 押金 CRUD + 状态操作 + 交易流水 |
| F2 | FE-06 | WALE 双口径查询与基础分析页 | FE-05, BE-08 | WALE 页面 |
| F3 | FE-07 | 账单列表、详情、核销录入页（含含税/不含税双金额） | FE-01, BE-09, BE-10 | 财务主链路页面 |
| F3 | FE-07a | 水电抄表录入页面（v1.7 新增） | FE-07, BE-09a | 抄表录入 + 费用预览 |
| F3 | FE-07b | 营业额申报与审核页面（v1.7 新增） | FE-07, BE-09b | 申报提交 + 审核操作 |
| F3 | FE-08 | NOI 看板页（含 NOI Margin/OpEx Ratio 展示 + 预算达成率）（v1.8 增强） | FE-07, BE-11 | NOI 页面 |
| F4 | FE-09 | 工单提报、派单、处理、验收页面（含 CapEx/OpEx 费用性质录入）（v1.8 增强） | FE-01, BE-12 | 工单闭环页面 |
| F4 | FE-10 | 二房东门户登录、填报、提交、重提页面 | FE-01, BE-13, BE-14 | 门户页面 |
| F4 | FE-11 | 内部审核页与穿透看板基础页 | FE-10, BE-13 | 穿透管理页面 |
| F5 | FE-12 | 预警中心与失败任务可视化 | FE-01, BE-15 | 运维辅助页面 |
| F5 | FE-12a | 通知中心页面（Admin + Flutter）（v1.8 新增） | FE-01, BE-15a | 通知列表 + 标记已读 + TopBar 铃铛 60s 轮询 |
| F5 | FE-12b | 审批队列页面（Admin）（v1.8 新增） | FE-01, BE-15b | 审批列表 + 审批/驳回操作 + 统计卡片 |
| F5 | FE-12c | 催收管理页面（Admin）（v1.8 新增） | FE-01, FE-07, BE-15c | 催收记录列表 + 新建催收对话框 |
| F4 | FE-13a | 组织架构管理页面（部门树 + 管辖范围配置） | FE-01, BE-16a | 组织管理页面 |
| F5 | FE-13 | KPI 正式考核看板（含正向/反向指标展示 + 雷达图） | FE-08, BE-16 | KPI 主页面 |
| F5 | FE-14 | KPI 排名榜 + 趋势折线 + 同比环比 | FE-13, BE-18 | 排名与趋势页面 |
| F5 | FE-15 | KPI 申诉提交与审核页面 | FE-13, BE-17 | 申诉页面 |
| F5 | FE-16 | KPI 评分 Excel 导出 | FE-14, BE-19 | 导出功能 |

---

## 四、数据初始化泳道

| 阶段 | 任务编号 | 任务 | 前置依赖 | 输出 |
|------|---------|------|---------|------|
| D1 | DI-01 | 定义楼栋/楼层/单元 Excel 模板（含 market_rent_reference） | 无 | 资产导入模板 |
| D1 | DI-02 | 定义历史合同导入模板（含多单元/含税/税率字段） | 无 | 合同导入模板 |
| D1 | DI-03 | 定义子租赁导入模板 | 无 | 穿透导入模板 |
| D1 | DI-03a | 定义水电抄表初始数据模板（v1.7 新增） | 无 | 抄表基线模板 |
| D2 | DI-04 | 整理 CAD 原始文件、命名规范和楼层映射 | 无 | 图纸清单 |
| D2 | DI-05 | 制定字段校验规则与错误码（含 v1.7 新增枚举） | DI-01, DI-02, DI-03 | 导入校验口径 |
| D3 | DI-06 | 清洗 639 套资产基础数据 | DI-01 | 可导入资产样本 |
| D3 | DI-07 | 清洗在租合同与未结账单样本（含押金初始状态） | DI-02 | 合同/账单/押金样本 |
| D3 | DI-08 | 清洗二房东主合同与子租赁样本 | DI-03 | 穿透样本 |
| D4 | DI-09 | 建立 WALE（双口径）、NOI、递增、工单、穿透、押金、水电验收样本 | DI-06, DI-07, DI-08 | 验收数据包 |
| D4 | DI-10 | 组织抽样复核与问题回写机制 | DI-09 | 复核记录 |
| D2 | DI-11 | 准备组织架构初始数据（部门树 + 员工部门归属 + 管辖范围） | DI-01 | 部门与归属样本 |
| D4 | DI-12 | KPI 验收扩展：含排名、申诉、导出对账 | DI-09 | KPI 验收数据包 |

---

## 五、跨泳道依赖

| 依赖项 | 提供方 | 消费方 | 说明 |
|--------|--------|--------|------|
| API 路径与字段契约 | 后端 | Flutter | B2 起必须冻结主要 DTO（含 v1.7 新增 DTO） |
| 导入模板与错误码 | 数据初始化 + 后端 | Flutter | 导入页面需复用校验结果展示 + 批次跟踪 |
| 图纸元数据与热区映射 | 数据初始化 + 后端 | Flutter | 前端只渲染，不承担绑定逻辑 |
| 验收样本 | 数据初始化 | 后端 + Flutter | 回归测试和业务验收共用 |
| 押金初始数据 | 数据初始化 | 后端 | 存量合同的押金需在导入时同步创建 deposit 记录 |
| 组织架构数据 | 数据初始化 | 后端 + Flutter | 部门树和员工归属必须在 KPI 考核前就绪 |

---

## 六、推荐并行方式

### 波次 1

后端执行 BE-01 ~ BE-04（含 BE-03a），Flutter 执行 FE-01 ~ FE-02，数据初始化执行 DI-01 ~ DI-05（含 DI-03a）。

### 波次 2

后端执行 BE-05 ~ BE-08（含 BE-07a），Flutter 执行 FE-03 ~ FE-06（含 FE-05a），数据初始化执行 DI-06 ~ DI-08。

### 波次 3

后端执行 BE-09 ~ BE-14（含 BE-09a/09b），Flutter 执行 FE-07 ~ FE-11（含 FE-07a/07b），数据初始化执行 DI-09。

### 波次 4

后端执行 BE-15、BE-15a/15b/15c（通知/审批/催收）、BE-16a（组织架构）、BE-16 ~ BE-19（KPI 全套），Flutter 执行 FE-12、FE-12a/12b/12c（通知/审批/催收页面）、FE-13a（组织管理）、FE-13 ~ FE-16（KPI 全套），数据初始化执行 DI-10 ~ DI-12。

---

## 七、阻塞项定义

1. 若 BE-01 未完成，Flutter 鉴权和门户路由不应开工到联调阶段。
2. 若 BE-09 / BE-10 未完成，NOI 页面只允许开发静态壳层，不进入真实联调。
3. 若 DI-06 ~ DI-08 未完成，批量导入和验收项不可关闭。
4. 若 BE-14 未完成，二房东门户不得进入测试环境开放。
5. 若 BE-03a 未完成，水电抄表和营业额申报 API 不可开工联调（v1.7 新增）。
6. 若 BE-07a 未完成，合同终止流程中的押金退还/冲抵联动不可测试（v1.7 新增）。
7. 若 BE-16a（组织架构）未完成，KPI 考核评分不可开工（数据归集依赖管辖范围）。
8. 若 BE-16 未完成，KPI 申诉、排名、导出不可联调。
9. 若 BE-15a 未完成，审批队列与催收提醒通知触发不可联调（v1.8 新增）。

---

## 八、v1.7 新增任务摘要

| 泳道 | 新增任务 | 说明 |
|------|---------|------|
| 后端 | BE-03a、BE-07a、BE-09a、BE-09b | deposits/meter_readings/turnover_reports/import_batches 表 + API |
| 后端 | BE-16a、BE-17、BE-18、BE-19 | 组织架构 API + KPI 申诉/排名/导出 API |
| Flutter | FE-05a、FE-07a、FE-07b | 押金管理/水电抄表/营业额审核页面 |
| Flutter | FE-13a、FE-14、FE-15、FE-16 | 组织管理/KPI 排名/申诉/导出页面 |
| 后端（v1.8） | BE-15a、BE-15b、BE-15c | 通知系统/审批队列/催收记录 API |
| Flutter（v1.8） | FE-12a、FE-12b、FE-12c | 通知中心/审批队列/催收管理页面 |
| 数据初始化 | DI-03a、DI-11、DI-12 | 水电抄表模板 + 组织架构数据 + KPI 验收数据包 |
| 跨泳道 | 阻塞项 5、6、7、8、9 | 新增依赖关系 |

### 变更说明

- BE-16 从“KPI 试运行评分”升级为“KPI 正式考核评分”，新增前置依赖 BE-16a（组织架构）。
- FE-13 从“KPI 试运行看板”升级为“KPI 正式考核看板”，含雷达图。
- 新增波次 4 任务：组织架构 + KPI 全套能力（排名/申诉/导出）。

### v1.2 对齐 data_model v1.3（2026-04-08）

- BE-06：补充 `floor_plans` 多版本图纸管理，FE-04 同步增加版本切换。
- BE-08：补充 `escalation_templates` 递增规则模板保存/应用，FE-05 同步增加模板选用。
- BE-13：补充 `sublease_review_status.draft` 草稿暂存状态。
- BE-15：补充 `alerts.target_user_id` 定向推送。
- FE-05：补充合同初始状态默认 `quoting` 标注。
- 依据文档引用从 `data_model v1.2` 更新为 `data_model v1.3`，实施清单从 v1.1 更新为 v1.2。

### v1.3 对齐 PRD v1.8 / ARCH v1.4（2026-04-13）

- BE-11：补充 NOI Margin（NOI÷EGI×100%）与 OpEx Ratio（OpEx÷EGI×100%）聚合接口，以及预算对比接口（`GET/POST /api/noi/budget`）。
- FE-08：看板页增加 NOI Margin/OpEx Ratio 指标卡片，以及对比预算 NOI 并计算 K07 NOI 达成率。
- FE-09：工单完工页增加费用性质选择（经常性 OpEx / 资本性 CapEx）；CapEx 工单不自动应射到 NOI。
- data_model 从 v1.3 升级到 v1.4：`expense_category` 枚举新增 `professional_service`，`work_orders` 表新增 `cost_nature`（opex/capex）列。
- 依据文档升级：PRD v1.7 → v1.8，ARCH v1.2 → v1.4，实施清单 v1.7(v1.2) → v1.7(v1.3)。

### v1.4 对齐 data_model v1.5（2026-04-13）

- 信用评级 `credit_rating` 枚举新增 D 级（12个月内逾期≥6次或单次>30天）。
- KPI 指标从 K01~K10 扩展至 K01~K14，新增 K11 预防性维修率、K12 空置面积降幅、K13 新签约面积、K14 续签率。
- KPI 方案 `is_active` 布尔字段迁移为 `status` 枚举（draft/active/archived），新增 `PATCH /api/kpi/schemes/:id/status` 端点。
- 合同新增 `pricing_model`（area/flat/revenue）字段。
- 预警 `alerts` 表新增 `target_roles user_role[]` 支持按角色广播推送。
- 依据文档升级：ARCH v1.4 → v1.5，data_model v1.4 → v1.5，实施清单 v1.7(v1.3) → v1.7(v1.4)。

### v1.5 对齐 API_CONTRACT v1.8（2026-04-13）

- 新增后端任务：BE-15a（通知系统 CRUD + 未读数聚合）、BE-15b（通用审批队列 API）、BE-15c（催收记录管理 API）。
- 新增前端任务：FE-12a（通知中心页面）、FE-12b（审批队列页面）、FE-12c（催收管理页面）。
- 波次 4 更新：后端新增 BE-15a/15b/15c，前端新增 FE-12a/12b/12c。
- 新增阻塞项 9：BE-15a 未完成则审批队列与催收提醒通知不可联调。
- 依据文档升级：实施清单 v1.7(v1.4) → v1.7(v1.5)，新增 API_CONTRACT v1.8 引用。
