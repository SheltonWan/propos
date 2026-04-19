# 全局错误码注册表

> **文档版本**: v1.0
> **更新日期**: 2026-04-08
> **用途**: 前端统一错误处理 + 后端 AppException 错误码常量定义

---

## 一、使用说明

- 所有错误码使用 `SCREAMING_SNAKE_CASE` 格式
- 前端按 `code` 字段做业务判断，**不解析 `message`**
- 后端新增错误码时**必须**同步更新本表
- 后端常量定义：`backend/lib/shared/constants/error_codes.dart`
- Flutter 常量定义：`flutter_app/lib/core/constants/error_codes.dart`
- Admin 常量定义：`admin/src/constants/error_codes.ts`

---

## 二、通用错误码

适用于所有端点，由全局 `error_handler.dart` 中间件统一处理。

| 错误码 | HTTP Status | 说明 | 前端处理 |
|--------|------------|------|---------------|
| `UNAUTHORIZED` | 401 | 未登录或 Token 无效 | 跳转登录页 |
| `FORBIDDEN` | 403 | 无操作权限 | Toast "无权限" |
| `NOT_FOUND` | 404 | 资源不存在 | Toast "资源未找到" |
| `VALIDATION_ERROR` | 400 | 请求参数校验失败 | 显示具体字段错误 |
| `CONFLICT` | 409 | 资源冲突（如重复创建） | Toast 具体冲突信息 |
| `INTERNAL_ERROR` | 500 | 服务端内部错误 | Toast "服务异常，请稍后重试" |

---

## 三、认证与用户模块

### 3.1 登录认证

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `INVALID_CREDENTIALS` | 401 | `POST /api/auth/login` | 用户名或密码错误 |
| `ACCOUNT_LOCKED` | 423 | `POST /api/auth/login` | 连续登录失败，账号锁定（含 `locked_until`） |
| `ACCOUNT_DISABLED` | 403 | `POST /api/auth/login` | 账号已停用 |
| `ACCOUNT_FROZEN` | 403 | `POST /api/auth/login` | 二房东账号已冻结（主合同过期） |

### 3.2 Token 刷新

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `TOKEN_EXPIRED` | 401 | `POST /api/auth/refresh` | Refresh Token 已过期 |
| `TOKEN_REVOKED` | 401 | `POST /api/auth/refresh` | Refresh Token 已被吊销 |
| `SESSION_VERSION_MISMATCH` | 401 | `POST /api/auth/refresh` | 改密/冻结后 session 版本不匹配 |

### 3.3 用户管理

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `EMAIL_ALREADY_EXISTS` | 409 | `POST /api/users` | 邮箱已被注册 |
| `PASSWORD_TOO_WEAK` | 400 | `POST /api/users`、`POST /api/auth/change-password` | 密码不符合复杂度要求 |
| `BOUND_CONTRACT_REQUIRED` | 400 | `POST /api/users` | 二房东角色必须绑定主合同 |
| `CONTRACT_NOT_SUBLEASE_MASTER` | 400 | `POST /api/users` | 绑定的合同不是二房东主合同 |
| `INVALID_OLD_PASSWORD` | 400 | `POST /api/auth/change-password` | 旧密码不正确 |
| `PASSWORD_SAME_AS_OLD` | 400 | `POST /api/auth/change-password` | 新密码不能与旧密码相同 |

---

## 四、组织架构模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `MAX_DEPTH_EXCEEDED` | 400 | `POST /api/departments` | 部门层级超过 3 级 |
| `PARENT_DEPARTMENT_NOT_FOUND` | 404 | `POST /api/departments` | 父部门不存在 |
| `PARENT_DEPARTMENT_INACTIVE` | 400 | `POST /api/departments` | 父部门已停用 |
| `DEPARTMENT_HAS_ACTIVE_USERS` | 400 | `DELETE /api/departments/:id` | 部门下有在职员工 |
| `DEPARTMENT_HAS_ACTIVE_CHILDREN` | 400 | `DELETE /api/departments/:id` | 部门下有活跃子部门 |

---

## 五、资产模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `FLOOR_ALREADY_EXISTS` | 409 | `POST /api/floors` | 同一楼栋下楼层号已存在 |
| `BUILDING_NOT_FOUND` | 404 | 资产相关 | 楼栋不存在 |
| `FLOOR_NOT_FOUND` | 404 | 资产相关 | 楼层不存在 |
| `UNIT_NOT_FOUND` | 404 | 资产相关 | 单元不存在 |
| `INVALID_CAD_FILE` | 400 | `POST /api/floors/:id/cad` | 不是有效的 DWG 文件 |
| `CAD_CONVERSION_FAILED` | 500 | `POST /api/floors/:id/cad` | DWG → SVG 转换失败 |

