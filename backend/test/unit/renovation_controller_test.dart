/// RenovationController 单元测试
///
/// 覆盖场景（共 11 个）：
///   GET  /renovations           — 返回列表 + meta / 带 unit_id 过滤
///   POST /renovations           — 缺 unit_id / 缺 renovation_type /
///                                 无效 started_at 格式 / 成功 201
///   GET  /renovations/:id       — NOT_FOUND → 404 / 成功
///   PATCH /renovations/:id      — 无效 completed_at 格式 → 400 /
///                                 Service 抛 NOT_FOUND → 404 / 成功 200
///   POST /renovations/:id/photos — 成功 / 无效 photo_stage → 400
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/core/errors/error_handler.dart';
import 'package:propos_backend/core/pagination.dart';
import 'package:propos_backend/core/request_context.dart';
import 'package:propos_backend/modules/assets/controllers/renovation_controller.dart';

import 'helpers/asset_fakes.dart';

// ─── 辅助 ─────────────────────────────────────────────────────────────────────

/// 构造带可选 RequestContext 的请求
Request makeReq(
  String method,
  String path, {
  Map<String, dynamic>? body,
  bool withContext = false,
}) {
  final headers = body != null
      ? {'content-type': 'application/json; charset=utf-8'}
      : const <String, String>{};
  var req = Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body != null ? jsonEncode(body) : null,
    headers: headers,
  );
  if (withContext) {
    req = req.change(context: {
      kRequestContextKey:
          RequestContext(userId: 'user-test', role: UserRole.superAdmin),
    });
  }
  return req;
}

/// 构造最小 multipart 请求（照片上传）
Request makePhotoReq(
  String path, {
  required String photoStage,
  String filename = 'photo.jpg',
  bool includeFile = true,
}) {
  const boundary = 'photo_boundary_42';
  final sb = StringBuffer();
  sb.write('--$boundary\r\n');
  sb.write('Content-Disposition: form-data; name="photo_stage"\r\n\r\n');
  sb.write('$photoStage\r\n');
  if (includeFile) {
    sb.write('--$boundary\r\n');
    sb.write(
        'Content-Disposition: form-data; name="file"; filename="$filename"\r\n');
    sb.write('Content-Type: image/jpeg\r\n\r\n');
    sb.write('\xFF\xD8\xFF\xE0\r\n'); // JPEG bytes
  }
  sb.write('--$boundary--\r\n');

  return Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: sb.toString(),
    headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
  );
}

Future<Map<String, dynamic>> readJson(Response resp) async =>
    jsonDecode(await resp.readAsString()) as Map<String, dynamic>;

