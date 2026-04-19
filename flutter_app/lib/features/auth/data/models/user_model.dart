import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// UserBrief DTO from login response.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required String role,
    @JsonKey(name: 'department_id') String? departmentId,
    @JsonKey(name: 'must_change_password') @Default(false) bool mustChangePassword,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  User toEntity() => User(
        id: id,
        name: name,
        email: email,
        role: UserRole.fromString(role),
        departmentId: departmentId,
        mustChangePassword: mustChangePassword,
      );
}

/// CurrentUser DTO from GET /api/auth/me.
@freezed
abstract class CurrentUserModel with _$CurrentUserModel {
  const factory CurrentUserModel({
    required String id,
    required String name,
    required String email,
    required String role,
    @JsonKey(name: 'department_id') String? departmentId,
    @JsonKey(name: 'department_name') String? departmentName,
    required List<String> permissions,
    @JsonKey(name: 'bound_contract_id') String? boundContractId,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
  }) = _CurrentUserModel;

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserModelFromJson(json);
}

extension CurrentUserModelX on CurrentUserModel {
  CurrentUser toEntity() => CurrentUser(
        id: id,
        name: name,
        email: email,
        role: UserRole.fromString(role),
        departmentId: departmentId,
        departmentName: departmentName,
        permissions: permissions,
        boundContractId: boundContractId,
        isActive: isActive,
        lastLoginAt: lastLoginAt != null ? DateTime.parse(lastLoginAt!) : null,
      );
}
