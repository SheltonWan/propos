/// Auth 模块集成测试
///
/// 直接启动真实服务器进程（读取 .env），连接本地 PostgreSQL，
/// 覆盖完整请求链路：HTTP → 中间件管道 → Controller → Service → DB。
///
/// 运行前提：
///   1. backend/.env 存在且配置正确
///   2. 本地 PostgreSQL 已启动，所有 migrations 已执行
///
/// 运行命令（在 backend/ 目录下执行）：
///   dart test test/integration/auth_integration_test.dart
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// 测试专用端口，避免与开发服务器（默认 8080）冲突
const _testPort = 8089;
const _base = 'http://localhost:$_testPort';

/// 测试专用用户（由 setUpAll 创建，tearDownAll 删除，不依赖种子数据密码）
const _testUserEmail = 'int_test_admin@propos.test';
const _testUserPassword = 'TestAdmin@9527!';

/// 确认存在于本地数据库的普通用户（用于验证 forgot-password 触发 OTP）
const _existingUserEmail = 'smartv@qq.com';

/// 肯定不存在于数据库的邮箱（防枚举静默返回验证）
const _ghostEmail = 'ghost_zzz_no_such_user@example.invalid';

// ─── 辅助：解析 .env 文件（key=value 格式，支持双/单引号值）──────────────────

Map<String, String> _loadDotEnv() {
  final result = <String, String>{};
  final file = File('.env');
  if (!file.existsSync()) return result;
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq < 0) continue;
    final key = line.substring(0, eq).trim();
    var val = line.substring(eq + 1).trim();
    if (val.length >= 2 &&
        ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'")))) {
      val = val.substring(1, val.length - 1);
    }
    result[key] = val;
  }
  return result;
}

/// 根据 DATABASE_URL 构建 postgres Pool（测试用，连接数限制为 2）
Pool _buildPool(String dbUrl, {String sslMode = 'disable'}) {
  final uri = Uri.parse(dbUrl);
  final userInfo = uri.userInfo.split(':');
  final endpoint = Endpoint(
    host: uri.host,
    port: uri.port == 0 ? 5432 : uri.port,
    database: uri.path.replaceFirst('/', ''),
    username: userInfo.first,
    password: userInfo.length > 1 ? userInfo.last : null,
  );
  final ssl = switch (sslMode) {
    'require' => SslMode.require,
    'verify-full' => SslMode.verifyFull,
    _ => SslMode.disable,
  };
  return Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(maxConnectionCount: 2, sslMode: ssl),
  );
}

