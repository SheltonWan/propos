import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// User entity (domain layer, pure Dart).
///
/// Aligned with `UserBrief` from API_CONTRACT v1.7.
/// No Flutter SDK dependency. No fromJson — see [UserModel] in data layer.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? departmentId,
    @Default(false) bool mustChangePassword,
  }) = _User;
}

/// Full user profile with permissions (from GET /api/auth/me).
@freezed
abstract class CurrentUser with _$CurrentUser {
  const CurrentUser._();
  const factory CurrentUser({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    String? departmentId,
    String? departmentName,
    required List<String> permissions,
    String? boundContractId,
    required bool isActive,
    DateTime? lastLoginAt,
  }) = _CurrentUser;

  bool hasPermission(String permission) => permissions.contains(permission);
}

/// User roles as defined in RBAC_MATRIX v2.1.
enum UserRole {
  superAdmin,
  operationsManager,
  leasingSpecialist,
  financeStaff,
  maintenanceStaff,
  propertyInspector,
  reportViewer,
  subLandlord;

  /// Parse server-side snake_case role string.
  static UserRole fromString(String value) => switch (value) {
        'super_admin' => UserRole.superAdmin,
        'operations_manager' => UserRole.operationsManager,
        'leasing_specialist' => UserRole.leasingSpecialist,
        'finance_staff' => UserRole.financeStaff,
        'maintenance_staff' => UserRole.maintenanceStaff,
        'property_inspector' => UserRole.propertyInspector,
        'report_viewer' => UserRole.reportViewer,
        'sub_landlord' => UserRole.subLandlord,
        _ => UserRole.reportViewer, // safe default
      };

  /// Convert back to server-side snake_case string.
  String toServerString() => switch (this) {
        UserRole.superAdmin => 'super_admin',
        UserRole.operationsManager => 'operations_manager',
        UserRole.leasingSpecialist => 'leasing_specialist',
        UserRole.financeStaff => 'finance_staff',
        UserRole.maintenanceStaff => 'maintenance_staff',
        UserRole.propertyInspector => 'property_inspector',
        UserRole.reportViewer => 'report_viewer',
        UserRole.subLandlord => 'sub_landlord',
      };
}
