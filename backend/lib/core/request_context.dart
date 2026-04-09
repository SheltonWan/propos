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

  /// 用户角色枚举值集合
  ///
  /// 定义系统中所有可用的用户角色类型：
  /// - [admin]: 系统管理员，具有最高权限
  /// - [operationsManager]: 运营经理，负责业务运营管理
  /// - [leaseSpecialist]: 租赁专员，处理租赁相关事务
  /// - [financeStaff]: 财务人员，管理财务相关事务
  /// - [maintenanceStaff]: 维护人员，负责设施维护工作
  /// - [subLandlord]: 二级房东，管理子租赁业务
  /// - [readOnly]: 只读权限用户，仅可查看信息不可修改
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
