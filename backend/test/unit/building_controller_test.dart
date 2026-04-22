/// BuildingController 单元测试
///
/// 覆盖场景（共 8 个）：
///   GET  /buildings         — 返回列表 / 空列表
///   POST /buildings         — 缺 name / 缺 property_type / 缺 total_floors /
///                             缺 gfa / 成功 201
///   GET  /buildings/:id     — Service 抛 NotFoundException → 404
///   PATCH /buildings/:id    — Service 抛 NotFoundException → 404 / 成功 200
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
}