---

## 六、租务与合同模块

### 6.1 租客

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `TENANT_NOT_FOUND` | 404 | 租客相关 | 租客不存在 |
| `INVALID_PASSWORD` | 401 | `POST /api/tenants/:id/unmask` | 脱敏解密二次验证失败 |

### 6.2 合同

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `CONTRACT_NOT_FOUND` | 404 | 合同相关 | 合同不存在 |
| `CONTRACT_NO_ALREADY_EXISTS` | 409 | `POST /api/contracts` | 合同编号已存在 |
| `UNIT_ALREADY_LEASED` | 409 | `POST /api/contracts` | 单元已被其他合同占用 |
| `INVALID_CONTRACT_DATES` | 400 | `POST /api/contracts` | 开始日期晚于结束日期 |
| `CONTRACT_UNITS_NOT_PATCHABLE` | 400 | `PATCH /api/contracts/:id` | 合同单元不可通过此端点修改 |
| `CONTRACT_NOT_ACTIVE` | 400 | `POST /api/contracts/:id/terminate` | 合同不在可终止状态 |
| `TERMINATION_DATE_INVALID` | 400 | `POST /api/contracts/:id/terminate` | 终止日期不在合同有效期内 |

### 6.3 押金

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `DEPOSIT_NOT_FOUND` | 404 | 押金相关 | 押金记录不存在 |
| `DEDUCTION_EXCEEDS_BALANCE` | 400 | `POST /api/deposits/:id/deduct` | 扣除金额超过押金余额 |
| `CONTRACT_HAS_OUTSTANDING_INVOICES` | 400 | `POST /api/deposits/:id/refund` | 合同有未结账单，无法退还 |
| `TARGET_CONTRACT_NOT_RENEWAL` | 400 | `POST /api/deposits/:id/transfer` | 目标合同不是续签合同 |

---

## 七、财务模块

### 7.1 账单

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `INVOICE_NOT_FOUND` | 404 | 账单相关 | 账单不存在 |
| `INVOICE_NOT_VOIDABLE` | 400 | `POST /api/invoices/:id/void` | 仅 `issued` 状态可作废 |

### 7.2 收款

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `ALLOCATION_EXCEEDS_OUTSTANDING` | 400 | `POST /api/payments` | 分配金额超过账单未结余额 |
| `ALLOCATION_SUM_MISMATCH` | 400 | `POST /api/payments` | 分配总额 ≠ 收款总额 |

### 7.3 支出

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `EXPENSE_NOT_FOUND` | 404 | 支出相关 | 支出记录不存在 |
| `EXPENSE_LINKED_TO_WORKORDER` | 400 | `DELETE /api/expenses/:id` | 支出关联工单，无法删除 |

### 7.4 水电抄表

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `INVALID_READING` | 400 | `POST /api/meter-readings` | 本期读数 ≤ 上期读数 |
| `METER_READING_ALREADY_INVOICED` | 400 | `PATCH /api/meter-readings/:id` | 已生成账单，无法修改 |

### 7.5 NOI 预算

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `NOI_BUDGET_NOT_FOUND` | 404 | `PATCH/DELETE /api/noi/budget/:id` | 预算记录不存在 |

### 7.6 催收

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `INVOICE_ALREADY_PAID` | 400 | `POST /api/dunning-logs` | 账单已全额核销，无需催收 |

---

## 八、KPI 模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `KPI_SCHEME_NOT_FOUND` | 404 | KPI 相关 | 考核方案不存在 |
| `WEIGHT_SUM_NOT_ONE` | 400 | `PUT /api/kpi/schemes/:id/metrics` | 权重总和 ≠ 1.00 |
| `METRIC_NOT_MANUAL_INPUT` | 400 | `POST /api/kpi/metrics/:id/manual-input` | 指标不支持手动录入 |
| `APPEAL_WINDOW_CLOSED` | 400 | `POST /api/kpi/appeals` | 申诉窗口（7 天）已关闭 |
| `SNAPSHOT_NOT_FOUND` | 404 | KPI 快照相关 | 评分快照不存在 |
| `SNAPSHOT_NOT_FROZEN` | 400 | KPI 申诉 | 快照未冻结，无法申诉 |

---

