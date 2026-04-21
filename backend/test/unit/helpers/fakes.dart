/// 认证模块单元测试共享伪对象库。
///
/// 包含：
///   - postgres 基础伪对象（FakeSession / FakeTxSession / FakePool）
///   - 测试用 AppConfig 工厂函数
///   - 伪 Repository 实现（FakeUserAuthRepository / FakeRefreshTokenRepository /
///     FakeOtpRepository）
///   - 伪 EmailService
///   - 辅助构建函数（makeActiveUser / makeRefreshToken / makeOtp / makeResult）
library test_helpers;

import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:propos_backend/config/app_config.dart';
import 'package:propos_backend/modules/auth/models/password_reset_otp.dart';
import 'package:propos_backend/modules/auth/models/refresh_token.dart';
import 'package:propos_backend/modules/auth/models/user_auth.dart';
import 'package:propos_backend/modules/auth/repositories/password_reset_otp_repository.dart';
import 'package:propos_backend/modules/auth/repositories/refresh_token_repository.dart';
import 'package:propos_backend/modules/auth/repositories/user_auth_repository.dart';
import 'package:propos_backend/shared/email_service.dart';

// ─── postgres 伪对象 ─────────────────────────────────────────────────────────

/// 不执行任何真实数据库操作的伪 Session（只用于满足 Repository 构造函数）
class FakeSession implements Session {
  @override
  bool get isOpen => true;

  @override
  Future<void> get closed => Completer<void>().future;

  @override
  Future<Statement> prepare(Object query) => throw UnimplementedError();

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async =>
      makeResult([], []);
}

/// 支持事务语义的伪 TxSession，execute 为无操作返回空结果
class FakeTxSession implements TxSession {
  @override
  bool get isOpen => true;

  @override
  Future<void> get closed => Completer<void>().future;

  @override
  Future<Statement> prepare(Object query) => throw UnimplementedError();

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async =>
      makeResult([], []);

  @override
  Future<void> rollback() async {}
}

/// 可配置的伪 Pool，支持拦截 execute 返回自定义结果以及 runTx 行为
class FakePool implements Pool<Object?> {
  /// 可在测试中按需覆盖：拦截所有 execute 调用并返回指定结果
  Result Function(Object query, Object? parameters)? executeHandler;

  /// runTx 是否已被调用
  bool runTxCalled = false;

  // ─── Session 方法 ─────────────────────────────────────────────
  @override
  bool get isOpen => true;

  @override
  Future<void> get closed => Completer<void>().future;

  @override
  Future<Statement> prepare(Object query) => throw UnimplementedError();

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    if (executeHandler != null) return executeHandler!(query, parameters);
    return makeResult([], []);
  }

  // ─── SessionExecutor 方法 ─────────────────────────────────────
  @override
  Future<void> close({bool force = false}) async {}

  // ─── Pool 方法（覆盖 SessionExecutor，新增 locality 参数） ────
  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    Object? locality,
  }) async =>
      fn(FakeTxSession());

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    Object? locality,
  }) async {
    runTxCalled = true;
    return fn(FakeTxSession());
  }

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    Object? locality,
  }) =>
      throw UnimplementedError('withConnection 在单元测试中不需要');
}

/// 辅助：按列名和行数据构建 postgres Result（用于 execute 的返回值）
///
/// 使用 [Type.text] 作为列的伪类型，测试中不关心具体 OID。
Result makeResult(List<String> columns, List<List<Object?>> data) {
  final schema = ResultSchema(
    columns
        .map(
          (c) => ResultSchemaColumn(
            typeOid: 0,
            // postgres 自定义 Type<T> 类，非 Dart 内建 Type；
            // 用 Type.text 作为通用占位符，测试中不做类型校验。
            type: Type.text,
            columnName: c,
          ),
        )
        .toList(),
  );
  final rows =
      data.map((row) => ResultRow(values: row, schema: schema)).toList();
  return Result(rows: rows, affectedRows: data.length, schema: schema);
}

// ─── 测试配置 ─────────────────────────────────────────────────────────────────

/// 创建满足所有必填环境变量校验的测试用 AppConfig
AppConfig makeTestConfig() => AppConfig.load(
      get: (key) => switch (key) {
        'DATABASE_URL' => 'postgres://localhost/test',
        'JWT_SECRET' => 'test-secret-key-must-be-32-bytes!!',
        'JWT_EXPIRES_IN_HOURS' => '1',
        'FILE_STORAGE_PATH' => '/tmp/propos_test',
        // 64 位 hex = 32 字节 AES-256 密钥
        'ENCRYPTION_KEY' =>
          '6162636465666768696a6b6c6d6e6f707172737475767778797a303132333435',
        'APP_PORT' => '8080',
        _ => null,
      },
    );

