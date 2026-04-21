/// Business rule constants.
///
/// All business thresholds and magic numbers must be defined here.
/// Never hardcode these values in Widget, BLoC, or Repository code.
abstract final class BusinessRules {
  // ── Contract Expiry Alerts (days) ──
  static const expiryAlertDays90 = 90;
  static const expiryAlertDays60 = 60;
  static const expiryAlertDays30 = 30;

  // ── Invoice Overdue Nodes (days) ──
  static const overdueNode1 = 1;
  static const overdueNode7 = 7;
  static const overdueNode15 = 15;

  // ── KPI ──
  static const kpiFullScoreThreshold = 0.95;
  static const kpiAppealWindowDays = 7;

  // ── Auth Session ──
  /// Refresh token 剩余有效期低于此天数时，自动触发静默续期，避免用户被强制登出。
  static const refreshTokenWarnDays = 3;

  // ── Password ──
  static const passwordMinLength = 8;

  // ── Deposit ──
  static const depositNotCountedInNoi = true;
}
