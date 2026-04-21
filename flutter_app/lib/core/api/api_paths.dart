/// All API path constants extracted from API_INVENTORY v1.7.
///
/// Usage: `ApiPaths.authLogin` → `/api/auth/login`
/// Never hardcode path strings in Repository or BLoC code.
abstract final class ApiPaths {
  // ── Auth ──
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';
  static const authLogout = '/api/auth/logout';
  static const authMe = '/api/auth/me';
  static const authChangePassword = '/api/auth/change-password';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';

  // ── Users ──
  static const users = '/api/users';

  // ── Departments ──
  static const departments = '/api/departments';
  static const managedScopes = '/api/managed-scopes';

  // ── Assets ──
  static const buildings = '/api/buildings';
  static const floors = '/api/floors';
  static const floorPlans = '/api/floor-plans';
  static const units = '/api/units';
  static const unitsImport = '/api/units/import';
  static const unitsExport = '/api/units/export';
  static const renovations = '/api/renovations';
  static const assetsOverview = '/api/assets/overview';

  // ── Tenants ──
  static const tenants = '/api/tenants';

  // ── Contracts ──
  static const contracts = '/api/contracts';
  static const contractsWale = '/api/contracts/wale';
  static const contractsWaleTrend = '/api/contracts/wale/trend';
  static const contractsWaleWaterfall = '/api/contracts/wale/waterfall';
  static const contractsWaleDashboard = '/api/contracts/wale/dashboard';
  static const contractsAtRisk = '/api/contracts/at-risk';

  // ── Escalation Templates ──
  static const escalationTemplates = '/api/escalation-templates';

  // ── Alerts ──
  static const alerts = '/api/alerts';
  static const alertsUnread = '/api/alerts/unread';

  // ── Deposits ──
  static const deposits = '/api/deposits';

  // ── Invoices ──
  static const invoices = '/api/invoices';
  static const invoicesGenerate = '/api/invoices/generate';
  static const invoicesExport = '/api/invoices/export';

  // ── Payments ──
  static const payments = '/api/payments';

  // ── Expenses ──
  static const expenses = '/api/expenses';

  // ── NOI ──
  static const noiSummary = '/api/noi/summary';
  static const noiTrend = '/api/noi/trend';
  static const noiBreakdown = '/api/noi/breakdown';
  static const noiVacancyLoss = '/api/noi/vacancy-loss';
  static const noiBudget = '/api/noi/budget';

  // ── Meter Readings ──
  static const meterReadings = '/api/meter-readings';
  static const meterReadingsAllocationPreview =
      '/api/meter-readings/allocation-preview';

  // ── Turnover Reports ──
  static const turnoverReports = '/api/turnover-reports';

  // ── Dunning ──
  static const dunningLogs = '/api/dunning-logs';

  // ── KPI ──
  static const kpiMetrics = '/api/kpi/metrics';
  static const kpiSchemes = '/api/kpi/schemes';
  static const kpiScores = '/api/kpi/scores';
  static const kpiScoresGenerate = '/api/kpi/scores/generate';
  static const kpiScoresRecalculate = '/api/kpi/scores/recalculate';
  static const kpiRankings = '/api/kpi/rankings';
  static const kpiTrends = '/api/kpi/trends';
  static const kpiExport = '/api/kpi/export';
  static const kpiAppeals = '/api/kpi/appeals';

  // ── Work Orders ──
  static const workorders = '/api/workorders';
  static const workordersCostReport = '/api/workorders/cost-report';
  static const suppliers = '/api/suppliers';

  // ── Subleases (Internal) ──
  static const subleases = '/api/subleases';
  static const subleasesDashboard = '/api/subleases/dashboard';
  static const subleasesExport = '/api/subleases/export';

  // ── Sublease Portal ──
  static const subleasePortalLogin = '/api/sublease-portal/login';
  static const subleasePortalUnits = '/api/sublease-portal/units';
  static const subleasePortalSubleases = '/api/sublease-portal/subleases';

  // ── Imports ──
  static const imports = '/api/imports';

  // ── Files ──
  static const files = '/api/files';

  // ── Audit Logs ──
  static const auditLogs = '/api/audit-logs';

  // ── Jobs ──
  static const jobsExecutions = '/api/jobs/executions';

  // ── Notifications ──
  static const notifications = '/api/notifications';
  static const notificationsUnreadCount = '/api/notifications/unread-count';

  // ── Health ──
  static const health = '/api/health';
}
