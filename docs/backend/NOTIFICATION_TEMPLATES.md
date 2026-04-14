# PropOS 通知模板规格

> **版本**: v1.2  
> **日期**: 2026-04-13  
> **依据**: PRD v1.8（2.3 智能预警引擎）/ data_model v1.5（alert_type 枚举、alerts.target_roles 字段、notifications 表 v1.8 新增）  
> **用途**: 定义各类预警通知的邮件主题、正文模板与站内消息正文  

---

## 一、通知渠道与优先级

| 渠道 | Phase 1 支持 | 说明 |
|------|:-----------:|------|
| 站内消息中心 | ✅ | 所有预警必须写入站内消息 |
| 邮件 | ✅ | 站内消息 + 邮件双发 |
| 企业微信 Webhook | ❌ | Phase 2 扩展 |
| 短信 | ❌ | Phase 2 扩展（工单紧急预警兜底） |

---

## 二、模板变量说明

模板中使用 `{{variable}}` 占位符，渲染时替换为实际值。

| 变量名 | 类型 | 说明 |
|--------|------|------|
| `{{tenant_name}}` | string | 租客名称 |
| `{{contract_number}}` | string | 合同编号 |
| `{{unit_numbers}}` | string | 单元编号列表（逗号分隔） |
| `{{building_name}}` | string | 楼栋名称 |
| `{{end_date}}` | date | 合同到期日期（YYYY-MM-DD） |
| `{{remaining_days}}` | integer | 距到期剩余天数 |
| `{{invoice_number}}` | string | 账单编号 |
| `{{invoice_amount}}` | decimal | 应收金额（含税） |
| `{{billing_period}}` | string | 账期（YYYY-MM） |
| `{{overdue_days}}` | integer | 逾期天数 |
| `{{due_date}}` | date | 应收日期 |
| `{{deposit_amount}}` | decimal | 押金金额 |
| `{{month}}` | string | 汇总月份（YYYY年MM月） |
| `{{expiring_count}}` | integer | 到期合同数量 |
| `{{expiring_list}}` | string | 到期合同列表（HTML 表格或纯文本列表） |
| `{{recipient_name}}` | string | 收件人姓名 |
| `{{system_url}}` | string | 系统地址（如 `https://propos.example.com`） |
| `{{termination_date}}` | date | 合同终止日期 |
| `{{approval_type}}` | string | 审批类型（合同终止 / 合同续签 / 大额费用 / 二房东审核）（v1.8 新增）|
| `{{approval_summary}}` | string | 审批摘要（v1.8 新增）|
| `{{approval_result}}` | string | 审批结果（已通过 / 已拒绝）（v1.8 新增）|
| `{{approval_remark}}` | string | 审批备注（v1.8 新增）|
| `{{dunning_method}}` | string | 催收方式（电话 / 短信 / 邮件 / 函件 / 上门）（v1.8 新增）|
| `{{dunning_date}}` | date | 催收日期（v1.8 新增）|
| `{{next_follow_up}}` | date | 下次跟进日期（v1.8 新增）|

---

## 三、预警类型模板定义

### 3.1 租约到期预警 — 90天（`lease_expiry_90`）

**接收方**: 租务专员 + 运营管理层

**邮件主题**:
```
[PropOS] 租约到期预警(90天) — {{tenant_name}} / {{contract_number}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下合同将在 90 天内到期，请及时跟进续签事宜：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}（{{building_name}}）
• 到期日期：{{end_date}}
• 剩余天数：{{remaining_days}} 天

建议操作：
1. 联络租客确认续签意向
2. 评估租金调整方案
3. 在系统中更新合同续签状态

点击查看合同详情：{{system_url}}/contracts/{{contract_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
租约到期预警：{{tenant_name}}（{{contract_number}}）将于 {{end_date}} 到期，剩余 {{remaining_days}} 天。
```

---

### 3.2 租约到期预警 — 60天（`lease_expiry_60`）

**接收方**: 租务专员 + 运营管理层

**邮件主题**:
```
[PropOS] 租约到期预警(60天) — {{tenant_name}} / {{contract_number}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下合同将在 60 天内到期，续签跟进已进入第二阶段：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}（{{building_name}}）
• 到期日期：{{end_date}}
• 剩余天数：{{remaining_days}} 天

若租客无续签意向，请考虑：
1. 启动空置预招商准备
2. 安排单元现场查验
3. 确认押金退还流程准备

点击查看合同详情：{{system_url}}/contracts/{{contract_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
⚠️ 租约到期预警(60天)：{{tenant_name}}（{{contract_number}}）将于 {{end_date}} 到期，请紧急跟进续签。
```

---

### 3.3 租约到期预警 — 30天（`lease_expiry_30`）

**接收方**: 租务专员 + 运营管理层

