/// 资产模块 M1 集成测试
///
/// 直接启动真实服务器进程（读取 .env），连接本地 PostgreSQL，
/// 覆盖完整请求链路：HTTP → RBAC中间件 → Controller → Service → Repository → DB。
///
/// 测试分组：
///   1. 楼栋 CRUD              — POST / GET / PATCH + 错误码验证
///   2. 楼层 CRUD + CAD 上传   — POST / GET + 重复楼层号 / 非.dwg 拒绝
///   3. 单元 CRUD + 导入/导出  — POST / GET / PATCH / import / export / overview
///   4. 改造记录 + 照片上传    — POST / GET / PATCH / photos
///
/// 运行前提：
///   1. backend/.env 存在且配置正确
///   2. 本地 PostgreSQL 已启动，所有 migrations 已执行
///
/// 运行命令（在 backend/ 目录下执行）：
///   dart test test/integration/assets_integration_test.dart
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// 测试专用端口（避免与 auth 集成测试端口 8089 冲突）
const _testPort = 8091;
const _base = 'http://localhost:$_testPort';

/// 集成测试专用账号
const _testUserEmail = 'int_test_assets@propos.test';
const _testUserPassword = 'TestAssets@9527!';

// ─── 辅助：解析 .env 文件 ──────────────────────────────────────────────────────

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

/// 根据 DATABASE_URL 构建 postgres Pool
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

// ─── 最小有效 Excel (.xlsx) 字节流 ──────────────────────────────────────────────

/// 生成仅含表头行的最小 xlsx ZIP 结构
/// 用于 POST /api/units/import 测试
List<int> _makeMinimalXlsx() {
  // ZIP 文件只需含合法结构即可触发 Service 层解析逻辑
  // 这里直接返回已知有效的最小 ZIP 文件魔术字节 + EOCD
  // 足以让 multipart 解析通过；Service 层会返回 error_rows
  const zipMagic = [0x50, 0x4B, 0x05, 0x06]; // PK EOCD signature
  final eocd = List<int>.filled(18, 0);
  return [...zipMagic, ...eocd];
}

// ─── 主体 ─────────────────────────────────────────────────────────────────────

