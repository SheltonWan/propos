/// 请求上下文 — JWT 解析后注入到 Request 中传递给后续中间件和 Controller
/// 通过 Request.context['propos.ctx'] 取出
class RequestContext {
  final String userId;
  final UserRole role;
  /// 二房东专用：绑定的主合同 ID（JWT claim: bound_contract_id）
  final String? boundContractId;

  const RequestContext({
    required this.userId,
    required this.role,
    this.boundContractId,
  });
}

enum UserRole {
  admin,
  operationsManager,
  leaseSpecialist,
  financeStaff,
  maintenanceStaff,
  subLandlord,
  readOnly;

  static UserRole fromString(String value) {
    return switch (value) {
      'admin' => admin,
      'operations_manager' => operationsManager,
      'lease_specialist' => leaseSpecialist,
      'finance_staff' => financeStaff,
      'maintenance_staff' => maintenanceStaff,
      'sub_landlord' => subLandlord,
      'read_only' => readOnly,
      _ => throw ArgumentError('未知角色: $value'),
    };
  }

  String get value => switch (this) {
    admin => 'admin',
    operationsManager => 'operations_manager',
    leaseSpecialist => 'lease_specialist',
    financeStaff => 'finance_staff',
    maintenanceStaff => 'maintenance_staff',
    subLandlord => 'sub_landlord',
    readOnly => 'read_only',
  };
}

/// Request context key
const kRequestContextKey = 'propos.ctx';

extension RequestContextExtension on Map<String, Object> {
  RequestContext get requestContext =>
      this[kRequestContextKey] as RequestContext;
}