**邮件主题**:
```
[PropOS] 🔴 租约即将到期(30天) — {{tenant_name}} / {{contract_number}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下合同将在 30 天内到期，请确认续签或退租安排：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}（{{building_name}}）
• 到期日期：{{end_date}}
• 剩余天数：{{remaining_days}} 天

⚠️ 注意事项：
- 如已确定续签，请在系统发起续签操作
- 如确定退租，请安排验收、押金结算流程
- 逾期未处理将影响 KPI 续约率指标

点击查看合同详情：{{system_url}}/contracts/{{contract_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
🔴 租约即将到期(30天)：{{tenant_name}}（{{contract_number}}）将于 {{end_date}} 到期，请立即确认续签或退租。
```

---

### 3.4 租金逾期预警 — 第1天（`payment_overdue_1`）

**接收方**: 财务人员 + 租务专员

**邮件主题**:
```
[PropOS] 租金逾期提醒 — {{tenant_name}} / {{billing_period}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下账单已超过应收日期，尚未到账：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}
• 账期：{{billing_period}}
• 应收金额：¥{{invoice_amount}}
• 应收日期：{{due_date}}
• 逾期天数：{{overdue_days}} 天

请核实到账情况，如已收款请及时核销；如未收款请联络租客确认付款计划。

点击查看账单详情：{{system_url}}/invoices/{{invoice_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
租金逾期提醒：{{tenant_name}} {{billing_period}} 应收 ¥{{invoice_amount}}，已逾期 {{overdue_days}} 天。
```

---

### 3.5 租金逾期预警 — 第7天（`payment_overdue_7`）

**接收方**: 财务人员 + 租务专员

**邮件主题**:
```
[PropOS] ⚠️ 租金逾期催收(7天) — {{tenant_name}} / {{billing_period}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下账单已逾期 7 天，请升级催收力度：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}
• 账期：{{billing_period}}
• 应收金额：¥{{invoice_amount}}
• 逾期天数：{{overdue_days}} 天

建议操作：
1. 电话联系租客确认付款时间
2. 发送正式催收函
3. 记录催收沟通记录

注意：持续逾期将影响该租户信用评级。

点击查看账单详情：{{system_url}}/invoices/{{invoice_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
⚠️ 租金逾期催收(7天)：{{tenant_name}} {{billing_period}} ¥{{invoice_amount}}，已逾期 {{overdue_days}} 天，请加紧催收。
```

---

### 3.6 租金逾期预警 — 第15天（`payment_overdue_15`）

**接收方**: 财务人员 + 租务专员 + 运营管理层

**邮件主题**:
```
[PropOS] 🔴 租金严重逾期(15天) — {{tenant_name}} / {{billing_period}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下账单已严重逾期（超过 15 天），需管理层介入：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}
• 账期：{{billing_period}}
• 应收金额：¥{{invoice_amount}}
• 逾期天数：{{overdue_days}} 天

⚠️ 风险提示：
- 该租户信用评级可能降至 C 级
- 严重逾期可能触发合同终止条款
- 建议评估押金冲抵方案

请管理层协助决策后续处理方案。

点击查看账单详情：{{system_url}}/invoices/{{invoice_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
🔴 租金严重逾期(15天)：{{tenant_name}} {{billing_period}} ¥{{invoice_amount}}，已逾期 {{overdue_days}} 天，需管理层介入。
```

---

### 3.7 月度到期汇总（`monthly_expiry_summary`）

**接收方**: 运营管理层

**触发时间**: 每月1日 08:00

