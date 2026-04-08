# 合同状态机转换矩阵

> **文档版本**: v1.0
> **更新日期**: 2026-04-08
> **对应 PRD**: v1.7

---

## 一、状态枚举

```sql
CREATE TYPE contract_status AS ENUM (
    'quoting',         -- 报价中
    'pending_sign',    -- 待签约
    'active',          -- 执行中
    'expiring_soon',   -- 即将到期（≤90天）
    'expired',         -- 已到期
    'renewed',         -- 已续签
    'terminated'       -- 已终止
);
```

## 二、状态转换矩阵

### 2.1 核心生命周期

```
                            ┌──────────────────┐
                            │    quoting       │  报价中
                            └────────┬─────────┘
                                     │ confirm_quote
                                     ▼
                            ┌──────────────────┐
                            │  pending_sign    │  待签约
                            └────────┬─────────┘
                                     │ sign_contract
                                     ▼
                            ┌──────────────────┐
                 ┌──────────│     active       │  执行中
                 │          └────────┬─────────┘
                 │                   │ (剩余 ≤90 天，由定时任务自动触发)
                 │                   ▼
                 │          ┌──────────────────┐
                 │          │  expiring_soon   │  即将到期
                 │          └──┬───────┬───┬───┘
                 │             │       │   │
      terminate  │   expire    │ renew │   │ terminate
      (提前终止) │  (自然到期) │       │   │ (到期前终止)
                 │             ▼       │   │
                 │    ┌────────────┐   │   │
                 │    │  expired   │   │   │
                 │    └────────────┘   │   │
                 │                     ▼   │
                 │    ┌────────────┐       │
                 │    │  renewed   │       │
                 │    └────────────┘       │
                 ▼                         ▼
        ┌──────────────┐         ┌──────────────┐
        │  terminated  │         │  terminated  │
        └──────────────┘         └──────────────┘
```

### 2.2 完整转换表

| # | 当前状态 (`from`) | 触发动作 (`action`) | 目标状态 (`to`) | 前置条件 | 副作用 |
|---|-------------------|---------------------|-----------------|---------|--------|
| T1 | `quoting` | `confirm_quote` | `pending_sign` | 至少关联 1 个可租单元；基准月租金 > 0 | 审计日志：状态变更 |
| T2 | `quoting` | `cancel_quote` | *(删除记录)* | 无签约动作 | 物理删除草稿合同 |
| T3 | `pending_sign` | `sign_contract` | `active` | 已上传签约 PDF 或确认线下已签；押金已收取（`deposit_status = collected`）；单元无冲突合同 | 1. 关联单元 `current_status → leased`，`current_contract_id → 本合同 ID`<br>2. 写入 `contract_units` 关联表<br>3. 生成首期账单（如 `free_rent_days = 0`）<br>4. 审计日志 |
| T4 | `pending_sign` | `reject_sign` | `quoting` | 签约被退回修改 | 审计日志 |
| T5 | `active` | *(定时任务)* | `expiring_soon` | `end_date - NOW() ≤ 90 天` | 1. 触发 `lease_expiry_90` 预警<br>2. 后续 60/30 天继续触发对应预警 |
| T6 | `active` | `terminate` | `terminated` | 操作人具有 `contract.terminate` 权限；提供 `termination_type` + `termination_date` | 1. 关联单元 `current_status → vacant`，`current_contract_id → NULL`<br>2. 未出账账单标记 `cancelled`<br>3. 押金转入退还流程（`deposit_status → frozen`）<br>4. 计算违约金写入 `penalty_amount`<br>5. 审计日志 |
| T7 | `expiring_soon` | `renew` | `renewed` | 已创建新续签合同（`parent_contract_id` 指向本合同） | 1. 新合同状态从 `quoting` 或 `pending_sign` 开始<br>2. 押金可选"滚转"到新合同（`deposit_transactions.transfer`）<br>3. 原合同关联单元保持到新合同签约生效后再切换<br>4. 审计日志 |
| T8 | `expiring_soon` | *(自然到期)* | `expired` | `end_date < NOW()` 且未续签 | 1. 关联单元 `current_status → vacant`，`current_contract_id → NULL`<br>2. 触发押金退还提醒<br>3. 审计日志 |
| T9 | `expiring_soon` | `terminate` | `terminated` | 同 T6 | 同 T6 |
| T10 | `expired` | — | *(终态)* | 不可再转出 | — |
| T11 | `renewed` | — | *(终态)* | 不可再转出 | — |
| T12 | `terminated` | — | *(终态)* | 不可再转出 | — |

### 2.3 终止类型细则

| 终止类型 | 说明 | 押金处理 | 违约金 |
|---------|------|---------|--------|
| `normal_expiry` | 合同到期不续 | 全额退还（扣除未结欠款后） | 无 |
| `tenant_early_exit` | 租户主动提前退租 | 扣除违约金后退还余额 | 按合同约定计算（默认 = 剩余月数 × 月租 × 违约系数） |
| `mutual_agreement` | 双方协商提前终止 | 按协议约定 | 按协议约定 |
| `owner_termination` | 业主单方解约 | 全额退还 + 可能补偿 | 无（业主承担补偿） |

---

## 三、工单状态机

```sql
CREATE TYPE work_order_status AS ENUM (
    'submitted',          -- 已提交
    'approved',           -- 已审核/派单
    'in_progress',        -- 处理中
    'pending_inspection', -- 待验收
    'completed',          -- 已完成
    'rejected',           -- 已拒绝
    'on_hold'             -- 挂起
);
```

### 工单状态转换表

