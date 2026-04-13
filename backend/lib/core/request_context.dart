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
/// 定义系统中所有可用的用户角色类型（v2.0 — 8 角色）：
/// - [superAdmin]: 超级管理员，具有最高权限
/// - [operationsManager]: 运营管理层，负责业务运营管理与审批
/// - [leasingSpecialist]: 租务专员，处理合同与租客日常事务
/// - [financeStaff]: 财务人员，管理财务收支与核销
/// - [maintenanceStaff]: 维修技工，负责工单接派与水电抄表
/// - [propertyInspector]: 楼管巡检员，负责资产巡检与登记
/// - [reportViewer]: 只读观察者（投资人/审计），仅可查看报表
/// - [subLandlord]: 二房东，管理子租赁业务（外部角色）
enum UserRole {
  superAdmin,
  operationsManager,
  leasingSpecialist,
  financeStaff,
  maintenanceStaff,
  propertyInspector,
  reportViewer,
  subLandlord;

  static UserRole fromString(String value) {
    return switch (value) {
      'super_admin' => superAdmin,
      'operations_manager' => operationsManager,
      'leasing_specialist' => leasingSpecialist,
      'finance_staff' => financeStaff,
      'maintenance_staff' => maintenanceStaff,
      'property_inspector' => propertyInspector,
      'report_viewer' => reportViewer,
      'sub_landlord' => subLandlord,
      // 向后兼容旧 JWT（过渡期，可在稳定后移除）
      'admin' => superAdmin,
      'lease_specialist' => leasingSpecialist,
      'read_only' => reportViewer,
      _ => throw ArgumentError('未知角色: $value'),
    };
  }

  String get value => switch (this) {
        superAdmin => 'super_admin',
    operationsManager => 'operations_manager',
        leasingSpecialist => 'leasing_specialist',
    financeStaff => 'finance_staff',
    maintenanceStaff => 'maintenance_staff',
        propertyInspector => 'property_inspector',
        reportViewer => 'report_viewer',
        subLandlord => 'sub_landlord',
  };
}

/// Request context key
const kRequestContextKey = 'propos.ctx';

extension RequestContextExtension on Map<String, Object> {
  RequestContext get requestContext =>
      this[kRequestContextKey] as RequestContext;
}