**邮件主题**:
```
[PropOS] {{month}} 合同到期汇总报告
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下是 {{month}} 的合同到期汇总：

本月到期合同数：{{expiring_count}} 份

{{expiring_list}}

汇总统计：
• 已确认续签：X 份
• 待跟进：X 份
• 确认退租：X 份

请在系统中查看各合同跟进状态，确保按时完成续签或退租处理。

点击查看到期合同列表：{{system_url}}/contracts?status=expiring_soon

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**`{{expiring_list}}` 格式（邮件HTML表格）**:

| 合同编号 | 租客 | 单元 | 到期日期 | 月租金 | 状态 |
|---------|------|------|---------|-------|------|
| HT-2025-XXX | XX公司 | 10A | 2026-01-31 | ¥45,500 | 待跟进 |

**站内消息**:
```
{{month}} 合同到期汇总：本月共 {{expiring_count}} 份合同到期，请及时查看跟进。
```

---

### 3.8 押金退还提醒（`deposit_refund_reminder`）

**接收方**: 财务人员

**触发时间**: 合同终止日期前 7 天

**邮件主题**:
```
[PropOS] 押金退还提醒 — {{tenant_name}} / {{contract_number}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

以下合同即将终止，请提前准备押金结算：

• 租客：{{tenant_name}}
• 合同编号：{{contract_number}}
• 单元：{{unit_numbers}}
• 终止日期：{{termination_date}}
• 押金金额：¥{{deposit_amount}}

请在合同终止前完成以下事项：
1. 核实该租客是否有未结清账单
2. 确认是否需要从押金中扣除欠费或违约金
3. 准备押金退还审批单

点击查看押金详情：{{system_url}}/deposits/{{deposit_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
押金退还提醒：{{tenant_name}}（{{contract_number}}）合同将于 {{termination_date}} 终止，押金 ¥{{deposit_amount}}，请提前准备结算。
```

---

## 四、二房东填报提醒

虽非 `alert_type` 枚举定义的预警类型，但属于定时通知，一并定义。

### 4.1 月度填报提醒

**接收方**: 二房东账号（`sub_landlord`）

**触发时间**: 每月1日 09:00

**邮件主题**:
```
[PropOS] 请完成上月子租赁数据填报 — {{month}}
```

**邮件正文**:
```
您好：

请于 {{month}} 5日前完成上月子租赁数据填报，确保以下信息已更新：

• 各单元终端租客入住状态
• 新增/退租租客信息
• 租金变动情况

您可通过以下方式提交：
1. 登录填报系统逐条更新：{{system_url}}/portal
2. 下载 Excel 模板批量上传

逾期未填报将被记录，请务必按时提交。

——
PropOS 物业管理方（自动发送，请勿直接回复）
```

---

## 五、催收与审批通知模板（v1.8 新增）

> 以下模板写入 `notifications` 表（notification_type 枚举），同步邮件发送。

### 5.1 催收提醒（`dunning_reminder`）

**接收方**: 租客对应的招商专员 + 财务专员  
**写入**: `notifications` 表（type = `dunning_reminder`, severity = `warning`）

**邮件主题**:
```
[PropOS] 催收提醒 — {{tenant_name}} / {{invoice_number}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

租客 {{tenant_name}} 存在逾期账单，已于 {{dunning_date}} 通过{{dunning_method}}方式进行催收：

• 账单编号：{{invoice_number}}
• 应收金额：¥{{invoice_amount}}
• 逾期天数：{{overdue_days}} 天
• 下次跟进：{{next_follow_up}}

请持续关注催收进展。

点击查看账单详情：{{system_url}}/finance/invoices/{{invoice_id}}

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
催收提醒：{{tenant_name}} 账单 {{invoice_number}}（¥{{invoice_amount}}）已逾期 {{overdue_days}} 天，{{dunning_date}} 已通过{{dunning_method}}催收。
```

### 5.2 审批待处理（`approval_pending`）

**接收方**: 审批人（SA / OM）  
**写入**: `notifications` 表（type = `approval_pending`, severity = `info`）

**邮件主题**:
```
[PropOS] 新审批待处理 — {{approval_type}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

您有一条新的审批申请待处理：

• 审批类型：{{approval_type}}
• 摘要：{{approval_summary}}
• 申请时间：{{created_at}}

请尽快登录系统处理。

点击查看审批详情：{{system_url}}/approvals

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
新审批待处理：{{approval_type}} — {{approval_summary}}，请尽快处理。
```

### 5.3 审批结果通知（`approval_result`）

**接收方**: 审批申请人  
**写入**: `notifications` 表（type = `approval_result`, severity = 根据结果 `info` 或 `warning`）

**邮件主题**:
```
[PropOS] 审批结果通知 — {{approval_type}} {{approval_result}}
```

**邮件正文**:
```
{{recipient_name}}，您好：

您提交的审批申请已处理完毕：

• 审批类型：{{approval_type}}
• 摘要：{{approval_summary}}
• 审批结果：{{approval_result}}
• 备注：{{approval_remark}}

点击查看详情：{{system_url}}/approvals

——
PropOS 智慧物业管理平台（自动发送，请勿直接回复）
```

**站内消息**:
```
审批{{approval_result}}：{{approval_type}} — {{approval_summary}}。{{approval_remark}}
```

---

## 六、实现要点

1. **模板存储**: 模板定义在 `backend/lib/shared/constants/notification_templates.dart` 中，作为 Dart 常量管理
2. **变量渲染**: 使用简单字符串替换（`template.replaceAll('{{var}}', value)`），不引入模板引擎
3. **邮件格式**: 正文为 HTML 格式（用 `<p>` / `<ul>` / `<table>` 标签），站内消息为纯文本
4. **去重**: 同一合同同一类预警同一自然日仅触发一次，通过 `alerts` 表判重
5. **失败重试**: 发送失败自动重试 3 次（间隔 1/5/15 分钟），超过后记录到 `job_execution_logs`
6. **补发**: 管理后台支持按合同或按日期区间手工补发，调用 `POST /api/alerts/:id/resend`
