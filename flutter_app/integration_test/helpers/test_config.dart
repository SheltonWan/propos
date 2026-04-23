/// 集成测试环境配置。
///
/// 通过 --dart-define 注入，本地开发默认指向 localhost:8080。
/// 运行示例：
///   flutter test integration_test/ \
///     --dart-define=API_BASE_URL=http://localhost:8080 \
///     --dart-define=IT_ADMIN_EMAIL=admin@propos.local \
///     --dart-define=IT_ADMIN_PASSWORD=Test1234! \
///     --dart-define=IT_SUBLORD_EMAIL=dingsheng@external.com \
///     --dart-define=IT_SUBLORD_PASSWORD=Test1234! \
///     -d `<simulator_id>`
abstract final class IntegrationTestConfig {
  /// 本地后端 Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// 超级管理员邮箱（种子数据 U-ADMIN）
  static const String adminEmail = String.fromEnvironment(
    'IT_ADMIN_EMAIL',
    defaultValue: 'admin@propos.local',
  );

  /// 超级管理员密码
  static const String adminPassword = String.fromEnvironment(
    'IT_ADMIN_PASSWORD',
    defaultValue: 'Test1234!',
  );

  /// 二房东邮箱（种子数据 U-SUBLORD）
  static const String subLandlordEmail = String.fromEnvironment(
    'IT_SUBLORD_EMAIL',
    defaultValue: 'dingsheng@external.com',
  );

  /// 二房东密码
  static const String subLandlordPassword = String.fromEnvironment(
    'IT_SUBLORD_PASSWORD',
    defaultValue: 'Test1234!',
  );

  /// 数据库中不存在的邮箱（用于防枚举测试）
  static const String nonExistentEmail = 'no_such_user_xyz_integration@propos.test';

  /// 错误密码（用于 INVALID_CREDENTIALS 测试）
  static const String wrongPassword = 'WrongPassword_Integration_999!';

  /// 等待真实 HTTP 完成的最大超时（用于 pumpAndSettle/Future.delayed）
  static const Duration httpTimeout = Duration(seconds: 15);

  /// pump 轮询间隔
  static const Duration pumpInterval = Duration(milliseconds: 100);
}
