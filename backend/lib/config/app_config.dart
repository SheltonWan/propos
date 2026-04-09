import 'dart:io';

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
  });

  static AppConfig load({String? Function(String)? get}) {
    String? lookup(String key) => get != null ? get(key) : Platform.environment[key];

    String require(String key) {
      final value = lookup(key);
      if (value == null || value.isEmpty) {
        stderr.writeln('[FATAL] 缺少必须环境变量: $key — 服务拒绝启动');
        exit(1);
      }
      return value;
    }

    final databaseUrl = require('DATABASE_URL');
    final jwtSecret = require('JWT_SECRET');
    if (jwtSecret.length < 32) {
      stderr.writeln('[FATAL] JWT_SECRET 长度不足 32 字节 — 服务拒绝启动');
      exit(1);
    }
    final jwtExpiresInHoursStr = require('JWT_EXPIRES_IN_HOURS');
    final jwtExpiresInHours = int.tryParse(jwtExpiresInHoursStr);
    if (jwtExpiresInHours == null) {
      stderr.writeln('[FATAL] JWT_EXPIRES_IN_HOURS 必须为整数 — 服务拒绝启动');
      exit(1);
    }
    final fileStoragePath = require('FILE_STORAGE_PATH');
    final encryptionKey = require('ENCRYPTION_KEY');
    if (encryptionKey.length < 32) {
      stderr.writeln('[FATAL] ENCRYPTION_KEY 长度不足 32 字节 — 服务拒绝启动');
      exit(1);
    }
    final appPortStr = require('APP_PORT');
    final appPort = int.tryParse(appPortStr);
    if (appPort == null) {
      stderr.writeln('[FATAL] APP_PORT 必须为整数 — 服务拒绝启动');
      exit(1);
    }

    return AppConfig._(
      databaseUrl: databaseUrl,
      jwtSecret: jwtSecret,
      jwtExpiresInHours: jwtExpiresInHours,
      fileStoragePath: fileStoragePath,
      encryptionKey: encryptionKey,
      appPort: appPort,
      corsOrigins: lookup('CORS_ORIGINS') ?? '*',
      logLevel: lookup('LOG_LEVEL') ?? 'info',
      maxUploadSizeMb: int.tryParse(lookup('MAX_UPLOAD_SIZE_MB') ?? '') ?? 50,
    );
  }
}
