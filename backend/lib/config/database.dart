import 'package:postgres/postgres.dart';
import 'app_config.dart';

/// PostgreSQL 连接池单例
class Database {
  static Pool? _pool;

  static Future<Pool> init(AppConfig config) async {
    if (_pool != null) return _pool!;
    final uri = Uri.parse(config.databaseUrl);
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.path.replaceFirst('/', ''),
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1
          ? uri.userInfo.split(':').last
          : null,
    );
    // SSL 模式由环境变量 DB_SSL_MODE 控制（默认 require）
    // 生产环境建议使用 verify-full，本地开发可设为 disable
    final sslMode = _resolveSslMode(config.dbSslMode);
    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: sslMode,
      ),
    );
    // 验证连接
    await _pool!.withConnection((conn) => conn.execute('SELECT 1'));
    return _pool!;
  }

  static Pool get pool {
    if (_pool == null) {
      throw StateError('Database.init() 尚未调用');
    }
    return _pool!;
  }

  /// 将 AppConfig 中的字符串值映射为 postgres 包的 SslMode 枚举
  static SslMode _resolveSslMode(String mode) {
    switch (mode) {
      case 'verify-full':
        return SslMode.verifyFull;
      case 'disable':
        return SslMode.disable;
      case 'require':
      default:
        return SslMode.require;
    }
  }
}