// ─── 共享 FakeSession 实例（只用于满足 Repository 构造函数，不执行真实 SQL）────

final _sharedFakeSession = FakeSession();

// ─── 伪 Repository 实现 ─────────────────────────────────────────────────────

/// 基于内存状态的伪 UserAuthRepository，所有 SQL 方法均通过字段控制返回值
class FakeUserAuthRepository extends UserAuthRepository {
  /// findByEmail / findById 返回的用户（null 表示用户不存在）
  UserAuth? user;

  /// 方法调用记录
  bool resetLoginFailuresCalled = false;
  bool incrementLoginFailureCalled = false;
  bool updatePasswordCalled = false;

  /// incrementLoginFailure 时传入的 lockedUntil 值
  DateTime? incrementedLockedUntil;

  /// updatePassword 时接收到的新密码哈希
  String? updatedPasswordHash;

  FakeUserAuthRepository() : super(_sharedFakeSession);

  @override
  Future<UserAuth?> findByEmail(String email) async =>
      user?.email == email ? user : null;

  @override
  Future<UserAuth?> findById(String userId) async =>
      user?.id == userId ? user : null;

  @override
  Future<void> resetLoginFailures(String userId) async {
    resetLoginFailuresCalled = true;
  }

  @override
  Future<void> incrementLoginFailure(
    String userId, {
    DateTime? lockedUntil,
  }) async {
    incrementLoginFailureCalled = true;
    incrementedLockedUntil = lockedUntil;
  }

  @override
  Future<void> updatePassword(
    String userId,
    String newPasswordHash, {
    required Session tx,
  }) async {
    updatePasswordCalled = true;
    updatedPasswordHash = newPasswordHash;
  }
}

/// 基于内存 Map 的伪 RefreshTokenRepository
class FakeRefreshTokenRepository extends RefreshTokenRepository {
  final Map<String, RefreshToken> _byHash = {};

  /// 已创建的 token 列表（按创建顺序）
  final List<RefreshToken> created = [];

  /// 已撤销的 token id 列表
  final List<String> revokedIds = [];

  /// revokeAllForUser 是否被调用
  bool revokeAllForUserCalled = false;

  FakeRefreshTokenRepository() : super(_sharedFakeSession);

  /// 预置一条 token（用于 refresh / logout 测试，绕过 login 流程直接设置已知 token）
  void seedToken(RefreshToken token) {
    _byHash[token.tokenHash] = token;
  }

  @override
  Future<RefreshToken> create({
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
    String? deviceInfo,
    Session? tx,
  }) async {
    final token = RefreshToken(
      id: 'rt-${created.length + 1}',
      userId: userId,
      tokenHash: tokenHash,
      expiresAt: expiresAt,
      revoked: false,
      deviceInfo: deviceInfo,
      createdAt: DateTime.now().toUtc(),
    );
    _byHash[tokenHash] = token;
    created.add(token);
    return token;
  }

  @override
  Future<RefreshToken?> findByHash(String tokenHash) async =>
      _byHash[tokenHash];

  @override
  Future<void> revoke(String id, {Session? tx}) async {
    revokedIds.add(id);
    // 同步更新内存状态（模拟 DB UPDATE revoked=true）
    for (final key in _byHash.keys.toList()) {
      final t = _byHash[key]!;
      if (t.id == id) {
        _byHash[key] = RefreshToken(
          id: t.id,
          userId: t.userId,
          tokenHash: t.tokenHash,
          expiresAt: t.expiresAt,
          revoked: true,
          deviceInfo: t.deviceInfo,
          createdAt: t.createdAt,
        );
        break;
      }
    }
  }

  @override
  Future<void> revokeAllForUser(String userId, {Session? tx}) async {
    revokeAllForUserCalled = true;
  }
}

/// 基于内存状态的伪 PasswordResetOtpRepository
class FakeOtpRepository extends PasswordResetOtpRepository {
  /// countRecentByUserId 返回的计数（控制速率限制逻辑）
  int recentCount = 0;

  /// findLatestByEmail 返回的 OTP 记录（null 表示不存在）
  PasswordResetOtp? latestOtp;

  /// create 是否被调用及相关参数
  bool createCalled = false;
  String? createdEmail;
  String? createdCodeHash;

  /// markUsed 是否被调用
  bool markUsedCalled = false;

  /// incrementFailed 是否被调用
  bool incrementFailedCalled = false;

