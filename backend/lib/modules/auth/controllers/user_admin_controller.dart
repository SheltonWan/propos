import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/request_context.dart';
import '../../../shared/multipart_parser.dart';
import '../services/user_admin_service.dart';
import '../services/user_import_service.dart';

/// UserAdminController — 用户管理 CRUD 路由（API_CONTRACT §1.5–1.11、§1.15）。
///
/// 与 AuthController（认证流程）分离，避免 mixin。
class UserAdminController {
  final UserAdminService _service;
  final UserImportService _importService;

  UserAdminController(this._service, this._importService);

  Router get router {
    final r = Router();
    // 注意：/users/import 必须先于 /users/<id> 注册，否则会被路由参数吃掉
    r.post('/users/import', _import);
    r.get('/users', _list);
    r.post('/users', _create);
    r.get('/users/<id>', _detail);
    r.patch('/users/<id>/role', _updateRole);
    r.patch('/users/<id>/department', _updateDepartment);
    r.patch('/users/<id>/status', _updateStatus);
    r.patch('/users/<id>', _updateBasic);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  Future<Response> _list(Request request) async {
    final q = request.url.queryParameters;
    final isActive = q['is_active'] == null
        ? null
        : q['is_active']!.toLowerCase() == 'true';
    final result = await _service.list(
      search: q['search'],
      role: q['role'],
      departmentId: q['department_id'],
      isActive: isActive,
      page: int.tryParse(q['page'] ?? '1') ?? 1,
      pageSize:
          int.tryParse(q['pageSize'] ?? q['page_size'] ?? '20') ?? 20,
    );
    return _json(200, {
      'data': result.items.map((u) => u.toJson()).toList(),
      'meta': result.meta.toJson(),
    });
  }

  Future<Response> _detail(Request request, String id) async {
    final user = await _service.getById(id);
    return _json(200, {'data': user.toJson()});
  }

  Future<Response> _create(Request request) async {
    final body = await _parseBody(request);
    final user = await _service.create(
      name: _requireString(body, 'name'),
      email: _requireString(body, 'email'),
      password: _requireString(body, 'password'),
      role: _requireString(body, 'role'),
      departmentId: body['department_id'] as String?,
      boundContractId: body['bound_contract_id'] as String?,
    );
    return _json(201, {'data': user.toJson()});
  }

  Future<Response> _updateBasic(Request request, String id) async {
    final body = await _parseBody(request);
    final user = await _service.updateBasic(
      id,
      name: body['name'] as String?,
      email: body['email'] as String?,
    );
    return _json(200, {'data': user.toJson()});
  }

  Future<Response> _updateStatus(Request request, String id) async {
    final body = await _parseBody(request);
    final v = body['is_active'];
    if (v is! bool) {
      throw const ValidationException('VALIDATION_ERROR', 'is_active 必须为布尔值');
    }
    final user = await _service.updateStatus(id, v);
    return _json(200, {'data': user.toJson()});
  }

  Future<Response> _updateRole(Request request, String id) async {
    final body = await _parseBody(request);
    final user = await _service.updateRole(
      id,
      role: _requireString(body, 'role'),
      boundContractId: body['bound_contract_id'] as String?,
      boundContractIdSet: body.containsKey('bound_contract_id'),
    );
    return _json(200, {'data': user.toJson()});
  }

  Future<Response> _updateDepartment(Request request, String id) async {
    final body = await _parseBody(request);
    final user = await _service.updateDepartment(
      id,
      _requireString(body, 'department_id'),
    );
    return _json(200, {'data': user.toJson()});
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
