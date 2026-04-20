import 'dart:io' show Platform, Directory;
import 'package:path/path.dart' as path_lib;

/// 全局运行时配置，从环境变量读取。
/// 缺失必须变量时拒绝启动并输出明确错误。
class AppConfig {
  final String databaseUrl;
  final String jwtSecret;
  final int jwtExpiresInHours;
  final String fileStoragePath;
  final String encryptionKey;
  final int appPort;

  // 可选变量（缺失时使用默认值）
  final String corsOrigins;
  final String logLevel;
  final int maxUploadSizeMb;
  /// 数据库 SSL 模式：require（默认）/ verify-full / disable
  /// 生产环境建议设为 verify-full，本地开发可设为 disable
  final String dbSslMode;

  AppConfig._({
    required this.databaseUrl,
    required this.jwtSecret,
    required this.jwtExpiresInHours,
    required this.fileStoragePath,
    required this.encryptionKey,
    required this.appPort,
    required this.corsOrigins,
    required this.logLevel,
    required this.maxUploadSizeMb,
    required this.dbSslMode,
  });

  static AppConfig load({String? Function(String)? get}) {
    String? lookup(String key) => get != null ? get(key) : Platform.environment[key];

    String require(String key) {
      final value = lookup(key);
      if (value == null || value.isEmpty) {
        throw StateError('缺少环境变量: $key');
      }
      return value;
    }

    final databaseUrl = require('DATABASE_URL');
    final jwtSecret = require('JWT_SECRET');
    if (jwtSecret.length < 32) {
      throw StateError('JWT_SECRET 长度不足 32 字节，至少需要 32 个字符');
    }
    final jwtExpiresInHoursStr = require('JWT_EXPIRES_IN_HOURS');
    final jwtExpiresInHours = int.tryParse(jwtExpiresInHoursStr);
    if (jwtExpiresInHours == null) {
      throw StateError('环境变量 JWT_EXPIRES_IN_HOURS 必须为整数，当前值: $jwtExpiresInHoursStr');
    }
    final rawStoragePath = require('FILE_STORAGE_PATH');
    // 相对路径以 CWD（通常为 backend/）为基准解析为绝对路径
    final fileStoragePath = path_lib.isAbsolute(rawStoragePath)
        ? rawStoragePath
        : path_lib.join(Directory.current.path, rawStoragePath);
    final encryptionKey = require('ENCRYPTION_KEY');
    if (encryptionKey.length < 32) {
      throw StateError('ENCRYPTION_KEY 长度不足 32 字节，至少需要 32 个字符');
    }
    final appPortStr = require('APP_PORT');
    final appPort = int.tryParse(appPortStr);
    if (appPort == null) {
      throw StateError('环境变量 APP_PORT 必须为整数，当前值: $appPortStr');
    }

    return AppConfig._(
      databaseUrl: databaseUrl,
      jwtSecret: jwtSecret,
      jwtExpiresInHours: jwtExpiresInHours,
      fileStoragePath: fileStoragePath,
      encryptionKey: encryptionKey,
      appPort: appPort,
      // 默认为空字符串（不发 CORS 头）；生产环境按实际前端域名配置
      corsOrigins: lookup('CORS_ORIGINS') ?? '',
      logLevel: lookup('LOG_LEVEL') ?? 'info',
      maxUploadSizeMb: int.tryParse(lookup('MAX_UPLOAD_SIZE_MB') ?? '') ?? 50,
      dbSslMode: _validatedSslMode(lookup('DB_SSL_MODE') ?? 'require'),
    );
  }

  /// 校验并标准化 DB_SSL_MODE 值。
  /// 只接受 require / verify-full / disable，其余值拒绝启动。
  static String _validatedSslMode(String raw) {
    const allowed = {'require', 'verify-full', 'disable'};
    final value = raw.trim().toLowerCase();
    if (!allowed.contains(value)) {
      throw StateError(
        'DB_SSL_MODE 值无效: "$raw"，允许的值为: require / verify-full / disable',
      );
    }
    return value;
  }
}