| # | 当前状态 | 触发动作 | 目标状态 | 前置条件 | 副作用 |
|---|---------|---------|---------|---------|--------|
| W1 | `submitted` | `approve` | `approved` | 操作人有审核权限 | 指派处理人 |
| W2 | `submitted` | `reject` | `rejected` | 操作人有审核权限 | 填写拒绝原因 |
| W3 | `approved` | `start_work` | `in_progress` | 处理人确认开工 | 记录开始时间 |
| W4 | `approved` | `hold` | `on_hold` | 说明挂起原因 | — |
| W5 | `in_progress` | `submit_completion` | `pending_inspection` | 处理人提交完工 | 记录完工时间、可上传完工照片 |
| W6 | `in_progress` | `hold` | `on_hold` | 说明挂起原因 | — |
| W7 | `pending_inspection` | `pass_inspection` | `completed` | 验收人确认通过 | 1. 记录完成时间<br>2. 如有维修费用，创建 `expenses` 记录 |
| W8 | `pending_inspection` | `fail_inspection` | `in_progress` | 验收不通过需返工 | 记录不通过原因 |
| W9 | `on_hold` | `resume` | `approved` 或 `in_progress` | 恢复到挂起前状态 | — |
| W10 | `rejected` | — | *(终态)* | — | — |
| W11 | `completed` | — | *(终态)* | — | — |

---

## 四、账单状态机

```sql
CREATE TYPE invoice_status AS ENUM (
    'draft',     -- 草稿（生成中）
    'issued',    -- 已出账
    'paid',      -- 已核销
    'overdue',   -- 逾期
    'cancelled', -- 已作废
    'exempt'     -- 免租期免单
);
```

### 账单状态转换表

| # | 当前状态 | 触发动作 | 目标状态 | 前置条件 | 副作用 |
|---|---------|---------|---------|---------|--------|
| I1 | `draft` | `issue` | `issued` | 账单金额 > 0；账期已到 | 发送账单通知 |
| I2 | `draft` | `exempt` | `exempt` | 账期在免租期内 | — |
| I3 | `draft` | `cancel` | `cancelled` | 合同终止导致未出账账单作废 | — |
| I4 | `issued` | `pay` | `paid` | 全额核销（`outstanding_amount = 0`） | 1. 关联 `payments` 记录<br>2. 更新租户逾期统计 |
| I5 | `issued` | *(定时任务)* | `overdue` | `due_date < NOW()` 且未全额核销 | 触发逾期预警（1/7/15 天节点） |
| I6 | `issued` | `void` | `cancelled` | 误开账单需作废 | 审计日志 |
| I7 | `overdue` | `pay` | `paid` | 全额核销 | 1. 更新租户 `overdue_count + 1`<br>2. 记录逾期天数用于信用评级 |
| I8 | `overdue` | `void` | `cancelled` | 特殊情况作废 | 审计日志 |
| I9 | `paid` | — | *(终态)* | — | — |
| I10 | `cancelled` | — | *(终态)* | — | — |
| I11 | `exempt` | — | *(终态)* | — | — |

---

## 五、押金状态机

```sql
CREATE TYPE deposit_status AS ENUM (
    'collected',           -- 已收取
    'frozen',              -- 冻结中（待退还审核）
    'partially_credited',  -- 部分冲抵
    'refunded'             -- 已退还
);
```

### 押金状态转换表

| # | 当前状态 | 触发动作 | 目标状态 | 前置条件 | 副作用 |
|---|---------|---------|---------|---------|--------|
| D1 | `collected` | `deduct` | `collected` | 扣除金额 ≤ 余额 | 写入 `deposit_transactions(deduction)` |
| D2 | `collected` | `freeze` | `frozen` | 合同终止触发 | 写入 `deposit_transactions(freeze)` |
| D3 | `collected` | `transfer` | `collected`（新合同） | 续签滚转；新合同已创建 | 原合同押金 → `refunded`，新合同押金 → `collected` |
| D4 | `frozen` | `deduct` | `partially_credited` | 扣除后余额 > 0 | 写入 `deposit_transactions(deduction)` |
| D5 | `frozen` | `refund` | `refunded` | 合同无未结账单 | 写入 `deposit_transactions(refund)` |
| D6 | `partially_credited` | `refund` | `refunded` | 合同无未结账单 | 写入 `deposit_transactions(refund)`（退还余额） |
| D7 | `refunded` | — | *(终态)* | — | — |

---

## 六、实现指导

### Service 层状态变更模式

```dart
// 伪代码：ContractService.terminate()
Future<Contract> terminate(String contractId, TerminateRequest req) async {
  final contract = await _repo.findById(contractId);

  // 1. 前置条件校验
  if (contract.status != ContractStatus.active &&
      contract.status != ContractStatus.expiringSoon) {
    throw AppException('CONTRACT_NOT_ACTIVE', '合同不在可终止状态', 400);
  }

  // 2. 状态转换
  final updated = contract.copyWith(
    status: ContractStatus.terminated,
    terminationType: req.terminationType,
    terminationDate: req.terminationDate,
    terminatedAt: clock.now(),
  );

  // 3. 副作用（在同一事务内）
  await _unitRepo.releaseUnits(contractId);           // 单元 → vacant
  await _invoiceRepo.cancelPendingInvoices(contractId); // 草稿账单 → cancelled
  await _depositService.freezeDeposit(contractId);     // 押金 → frozen
  await _auditRepo.log(action: 'terminate', ...);     // 审计日志

  return _repo.update(updated);
}
```

### 定时任务触发的状态变更

| 任务 | 触发时机 | 状态变更 |
|------|---------|---------|
| 合同到期检查 | 每日 01:00 UTC | `active` → `expiring_soon`（≤90天）; `expiring_soon` → `expired`（已过期） |
| 账单逾期检查 | 每日 01:00 UTC | `issued` → `overdue`（已过 due_date） |
| 信用评级重算 | 每月 1 日 | 更新 `tenants.credit_rating` |
