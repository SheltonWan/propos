/// 一次性 SMTP 发送测试脚本，运行后请删除，不要提交到版本控制。
/// 用法：
///   cd backend
///   dart run bin/test_smtp.dart
///
/// 脚本从 .env 文件读取 SMTP 配置，不需要手动填写凭据。
library;

import 'dart:io';
import 'dart:math';

import 'package:propos_backend/shared/email_service.dart';

Future<void> main() async {
  // 加载 .env 文件（从 backend/ 目录运行时相对路径为 .env）
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('[错误] 未找到 .env 文件，请在 backend/ 目录下运行此脚本');
    exit(1);
  }

  final env = <String, String>{};
  for (final line in envFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx == -1) continue;
    env[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
  }

  // 生成随机 6 位验证码
  final otp = (100000 + Random.secure().nextInt(900000)).toString();

  // 目标收件人
  const recipient = 'smartv@qq.com';

  print('[测试] 准备向 $recipient 发送验证码: $otp');
  print('[测试] SMTP 服务器: ${env['SMTP_HOST']}:${env['SMTP_PORT']}');
  print('[测试] 发件人: ${env['SMTP_FROM']}');

  final service = EmailService(
    smtpHost: env['SMTP_HOST'] ?? '',
    smtpPort: int.tryParse(env['SMTP_PORT'] ?? '') ?? 465,
    smtpUser: env['SMTP_USER'] ?? '',
    smtpPassword: env['SMTP_PASSWORD'] ?? '',
    senderAddress: env['SMTP_FROM'] ?? '',
  );

  try {
    await service.sendOtpEmail(
      email: recipient,
      otp: otp,
      expireMinutes: 10,
    );
    print('[测试] 发送成功！');
  } catch (e) {
    stderr.writeln('[测试] 发送失败: $e');
    exit(1);
  }

  exit(0);
}
