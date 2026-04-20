/// 编译时注入的环境配置，通过 `--dart-define` 传入。
///
/// 构建命令示例：
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.propos.cn --dart-define=USE_MOCK=false
/// ```
abstract final class AppConfig {
  /// API 基础地址，默认本地开发地址。
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 是否启用 Mock 拦截器（仅开发/测试时使用）。
  static const bool useMock = bool.fromEnvironment('USE_MOCK');
}
