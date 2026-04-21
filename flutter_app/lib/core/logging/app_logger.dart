import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// 应用日志单例封装，统一管理所有日志输出行为。
///
/// 各环境行为：
/// - **debug**：输出所有级别（verbose/debug/info/warning/error/critical），
///   彩色控制台 + TalkerScreen 可视化（摇动设备触发）。
/// - **profile**：输出 info 及以上，彩色控制台，无 TalkerScreen。
/// - **release**：仅记录 error/critical，无控制台输出，写入内存 buffer。
///
/// 使用方式：
/// ```dart
/// final logger = getIt<AppLogger>();
/// logger.info('合同列表加载完成');
/// logger.error('[ApiClient] 请求失败', exception, stackTrace);
/// ```
///
/// 禁止在 Widget / Cubit / Repository 中直接实例化。
class AppLogger {
  final Talker _talker;

  AppLogger._(this._talker);

  /// 工厂构造，由 DI 容器在 [configureDependencies] 中调用一次。
  factory AppLogger.create() {
    final talker = TalkerFlutter.init(
      settings: TalkerSettings(
        /// Release 模式关闭控制台打印，保留内存 history buffer。
        useConsoleLogs: !kReleaseMode,
        enabled: true,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          enableColors: !kReleaseMode,
        ),
      ),
    );
    return AppLogger._(talker);
  }

  /// 底层 [Talker] 实例，供 [TalkerDioLogger] / [TalkerBlocLogger] 直接引用。
  Talker get talker => _talker;

  // ── 日志级别方法 ──

  /// Verbose：仅 debug build 输出，供极细粒度调试使用。
  void verbose(String message, [Object? exception, StackTrace? stackTrace]) {
    if (kDebugMode) _talker.verbose(message, exception, stackTrace);
  }

  /// Debug：BLoC state 变更、路由跳转等开发期可见信息。
  void debug(String message, [Object? exception, StackTrace? stackTrace]) {
    if (!kReleaseMode) _talker.debug(message, exception, stackTrace);
  }

  /// Info：API 请求开始/完成（无 body）、关键业务流程节点。
  void info(String message) => _talker.info(message);

  /// Warning：可降级错误（token 刷新、网络重试、功能降级）。
  void warning(String message, [Object? exception, StackTrace? stackTrace]) =>
      _talker.warning(message, exception, stackTrace);

  /// Error：ApiException、业务流程中断，必须附 StackTrace。
  void error(String message, [Object? exception, StackTrace? stackTrace]) =>
      _talker.error(message, exception, stackTrace);

  /// Critical：崩溃级别，预留接入远程上报（Crashlytics/Sentry）。
  void critical(String message, [Object? exception, StackTrace? stackTrace]) =>
      _talker.critical(message, exception, stackTrace);
}
