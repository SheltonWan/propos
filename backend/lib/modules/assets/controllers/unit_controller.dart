import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/unit_service.dart';
import '../services/unit_import_service.dart';

/// UnitController — 房源单元资源路由处理器。
///
/// 端点：
///   GET   /api/units           — 单元列表（含过滤、分页）
///   POST  /api/units           — 新建单元
///   GET   /api/units/export    — 导出房源台账（Excel）
///   POST  /api/units/import    — 批量导入（Excel multipart）
///   GET   /api/units/:id       — 单元详情
///   PATCH /api/units/:id       — 更新单元
///   GET   /api/assets/overview — 资产总览统计
///
/// 注意：/export 和 /import 必须先于 /:id 注册，避免被路径参数匹配拦截。
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class UnitController {
  final UnitService _service;
  final UnitImportService _importService;

  UnitController(this._service, this._importService);

  Router get router {
    final r = Router();
    // 具体路径先于参数路径
    r.get('/units/export', _export);
    r.post('/units/import', _import);
    r.get('/assets/overview', _overview);
    r.get('/units', _list);
    r.post('/units', _create);
    r.get('/units/<id>', _getOne);
    r.patch('/units/<id>', _update);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// GET /api/units?building_id=&floor_id=&property_type=&current_status=&is_leasable=&include_archived=&page=&pageSize=
  ///
  /// 分页参数：`pageSize`（官方）；为兼容旧客户端同时接受 `page_size`。
  Future<Response> _list(Request request) async {
    final q = request.url.queryParameters;
    final page = int.tryParse(q['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(q['pageSize'] ?? q['page_size'] ?? '20') ?? 20;
    final isLeasable = q['is_leasable'] == null
        ? null
        : q['is_leasable'] == 'true';
    final includeArchived = q['include_archived'] == 'true';

    final result = await _service.listUnits(
      buildingId: q['building_id'],
      floorId: q['floor_id'],
      propertyType: q['property_type'],
      currentStatus: q['current_status'],
      isLeasable: isLeasable,
      includeArchived: includeArchived,
      page: page,
      pageSize: pageSize,
    );
    return _jsonResponse(200, {
      'data': result.items.map((u) => u.toJson()).toList(),
      'meta': result.meta.toJson(),
    });
  }

  /// POST /api/units
  Future<Response> _create(Request request) async {
    final body = await _parseBody(request);
    final unit = await _service.createUnit(
      floorId: _requireString(body, 'floor_id'),
      buildingId: _requireString(body, 'building_id'),
      unitNumber: _requireString(body, 'unit_number'),
      propertyType: _requireString(body, 'property_type'),
      grossArea: (body['gross_area'] as num?)?.toDouble(),
      netArea: (body['net_area'] as num?)?.toDouble(),
      orientation: body['orientation'] as String?,
      ceilingHeight: (body['ceiling_height'] as num?)?.toDouble(),
      decorationStatus: body['decoration_status'] as String? ?? 'blank',
      isLeasable: body['is_leasable'] as bool? ?? true,
      extFields: body['ext_fields'] as Map<String, dynamic>?,
      marketRentReference: (body['market_rent_reference'] as num?)?.toDouble(),
      qrCode: body['qr_code'] as String?,
    );
    return _jsonResponse(201, {'data': unit.toJson()});
  }

  /// GET /api/units/:id
  Future<Response> _getOne(Request request, String id) async {
    final unit = await _service.getUnit(id);
    return _jsonResponse(200, {'data': unit.toJson()});
  }

  /// PATCH /api/units/:id
  Future<Response> _update(Request request, String id) async {
    final body = await _parseBody(request);
    final hasArchivedAt = body.containsKey('archived_at');
    DateTime? archivedAt;
    if (hasArchivedAt && body['archived_at'] != null) {
      archivedAt = DateTime.tryParse(body['archived_at'] as String);
    }

    final unit = await _service.updateUnit(
      id,
      unitNumber: body['unit_number'] as String?,
      grossArea: (body['gross_area'] as num?)?.toDouble(),
      netArea: (body['net_area'] as num?)?.toDouble(),
      orientation: body['orientation'] as String?,
      ceilingHeight: (body['ceiling_height'] as num?)?.toDouble(),
      decorationStatus: body['decoration_status'] as String?,
      isLeasable: body['is_leasable'] as bool?,
      extFields: body['ext_fields'] as Map<String, dynamic>?,
      marketRentReference: (body['market_rent_reference'] as num?)?.toDouble(),
      predecessorUnitIds: (body['predecessor_unit_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      archivedAt: archivedAt,
      archivedAtSet: hasArchivedAt,
    );
    return _jsonResponse(200, {'data': unit.toJson()});
  }

  /// GET /api/units/export?property_type=
  Future<Response> _export(Request request) async {
    final q = request.url.queryParameters;
    final bytes = await _importService.exportUnits(
      propertyType: q['property_type'],
    );
    return Response(
      200,
      body: bytes,
      headers: {
        'content-type':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'content-disposition': 'attachment; filename="units_export.xlsx"',
      },
    );
  }

  /// POST /api/units/import
  /// Content-Type: multipart/form-data
  /// Fields: dry_run?; Files: file
  Future<Response> _import(Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final parsed = await MultipartParser.parse(request);
    final file = parsed.requireFile('file');
    final dryRun = parsed.optionalField('dry_run') == 'true';

    final result = await _importService.importUnits(
      filename: file.filename,
      fileBytes: file.bytes,
      dryRun: dryRun,
      userId: ctx.userId,
    );
    return _jsonResponse(200, {'data': result});
  }

  /// GET /api/assets/overview
  Future<Response> _overview(Request request) async {
    final stats = await _service.getOverview();
    return _jsonResponse(200, {'data': stats.toJson()});
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