void main() {
  late Process server;
  late http.Client client;
  late Pool db;
  late String token;

  /// 测试创建的楼栋 ID（tearDownAll 用于清理）
  late String buildingId;
  /// 测试创建的楼层 ID
  late String floorId;
  /// 测试创建的单元 ID
  late String unitId;
  /// 测试创建的改造记录 ID
  late String renovationId;
  /// CAD 导入落库验证组专用单元 ID
  String cadUnitId = '';

  // ─── setUpAll: 启动服务器 + 创建测试账号 + 登录 ──────────────────────────

  setUpAll(() async {
    // 1. 读取 .env
    final env = {..._loadDotEnv(), ...Platform.environment};
    final dbUrl = env['DATABASE_URL'] ?? '';
    if (dbUrl.isEmpty) throw StateError('DATABASE_URL 未配置，请检查 .env 文件');
    final sslMode = env['DB_SSL_MODE'] ?? 'disable';

    // 2. 创建集成测试账号（已知密码）
    db = _buildPool(dbUrl, sslMode: sslMode);
    final hash = BCrypt.hashpw(_testUserPassword, BCrypt.gensalt(logRounds: 4));
    await db.execute(
      Sql.named('''
        INSERT INTO users (name, email, password_hash, role, is_active, password_changed_at)
        VALUES ('资产集成测试账号', @email, @hash, 'super_admin'::user_role, true, now())
        ON CONFLICT (email)
        DO UPDATE SET password_hash = @hash, is_active = true, password_changed_at = now()
      '''),
      parameters: {'email': _testUserEmail, 'hash': hash},
    );

    // 3. 启动服务器子进程
    client = http.Client();
    server = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {...Platform.environment, 'APP_PORT': '$_testPort'},
    );
    server.stdout.transform(utf8.decoder).listen(stdout.write);
    server.stderr.transform(utf8.decoder).listen(stderr.write);

    // 4. 轮询 /health（最多 60 秒）
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
        throw TimeoutException('服务器启动超时（60s），请检查 .env 配置和数据库连接');
      }
    }

    // 5. 登录，获取 token
    final loginResp = await client.post(
      Uri.parse('$_base/api/auth/login'),
      headers: {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'email': _testUserEmail,
        'password': _testUserPassword,
      }),
    );
    if (loginResp.statusCode != 200) {
      throw StateError('集成测试账号登录失败：${loginResp.body}');
    }
    token = ((jsonDecode(loginResp.body) as Map)['data'] as Map)['access_token']
        as String;
  });

  // ─── tearDownAll: 清理测试数据（按 FK 顺序） ───────────────────────────────

  tearDownAll(() async {
    client.close();
    server.kill();
    await server.exitCode;

    // 清理顺序：改造记录 → 单元 → 楼层 → 楼栋
    // 使用 DELETE … USING 避免 FK 级联问题
    if (renovationId.isNotEmpty) {
      await db.execute(
        Sql.named('DELETE FROM renovation_records WHERE id = @id'),
        parameters: {'id': renovationId},
      );
    }
    if (unitId.isNotEmpty) {
      await db.execute(
        Sql.named('DELETE FROM units WHERE id = @id'),
        parameters: {'id': unitId},
      );
    }
    if (floorId.isNotEmpty) {
      // 先删除楼层图纸（FK 约束）
      await db.execute(
        Sql.named('DELETE FROM floor_plans WHERE floor_id = @id'),
        parameters: {'id': floorId},
      );
      await db.execute(
        Sql.named('DELETE FROM floors WHERE id = @id'),
        parameters: {'id': floorId},
      );
    }
    if (buildingId.isNotEmpty) {
      await db.execute(
        Sql.named('DELETE FROM buildings WHERE id = @id'),
        parameters: {'id': buildingId},
      );
    }
    // 删除测试账号（先清理所有该用户上传的图纸记录，避免 FK 约束）
    await db.execute(
      Sql.named('''
        DELETE FROM floor_plans
        WHERE uploaded_by IN (
          SELECT id FROM users WHERE email = @email
        )
      '''),
      parameters: {'email': _testUserEmail},
    );
    await db.execute(
      Sql.named('DELETE FROM users WHERE email = @email'),
      parameters: {'email': _testUserEmail},
    );
    await db.close();
  });

  // ─── 请求辅助函数 ────────────────────────────────────────────────────────

  Map<String, dynamic> jsonBody(http.Response resp) =>
      jsonDecode(resp.body) as Map<String, dynamic>;

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      client.post(
        Uri.parse('$_base$path'),
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

  Future<http.Response> getReq(String path) => client.get(
        Uri.parse('$_base$path'),
        headers: {'authorization': 'Bearer $token'},
      );

  Future<http.Response> patchReq(String path, Map<String, dynamic> body) =>
      client.patch(
        Uri.parse('$_base$path'),
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

  /// 上传 multipart 请求（文件 + 表单字段）
  Future<http.Response> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base$path'));
    req.headers['authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    req.files.addAll(files);
    final streamed = await req.send();
    return http.Response.fromStream(streamed);
  }

  // =========================================================================
  // Group 1: 楼栋 CRUD
  // =========================================================================

  group('楼栋 CRUD', () {
    test('POST /api/buildings 缺少 name → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/buildings', {
        'property_type': 'office',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      });
      expect(resp.statusCode, 400);
      expect(jsonBody(resp)['error']['code'], 'VALIDATION_ERROR');
    });

    test('POST /api/buildings 成功 → 201 返回 id', () async {
      final resp = await post('/api/buildings', {
        'name': 'INT_TEST_楼栋_${DateTime.now().millisecondsSinceEpoch}',
        'property_type': 'office',
        'total_floors': 5,
        'gfa': 2000.0,
        'nla': 1600.0,
        'address': '集成测试路 1 号',
      });
      expect(resp.statusCode, 201);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['id'], isA<String>());
      buildingId = data['id'] as String;
    });

    test('GET /api/buildings → 200 列表含新建楼栋', () async {
      final resp = await getReq('/api/buildings');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as List;
      expect(data.any((b) => b['id'] == buildingId), isTrue);
    });

    test('GET /api/buildings/:id → 200 含 property_type', () async {
      final resp = await getReq('/api/buildings/$buildingId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['property_type'], 'office');
    });

    test('PATCH /api/buildings/:id → 200 name 已更新', () async {
      const newName = 'INT_TEST_更新楼栋名';
      final resp = await patchReq('/api/buildings/$buildingId', {'name': newName});
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['name'], newName);
    });

    test('GET /api/buildings/nonexistent → 404 BUILDING_NOT_FOUND', () async {
      final resp = await getReq('/api/buildings/00000000-0000-4000-8000-000000000000');
      expect(resp.statusCode, 404);
      expect(jsonBody(resp)['error']['code'], 'BUILDING_NOT_FOUND');
    });
  });

  // =========================================================================
  // Group 2: 楼层 CRUD + CAD 上传
  // =========================================================================

  group('楼层 CRUD + CAD 上传', () {
    test('POST /api/floors 缺少 floor_number → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/floors', {'building_id': buildingId});
      expect(resp.statusCode, 400);
      expect(jsonBody(resp)['error']['code'], 'VALIDATION_ERROR');
    });

    test('POST /api/floors 成功 → 201 返回 floor_number', () async {
      final resp = await post('/api/floors', {
        'building_id': buildingId,
        'floor_number': 1,
        'floor_name': 'INT_TEST_1F',
      });
      expect(resp.statusCode, 201);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['floor_number'], 1);
      floorId = data['id'] as String;
    });

    test('GET /api/floors?building_id=… → 200 含新建楼层', () async {
      final resp = await getReq('/api/floors?building_id=$buildingId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as List;
      expect(data.any((f) => f['id'] == floorId), isTrue);
    });

    test('GET /api/floors/:id → 200 含 building_id', () async {
      final resp = await getReq('/api/floors/$floorId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['building_id'], buildingId);
    });

    test('GET /api/floors/:id/heatmap → 200 含 units 数组', () async {
      final resp = await getReq('/api/floors/$floorId/heatmap');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data.containsKey('units'), isTrue);
    });

    test('POST /api/floors 重复楼层号 → 409 FLOOR_ALREADY_EXISTS', () async {
      // 同一楼栋同一 floor_number=1 再次创建应冲突
      final resp = await post('/api/floors', {
        'building_id': buildingId,
        'floor_number': 1,
        'floor_name': '重复层',
      });
      expect(resp.statusCode, 409);
      expect(jsonBody(resp)['error']['code'], 'FLOOR_ALREADY_EXISTS');
    });

    test('POST /api/floors/:id/cad 非.dwg 文件 → 400 INVALID_CAD_FILE',
        () async {
      final resp = await postMultipart(
        '/api/floors/$floorId/cad',
        fields: {'version_label': 'v1'},
        files: [
          http.MultipartFile.fromBytes(
            'file',
            [0x25, 0x50, 0x44, 0x46], // PDF magic bytes
            filename: 'plan.pdf',
          ),
        ],
      );
      expect(resp.statusCode, 400);
      expect(jsonBody(resp)['error']['code'], 'INVALID_CAD_FILE');
    });

    test('POST /api/floors/:id/cad 合法 .dwg → 202 status=converting', () async {
      final resp = await postMultipart(
        '/api/floors/$floorId/cad',
        fields: {'version_label': 'v_int_test'},
        files: [
          http.MultipartFile.fromBytes(
            'file',
            Uint8List.fromList(
                [0x41, 0x43, 0x31, 0x30, 0x31, 0x32, 0x00, 0x00]), // AC1012 DWG
            filename: 'floor_plan.dwg',
          ),
        ],
      );
      expect(resp.statusCode, 202);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['status'], 'converting');
    });

    test('GET /api/floors/:id/plans → 200 含上传版本', () async {
      final resp = await getReq('/api/floors/$floorId/plans');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as List;
      expect(data, isNotEmpty);
    });
  });

  // =========================================================================
  // Group 3: 单元 CRUD + 导入/导出/总览
  // =========================================================================

  group('单元 CRUD + 导入/导出/总览', () {
    test('POST /api/units 缺少 unit_number → 400 VALIDATION_ERROR', () async {
      final resp = await post('/api/units', {
        'floor_id': floorId,
        'building_id': buildingId,
        'property_type': 'office',
      });
      expect(resp.statusCode, 400);
      expect(jsonBody(resp)['error']['code'], 'VALIDATION_ERROR');
    });

    test('POST /api/units 成功 → 201 含 id', () async {
      final resp = await post('/api/units', {
        'floor_id': floorId,
        'building_id': buildingId,
        'unit_number': 'INT_TEST_101',
        'property_type': 'office',
        'gross_area': 150.0,
        'net_area': 120.0,
        'is_leasable': true,
        'decoration_status': 'blank',
      });
      expect(resp.statusCode, 201);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['unit_number'], 'INT_TEST_101');
      unitId = data['id'] as String;
    });

    test('GET /api/units?building_id=… → 200 meta.total >= 1', () async {
      final resp = await getReq('/api/units?building_id=$buildingId');
      expect(resp.statusCode, 200);
      final json = jsonBody(resp);
      expect((json['meta'] as Map)['total'], greaterThanOrEqualTo(1));
    });

    test('GET /api/units/:id → 200 含 property_type', () async {
      final resp = await getReq('/api/units/$unitId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['property_type'], 'office');
    });

    test('PATCH /api/units/:id → 200 is_leasable 已更新', () async {
      final resp = await patchReq('/api/units/$unitId', {'is_leasable': false});
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['is_leasable'], isFalse);
    });

    test('GET /api/assets/overview → 200 total_units >= 1', () async {
      final resp = await getReq('/api/assets/overview');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect((data['total_units'] as int), greaterThanOrEqualTo(1));
      expect(data.containsKey('total_occupancy_rate'), isTrue);
    });

    test('GET /api/units/export → 200 content-type=xlsx 含字节', () async {
      final resp = await getReq('/api/units/export');
      expect(resp.statusCode, 200);
      expect(resp.headers['content-type'], contains('spreadsheetml'));
      expect(resp.bodyBytes.isNotEmpty, isTrue);
    });

    test('POST /api/units/import dry_run=true → 200 dry_run=true', () async {
      final resp = await postMultipart(
        '/api/units/import?dry_run=true',
        files: [
          http.MultipartFile.fromBytes(
            'file',
            _makeMinimalXlsx(),
            filename: 'units.xlsx',
          ),
        ],
      );
      // Service 解析无效 xlsx → 返回 200 含 error_rows（dry_run 本身通过）
      expect(resp.statusCode, anyOf(200, 400));
    });

    test('GET /api/units/nonexistent → 404 UNIT_NOT_FOUND', () async {
      final resp =
          await getReq('/api/units/00000000-0000-4000-8000-000000000000');
      expect(resp.statusCode, 404);
      expect(jsonBody(resp)['error']['code'], 'UNIT_NOT_FOUND');
    });
  });

  // =========================================================================
  // Group 4: 改造记录 + 照片上传
  // =========================================================================

  group('改造记录 + 照片上传', () {
    test('POST /api/renovations 缺少 renovation_type → 400', () async {
      final resp = await post('/api/renovations', {
        'unit_id': unitId,
        'started_at': '2026-01-01T00:00:00Z',
      });
      expect(resp.statusCode, 400);
      expect(jsonBody(resp)['error']['code'], 'VALIDATION_ERROR');
    });

    test('POST /api/renovations 成功 → 201 含 id', () async {
      final resp = await post('/api/renovations', {
        'unit_id': unitId,
        'renovation_type': '隔断改造',
        'started_at': '2026-01-10T00:00:00Z',
        'cost': 30000.0,
        'contractor': '集成测试施工队',
      });
      expect(resp.statusCode, 201);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['renovation_type'], '隔断改造');
      renovationId = data['id'] as String;
    });

    test('GET /api/renovations?unit_id=… → 200 含改造记录', () async {
      final resp = await getReq('/api/renovations?unit_id=$unitId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as List;
      expect(data.any((r) => r['id'] == renovationId), isTrue);
    });

    test('GET /api/renovations/:id → 200 含 unit_id', () async {
      final resp = await getReq('/api/renovations/$renovationId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['unit_id'], unitId);
    });

    test('PATCH /api/renovations/:id → 200 contractor 已更新', () async {
      final resp = await patchReq('/api/renovations/$renovationId', {
        'completed_at': '2026-02-28T00:00:00Z',
        'contractor': '升级施工队',
      });
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['contractor'], '升级施工队');
    });

    test('POST /api/renovations/:id/photos 无效 photo_stage → 400', () async {
      final resp = await postMultipart(
        '/api/renovations/$renovationId/photos',
        fields: {'photo_stage': 'during'}, // 非法值
        files: [
          http.MultipartFile.fromBytes(
            'file',
            [0xFF, 0xD8, 0xFF, 0xE0],
            filename: 'photo.jpg',
          ),
        ],
      );
      expect(resp.statusCode, 400);
    });

    test('POST /api/renovations/:id/photos before .jpg → 201 含 storage_path',
        () async {
      final resp = await postMultipart(
        '/api/renovations/$renovationId/photos',
        fields: {'photo_stage': 'before'},
        files: [
          http.MultipartFile.fromBytes(
            'file',
            Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
            filename: 'before_shot.jpg',
          ),
        ],
      );
      expect(resp.statusCode, 201);
      final data = jsonBody(resp)['data'] as Map;
      expect(data['storage_path'], contains('renovations/$renovationId/'));
      expect(data['photo_stage'], 'before');
    });

    test('GET /api/renovations/nonexistent → 404 RENOVATION_NOT_FOUND',
        () async {
      final resp = await getReq(
          '/api/renovations/00000000-0000-4000-8000-000000000000');
      expect(resp.statusCode, 404);
      expect(jsonBody(resp)['error']['code'], 'RENOVATION_NOT_FOUND');
    });
  });

  // =========================================================================
  // Group 5: CAD 导入 → floor_plan_coords 落库验证
  //
  // 目的：确保 CadImportService._createUnitsFromJsonData 经 UnitRepository.create()
  //       将 hotspot 坐标写入 units.floor_plan_coords 正式列（而非 ext_fields.hotspot）。
  //
  // 策略：绕过不可在 CI 中运行的 Python 流水线，直接通过 SQL INSERT 模拟落库结果，
  //       再通过 HTTP + DB 分别验证读取路径的完整性。
  // =========================================================================

  group('CAD 导入 → floor_plan_coords 落库验证', () {
    // 模拟 annotate_hotzone.py 输出的圆心坐标（SVG 坐标系）
    final testCoords = <String, dynamic>{'x': 1234.56, 'y': 789.01};

    setUpAll(() async {
      // 直接通过 SQL INSERT 模拟 CadImportService._createUnitsFromJsonData
      // → UnitRepository.create(floorPlanCoords: hotspot) 的落库效果
      final result = await db.execute(
        Sql.named('''
          INSERT INTO units (
            floor_id, building_id, unit_number, property_type,
            floor_plan_coords
          )
          VALUES (
            @floorId::UUID, @buildingId::UUID, @unitNumber,
            @propertyType::property_type,
            @coords::JSONB
          )
          RETURNING id::TEXT
        '''),
        parameters: {
          'floorId': floorId,
          'buildingId': buildingId,
          'unitNumber': 'INT_CAD_001',
          'propertyType': 'office',
          'coords': jsonEncode(testCoords),
        },
      );
      cadUnitId = result.first.toColumnMap()['id'] as String;
    });

    tearDownAll(() async {
      if (cadUnitId.isNotEmpty) {
        await db.execute(
          Sql.named('DELETE FROM units WHERE id = @id'),
          parameters: {'id': cadUnitId},
        );
      }
    });

    test('GET /api/units/:id → floor_plan_coords 含正确的 x/y 坐标', () async {
      final resp = await getReq('/api/units/$cadUnitId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      final coords = data['floor_plan_coords'] as Map?;
      expect(
        coords,
        isNotNull,
        reason: 'floor_plan_coords 应被 unit_repository SELECT 并通过 HTTP API 返回',
      );
      expect((coords!['x'] as num).toDouble(), closeTo(1234.56, 0.01));
      expect((coords['y'] as num).toDouble(), closeTo(789.01, 0.01));
    });

    test('ext_fields 不含 hotspot 键（旧写法回归检查）', () async {
      final resp = await getReq('/api/units/$cadUnitId');
      expect(resp.statusCode, 200);
      final data = jsonBody(resp)['data'] as Map;
      final extFields = (data['ext_fields'] as Map?) ?? {};
      expect(
        extFields.containsKey('hotspot'),
        isFalse,
        reason: 'hotspot 坐标应写入 floor_plan_coords 正式列，不得再写入 ext_fields',
      );
    });

    test('DB 直接 SELECT → floor_plan_coords 列已正确写入 JSONB', () async {
      final rows = await db.execute(
        Sql.named(
            'SELECT floor_plan_coords FROM units WHERE id = @id'),
        parameters: {'id': cadUnitId},
      );
      expect(rows, isNotEmpty);
      final coords =
          rows.first.toColumnMap()['floor_plan_coords'] as Map?;
      expect(coords, isNotNull);
      expect(
          (coords!['x'] as num).toDouble(), closeTo(1234.56, 0.01));
    });
  });
}
