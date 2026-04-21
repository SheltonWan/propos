import 'dart:io' show Platform;

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// 用于测试注入的 SMTP 发送函数类型
typedef SmtpSender = Future<SendReport> Function(Message, SmtpServer);

/// 邮件发送服务。
/// 当前实现：通过 SMTP 或第三方邮件 API 发送（生产），
///           若未配置 SMTP，则仅打印日志（开发模式）。
///
/// 约定：只有 backend 层调用此服务，前端不感知邮件发送逻辑。
class EmailService {
  /// SMTP 主机（空字符串表示使用开发模式）
  final String _smtpHost;
  final int _smtpPort;
  final String _smtpUser;
  final String _smtpPassword;
  final String _senderAddress;

  /// SMTP 发送函数（生产使用 mailer 的 send，测试注入伪实现）
  final SmtpSender _sender;

  EmailService({
    required String smtpHost,
    required int smtpPort,
    required String smtpUser,
    required String smtpPassword,
    required String senderAddress,
    SmtpSender? sender,
  })  : _smtpHost = smtpHost,
        _smtpPort = smtpPort,
        _smtpUser = smtpUser,
        _smtpPassword = smtpPassword,
        _senderAddress = senderAddress,
        _sender = sender ?? send;

  /// 从环境变量构建 EmailService 实例
  factory EmailService.fromEnv({
    String? Function(String)? get,
    SmtpSender? sender,
  }) {
    String? lookup(String key) => get != null ? get(key) : Platform.environment[key];
    return EmailService(
      smtpHost: lookup('SMTP_HOST') ?? '',
      smtpPort: int.tryParse(lookup('SMTP_PORT') ?? '') ?? 465,
      smtpUser: lookup('SMTP_USER') ?? '',
      smtpPassword: lookup('SMTP_PASSWORD') ?? '',
      senderAddress: lookup('SMTP_FROM') ?? 'noreply@propos.internal',
      sender: sender,
    );
  }

  /// 发送 OTP 验证码邮件（忘记密码场景）。
  ///
  /// [email]         — 收件人邮箱
  /// [otp]           — 6 位数字验证码明文
  /// [expireMinutes] — 有效期（分钟）
  Future<void> sendOtpEmail({
    required String email,
    required String otp,
    int expireMinutes = 10,
  }) async {
    final subject = '【PropOS】您的密码重置验证码';

    if (_smtpHost.isEmpty) {
      // 开发模式：控制台输出（不实际发送）
      print('[EmailService] 开发模式：模拟发送 OTP 邮件');
      print('  收件人: $email');
      print('  主题:   $subject');
      print('  验证码: $otp（有效期 $expireMinutes 分钟）');
      return;
    }

    // 端口 465 使用隐式 SSL，其余端口（如 587）使用 STARTTLS
    final useSSL = _smtpPort == 465;
    final smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      ssl: useSSL,
      username: _smtpUser.isNotEmpty ? _smtpUser : null,
      password: _smtpPassword.isNotEmpty ? _smtpPassword : null,
    );

    final message = Message()
      ..from = Address(_senderAddress, 'PropOS')
      ..recipients.add(email)
      ..subject = subject
      ..html = _buildOtpEmailBody(otp, expireMinutes);

    final report = await _sender(message, smtpServer);
    print('[EmailService] OTP 邮件已发送至 $email，服务器响应: ${report.toString()}');
  }

  /// 构建 OTP 验证码邮件 HTML 正文
  String _buildOtpEmailBody(String otp, int expireMinutes) {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: sans-serif; color: #333; max-width: 600px; margin: auto;">
  <h2>PropOS &#8212; 密码重置验证码</h2>
  <p>您好，</p>
  <p>您正在重置 PropOS 账号密码，请使用以下验证码完成操作：</p>
  <p style="text-align: center; margin: 28px 0;">
    <span style="
      display: inline-block;
      font-size: 36px;
      font-weight: bold;
      letter-spacing: 12px;
      padding: 16px 32px;
      background: #f5f5f5;
      border-radius: 8px;
      color: #1677ff;
    ">$otp</span>
  </p>
  <p>验证码有效期为 <strong>$expireMinutes 分钟</strong>，如超时请重新获取。</p>
  <p>如果您没有发起此请求，请忽略此邮件，您的账号密码不会被修改。</p>
</body></html>''';
  }
}
