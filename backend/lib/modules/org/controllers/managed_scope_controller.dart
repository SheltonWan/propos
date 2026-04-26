import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/errors/app_exception.dart';
import '../services/managed_scope_service.dart';

/// ManagedScopeController — 管辖范围读取与覆写。
class ManagedScopeController {
  final ManagedScopeService _service;

  ManagedScopeController(this._service);

  Router get router {
    final r = Router();
    r.get('/managed-scopes', _list);
    r.put('/managed-scopes', _set);
    return r;
  }

  Future<Response> _list(Request request) async {
    final q = request.url.queryParameters;
    final result = await _service.list(
      departmentId: q['department_id'],
      userId: q['user_id'],
    );
    return _json(200, {
      'data': result.map((s) => s.toJson()).toList(),
    });
  }

  Future<Response> _set(Request request) async {
    final body = await _parseBody(request);
    final departmentId = body['department_id'] as String?;
    final userId = body['user_id'] as String?;
    final scopesRaw = body['scopes'];
    if (scopesRaw is! List) {
      throw const ValidationException('VALIDATION_ERROR', 'scopes 必须为数组');
    }
    final scopes = scopesRaw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final result = await _service.set(
      departmentId: departmentId,
      userId: userId,
      scopes: scopes,
    );
    return _json(200, {
      'data': result.map((s) => s.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> _parseBody(Request request) async {
    final s = await request.readAsString();
    if (s.isEmpty) return {};
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      throw const ValidationException('VALIDATION_ERROR', '请求体格式无效');
    }
  }

  Response _json(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
