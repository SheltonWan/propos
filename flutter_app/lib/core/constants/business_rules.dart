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

  // ── SVG Floor Map Cache ──
  /// 热区数据内存缓存 TTL（分钟）。TTL 到期后下次访问重新 fetch。
  static const heatmapCacheTtlMinutes = 5;
  /// 文件系统 SVG 缓存最大条目数（LRU 淘汰最旧文件）。
  static const svgCacheMaxEntries = 20;
  /// 预加载相邻楼层数量（当前楼层两侧各加载 N 层）。
  static const svgPreloadAdjacentCount = 2;
}
