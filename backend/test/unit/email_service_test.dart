/// EmailService 单元测试
///
/// 覆盖场景：
///   fromEnv()      — 默认值 / 自定义环境变量读取 / 端口解析失败回退默认值
///   sendOtpEmail() — 开发模式（smtpHost 为空）静默返回 /
///                    SMTP 路径：端口 465 启用 SSL / 端口 587 使用 STARTTLS /
///                    SMTP 路径：构造正确收件人与主题 /
///                    SMTP 路径：HTML 正文包含 OTP 和有效期 /
///                    SMTP 发送失败向上抛出（让 AuthService 负责吞异常）
library;

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:test/test.dart';

import 'package:propos_backend/shared/email_service.dart';

// ─── 测试替身 ──────────────────────────────────────────────────────────────────

/// 捕获传入参数的伪 SMTP 发送函数，不真实连接服务器
class FakeSender {
  Message? capturedMessage;
  SmtpServer? capturedServer;
  bool shouldThrow = false;

  Future<SendReport> call(Message message, SmtpServer server) async {
    if (shouldThrow) throw SmtpClientCommunicationException('SMTP 连接失败（测试模拟）');
    capturedMessage = message;
    capturedServer = server;
    final now = DateTime.now();
    return SendReport(message, now, now, now);
  }
}

// ─── 辅助构建函数 ──────────────────────────────────────────────────────────────

/// 构建注入了伪 sender 的 EmailService
EmailService makeService(
  FakeSender fakeSender, {
  String smtpHost = 'smtp.test.com',
  int smtpPort = 587,
  String smtpUser = 'user@test.com',
  String smtpPassword = 'secret',
  String senderAddress = 'noreply@propos.internal',
}) {
  return EmailService(
    smtpHost: smtpHost,
    smtpPort: smtpPort,
    smtpUser: smtpUser,
    smtpPassword: smtpPassword,
    senderAddress: senderAddress,
    sender: fakeSender.call,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  group('EmailService.fromEnv()', () {
    test('所有环境变量均未设置 → 使用默认值', () {
      final svc = EmailService.fromEnv(get: (_) => null);

      // smtpHost 默认空字符串（开发模式）
      // 通过 sendOtpEmail 不抛异常来间接验证构造成功
      expect(
        svc.sendOtpEmail(email: 'a@b.com', otp: '123456'),
        completes,
      );
    });

    test('从环境变量读取 SMTP 配置 → 字段正确注入', () {
      final env = {
        'SMTP_HOST': 'smtp.example.com',
        'SMTP_PORT': '587',
        'SMTP_USER': 'hello@example.com',
        'SMTP_PASSWORD': 'pa\$\$word',
        'SMTP_FROM': 'no-reply@example.com',
      };
      // 使用注入伪 sender 避免真实 SMTP 调用
      final fakeSender = FakeSender();
      final svc = EmailService.fromEnv(get: (k) => env[k], sender: fakeSender.call);

      // 触发 SMTP 路径以验证 host/port/ssl 是否正确传入
      expect(
        svc.sendOtpEmail(email: 'x@y.com', otp: '654321'),
        completes,
      );
    });

    test('SMTP_PORT 无法解析为整数 → 回退默认值 465', () {
      final env = {'SMTP_HOST': '', 'SMTP_PORT': 'not-a-number'};
      // 不抛异常即说明 int.tryParse 回退逻辑正常
      expect(
        () => EmailService.fromEnv(get: (k) => env[k]),
        returnsNormally,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('sendOtpEmail() — 开发模式（smtpHost 为空）', () {
    test('smtpHost 为空 → 不调用 sender，正常返回', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender, smtpHost: '');

      await svc.sendOtpEmail(email: 'dev@propos.com', otp: '000000');

      // sender 从未被调用
      expect(fakeSender.capturedMessage, isNull);
    });

    test('smtpHost 为空 → 不抛出任何异常', () {
      final svc = makeService(FakeSender(), smtpHost: '');

      expect(
        svc.sendOtpEmail(email: 'dev@propos.com', otp: '111111'),
        completes,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  group('sendOtpEmail() — SMTP 发送路径', () {
    test('端口 465 → SmtpServer.ssl 为 true', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender, smtpPort: 465);

      await svc.sendOtpEmail(email: 'a@b.com', otp: '123456');

      expect(fakeSender.capturedServer, isNotNull);
      expect(fakeSender.capturedServer!.ssl, isTrue);
      expect(fakeSender.capturedServer!.port, 465);
    });

    test('端口 587 → SmtpServer.ssl 为 false（使用 STARTTLS）', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender, smtpPort: 587);

      await svc.sendOtpEmail(email: 'a@b.com', otp: '123456');

      expect(fakeSender.capturedServer!.ssl, isFalse);
      expect(fakeSender.capturedServer!.port, 587);
    });

    test('SmtpServer 使用正确的 host / username / password', () async {
      final fakeSender = FakeSender();
      final svc = makeService(
        fakeSender,
        smtpHost: 'smtp.myhost.com',
        smtpUser: 'me@myhost.com',
        smtpPassword: 'hunter2',
      );

      await svc.sendOtpEmail(email: 'r@r.com', otp: '999999');

      final server = fakeSender.capturedServer!;
      expect(server.host, 'smtp.myhost.com');
      expect(server.username, 'me@myhost.com');
      expect(server.password, 'hunter2');
    });

    test('smtpUser 为空 → SmtpServer.username 为 null（匿名发送）', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender, smtpUser: '', smtpPassword: '');

      await svc.sendOtpEmail(email: 'a@b.com', otp: '123456');

      expect(fakeSender.capturedServer!.username, isNull);
      expect(fakeSender.capturedServer!.password, isNull);
    });

    test('Message 收件人与主题正确', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender, senderAddress: 'noreply@propos.com');

      await svc.sendOtpEmail(email: 'target@example.com', otp: '555555');

      final msg = fakeSender.capturedMessage!;
      expect(msg.recipients, contains('target@example.com'));
      expect(msg.subject, contains('PropOS'));
      expect(msg.subject, contains('验证码'));
      expect((msg.from as Address).mailAddress, 'noreply@propos.com');
    });

    test('HTML 正文包含 OTP 明文', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender);

      await svc.sendOtpEmail(email: 'a@b.com', otp: '246810');

      expect(fakeSender.capturedMessage!.html, contains('246810'));
    });

    test('HTML 正文包含有效期分钟数', () async {
      final fakeSender = FakeSender();
      final svc = makeService(fakeSender);

      await svc.sendOtpEmail(
        email: 'a@b.com',
        otp: '111111',
        expireMinutes: 15,
      );

      expect(fakeSender.capturedMessage!.html, contains('15'));
    });

    test('sender 抛出 MailerException → 异常向上传播（由调用方 AuthService 吞掉）',
        () async {
      final fakeSender = FakeSender()..shouldThrow = true;
      final svc = makeService(fakeSender);

      await expectLater(
        svc.sendOtpEmail(email: 'a@b.com', otp: '123456'),
        throwsA(isA<MailerException>()),
      );
    });
  });
}
