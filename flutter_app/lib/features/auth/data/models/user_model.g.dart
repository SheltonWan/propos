// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  departmentId: json['department_id'] as String?,
  mustChangePassword: json['must_change_password'] as bool? ?? false,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'department_id': instance.departmentId,
      'must_change_password': instance.mustChangePassword,
    };

_CurrentUserModel _$CurrentUserModelFromJson(Map<String, dynamic> json) =>
    _CurrentUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      departmentId: json['department_id'] as String?,
      departmentName: json['department_name'] as String?,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      boundContractId: json['bound_contract_id'] as String?,
      isActive: json['is_active'] as bool,
      lastLoginAt: json['last_login_at'] as String?,
    );

Map<String, dynamic> _$CurrentUserModelToJson(_CurrentUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'department_id': instance.departmentId,
      'department_name': instance.departmentName,
      'permissions': instance.permissions,
      'bound_contract_id': instance.boundContractId,
      'is_active': instance.isActive,
      'last_login_at': instance.lastLoginAt,
    };