## 九、工单模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `WORKORDER_NOT_FOUND` | 404 | 工单相关 | 工单不存在 |
| `INVALID_STATUS_TRANSITION` | 400 | 工单状态变更 | 非法状态转换（参见状态机矩阵） |
| `INVALID_WORK_ORDER_TYPE` | 400 | `POST /api/workorders` | 无效的工单类型（必须为 `repair` / `complaint` / `inspection`） |
| `INVALID_ISSUE_TYPE_FOR_WORK_ORDER_TYPE` | 400 | `POST /api/workorders` | `issue_type` 与 `work_order_type` 不匹配 |
| `CONTRACT_REQUIRED_FOR_INSPECTION` | 400 | `POST /api/workorders` | 退租验房类型必须关联合同 |
| `ASSIGNEE_NOT_FOUND` | 404 | `POST /api/workorders/:id/assign` | 指派人不存在 |

---

## 十、二房东模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `SUBLEASE_NOT_FOUND` | 404 | 二房东相关 | 子租赁记录不存在 |
| `SUBLEASE_AREA_EXCEEDS_MASTER` | 400 | `POST /api/subleases` | 子租面积超过主合同签约面积 |
| `SUBLEASE_NOT_EDITABLE` | 400 | `PATCH /api/subleases/:id` | 已审核通过的记录不可编辑 |
| `IMPORT_BATCH_NOT_FOUND` | 404 | 批量导入 | 导入批次不存在 |

---

## 十一、文件模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `FILE_NOT_FOUND` | 404 | `GET /api/files/{path}` | 文件不存在 |
| `FILE_ACCESS_DENIED` | 403 | `GET /api/files/{path}` | 无权访问该文件 |
| `FILE_TOO_LARGE` | 413 | 文件上传 | 超过大小限制 |
| `FILE_TYPE_NOT_ALLOWED` | 415 | 文件上传 | 不支持的文件类型 |
| `UPLOAD_FAILED` | 500 | 文件上传 | 服务端存储失败 |
| `TOO_MANY_PHOTOS` | 400 | 工单/改造照片上传 | 单次上传超过限制 |

---

## 十二、审批模块

| 错误码 | HTTP | 触发端点 | 说明 |
|--------|------|---------|------|
| `APPROVAL_NOT_FOUND` | 404 | `PATCH /api/approvals/:id` | 审批记录不存在 |
| `APPROVAL_ALREADY_PROCESSED` | 400 | `PATCH /api/approvals/:id` | 审批已处理，不可重复操作 |
| `APPROVAL_SELF_REVIEW` | 403 | `PATCH /api/approvals/:id` | 不允许审批自己提交的内容 |

---

## 十三、Dart 常量定义模板

