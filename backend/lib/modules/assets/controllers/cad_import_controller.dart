import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/cad_import_service.dart';

/// CadImportController — 楼栋级 DXF 导入任务路由处理器。
///
/// 端点：
///   POST  /api/buildings/:id/cad-upload       — 上传整栋 DXF 启动切分（异步）
///   GET   /api/cad-import-jobs/:id            — 查询任务状态（轮询）
///   PATCH /api/cad-import-jobs/:id/assign     — 手动指派未匹配 SVG 到楼层
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class CadImportController {
  final CadImportService _service;

  CadImportController(this._service);

  Router get router {
    final r = Router();
    r.post('/buildings/<id>/cad-upload', _uploadDxf);
    r.get('/cad-import-jobs/<id>', _getJob);
    r.patch('/cad-import-jobs/<id>/assign', _assignUnmatched);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// POST /api/buildings/:id/cad-upload
  /// Content-Type: multipart/form-data
  /// Files: file（必须是 .dxf）
  Future<Response> _uploadDxf(Request request, String id) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final parsed = await MultipartParser.parse(request);
    final file = parsed.requireFile('file');

    final job = await _service.uploadDxf(
      buildingId: id,
      fileBytes: file.bytes,
      originalFilename: file.filename,
      createdBy: ctx.userId,
    );
    return _jsonResponse(202, {'data': job.toJson()});
  }

  /// GET /api/cad-import-jobs/:id
  Future<Response> _getJob(Request request, String id) async {
    final job = await _service.getJob(id);
    return _jsonResponse(200, {'data': job.toJson()});
  }

  /// PATCH /api/cad-import-jobs/:id/assign
  /// Body: { svg_label: string, floor_id: string }
  Future<Response> _assignUnmatched(Request request, String id) async {
    final body = await _parseBody(request);
    final job = await _service.assignUnmatched(
      id,
      svgLabel: _requireString(body, 'svg_label'),
      floorId: _requireString(body, 'floor_id'),
      propertyType: body['property_type'] as String?,
    );
    return _jsonResponse(200, {'data': job.toJson()});
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
