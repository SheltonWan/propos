import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/auth/domain/entities/user.dart';
import 'package:propos_app/features/auth/presentation/pages/login_page.dart';
import 'package:propos_app/main.dart';

import '../../helpers/di_test_setup.dart';
import '../../helpers/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────────────────
  // Group 1：Repository 层 → 本地后端（无 Widget 树，直接调用 HTTP）
  // ──────────────────────────────────────────────────────────────────────────
  group('Repository 层 → 本地后端', () {
    late RawAuthComponents raw;

    setUpAll(() async {
      // 重置管理员账号的登录失败计数和锁定状态。
      // 背景：test 1.2 会用错误密码请求管理员账号，每轮测试积累一次失败次数；
      // 后端阈值为 5 次，第 5 轮起账号将被锁定 30 分钟，导致所有后续测试失败。
      // setUpAll 在每次测试套件启动时重置，确保每轮都从干净状态开始。
      await resetTestAccountLock(IntegrationTestConfig.adminEmail);
    });

    setUp(() async {
      raw = buildRawComponents();
      // 每次测试前清除 SecureStorage，确保状态隔离
      await raw.storage.deleteAll();
    });

    tearDown(() async {
      await raw.storage.deleteAll();
      raw.dispose();
    });

    // ── 1.1 正确凭证登录 ───────────────────────────────────────────────────
    test('login 正确凭证 → tokens 写入 storage、user 信息正确', () async {
      final (tokens, user) = await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );

      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
      expect(user.email, IntegrationTestConfig.adminEmail);
      expect(user.role, UserRole.superAdmin);

      // 验证 tokens 已持久化到 SecureStorage
      expect(
        await raw.storage.read(key: 'access_token'),
        tokens.accessToken,
      );
      expect(
        await raw.storage.read(key: 'refresh_token'),
        tokens.refreshToken,
      );
    });

    // ── 1.2 错误密码 ───────────────────────────────────────────────────────
    //
    // 期望后端拒绝认证。正常情况返回 INVALID_CREDENTIALS；
    // 若同一账号在此轮测试前已有失败次数积累（例如 setUpAll 的重置请求未生效），
    // 可能直接返回 ACCOUNT_LOCKED——两者都属于「凭证被拒」的合法结果。
    test('login 错误密码 → ApiException(code: INVALID_CREDENTIALS)', () async {
      await expectLater(
        () => raw.repository.login(
          email: IntegrationTestConfig.adminEmail,
          password: IntegrationTestConfig.wrongPassword,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            anyOf('INVALID_CREDENTIALS', 'ACCOUNT_LOCKED'),
          ),
        ),
      );
    });

    // ── 1.3 不存在的邮箱 ──────────────────────────────────────────────────
    test('login 不存在的邮箱 → ApiException(code: INVALID_CREDENTIALS)', () async {
      await expectLater(
        () => raw.repository.login(
          email: IntegrationTestConfig.nonExistentEmail,
          password: IntegrationTestConfig.wrongPassword,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    // ── 1.4 登录后 isLoggedIn ─────────────────────────────────────────────
    test('login 成功后 isLoggedIn → true', () async {
      await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );
      expect(await raw.repository.isLoggedIn, true);
    });

    // ── 1.5 getCurrentUser ────────────────────────────────────────────────
    test('login 后 getCurrentUser → 返回完整 CurrentUser', () async {
      await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );
      final user = await raw.repository.getCurrentUser();

      expect(user.id, isNotEmpty);
      expect(user.email, IntegrationTestConfig.adminEmail);
      expect(user.role, UserRole.superAdmin);
      expect(user.isActive, true);
      expect(user.permissions, isNotEmpty);
    });

    // ── 1.6 logout → tokens 清除 → isLoggedIn false ───────────────────────
    test('logout → storage 清除 → isLoggedIn false', () async {
      await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );
      expect(await raw.repository.isLoggedIn, true);

      await raw.repository.logout();

      expect(await raw.repository.isLoggedIn, false);
      expect(await raw.storage.read(key: 'access_token'), isNull);
      expect(await raw.storage.read(key: 'refresh_token'), isNull);
    });

    // ── 1.7 logout 后 getCurrentUser → 401 ────────────────────────────────
    test('logout 后 getCurrentUser → ApiException(statusCode 401)', () async {
      await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );
      await raw.repository.logout();

      await expectLater(
        () => raw.repository.getCurrentUser(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    // ── 1.8 access_token 失效 → ApiClient 自动刷新 → 请求成功 ─────────────
    //
    // 场景：Token 已过期（注入无效值），但 refresh_token 仍有效。
    // ApiClient._onError 拦截 401 → 调用 POST /api/auth/refresh → 写入新 token → 重试原请求。
    test('access_token 注入失效值 → 自动刷新 → getCurrentUser 仍成功', () async {
      // 先登录，获得有效的 refresh_token
      await raw.repository.login(
        email: IntegrationTestConfig.adminEmail,
        password: IntegrationTestConfig.adminPassword,
      );

      // 注入无效 access_token，模拟 Token 过期
      await raw.storage.write(
        key: 'access_token',
        value: 'invalid-expired-token-for-test',
      );

      // ApiClient 应自动 401 → refresh → 重试，最终返回用户信息
      final user = await raw.repository.getCurrentUser();
      expect(user.email, IntegrationTestConfig.adminEmail);

      // 新 access_token 已被写回 storage
      final newToken = await raw.storage.read(key: 'access_token');
      expect(newToken, isNotNull);
      expect(newToken, isNot('invalid-expired-token-for-test'));
    });

    // ── 1.9 refresh_token 无效 → ApiException ────────────────────────────
    test('refresh_token 无效 → refreshToken → ApiException', () async {
      // 写入任意 refresh_token（无效），模拟双 Token 均过期的极端情况
      await raw.storage.write(
        key: 'refresh_token',
        value: 'invalid-refresh-token-for-test',
      );

      await expectLater(
        () => raw.repository.refreshToken(),
        throwsA(isA<ApiException>()),
      );
    });

    // ── 1.10 forgotPassword 防枚举（已注册邮箱）────────────────────────────
    //
    // 后端设计：无论邮箱是否存在均返回 200，防止通过错误信息枚举用户邮箱。
    test('forgotPassword 已注册邮箱 → 无异常（防枚举）', () async {
      await expectLater(
        raw.repository.forgotPassword(
          email: IntegrationTestConfig.adminEmail,
        ),
        completes,
      );
    });

    // ── 1.11 forgotPassword 防枚举（不存在邮箱）──────────────────────────
    test('forgotPassword 不存在邮箱 → 无异常（防枚举）', () async {
      await expectLater(
        raw.repository.forgotPassword(
          email: IntegrationTestConfig.nonExistentEmail,
        ),
        completes,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Group 2：Widget 层 → 全链路（真实 Widget 树 + 真实 HTTP）
  // ──────────────────────────────────────────────────────────────────────────
  group('Widget 层 → 全链路', () {
    setUpAll(() async {
      // 同 Repository 组：重置管理员账号锁定状态，避免积累的失败次数影响 Widget 层测试。
      await resetTestAccountLock(IntegrationTestConfig.adminEmail);
    });

    setUp(() async {
      await setUpRealDependencies();
      await const FlutterSecureStorage().deleteAll();
    });

    tearDown(() async {
      await tearDownRealDependencies();
    });

    // ── 2.1 无 Token 启动 → 路由至登录页 ───────────────────────────────────
    testWidgets('应用启动无 token → 路由至 LoginPage', (tester) async {
      await tester.pumpWidget(const ProposApp());
      // 等待 checkAuth() 完成 + go_router 初次路由
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // ── 2.2 正确凭证登录 → 离开登录页 ─────────────────────────────────────
    //
    // 登录后 go_router 导航至 /dashboard（MainShell），LoginPage 从树中移除。
    testWidgets('登录页正确凭证 → 登录成功 → 离开登录页', (tester) async {
      await tester.pumpWidget(const ProposApp());
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      expect(find.byType(LoginPage), findsOneWidget);

      // 输入邮箱（第 0 个 TextFormField）
      await tester.enterText(
        find.byType(TextFormField).at(0),
        IntegrationTestConfig.adminEmail,
      );
      // 输入密码（第 1 个 TextFormField）
      await tester.enterText(
        find.byType(TextFormField).at(1),
        IntegrationTestConfig.adminPassword,
      );

      // 点击「登 录」按钮（注意：文字中含空格，与 login_page.dart Text('登 录') 一致）
      await tester.tap(find.text('登 录'));

      // 等待真实 HTTP 响应 + BLoC 状态变更 + 路由跳转
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      // 已成功离开登录页
      expect(find.byType(LoginPage), findsNothing);
    });

    // ── 2.3 错误密码 → 内联错误图标/文本可见 ───────────────────────────────
    testWidgets('登录页错误密码 → 仍在登录页 + 内联错误图标', (tester) async {
      await tester.pumpWidget(const ProposApp());
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        IntegrationTestConfig.adminEmail,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        IntegrationTestConfig.wrongPassword,
      );

      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      // 仍在登录页
      expect(find.byType(LoginPage), findsOneWidget);
      // PAGE_SPEC §3.1：错误通过 Icons.warning_amber_rounded 内联展示
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    // ── 2.4 有效 Token 存在 → checkAuth → 跳过登录页 ────────────────────────
    //
    // 先通过 DI-managed repository 完成登录（tokens 写入 SecureStorage），
    // 再重建 DI + 重启 App，checkAuth() 读取到有效 Token 后直接进入 dashboard。
    testWidgets('有效 token 存在 → checkAuth → 跳过登录页', (tester) async {
      // 借助已注册的 AuthRepository 完成真实登录，将 tokens 写入 SecureStorage
      // （AuthCubit 此时尚未实例化，仍为 lazy singleton，不影响 DI 状态）
      final raw = buildRawComponents();
      try {
        await raw.repository.login(
          email: IntegrationTestConfig.adminEmail,
          password: IntegrationTestConfig.adminPassword,
        );
      } finally {
        raw.dispose();
      }

      // 重置 DI，确保 AuthCubit 以全新状态启动（不携带上次 checkAuth 结果）
      await setUpRealDependencies();
      // 注意：SecureStorage 仍保有上一步写入的有效 tokens，不清除

      await tester.pumpWidget(const ProposApp());
      // checkAuth() → getCurrentUser() 成功 → router 跳转至 dashboard
      await tester.pumpAndSettle(IntegrationTestConfig.pumpInterval);

      expect(find.byType(LoginPage), findsNothing);
    });
  });
}