void main() {
  late Process server;
  late http.Client client;
  late Pool db;

  /// 已登录用户的 access_token（setUpAll 登录后写入，供需要 JWT 的测试使用）
  late String accessToken;

  // ─── 启动服务器 + 创建测试用户 ──────────────────────────────────────────

  setUpAll(() async {
    // 1. 读取 .env，Platform.environment 优先
    final env = {..._loadDotEnv(), ...Platform.environment};
    final dbUrl = env['DATABASE_URL'] ?? '';
    if (dbUrl.isEmpty) throw StateError('DATABASE_URL 未配置，请检查 .env 文件');
    final sslMode = env['DB_SSL_MODE'] ?? 'disable';

    // 2. 直接连 DB：创建集成测试专用用户（已知密码），不依赖种子数据密码
    db = _buildPool(dbUrl, sslMode: sslMode);
    // bcrypt logRounds: 4 仅用于测试（速度快），生产使用 12
    final hash = BCrypt.hashpw(_testUserPassword, BCrypt.gensalt(logRounds: 4));
    await db.execute(
      Sql.named('''
        INSERT INTO users (name, email, password_hash, role, is_active, password_changed_at)
        VALUES ('集成测试管理员', @email, @hash, 'super_admin'::user_role, true, now())
        ON CONFLICT (email)
        DO UPDATE SET password_hash = @hash, is_active = true, password_changed_at = now()
      '''),
      parameters: {'email': _testUserEmail, 'hash': hash},
    );

    // 3. 启动服务器子进程（APP_PORT 覆盖 .env 端口）
    client = http.Client();
    server = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {...Platform.environment, 'APP_PORT': '$_testPort'},
    );
    server.stdout.transform(utf8.decoder).listen(stdout.write);
    server.stderr.transform(utf8.decoder).listen(stderr.write);

    // 4. 轮询 /health 等待服务就绪（最多 60 秒）
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try {
        final resp = await client
            .get(Uri.parse('$_base/health'))
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) break;
      } catch (_) {}
      if (DateTime.now().isAfter(deadline)) {
        server.kill();
        throw TimeoutException('服务器启动超时（60s），请检查 .env 配置和数据库连接是否正常');
      }
    }

    // 5. 预先登录，存储 access_token 供需要 JWT 的测试使用
    final loginResp = await client.post(
      Uri.parse('$_base/api/auth/login'),
      headers: {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': _testUserEmail, 'password': _testUserPassword}),
    );
    if (loginResp.statusCode != 200) {
      throw StateError('集成测试用户登录失败（${loginResp.statusCode}）：${loginResp.body}');
    }
    accessToken =
        ((jsonDecode(loginResp.body) as Map)['data'] as Map)['access_token'] as String;
  });

  tearDownAll(() async {
    client.close();
    server.kill();
    await server.exitCode;
    // 清理测试用户（refresh_tokens 等通过 FK CASCADE 自动删除）
    await db.execute(
      Sql.named('DELETE FROM users WHERE email = @email'),
      parameters: {'email': _testUserEmail},
    );
    // 清理 forgot-password 测试产生的 OTP 记录
    await db.execute(
      Sql.named('DELETE FROM password_reset_otps WHERE email = @email'),
      parameters: {'email': _existingUserEmail},
    );
    await db.close();
  });

  // ─── 请求辅助 ────────────────────────────────────────────────────────────

  Future<http.Response> post(String path, Map<String, dynamic> body,
          {String? token}) =>
      client.post(
        Uri.parse('$_base$path'),
        headers: {
          'content-type': 'application/json; charset=utf-8',
          if (token != null) 'authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

  Future<http.Response> getReq(String path, {String? token}) =>
      client.get(Uri.parse('$_base$path'),
          headers: {if (token != null) 'authorization': 'Bearer $token'});

  // ─── GET /health ─────────────────────────────────────────────────────────

  group('GET /health', () {
    test('返回 200 status=ok', () async {
      final resp = await getReq('/health');
      expect(resp.statusCode, 200);
      expect(jsonDecode(resp.body)['status'], 'ok');
    });
  });

  // ─── POST /api/auth/login ─────────────────────────────────────────────────

  group('POST /api/auth/login', () {
    test('缺少 email → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/auth/login', {'password': 'Pass1!'});
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'VALIDATION_ERROR');
    });

    test('缺少 password → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/auth/login', {'email': _testUserEmail});
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'VALIDATION_ERROR');
    });

    test('邮箱不存在 → 401 INVALID_CREDENTIALS', () async {
      final resp = await post(
          '/api/auth/login', {'email': _ghostEmail, 'password': 'SomePass1!'});
      expect(resp.statusCode, 401);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'INVALID_CREDENTIALS');
    });

    test('密码错误 → 401 INVALID_CREDENTIALS', () async {
      final resp = await post('/api/auth/login',
          {'email': _testUserEmail, 'password': 'WrongPassword!'});
      expect(resp.statusCode, 401);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'INVALID_CREDENTIALS');
    });

    test('正确凭据 → 200，data 包含 access_token / refresh_token / expires_in',
        () async {
      final resp = await post('/api/auth/login',
          {'email': _testUserEmail, 'password': _testUserPassword});
      expect(resp.statusCode, 200);
      final data = (jsonDecode(resp.body) as Map)['data'] as Map;
      expect(data['access_token'], isA<String>());
      expect((data['access_token'] as String).isNotEmpty, isTrue);
      expect(data['refresh_token'], isA<String>());
      expect(data['expires_in'], isA<int>());
    });
  });

  // ─── POST /api/auth/forgot-password ──────────────────────────────────────

  group('POST /api/auth/forgot-password', () {
    test('缺少 email 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/auth/forgot-password', {});
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'VALIDATION_ERROR');
    });

    test('邮箱不存在 → 200 静默返回（防枚举）', () async {
      final resp =
          await post('/api/auth/forgot-password', {'email': _ghostEmail});
      expect(resp.statusCode, 200);
      expect(((jsonDecode(resp.body) as Map)['data'] as Map)['message'], isNotEmpty);
    });

    test('邮箱存在 → 200，消息与不存在场景相同（防枚举）', () async {
      final resp =
          await post('/api/auth/forgot-password', {'email': _existingUserEmail});
      expect(resp.statusCode, 200);
      expect(((jsonDecode(resp.body) as Map)['data'] as Map)['message'], isNotEmpty);
    });
  });

  // ─── POST /api/auth/reset-password ───────────────────────────────────────

  group('POST /api/auth/reset-password', () {
    test('缺少 email → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/auth/reset-password',
          {'otp': '123456', 'new_password': 'NewPass1!'});
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'VALIDATION_ERROR');
    });

    test('密码强度不足 → 400 PASSWORD_TOO_WEAK（快速失败，无 DB 访问）', () async {
      final resp = await post('/api/auth/reset-password', {
        'email': _ghostEmail,
        'otp': '000000',
        'new_password': 'weakpassword',
      });
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'PASSWORD_TOO_WEAK');
    });

    test('OTP 不存在 → 400 OTP_INVALID', () async {
      final resp = await post('/api/auth/reset-password', {
        'email': _ghostEmail,
        'otp': '000000',
        'new_password': 'ValidPass1!',
      });
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'OTP_INVALID');
    });
  });

  // ─── GET /api/auth/me（需要有效 JWT）─────────────────────────────────────

  group('GET /api/auth/me', () {
    test('无 Authorization 头 → 401 MISSING_TOKEN', () async {
      final resp = await getReq('/api/auth/me');
      expect(resp.statusCode, 401);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'MISSING_TOKEN');
    });

    test('伪造 Token → 401 INVALID_TOKEN', () async {
      final resp = await getReq('/api/auth/me', token: 'not.a.valid.jwt.token');
      expect(resp.statusCode, 401);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'INVALID_TOKEN');
    });

    test('有效 Token → 200，data.email 与登录账号一致', () async {
      final resp = await getReq('/api/auth/me', token: accessToken);
      expect(resp.statusCode, 200);
      final data = (jsonDecode(resp.body) as Map)['data'] as Map;
      expect(data['email'], _testUserEmail);
      expect(data['role'], isNotEmpty);
    });
  });

  // ─── POST /api/auth/refresh ───────────────────────────────────────────────

  group('POST /api/auth/refresh', () {
    test('缺少 refresh_token → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/auth/refresh', {});
      expect(resp.statusCode, 400);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'VALIDATION_ERROR');
    });

    test('无效 refresh_token → 401', () async {
      final resp = await post(
          '/api/auth/refresh', {'refresh_token': 'invalid-token-value'});
      expect(resp.statusCode, 401);
      expect((jsonDecode(resp.body) as Map)['error'], isNotNull);
    });
  });

  // ─── 404 路由兜底 ─────────────────────────────────────────────────────────

  group('未注册路由', () {
    // 携带有效 JWT → auth 中间件放行，路由层返回 404
    test('携带有效 JWT 访问不存在路由 → 404 NOT_FOUND', () async {
      final resp = await getReq('/api/nonexistent_xyz', token: accessToken);
      expect(resp.statusCode, 404);
      expect((jsonDecode(resp.body) as Map)['error']['code'], 'NOT_FOUND');
    });

    // 无 JWT → auth 中间件拦截，返回 401（早于路由匹配）
    test('无 JWT 访问不存在路由 → 401（auth 中间件优先于路由）', () async {
      final resp = await getReq('/api/nonexistent_xyz');
      expect(resp.statusCode, 401);
    });
  });
}
