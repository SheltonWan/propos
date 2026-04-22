import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/floor_service.dart';

/// FloorPlanController — 图纸版本切换路由处理器。
///
/// 端点：
///   PATCH /api/floor-plans/:id/set-current — 将指定图纸版本设为当前生效版本
///
/// 所有端点受 RBAC 中间件保护，Controller 不做角色判断。
class FloorPlanController {
  final FloorService _service;

  FloorPlanController(this._service);

  Router get router {
    final r = Router();
    r.patch('/floor-plans/<id>/set-current', _setCurrent);
    return r;
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  /// PATCH /api/floor-plans/:id/set-current
  Future<Response> _setCurrent(Request request, String id) async {
    final plan = await _service.setCurrentPlan(id);
    return _jsonResponse(200, {'data': plan.toJson()});
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Response _jsonResponse(int status, Map<String, dynamic> body) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
