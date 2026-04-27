import 'package:postgres/postgres.dart';
import 'app_config.dart';

/// PostgreSQL 连接池单例
class Database {
  static Pool? _pool;

  static Future<Pool> init(AppConfig config) async {
    if (_pool != null) return _pool!;
    // 使用自定义解析器，正确处理密码中包含 @ / : 等特殊字符的情况
    final endpoint = _parseEndpoint(config.databaseUrl);
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

  /// 手动解析 DATABASE_URL，正确处理密码中含 @、: 等特殊字符的情况。
  /// 标准格式：postgres://user:password@host:port/database
  /// 关键点：取最后一个 @ 作为 userinfo 与 host 的分界，
  /// 取第一个 : 作为 username 与 password 的分界（密码中的 : 不影响）。
  static Endpoint _parseEndpoint(String url) {
    // 去掉 scheme（postgres:// 或 postgresql://）
    final schemeEnd = url.indexOf('://');
    final rest = url.substring(schemeEnd + 3);

    // 最后一个 @ 才是 userinfo/host 分隔符（密码中可能含 @）
    final atIndex = rest.lastIndexOf('@');
    final userInfo = rest.substring(0, atIndex);
    final hostPart = rest.substring(atIndex + 1);

    // username:password —— 只取第一个 : 分割，密码中的 : 保留
    final colonInUser = userInfo.indexOf(':');
    final username =
        colonInUser >= 0 ? userInfo.substring(0, colonInUser) : userInfo;
    final password =
        colonInUser >= 0 ? userInfo.substring(colonInUser + 1) : null;

    // host:port/database
    final slashInHost = hostPart.indexOf('/');
    final hostPort =
        slashInHost >= 0 ? hostPart.substring(0, slashInHost) : hostPart;
    final database =
        slashInHost >= 0 ? hostPart.substring(slashInHost + 1) : '';

    final colonInHost = hostPort.lastIndexOf(':');
    final host =
        colonInHost >= 0 ? hostPort.substring(0, colonInHost) : hostPort;
    final port = colonInHost >= 0
        ? int.tryParse(hostPort.substring(colonInHost + 1)) ?? 5432
        : 5432;

    return Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );
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
