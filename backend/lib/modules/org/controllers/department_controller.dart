import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/department_import_service.dart';
import '../services/department_service.dart';

/// DepartmentController — 组织架构相关路由。
class DepartmentController {
  final DepartmentService _service;
  final DepartmentImportService _importService;

  DepartmentController(this._service, this._importService);

  Router get router {
    final r = Router();
    r.get('/departments', _list);
    r.post('/departments', _create);
    r.patch('/departments/<id>', _update);
    r.delete('/departments/<id>', _deactivate);
    r.post('/departments/import', _import);
    return r;
  }

  Future<Response> _list(Request request) async {
    final tree = await _service.getTree();
    return _json(200, {
      'data': tree.map((d) => d.toJson()).toList(),
    });
  }

  Future<Response> _create(Request request) async {
    final body = await _parseBody(request);
    final name = _requireString(body, 'name');
    final dep = await _service.create(
      name: name,
      parentId: body['parent_id'] as String?,
      sortOrder: (body['sort_order'] as num?)?.toInt() ?? 0,
    );
    return _json(201, {'data': dep.toJson()});
  }

  Future<Response> _update(Request request, String id) async {
    final body = await _parseBody(request);
    final hasParent = body.containsKey('parent_id');
    final dep = await _service.update(
      id,
      name: body['name'] as String?,
      parentId: hasParent ? body['parent_id'] as String? : null,
      parentIdSet: hasParent,
      sortOrder: (body['sort_order'] as num?)?.toInt(),
    );
    return _json(200, {'data': dep.toJson()});
  }

  Future<Response> _deactivate(Request request, String id) async {
    await _service.deactivate(id);
    return _json(200, {
      'data': {'message': '部门已停用'},
    });
  }

  Future<Response> _import(Request request) async {
    final ctx = request.context[kRequestContextKey] as RequestContext;
    final parsed = await MultipartParser.parse(request);
    final file = parsed.requireFile('file');
    final dryRun = parsed.optionalField('dry_run')?.toLowerCase() == 'true';
    final batchName = parsed.optionalField('batch_name');

    final result = await _importService.import(
      filename: file.filename,
      bytes: file.bytes,
      dryRun: dryRun,
      batchName: batchName,
      createdBy: ctx.userId,
    );
    return _json(200, {'data': result});
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _parseBody(Request request) async {
    final s = await request.readAsString();
    if (s.isEmpty) return {};
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      throw const ValidationException('VALIDATION_ERROR', '请求体格式无效');
    }
  }

  String _requireString(Map<String, dynamic> b, String key) {
    final v = b[key];
    if (v == null || v is! String || v.trim().isEmpty) {
      throw ValidationException('VALIDATION_ERROR', '$key 不能为空');
    }
    return v;
  }

  Response _json(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
