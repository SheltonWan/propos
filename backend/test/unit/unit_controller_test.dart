/// UnitController 单元测试
///
/// 覆盖场景（共 16 个）：
///   GET  /units              — 返回列表 + meta / 带过滤参数 /
///                              is_leasable=false 解析为 bool false /
///                              include_archived=true 解析为 bool true
///   POST /units              — 缺 floor_id / 缺 unit_number / 成功 201
///   GET  /units/export       — 成功 200 返回 xlsx 字节
///   POST /units/import       — 缺少文件 → 400 / dry_run=true → 200
///   GET  /units/:id          — NOT_FOUND → 404 / 成功
///   PATCH /units/:id         — NOT_FOUND → 404 / 成功 /
///                              archived_at 合法 ISO 字符串解析为 DateTime /
///                              archived_at=null 清空字段（archivedAtSet=true）
///   GET  /assets/overview    — 成功 200 含 total_units
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/pagination.dart';
import 'package:propos_backend/core/request_context.dart';
import 'package:propos_backend/modules/assets/controllers/unit_controller.dart';
import 'package:propos_backend/modules/assets/models/unit.dart';

import 'helpers/asset_fakes.dart';

// ─── 辅助 ─────────────────────────────────────────────────────────────────────

Request makeReq(
  String method,
  String path, {
  Map<String, dynamic>? body,
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body != null ? jsonEncode(body) : null,
    headers: body != null
        ? {'content-type': 'application/json; charset=utf-8'}
        : const {},
  );
}

/// 构造最小 multipart 请求（用于 import 上传）
Request makeImportReq({bool includeFile = true}) {
  const boundary = 'import_boundary_99';
  final sb = StringBuffer();
  sb.write('--$boundary\r\nContent-Disposition: form-data; name="dry_run"\r\n\r\ntrue\r\n');
  if (includeFile) {
    sb.write('--$boundary\r\n');
    sb.write('Content-Disposition: form-data; name="file"; filename="units.xlsx"\r\n');
    sb.write('Content-Type: application/octet-stream\r\n\r\n');
    sb.write('FAKEXLSXBYTES\r\n');
  }
  sb.write('--$boundary--\r\n');

  return Request(
    'POST',
    Uri.parse('http://localhost/units/import'),
    body: sb.toString(),
    headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
    context: {
      kRequestContextKey: RequestContext(
        userId: '00000000-0000-0000-0000-000000000001',
        role: UserRole.superAdmin,
      ),
    },
  );
}

Future<Map<String, dynamic>> readJson(Response resp) async =>
    jsonDecode(await resp.readAsString()) as Map<String, dynamic>;

