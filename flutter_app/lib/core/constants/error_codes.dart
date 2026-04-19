/// All error codes from the backend ERROR_CODE_REGISTRY.
///
/// Frontend uses these codes for programmatic error handling.
/// Never parse `message` for business logic — always match on `code`.
abstract final class ErrorCodes {
  // ── Common ──
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const conflict = 'CONFLICT';
  static const internalError = 'INTERNAL_ERROR';

  // ── Auth: Login ──
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const accountLocked = 'ACCOUNT_LOCKED';
  static const accountDisabled = 'ACCOUNT_DISABLED';
  static const accountFrozen = 'ACCOUNT_FROZEN';

  // ── Auth: Token ──
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const tokenRevoked = 'TOKEN_REVOKED';
  static const sessionVersionMismatch = 'SESSION_VERSION_MISMATCH';

  // ── User Management ──
  static const emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const passwordTooWeak = 'PASSWORD_TOO_WEAK';
  static const boundContractRequired = 'BOUND_CONTRACT_REQUIRED';
  static const contractNotSubleaseMaster = 'CONTRACT_NOT_SUBLEASE_MASTER';
  static const invalidOldPassword = 'INVALID_OLD_PASSWORD';
  static const passwordSameAsOld = 'PASSWORD_SAME_AS_OLD';

  // ── Organization ──
  static const maxDepthExceeded = 'MAX_DEPTH_EXCEEDED';
  static const parentDepartmentNotFound = 'PARENT_DEPARTMENT_NOT_FOUND';
  static const parentDepartmentInactive = 'PARENT_DEPARTMENT_INACTIVE';
  static const departmentHasActiveUsers = 'DEPARTMENT_HAS_ACTIVE_USERS';
  static const departmentHasActiveChildren = 'DEPARTMENT_HAS_ACTIVE_CHILDREN';

  // ── Assets ──
  static const floorAlreadyExists = 'FLOOR_ALREADY_EXISTS';
  static const buildingNotFound = 'BUILDING_NOT_FOUND';
  static const floorNotFound = 'FLOOR_NOT_FOUND';
  static const unitNotFound = 'UNIT_NOT_FOUND';
  static const invalidCadFile = 'INVALID_CAD_FILE';
  static const cadConversionFailed = 'CAD_CONVERSION_FAILED';

  // ── Tenants ──
  static const tenantNotFound = 'TENANT_NOT_FOUND';
  static const invalidPassword = 'INVALID_PASSWORD';

  // ── Contracts ──
  static const contractNotFound = 'CONTRACT_NOT_FOUND';
  static const contractNoAlreadyExists = 'CONTRACT_NO_ALREADY_EXISTS';
  static const unitAlreadyLeased = 'UNIT_ALREADY_LEASED';
  static const invalidContractDates = 'INVALID_CONTRACT_DATES';
  static const contractUnitsNotPatchable = 'CONTRACT_UNITS_NOT_PATCHABLE';
  static const contractNotActive = 'CONTRACT_NOT_ACTIVE';
  static const terminationDateInvalid = 'TERMINATION_DATE_INVALID';

  // ── Deposits ──
  static const depositNotFound = 'DEPOSIT_NOT_FOUND';
  static const deductionExceedsBalance = 'DEDUCTION_EXCEEDS_BALANCE';
  static const contractHasOutstandingInvoices =
      'CONTRACT_HAS_OUTSTANDING_INVOICES';
  static const targetContractNotRenewal = 'TARGET_CONTRACT_NOT_RENEWAL';

  // ── Invoices ──
  static const invoiceNotFound = 'INVOICE_NOT_FOUND';
  static const invoiceNotVoidable = 'INVOICE_NOT_VOIDABLE';

  // ── Payments ──
  static const allocationExceedsOutstanding =
      'ALLOCATION_EXCEEDS_OUTSTANDING';
  static const allocationSumMismatch = 'ALLOCATION_SUM_MISMATCH';

  // ── Expenses ──
  static const expenseNotFound = 'EXPENSE_NOT_FOUND';
  static const expenseLinkedToWorkorder = 'EXPENSE_LINKED_TO_WORKORDER';

  // ── Meter Readings ──
  static const invalidReading = 'INVALID_READING';
  static const meterReadingAlreadyInvoiced = 'METER_READING_ALREADY_INVOICED';

  // ── NOI Budget ──
  static const noiBudgetNotFound = 'NOI_BUDGET_NOT_FOUND';

  // ── Dunning ──
  static const invoiceAlreadyPaid = 'INVOICE_ALREADY_PAID';

  // ── KPI ──
  static const kpiSchemeNotFound = 'KPI_SCHEME_NOT_FOUND';
  static const weightSumNotOne = 'WEIGHT_SUM_NOT_ONE';
  static const metricNotManualInput = 'METRIC_NOT_MANUAL_INPUT';
  static const appealWindowClosed = 'APPEAL_WINDOW_CLOSED';
  static const snapshotNotFound = 'SNAPSHOT_NOT_FOUND';
  static const snapshotNotFrozen = 'SNAPSHOT_NOT_FROZEN';

  // ── Work Orders ──
  static const workorderNotFound = 'WORKORDER_NOT_FOUND';
  static const invalidStatusTransition = 'INVALID_STATUS_TRANSITION';
  static const invalidWorkOrderType = 'INVALID_WORK_ORDER_TYPE';
  static const invalidIssueTypeForWorkOrderType =
      'INVALID_ISSUE_TYPE_FOR_WORK_ORDER_TYPE';
  static const contractRequiredForInspection =
      'CONTRACT_REQUIRED_FOR_INSPECTION';
  static const assigneeNotFound = 'ASSIGNEE_NOT_FOUND';

  // ── Subleases ──
  static const subleaseNotFound = 'SUBLEASE_NOT_FOUND';
  static const subleaseAreaExceedsMaster = 'SUBLEASE_AREA_EXCEEDS_MASTER';
  static const subleaseNotEditable = 'SUBLEASE_NOT_EDITABLE';
}
