/// BuildingController 单元测试
///
/// 覆盖场景（共 16 个）：
///   GET  /buildings             — 返回列表 / 空列表
///   POST /buildings             — 缺 name / 缺 property_type / 缺 gfa / 成功 201
///   POST /buildings/with-floors — 缺 name / 缺 property_type / Service 抛异常 → 400 /
///                                 成功 201 含 building + floors 数组
///   GET  /buildings/:id         — Service 抛 NotFoundException → 404 / 成功 200
///   PATCH /buildings/:id        — Service 抛 NotFoundException → 404 / 成功 200
///   DELETE /buildings/:id       — Service 抛 ValidationException(BUILDING_HAS_UNITS) → 400 /
///                                 Service 抛 NotFoundException → 404 / 成功 200
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/modules/assets/controllers/building_controller.dart';

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

Future<Map<String, dynamic>> readJson(Response resp) async =>
    jsonDecode(await resp.readAsString()) as Map<String, dynamic>;

// ─── 主体 ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeBuildingService svc;
  late Handler handler;

  setUp(() {
    svc = FakeBuildingService();
    handler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(BuildingController(svc).router.call);
  });

  // ─── GET /buildings ───────────────────────────────────────────────────────

  group('GET /buildings', () {
    test('服务返回空 → 200 data=[]', () async {
      final resp = await handler(makeReq('GET', '/buildings'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect(json['data'], isEmpty);
    });

    test('服务返回 1 条楼栋 → 200 data 长度 1', () async {
      svc.listResult = [fakeBuilding()];

      final resp = await handler(makeReq('GET', '/buildings'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as List), hasLength(1));
    });
  });

  // ─── POST /buildings ──────────────────────────────────────────────────────

  group('POST /buildings', () {
    test('缺少 name → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/buildings', body: {
        'property_type': 'office',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 property_type → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/buildings', body: {
        'name': '新楼',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 gfa（数字类型字段）→ 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/buildings', body: {
        'name': '新楼',
        'property_type': 'office',
        'total_floors': 5,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('合法请求体 → 201 data 含 id', () async {
      svc.itemResult = fakeBuilding(id: 'b-new');

      final resp = await handler(makeReq('POST', '/buildings', body: {
        'name': '新楼',
        'property_type': 'office',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      expect((json['data'] as Map)['id'], 'b-new');
    });
  });

  // ─── GET /buildings/:id ───────────────────────────────────────────────────

  group('GET /buildings/:id', () {
    test('服务抛出 NotFoundException → 404', () async {
      svc.shouldThrow =
          const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');

      final resp = await handler(makeReq('GET', '/buildings/b-x'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'BUILDING_NOT_FOUND');
    });

    test('成功 → 200 data.property_type 存在', () async {
      svc.itemResult = fakeBuilding(propertyType: 'retail');

      final resp = await handler(makeReq('GET', '/buildings/b-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['property_type'], 'retail');
    });
  });

  // ─── PATCH /buildings/:id ─────────────────────────────────────────────────

  group('PATCH /buildings/:id', () {
    test('楼栋不存在 → 404 BUILDING_NOT_FOUND', () async {
      svc.shouldThrow =
          const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');

      final resp = await handler(makeReq('PATCH', '/buildings/b-x',
          body: {'name': '新名称'}));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'BUILDING_NOT_FOUND');
    });

    test('合法更新 → 200 data 含更新后字段', () async {
      svc.itemResult = fakeBuilding(name: '更新后名称');

      final resp = await handler(makeReq('PATCH', '/buildings/b-1',
          body: {'name': '更新后名称'}));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['name'], '更新后名称');
    });
  });

  // ─── POST /buildings/with-floors ─────────────────────────────────────────

  group('POST /buildings/with-floors', () {
    test('缺少 name → 400 VALIDATION_ERROR', () async {
      final resp =
          await handler(makeReq('POST', '/buildings/with-floors', body: {
        'property_type': 'office',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 property_type → 400 VALIDATION_ERROR', () async {
      final resp =
          await handler(makeReq('POST', '/buildings/with-floors', body: {
        'name': '新楼',
        'total_floors': 5,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('Service 抛出 ValidationException → 400', () async {
      svc.shouldThrow =
          const ValidationException('VALIDATION_ERROR', '总楼层数必须大于 0');

      final resp =
          await handler(makeReq('POST', '/buildings/with-floors', body: {
        'name': '新楼',
        'property_type': 'office',
        'total_floors': 0,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('合法请求体 → 201 data 含 building 和 floors 数组', () async {
      svc.itemResult = fakeBuilding(id: 'b-new');
      svc.floorsResult = [
        fakeFloor(id: 'f-1', floorNumber: 1),
        fakeFloor(id: 'f-2', floorNumber: 2),
      ];

      final resp =
          await handler(makeReq('POST', '/buildings/with-floors', body: {
        'name': '新楼',
        'property_type': 'office',
        'total_floors': 2,
        'gfa': 1000.0,
        'nla': 800.0,
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      final data = json['data'] as Map;
      expect((data['building'] as Map)['id'], 'b-new');
      expect((data['floors'] as List), hasLength(2));
    });
  });

  // ─── DELETE /buildings/:id ────────────────────────────────────────────────

  group('DELETE /buildings/:id', () {
    test('楼栋有单元 → 400 BUILDING_HAS_UNITS', () async {
      svc.shouldThrow =
          const ValidationException('BUILDING_HAS_UNITS', '楼栋下仍有单元');

      final resp = await handler(makeReq('DELETE', '/buildings/b-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'BUILDING_HAS_UNITS');
    });

    test('楼栋不存在 → 404 BUILDING_NOT_FOUND', () async {
      svc.shouldThrow = const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');

      final resp = await handler(makeReq('DELETE', '/buildings/b-x'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'BUILDING_NOT_FOUND');
    });

    test('成功删除 → 200 data.{id, deleted: true}', () async {
      // FakeBuildingService.deleteBuilding 默认返回 void（无异常）
      final resp = await handler(makeReq('DELETE', '/buildings/b-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      final data = json['data'] as Map;
      expect(data['id'], 'b-1');
      expect(data['deleted'], isTrue);
    });
  });
}