// ─── 主体 ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeRenovationService svc;
  late Handler handler;

  setUp(() {
    svc = FakeRenovationService();
    handler = const Pipeline()
        .addMiddleware(errorHandler())
        .addHandler(RenovationController(svc).router.call);
  });

  // ─── GET /renovations ────────────────────────────────────────────────────

  group('GET /renovations', () {
    test('返回空列表 → 200 data=[] meta.total=0', () async {
      final resp = await handler(makeReq('GET', '/renovations'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect(json['data'], isEmpty);
      expect((json['meta'] as Map)['total'], 0);
    });

    test('带 unit_id 过滤 → 200 data 含改造记录', () async {
      svc.listResult = PaginatedResult(
        items: [fakeRenovationRecord(unitId: 'u-1')],
        meta: const PaginationMeta(page: 1, pageSize: 20, total: 1),
      );

      final resp =
          await handler(makeReq('GET', '/renovations?unit_id=u-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as List), hasLength(1));
    });
  });

  // ─── POST /renovations ────────────────────────────────────────────────────

  group('POST /renovations', () {
    test('缺少 unit_id → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/renovations',
          body: {
            'renovation_type': '隔断改造',
            'started_at': '2026-01-01T00:00:00Z',
          },
          withContext: true));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('缺少 renovation_type → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/renovations',
          body: {
            'unit_id': 'u-1',
            'started_at': '2026-01-01T00:00:00Z',
          },
          withContext: true));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('无效 started_at 格式 → 400 VALIDATION_ERROR', () async {
      final resp = await handler(makeReq('POST', '/renovations',
          body: {
            'unit_id': 'u-1',
            'renovation_type': '改造',
            'started_at': '2026年1月1日', // 非 ISO 8601
          },
          withContext: true));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('合法请求 → 201 data 含 id', () async {
      svc.itemResult = fakeRenovationRecord(id: 'r-new');

      final resp = await handler(makeReq('POST', '/renovations',
          body: {
            'unit_id': 'u-1',
            'renovation_type': '水电改造',
            'started_at': '2026-01-01T00:00:00Z',
          },
          withContext: true));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      expect((json['data'] as Map)['id'], 'r-new');
    });
  });

  // ─── GET /renovations/:id ─────────────────────────────────────────────────

  group('GET /renovations/:id', () {
    test('不存在 → 404 RENOVATION_NOT_FOUND', () async {
      svc.shouldThrow =
          const NotFoundException('RENOVATION_NOT_FOUND', '改造记录不存在');

      final resp = await handler(makeReq('GET', '/renovations/r-x'));
      final json = await readJson(resp);

      expect(resp.statusCode, 404);
      expect((json['error'] as Map)['code'], 'RENOVATION_NOT_FOUND');
    });

    test('成功 → 200 data 含 renovation_type', () async {
      svc.itemResult = fakeRenovationRecord(renovationType: '精装改造');

      final resp = await handler(makeReq('GET', '/renovations/r-1'));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['renovation_type'], '精装改造');
    });
  });

  // ─── PATCH /renovations/:id ───────────────────────────────────────────────

  group('PATCH /renovations/:id', () {
    test('无效 completed_at ISO 格式 → 400 VALIDATION_ERROR', () async {
      final resp =
          await handler(makeReq('PATCH', '/renovations/r-1', body: {
        'completed_at': 'not-a-date',
      }));
      final json = await readJson(resp);

      expect(resp.statusCode, 400);
      expect((json['error'] as Map)['code'], 'VALIDATION_ERROR');
    });

    test('记录不存在 → 404', () async {
      svc.shouldThrow =
          const NotFoundException('RENOVATION_NOT_FOUND', '改造记录不存在');

      final resp = await handler(makeReq('PATCH', '/renovations/r-x',
          body: {'status': 'completed'}));
      await readJson(resp);

      expect(resp.statusCode, 404);
    });

    test('合法更新 → 200 data 含 renovation_type', () async {
      svc.itemResult = fakeRenovationRecord(renovationType: '升级改造');

      final resp = await handler(makeReq('PATCH', '/renovations/r-1',
          body: {'renovation_type': '升级改造'}));
      final json = await readJson(resp);

      expect(resp.statusCode, 200);
      expect((json['data'] as Map)['renovation_type'], '升级改造');
    });
  });

  // ─── POST /renovations/:id/photos ────────────────────────────────────────

  group('POST /renovations/:id/photos', () {
    test('无效 photo_stage → 400 (Service 抛异常)', () async {
      svc.shouldThrow =
          const ValidationException('VALIDATION_ERROR', '无效 photo_stage');

      final resp = await handler(makePhotoReq(
        '/renovations/r-1/photos',
        photoStage: 'during', // 非法值
      ));
      await readJson(resp);

      expect(resp.statusCode, 400);
    });

    test('合法照片上传 → 201 data 含 storage_path', () async {
      svc.photoResult = {
        'storage_path': 'renovations/r-1/abc.jpg',
        'photo_stage': 'before',
      };

      final resp = await handler(makePhotoReq(
        '/renovations/r-1/photos',
        photoStage: 'before',
      ));
      final json = await readJson(resp);

      expect(resp.statusCode, 201);
      expect((json['data'] as Map)['storage_path'], contains('renovations/r-1/'));
    });
  });
}
