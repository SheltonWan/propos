import 'dart:io' show Platform;

/// 邮件发送服务。
/// 当前实现：通过 SMTP 或第三方邮件 API 发送（生产），
///           若未配置 SMTP，则仅打印日志（开发模式）。
///
/// 约定：只有 backend 层调用此服务，前端不感知邮件发送逻辑。
class EmailService {
  /// 重置密码邮件中跳转到 Admin Web 的 base URL
  /// 例如：https://admin.company.com
  final String _adminWebBaseUrl;

  /// SMTP 主机（空字符串表示使用开发模式）
  final String _smtpHost;
  final int _smtpPort;
  final String _smtpUser;
  final String _smtpPassword;
  final String _senderAddress;

  EmailService({
    required String adminWebBaseUrl,
    required String smtpHost,
    required int smtpPort,
    required String smtpUser,
    required String smtpPassword,
    required String senderAddress,
  })  : _adminWebBaseUrl = adminWebBaseUrl,
        _smtpHost = smtpHost,
        _smtpPort = smtpPort,
        _smtpUser = smtpUser,
        _smtpPassword = smtpPassword,
        _senderAddress = senderAddress;

  /// 从环境变量构建 EmailService 实例
  factory EmailService.fromEnv({String? Function(String)? get}) {
    String? lookup(String key) => get != null ? get(key) : Platform.environment[key];
    return EmailService(
      adminWebBaseUrl: lookup('ADMIN_WEB_BASE_URL') ?? 'http://localhost:5173',
      smtpHost: lookup('SMTP_HOST') ?? '',
      smtpPort: int.tryParse(lookup('SMTP_PORT') ?? '') ?? 465,
      smtpUser: lookup('SMTP_USER') ?? '',
      smtpPassword: lookup('SMTP_PASSWORD') ?? '',
      senderAddress: lookup('SMTP_FROM') ?? 'noreply@propos.internal',
    );
  }

  /// 发送密码重置邮件。
  /// [email] — 收件人邮箱
  /// [rawToken] — 原始 token（将拼接到链接中，不存库）
  /// [locale] — 邮件语言（现阶段固定 zh-CN）
  Future<void> sendPasswordResetEmail({
    required String email,
    required String rawToken,
    String locale = 'zh-CN',
  }) async {
    final resetLink = '$_adminWebBaseUrl/reset-password?token=$rawToken';
    final subject = '【PropOS】密码重置请求';
    final body = _buildEmailBody(resetLink);

    if (_smtpHost.isEmpty) {
      // 开发模式：控制台输出（不实际发送）
      print('[EmailService] 开发模式：模拟发送邮件');
      print('  收件人: $email');
      print('  主题:   $subject');
      print('  重置链接: $resetLink');
      return;
    }

    // TODO: 接入 SMTP 库（如 dart_mailer 或 mailer 包），此处预留占位
    // 示例结构（待引入依赖后解注释）：
    //
    // final smtpServer = SmtpServer(
    //   _smtpHost,
    //   port: _smtpPort,
    //   username: _smtpUser,
    //   password: _smtpPassword,
    //   ssl: true,
    // );
    // final message = Message()
    //   ..from = Address(_senderAddress, 'PropOS 系统')
    //   ..recipients.add(email)
    //   ..subject = subject
    //   ..html = body;
    // await send(message, smtpServer);

    // 当前无 SMTP 依赖时退化为日志输出
    print('[EmailService] 邮件发送（SMTP 依赖待配置）: $email -> $resetLink');
  }

  /// 构建 HTML 邮件正文
  String _buildEmailBody(String resetLink) {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: sans-serif; color: #333; max-width: 600px; margin: auto;">
  <h2>PropOS &#8212; 密码重置</h2>
  <p>您好，</p>
  <p>我们收到了您的密码重置请求。请点击下方按钮完成密码重置：</p>
  <p style="text-align: center; margin: 28px 0;">
    <a href="$resetLink"
       style="background:#1677ff;color:#fff;padding:12px 28px;border-radius:6px;text-decoration:none;font-size:16px;">
      重置密码
    </a>
  </p>
  <p>或复制以下链接至浏览器打开：</p>
  <p style="word-break:break-all;color:#1677ff;">$resetLink</p>
  <p><strong>链接有效期为 2 小时</strong>，过期后请重新申请。</p>
  <p>如果您没有发起此请求，请忽略此邮件。</p>
  <hr style="margin-top:32px;">
  <p style="font-size:12px;color:#888;">此邮件由 PropOS 系统自动发送，请勿回复。</p>
</body>
</html>
''';
  }
}