  FakeOtpRepository() : super(_sharedFakeSession);

  @override
  Future<int> countRecentByUserId(String userId, Duration window) async =>
      recentCount;

  @override
  Future<PasswordResetOtp?> findLatestByEmail(String email) async => latestOtp;

  @override
  Future<PasswordResetOtp> create({
    required String userId,
    required String email,
    required String codeHash,
    int expiryMinutes = 10,
  }) async {
    createCalled = true;
    createdEmail = email;
    createdCodeHash = codeHash;
    return PasswordResetOtp(
      id: 'otp-1',
      userId: userId,
      email: email,
      codeHash: codeHash,
      createdAt: DateTime.now().toUtc(),
      expiresAt:
          DateTime.now().toUtc().add(Duration(minutes: expiryMinutes)),
      failedAttempts: 0,
    );
  }

  @override
  Future<void> markUsed(String id) async {
    markUsedCalled = true;
  }

  @override
  Future<void> incrementFailed(String id) async {
    incrementFailedCalled = true;
  }

  @override
  Future<void> deleteStaleByUserId(String userId) async {
    // 无操作（清理逻辑在单元测试中不需要验证）
  }
}

// ─── 伪 EmailService ──────────────────────────────────────────────────────────

/// 捕获发送参数的伪 EmailService，不实际发送邮件
class FakeEmailService extends EmailService {
  /// 最后一次 sendOtpEmail 调用的收件人邮箱
  String? lastRecipient;

  /// 最后一次 sendOtpEmail 调用的 OTP 明文
  String? lastOtp;

  /// 设为 true 后 sendOtpEmail 将抛出异常（模拟 SMTP 故障）
  bool shouldThrow = false;

  FakeEmailService()
      : super(
          smtpHost: '',
          smtpPort: 465,
          smtpUser: '',
          smtpPassword: '',
          senderAddress: 'noreply@test.propos',
        );

  @override
  Future<void> sendOtpEmail({
    required String email,
    required String otp,
    int expireMinutes = 10,
  }) async {
    if (shouldThrow) throw Exception('SMTP 连接失败（测试模拟）');
    lastRecipient = email;
    lastOtp = otp;
  }
}

// ─── 辅助构建函数 ─────────────────────────────────────────────────────────────

/// 构建一个可用于登录校验的测试 UserAuth 对象（默认为活跃 admin 账号）
UserAuth makeActiveUser({
  String id = 'user-1',
  String name = '测试用户',
  String email = 'test@propos.com',
  required String passwordHash,
  String role = 'admin',
  bool isActive = true,
  int failedLoginAttempts = 0,
  DateTime? lockedUntil,
  DateTime? frozenAt,
  DateTime? passwordChangedAt,
  int sessionVersion = 1,
}) {
  return UserAuth(
    id: id,
    name: name,
    email: email,
    passwordHash: passwordHash,
    role: role,
    isActive: isActive,
    failedLoginAttempts: failedLoginAttempts,
    lockedUntil: lockedUntil,
    frozenAt: frozenAt,
    passwordChangedAt: passwordChangedAt,
    sessionVersion: sessionVersion,
  );
}

/// 构建一个测试用 RefreshToken（可控制是否撤销 / 已过期）
RefreshToken makeRefreshToken({
  String id = 'rt-seed-1',
  required String userId,
  required String tokenHash,
  bool revoked = false,
  bool expired = false,
}) {
  final expiresAt = expired
      ? DateTime.now().toUtc().subtract(const Duration(days: 1))
      : DateTime.now().toUtc().add(const Duration(days: 30));
  return RefreshToken(
    id: id,
    userId: userId,
    tokenHash: tokenHash,
    expiresAt: expiresAt,
    revoked: revoked,
    createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
  );
}

/// 构建一个测试用 PasswordResetOtp（可控制状态：已使用、已过期、失败次数）
PasswordResetOtp makeOtp({
  String id = 'otp-1',
  String userId = 'user-1',
  String email = 'test@propos.com',
  required String codeHash,
  bool used = false,
  bool expired = false,
  int failedAttempts = 0,
}) {
  final expiresAt = expired
      ? DateTime.now().toUtc().subtract(const Duration(minutes: 1))
      : DateTime.now().toUtc().add(const Duration(minutes: 10));
  return PasswordResetOtp(
    id: id,
    userId: userId,
    email: email,
    codeHash: codeHash,
    createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    expiresAt: expiresAt,
    usedAt: used ? DateTime.now().toUtc() : null,
    failedAttempts: failedAttempts,
  );
}
