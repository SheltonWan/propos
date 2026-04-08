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
    _pool = Pool.withEndpoints(
      [endpoint],
      settings: const PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
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
}
