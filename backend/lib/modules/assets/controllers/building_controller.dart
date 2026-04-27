import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../services/building_service.dart';

/// BuildingController — 楼栋资源路由处理器。
///
/// 端点：
///   GET  /api/buildings       — 楼栋列表
///   POST /api/buildings       — 新建楼栋
///   GET  /api/buildings/:id   — 楼栋详情
///   PATCH /api/buildings/:id  — 更新楼栋
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class BuildingController {
  final BuildingService _service;

  BuildingController(this._service);

  Router get router {
    final r = Router();
    r.get('/buildings', _list);
    r.post('/buildings', _create);
    r.post('/buildings/with-floors', _createWithFloors);
    r.get('/buildings/<id>', _getOne);
    r.patch('/buildings/<id>', _update);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// GET /api/buildings
  Future<Response> _list(Request request) async {
    final buildings = await _service.listBuildings();
    return _jsonResponse(200, {
      'data': buildings.map((b) => b.toJson()).toList(),
    });
  }

  /// POST /api/buildings
  /// Body: { name, property_type, total_floors, gfa, nla, address?, built_year? }
  Future<Response> _create(Request request) async {
    final body = await _parseBody(request);
    final building = await _service.createBuilding(
      name: _requireString(body, 'name'),
      propertyType: _requireString(body, 'property_type'),
      totalFloors: _requireInt(body, 'total_floors'),
      gfa: _requireDouble(body, 'gfa'),
      nla: _requireDouble(body, 'nla'),
      address: body['address'] as String?,
      builtYear: body['built_year'] as int?,
    );
    return _jsonResponse(201, {'data': building.toJson()});
  }

  /// POST /api/buildings/with-floors
  /// 创建楼栋并自动批量创建 1F~NF 共 N 个楼层（事务）。
  /// Body: { name, property_type, total_floors, gfa, nla, address?, built_year? }
  /// 返回: { data: { building, floors: [...] } }
  Future<Response> _createWithFloors(Request request) async {
    final body = await _parseBody(request);
    final result = await _service.createBuildingWithFloors(
      name: _requireString(body, 'name'),
      propertyType: _requireString(body, 'property_type'),
      totalFloors: _requireInt(body, 'total_floors'),
      gfa: _requireDouble(body, 'gfa'),
      nla: _requireDouble(body, 'nla'),
      address: body['address'] as String?,
      builtYear: body['built_year'] as int?,
    );
    return _jsonResponse(201, {
      'data': {
        'building': result.building.toJson(),
        'floors': result.floors.map((f) => f.toJson()).toList(),
      },
    });
  }

  /// GET /api/buildings/:id
  Future<Response> _getOne(Request request, String id) async {
    final building = await _service.getBuilding(id);
    return _jsonResponse(200, {'data': building.toJson()});
  }

  /// PATCH /api/buildings/:id
  Future<Response> _update(Request request, String id) async {
    final body = await _parseBody(request);

    // address 字段需区分「未传 / 传 null / 传具体值」
    final hasAddress = body.containsKey('address');
    final addressValue = body['address'] as String?;

    final building = await _service.updateBuilding(
      id,
      name: body['name'] as String?,
      propertyType: body['property_type'] as String?,
      totalFloors: body['total_floors'] as int?,
      gfa: (body['gfa'] as num?)?.toDouble(),
      nla: (body['nla'] as num?)?.toDouble(),
      address: hasAddress ? addressValue : null,
      addressSet: hasAddress,
      builtYear: body['built_year'] as int?,
    );
    return _jsonResponse(200, {'data': building.toJson()});
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

  double _requireDouble(Map<String, dynamic> body, String field) {
    final v = body[field];
    if (v == null) {
      throw ValidationException('VALIDATION_ERROR', '$field 不能为空');
    }
    if (v is num) return v.toDouble();
    throw ValidationException('VALIDATION_ERROR', '$field 必须为数字');
  }

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