```dart
/// backend/lib/shared/constants/error_codes.dart
/// 与本文档保持同步

class ErrorCodes {
  ErrorCodes._();

  // ── 通用 ──
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const conflict = 'CONFLICT';
  static const internalError = 'INTERNAL_ERROR';

  // ── 认证 ──
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const accountLocked = 'ACCOUNT_LOCKED';
  static const accountDisabled = 'ACCOUNT_DISABLED';
  static const accountFrozen = 'ACCOUNT_FROZEN';
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const tokenRevoked = 'TOKEN_REVOKED';
  static const sessionVersionMismatch = 'SESSION_VERSION_MISMATCH';

  // ── 用户 ──
  static const emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const passwordTooWeak = 'PASSWORD_TOO_WEAK';
  static const boundContractRequired = 'BOUND_CONTRACT_REQUIRED';
  static const contractNotSubleaseMaster = 'CONTRACT_NOT_SUBLEASE_MASTER';
  static const invalidOldPassword = 'INVALID_OLD_PASSWORD';
  static const passwordSameAsOld = 'PASSWORD_SAME_AS_OLD';

  // ── 组织架构 ──
  static const maxDepthExceeded = 'MAX_DEPTH_EXCEEDED';
  static const parentDepartmentNotFound = 'PARENT_DEPARTMENT_NOT_FOUND';
  static const parentDepartmentInactive = 'PARENT_DEPARTMENT_INACTIVE';
  static const departmentHasActiveUsers = 'DEPARTMENT_HAS_ACTIVE_USERS';
  static const departmentHasActiveChildren = 'DEPARTMENT_HAS_ACTIVE_CHILDREN';

  // ── 资产 ──
  static const floorAlreadyExists = 'FLOOR_ALREADY_EXISTS';
  static const buildingNotFound = 'BUILDING_NOT_FOUND';
  static const floorNotFound = 'FLOOR_NOT_FOUND';
  static const unitNotFound = 'UNIT_NOT_FOUND';
  static const invalidCadFile = 'INVALID_CAD_FILE';
  static const cadConversionFailed = 'CAD_CONVERSION_FAILED';

  // ── 租客 ──
  static const tenantNotFound = 'TENANT_NOT_FOUND';
  static const invalidPassword = 'INVALID_PASSWORD';

  // ── 合同 ──
  static const contractNotFound = 'CONTRACT_NOT_FOUND';
  static const contractNoAlreadyExists = 'CONTRACT_NO_ALREADY_EXISTS';
  static const unitAlreadyLeased = 'UNIT_ALREADY_LEASED';
  static const invalidContractDates = 'INVALID_CONTRACT_DATES';
  static const contractUnitsNotPatchable = 'CONTRACT_UNITS_NOT_PATCHABLE';
  static const contractNotActive = 'CONTRACT_NOT_ACTIVE';
  static const terminationDateInvalid = 'TERMINATION_DATE_INVALID';

  // ── 押金 ──
  static const depositNotFound = 'DEPOSIT_NOT_FOUND';
  static const deductionExceedsBalance = 'DEDUCTION_EXCEEDS_BALANCE';
  static const contractHasOutstandingInvoices = 'CONTRACT_HAS_OUTSTANDING_INVOICES';
  static const targetContractNotRenewal = 'TARGET_CONTRACT_NOT_RENEWAL';

  // ── 账单 ──
  static const invoiceNotFound = 'INVOICE_NOT_FOUND';
  static const invoiceNotVoidable = 'INVOICE_NOT_VOIDABLE';

  // ── 收款 ──
  static const allocationExceedsOutstanding = 'ALLOCATION_EXCEEDS_OUTSTANDING';
  static const allocationSumMismatch = 'ALLOCATION_SUM_MISMATCH';

  // ── 支出 ──
  static const expenseNotFound = 'EXPENSE_NOT_FOUND';
  static const expenseLinkedToWorkorder = 'EXPENSE_LINKED_TO_WORKORDER';

  // ── 水电 ──
  static const invalidReading = 'INVALID_READING';
  static const meterReadingAlreadyInvoiced = 'METER_READING_ALREADY_INVOICED';

  // ── KPI ──
  static const kpiSchemeNotFound = 'KPI_SCHEME_NOT_FOUND';
  static const weightSumNotOne = 'WEIGHT_SUM_NOT_ONE';
  static const metricNotManualInput = 'METRIC_NOT_MANUAL_INPUT';
  static const appealWindowClosed = 'APPEAL_WINDOW_CLOSED';
  static const snapshotNotFound = 'SNAPSHOT_NOT_FOUND';
  static const snapshotNotFrozen = 'SNAPSHOT_NOT_FROZEN';

  // ── 工单 ──
  static const workorderNotFound = 'WORKORDER_NOT_FOUND';
  static const invalidStatusTransition = 'INVALID_STATUS_TRANSITION';
  static const assigneeNotFound = 'ASSIGNEE_NOT_FOUND';

  // ── 二房东 ──
  static const subleaseNotFound = 'SUBLEASE_NOT_FOUND';
  static const subleaseAreaExceedsMaster = 'SUBLEASE_AREA_EXCEEDS_MASTER';
  static const subleaseNotEditable = 'SUBLEASE_NOT_EDITABLE';
  static const importBatchNotFound = 'IMPORT_BATCH_NOT_FOUND';

  // ── 文件 ──
  static const fileNotFound = 'FILE_NOT_FOUND';
  static const fileAccessDenied = 'FILE_ACCESS_DENIED';
  static const fileTooLarge = 'FILE_TOO_LARGE';
  static const fileTypeNotAllowed = 'FILE_TYPE_NOT_ALLOWED';
  static const uploadFailed = 'UPLOAD_FAILED';
  static const tooManyPhotos = 'TOO_MANY_PHOTOS';

  // ── NOI 预算 ──
  static const noiBudgetNotFound = 'NOI_BUDGET_NOT_FOUND';

  // ── 催收 ──
  static const invoiceAlreadyPaid = 'INVOICE_ALREADY_PAID';

  // ── 审批 ──
  static const approvalNotFound = 'APPROVAL_NOT_FOUND';
  static const approvalAlreadyProcessed = 'APPROVAL_ALREADY_PROCESSED';
  static const approvalSelfReview = 'APPROVAL_SELF_REVIEW';
}
```
