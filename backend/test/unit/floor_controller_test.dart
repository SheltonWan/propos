/// FloorController + FloorPlanController 单元测试
///
/// 覆盖场景（共 9 个）：
///   GET  /floors              — 返回列表
///   POST /floors              — 缺 building_id / 缺 floor_number / 成功 201
///   GET  /floors/:id          — NOT_FOUND → 404 / 成功
///   POST /floors/:id/cad      — 成功 202 (multipart 构造)
///   GET  /floors/:id/heatmap  — NOT_FOUND → 404 / 成功
///   GET  /floors/:id/plans    — 成功
///   PATCH /floor-plans/:id/set-current — NOT_FOUND → 404 / 成功 200
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/request_context.dart';
import 'package:propos_backend/modules/assets/controllers/floor_controller.dart';
import 'package:propos_backend/modules/assets/controllers/floor_plan_controller.dart';
import 'package:propos_backend/modules/assets/models/floor.dart';

import 'helpers/asset_fakes.dart';

// ─── 辅助 ─────────────────────────────────────────────────────────────────────

Request makeReq(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? userId,
}) {
  var req = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body != null ? jsonEncode(body) : null,
    headers: body != null
        ? {'content-type': 'application/json; charset=utf-8'}
        : const {},
  );
  if (userId != null) {
    req = req.change(context: {
      kRequestContextKey:
          RequestContext(userId: userId, role: UserRole.superAdmin),
    });
  }
  return req;
}

/// 构造最小 multipart 请求（用于 CAD 上传）
Request makeMultipartReq(String path, Map<String, String> fields,
    {String? userId}) {
  const boundary = 'test_boundary_12345';
  final sb = StringBuffer();
  for (final entry in fields.entries) {
    sb.write('--$boundary\r\n');
    sb.write('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
    sb.write('${entry.value}\r\n');
  }
  // 最小 .dwg 文件
  sb.write('--$boundary\r\n');
  sb.write('Content-Disposition: form-data; name="file"; filename="plan.dwg"\r\n');
  sb.write('Content-Type: application/octet-stream\r\n\r\n');
  final body = '${sb}DUMMYDWGBYTES\r\n--$boundary--\r\n';

  var req = Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: body,
    headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
  );
  if (userId != null) {
    req = req.change(context: {
      kRequestContextKey:
          RequestContext(userId: userId, role: UserRole.superAdmin),
    });
  }
  return req;
}

Future<Map<String, dynamic>> readJson(Response resp) async =>
    jsonDecode(await resp.readAsString()) as Map<String, dynamic>;

// ─── 主体 ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeFloorService svc;
  late Handler floorHandler;
  late Handler planHandler;

  setUp(() {
    svc = FakeFloorService();
    floorHandler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(FloorController(svc).router.call);
    planHandler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(FloorPlanController(svc).router.call);
  });

  // ─── GET /floors ──────────────────────────────────────────────────────────

  group('GET /floors', () {
    test('服务返回 2 个楼层 → 200 data 长度 2', () async {
      svc.listResult = [fakeFloor(id: 'f-1'), fakeFloor(id: 'f-2')];

      final resp = await floorHandler(makeReq('GET', '/floors'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as List), hasLength(2));
    });
  });

  // ─── POST /floors ─────────────────────────────────────────────────────────

  group('POST /floors', () {
    test('缺少 building_id → 400 VALIDATION_ERROR', () async {
      final resp = await floorHandler(
          makeReq('POST', '/floors', body: {'floor_number': 1}));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 floor_number → 400 VALIDATION_ERROR', () async {
      final resp = await floorHandler(
          makeReq('POST', '/floors', body: {'building_id': 'b-1'}));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('合法请求 → 201 data 含 building_id', () async {
      svc.itemResult = fakeFloor(id: 'f-new', buildingId: 'b-1');

      final resp = await floorHandler(makeReq('POST', '/floors', body: {
        'building_id': 'b-1',
        'floor_number': 3,
        'floor_name': '3F',
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      expect((json['data'] as Map)['building_id'], 'b-1');
    });
  });

  // ─── GET /floors/:id ─────────────────────────────────────────────────────

  group('GET /floors/:id', () {
    test('楼层不存在 → 404 FLOOR_NOT_FOUND', () async {
      svc.shouldThrow = const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');

      final resp = await floorHandler(makeReq('GET', '/floors/f-x'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'FLOOR_NOT_FOUND');
    });

    test('成功 → 200 data 含 floor_number', () async {
      svc.itemResult = fakeFloor(floorNumber: 5);

      final resp = await floorHandler(makeReq('GET', '/floors/f-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['floor_number'], 5);
    });
  });

  // ─── POST /floors/:id/cad ─────────────────────────────────────────────────

  group('POST /floors/:id/cad', () {
    test('合法 multipart .dwg 上传 → 202 status=converting', () async {
      svc.cadResult = {
        'floor_plan_id': 'fp-1',
        'version_label': 'v1',
        'status': 'converting',
      };

      final resp = await floorHandler(makeMultipartReq(
        '/floors/f-1/cad',
        {'version_label': 'v1'},
        userId: 'user-1',
      ));
      final json = await readJson(resp);

      expect(resp.statusCode, 202);
      expect((json['data'] as Map)['status'], 'converting');
    });
  });

  // ─── GET /floors/:id/heatmap ──────────────────────────────────────────────

  group('GET /floors/:id/heatmap', () {
    test('楼层不存在 → 404 FLOOR_NOT_FOUND', () async {
      svc.shouldThrow = const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');

      final resp = await floorHandler(makeReq('GET', '/floors/f-x/heatmap'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'FLOOR_NOT_FOUND');
    });

    test('楼层存在 → 200 data 含 units 数组，area_sqm 和 contract_id 序列化', () async {
      svc.heatmapResult = FloorHeatmap(
        floorId: 'f-1',
        svgPath: null,
        units: [
          HeatmapUnit(
            unitId: 'u-1',
            unitNumber: '101',
            currentStatus: 'leased',
            propertyType: 'office',
            tenantName: '测试租户',
            contractEndDate: '2027-06-30',
            areaSqm: 95.0,
            contractId: 'c-1',
          ),
        ],
      );

      final resp = await floorHandler(makeReq('GET', '/floors/f-1/heatmap'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      final units = (json['data'] as Map)['units'] as List;
      expect(units, hasLength(1));
      final unit = units.first as Map;
      expect(unit['area_sqm'], 95.0);
      expect(unit['contract_id'], 'c-1');
    });
  });

  // ─── GET /floors/:id/plans ────────────────────────────────────────────────

  group('GET /floors/:id/plans', () {
    test('楼层存在 → 200 data 长度与列表一致', () async {
      svc.plansResult = [fakeFloorPlan()];

      final resp = await floorHandler(makeReq('GET', '/floors/f-1/plans'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as List), hasLength(1));
    });
  });

  // ─── PATCH /floor-plans/:id/set-current ──────────────────────────────────

  group('PATCH /floor-plans/:id/set-current', () {
    test('图纸版本不存在 → 404', () async {
      svc.shouldThrow = const NotFoundException('FLOOR_NOT_FOUND', '图纸版本不存在');

      final resp =
          await planHandler(makeReq('PATCH', '/floor-plans/fp-x/set-current'));
      await readJson(resp);

      expect(resp.statusCode, 404);
    });

    test('成功 → 200 data 含 is_current=true', () async {
      svc.planResult = fakeFloorPlan(isCurrent: true);

      final resp =
          await planHandler(makeReq('PATCH', '/floor-plans/fp-1/set-current'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['is_current'], isTrue);
    });
  });
}