// ─── 主体 ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeUnitService svc;
  late Handler handler;

  setUp(() {
    svc = FakeUnitService();
    handler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(UnitController(svc).router.call);
  });

  // ─── GET /units ───────────────────────────────────────────────────────────

  group('GET /units', () {
    test('返回空列表 → 200 data=[] meta.total=0', () async {
      final resp = await handler(makeReq('GET', '/units'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect(json['data'], isEmpty);
      expect((json['meta'] as Map)['total'], 0);
    });

    test('返回 2 条单元 → 200 data 长度 2', () async {
      svc.listResult = PaginatedResult(
        items: [fakeUnit(id: 'u-1'), fakeUnit(id: 'u-2')],
        meta: const PaginationMeta(page: 1, pageSize: 20, total: 2),
      );

      final resp = await handler(makeReq('GET', '/units?page=1&page_size=20'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as List), hasLength(2));
      expect((json['meta'] as Map)['total'], 2);
    });

    test('is_leasable=false → Service 接收到 isLeasable=false（非 null）', () async {
      final resp = await handler(makeReq('GET', '/units?is_leasable=false'));
      expect(resp.statusCode, 200);
      expect(svc.capturedIsLeasable, isFalse);
    });

    test('include_archived=true → Service 接收到 includeArchived=true', () async {
      final resp =
          await handler(makeReq('GET', '/units?include_archived=true'));
      expect(resp.statusCode, 200);
      expect(svc.capturedIncludeArchived, isTrue);
    });
  });

  // ─── POST /units ──────────────────────────────────────────────────────────

  group('POST /units', () {
    test('缺少 floor_id → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/units', body: {
        'building_id': 'b-1',
        'unit_number': '101',
        'property_type': 'office',
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 unit_number → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/units', body: {
        'floor_id': 'f-1',
        'building_id': 'b-1',
        'property_type': 'office',
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('Service 抛出 ValidationException → 400', () async {
      svc.shouldThrow =
          const ValidationException('VALIDATION_ERROR', '无效业态');

      final resp = await handler(makeReq('POST', '/units', body: {
        'floor_id': 'f-1',
        'building_id': 'b-1',
        'unit_number': '101',
        'property_type': 'shop',
      }));
      await readJson(resp);

      expect(resp.statusCode, 400);
    });

    test('合法请求 → 201 data 含 unit_number', () async {
      svc.itemResult = fakeUnit(unitNumber: '305');

      final resp = await handler(makeReq('POST', '/units', body: {
        'floor_id': 'f-1',
        'building_id': 'b-1',
        'unit_number': '305',
        'property_type': 'office',
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      expect((json['data'] as Map)['unit_number'], '305');
    });
  });

  // ─── GET /units/export ────────────────────────────────────────────────────

  group('GET /units/export', () {
    test('成功 → 200 content-type=xlsx 有字节内容', () async {
      svc.exportBytes = [0x50, 0x4B, 0x03, 0x04]; // ZIP/XLSX magic bytes

      final resp = await handler(makeReq('GET', '/units/export'));

      expect(resp.statusCode, 200);
      expect(resp.headers['content-type'],
          contains('spreadsheetml'));
      final bytes = await resp.read().expand((b) => b).toList();
      expect(bytes, isNotEmpty);
    });
  });

  // ─── POST /units/import ───────────────────────────────────────────────────

  group('POST /units/import', () {
    test('缺少 file 字段 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeImportReq(includeFile: false));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('Service 正常处理 → 200 data 含 is_dry_run', () async {
      svc.importResult = {
        'id': 'b1',
        'batch_name': 'units_test',
        'data_type': 'units',
        'total_records': 1,
        'success_count': 1,
        'failure_count': 0,
        'rollback_status': 'committed',
        'is_dry_run': true,
        'error_details': null,
        'source_file_path': null,
        'created_by': null,
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final resp = await handler(makeImportReq(includeFile: true));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['is_dry_run'], isTrue);
      expect((json['data'] as Map)['rollback_status'], 'committed');
    });
  });

  // ─── GET /units/:id ───────────────────────────────────────────────────────

  group('GET /units/:id', () {
    test('Service 抛出 NOT_FOUND → 404', () async {
      svc.shouldThrow = const NotFoundException('UNIT_NOT_FOUND', '单元不存在');

      final resp = await handler(makeReq('GET', '/units/u-x'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'UNIT_NOT_FOUND');
    });

    test('成功 → 200 data.property_type 存在', () async {
      svc.itemResult = fakeUnit(propertyType: 'apartment');

      final resp = await handler(makeReq('GET', '/units/u-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['property_type'], 'apartment');
    });
  });

  // ─── PATCH /units/:id ─────────────────────────────────────────────────────

  group('PATCH /units/:id', () {
    test('单元不存在 → 404 UNIT_NOT_FOUND', () async {
      svc.shouldThrow = const NotFoundException('UNIT_NOT_FOUND', '单元不存在');

      final resp = await handler(
          makeReq('PATCH', '/units/u-x', body: {'is_leasable': false}));
      await readJson(resp);

      expect(resp.statusCode, 404);
    });

    test('合法更新 → 200 data 含 is_leasable', () async {
      svc.itemResult = fakeUnit(isLeasable: false);

      final resp = await handler(
          makeReq('PATCH', '/units/u-1', body: {'is_leasable': false}));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['is_leasable'], isFalse);
    });

    test('archived_at 合法 ISO 字符串 → Service 接收到解析后的 DateTime', () async {
      svc.itemResult = fakeUnit();
      const iso = '2025-03-01T08:00:00Z';

      final resp = await handler(
          makeReq('PATCH', '/units/u-1', body: {'archived_at': iso}));
      expect(resp.statusCode, 200);
      expect(svc.capturedArchivedAtSet, isTrue);
      expect(svc.capturedArchivedAt, equals(DateTime.parse(iso)));
    });

    test('archived_at=null → archivedAtSet=true 且 archivedAt=null（清空字段）',
        () async {
      svc.itemResult = fakeUnit();

      final resp = await handler(
          makeReq('PATCH', '/units/u-1', body: {'archived_at': null}));
      expect(resp.statusCode, 200);
      expect(svc.capturedArchivedAtSet, isTrue);
      expect(svc.capturedArchivedAt, isNull);
    });
  });

  // ─── GET /assets/overview ─────────────────────────────────────────────────

  group('GET /assets/overview', () {
    test('成功 → 200 data 含 total_units / total_occupancy_rate / wale_*',
        () async {
      svc.overviewResult = const AssetOverviewStats(
        totalUnits: 30,
        totalLeasableUnits: 27,
        totalOccupancyRate: 0.5,
        waleIncomeWeighted: 2.5,
        waleAreaWeighted: 2.3,
        byPropertyType: [],
      );

      final resp = await handler(makeReq('GET', '/assets/overview'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['total_units'], 30);
      expect((json['data'] as Map)['total_leasable_units'], 27);
      expect(
          (json['data'] as Map)['total_occupancy_rate'], closeTo(0.5, 0.001));
      expect(
          (json['data'] as Map)['wale_income_weighted'], closeTo(2.5, 0.001));
      expect((json['data'] as Map)['wale_area_weighted'], closeTo(2.3, 0.001));
    });
  });
}
