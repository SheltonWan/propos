import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/floor_service.dart';

/// FloorController — 楼层与图纸上传路由处理器。
///
/// 端点：
///   GET  /api/floors                          — 楼层列表（可按 building_id 过滤）
///   POST /api/floors                          — 新建楼层
///   GET  /api/floors/:id                      — 楼层详情
///   POST /api/floors/:id/cad                  — 上传 CAD 文件
///   GET  /api/floors/:id/heatmap              — 楼层热区状态图（含 svg_path + units[]）
///   GET  /api/floors/:id/units                — 楼层单元状态列表（热区绑定专用，无分页）
///   GET  /api/floors/:id/plans                — 图纸版本列表
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class FloorController {
  final FloorService _service;

  FloorController(this._service);

  Router get router {
    final r = Router();
    r.get('/floors', _list);
    r.post('/floors', _create);
    r.get('/floors/<id>', _getOne);
    r.post('/floors/<id>/cad', _uploadCad);
    r.get('/floors/<id>/heatmap', _heatmap);
    r.get('/floors/<id>/units', _unitsByFloor);
    r.get('/floors/<id>/plans', _plans);
    return r;
  }

  // UUID 格式正则（防止非法值直接传入 PostgreSQL::UUID 转换）
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// GET /api/floors?building_id=xxx
  Future<Response> _list(Request request) async {
    final buildingId = request.url.queryParameters['building_id'];
    // 若提供了 building_id，必须符合 UUID 格式，防止非法值到达 PostgreSQL 层
    if (buildingId != null && !_uuidRegex.hasMatch(buildingId)) {
      throw const ValidationException(
          'VALIDATION_ERROR', 'building_id 必须是合法的 UUID 格式');
    }
    final floors = await _service.listFloors(buildingId: buildingId);
    return _jsonResponse(200, {
      'data': floors.map((f) => f.toJson()).toList(),
    });
  }

  /// POST /api/floors
  /// Body: { building_id, floor_number, floor_name?, nla? }
  Future<Response> _create(Request request) async {
    final body = await _parseBody(request);
    final floor = await _service.createFloor(
      buildingId: _requireString(body, 'building_id'),
      floorNumber: _requireInt(body, 'floor_number'),
      floorName: body['floor_name'] as String?,
      nla: (body['nla'] as num?)?.toDouble(),
    );
    return _jsonResponse(201, {'data': floor.toJson()});
  }

  /// GET /api/floors/:id
  Future<Response> _getOne(Request request, String id) async {
    final floor = await _service.getFloor(id);
    return _jsonResponse(200, {'data': floor.toJson()});
  }

  /// POST /api/floors/:id/cad
  /// Content-Type: multipart/form-data
  /// Fields: version_label; Files: file
  Future<Response> _uploadCad(Request request, String id) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final parsed = await MultipartParser.parse(request);

    final versionLabel = parsed.requireField('version_label');
    final file = parsed.requireFile('file');

    final result = await _service.uploadCad(
      floorId: id,
      versionLabel: versionLabel,
      fileBytes: file.bytes,
      originalFilename: file.filename,
      uploadedBy: ctx.userId,
    );
    return _jsonResponse(202, {'data': result});
  }

  /// GET /api/floors/:id/heatmap
  Future<Response> _heatmap(Request request, String id) async {
    final heatmap = await _service.getHeatmap(id);
    return _jsonResponse(200, {'data': heatmap.toJson()});
  }

  /// GET /api/floors/:id/units
  /// 热区绑定专用端点：返回该楼层全部单元状态列表，无分页。
  /// 前端 加载 SVG 后通过 data-unit-id 属性匹配 DB 单元 UUID 覆盖热区状态色。
  Future<Response> _unitsByFloor(Request request, String id) async {
    final heatmap = await _service.getHeatmap(id);
    return _jsonResponse(200, {
      'data': heatmap.units.map((u) => u.toJson()).toList(),
    });
  }

  /// GET /api/floors/:id/plans
  Future<Response> _plans(Request request, String id) async {
    final plans = await _service.listPlans(id);
    return _jsonResponse(200, {
      'data': plans.map((p) => p.toJson()).toList(),
    });
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

  int _requireInt(Map<String, dynamic> body, String field) {
    final v = body[field];
    if (v == null) {
      throw ValidationException('VALIDATION_ERROR', '$field 不能为空');
    }
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw ValidationException('VALIDATION_ERROR', '$field 必须为整数');
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
