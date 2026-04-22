import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/renovation_service.dart';

/// RenovationController — 改造记录与照片路由处理器。
///
/// 端点：
///   GET  /api/renovations             — 改造记录列表（可按 unit_id 过滤）
///   POST /api/renovations             — 新建改造记录
///   GET  /api/renovations/:id         — 改造记录详情
///   PATCH /api/renovations/:id        — 更新改造记录
///   POST /api/renovations/:id/photos  — 上传改造照片
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class RenovationController {
  final RenovationService _service;

  RenovationController(this._service);

  Router get router {
    final r = Router();
    r.get('/renovations', _list);
    r.post('/renovations', _create);
    r.get('/renovations/<id>', _getOne);
    r.patch('/renovations/<id>', _update);
    r.post('/renovations/<id>/photos', _uploadPhoto);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// GET /api/renovations?unit_id=&page=&page_size=
  Future<Response> _list(Request request) async {
    final q = request.url.queryParameters;
    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final pageSize = int.tryParse(q['page_size'] ?? '20') ?? 20;

    final result = await _service.listRenovations(
      unitId: q['unit_id'],
      page: page,
      pageSize: pageSize,
    );
    return _jsonResponse(200, {
      'data': result.items.map((r) => r.toJson()).toList(),
      'meta': result.meta.toJson(),
    });
  }

  /// POST /api/renovations
  /// Body: { unit_id, renovation_type, started_at, completed_at?, cost?, contractor?, description? }
  Future<Response> _create(Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final body = await _parseBody(request);

    final startedAtStr = _requireString(body, 'started_at');
    final startedAt = DateTime.tryParse(startedAtStr);
    if (startedAt == null) {
      throw const ValidationException('VALIDATION_ERROR', 'started_at 日期格式无效');
    }

    DateTime? completedAt;
    final completedAtStr = body['completed_at'] as String?;
    if (completedAtStr != null) {
      completedAt = DateTime.tryParse(completedAtStr);
      if (completedAt == null) {
        throw const ValidationException(
            'VALIDATION_ERROR', 'completed_at 日期格式无效');
      }
    }

    final record = await _service.createRenovation(
      unitId: _requireString(body, 'unit_id'),
      renovationType: _requireString(body, 'renovation_type'),
      startedAt: startedAt,
      completedAt: completedAt,
      cost: (body['cost'] as num?)?.toDouble(),
      contractor: body['contractor'] as String?,
      description: body['description'] as String?,
      createdBy: ctx.userId,
    );
    return _jsonResponse(201, {'data': record.toJson()});
  }

  /// GET /api/renovations/:id
  Future<Response> _getOne(Request request, String id) async {
    final record = await _service.getRenovation(id);
    return _jsonResponse(200, {'data': record.toJson()});
  }

  /// PATCH /api/renovations/:id
  Future<Response> _update(Request request, String id) async {
    final body = await _parseBody(request);

    DateTime? startedAt;
    final startedAtStr = body['started_at'] as String?;
    if (startedAtStr != null) {
      startedAt = DateTime.tryParse(startedAtStr);
      if (startedAt == null) {
        throw const ValidationException(
            'VALIDATION_ERROR', 'started_at 日期格式无效');
      }
    }

    final hasCompletedAt = body.containsKey('completed_at');
    DateTime? completedAt;
    if (hasCompletedAt && body['completed_at'] != null) {
      completedAt = DateTime.tryParse(body['completed_at'] as String);
      if (completedAt == null) {
        throw const ValidationException(
            'VALIDATION_ERROR', 'completed_at 日期格式无效');
      }
    }

    final record = await _service.updateRenovation(
      id,
      renovationType: body['renovation_type'] as String?,
      startedAt: startedAt,
      completedAt: completedAt,
      completedAtSet: hasCompletedAt,
      cost: (body['cost'] as num?)?.toDouble(),
      contractor: body['contractor'] as String?,
      description: body['description'] as String?,
    );
    return _jsonResponse(200, {'data': record.toJson()});
  }

  /// POST /api/renovations/:id/photos
  /// Content-Type: multipart/form-data
  /// Fields: photo_stage (before|after); Files: file
  Future<Response> _uploadPhoto(Request request, String id) async {
    final parsed = await MultipartParser.parse(request);
    final photoStage = parsed.requireField('photo_stage');
    final file = parsed.requireFile('file');

    final result = await _service.uploadPhoto(
      renovationId: id,
      fileBytes: file.bytes,
      originalFilename: file.filename,
      photoStage: photoStage,
    );
    return _jsonResponse(201, {'data': result});
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _parseBody(Request request) async {
    final bodyStr = await request.readAsString();
    if (bodyStr.isEmpty) return {};
    try {
      return jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _requireString(Map<String, dynamic> body, String field) {
    final v = body[field];
    if (v == null || v is! String || v.trim().isEmpty) {
      throw ValidationException('VALIDATION_ERROR', '$field 不能为空');
    }
    return v;
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
