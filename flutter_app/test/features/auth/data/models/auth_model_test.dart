import 'package:flutter_test/flutter_test.dart';
import 'package:propos_app/features/auth/data/models/auth_tokens_model.dart';
import 'package:propos_app/features/auth/data/models/user_model.dart';
import 'package:propos_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:propos_app/features/auth/domain/entities/user.dart';

// 认证相关 DTO 模型单元测试：验证 JSON 反序列化与 toEntity() 映射的正确性
void main() {
  // ── AuthTokensModel ──

  group('AuthTokensModel', () {
    // 标准响应字段 → 全部正确解析
    test('fromJson parses all fields correctly', () {
      const json = <String, dynamic>{
        'access_token': 'eyJhbGciOi...',
        'refresh_token': 'dGVzdC1yZWZyZXNo',
        'expires_in': 3600,
      };

      final model = AuthTokensModel.fromJson(json);

      expect(model.accessToken, 'eyJhbGciOi...');
      expect(model.refreshToken, 'dGVzdC1yZWZyZXNo');
      expect(model.expiresIn, 3600);
    });

    // toEntity() → 映射至纯 Dart 实体，字段无损
    test('toEntity maps to AuthTokens correctly', () {
      const model = AuthTokensModel(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        expiresIn: 7200,
      );

      final entity = model.toEntity();

      expect(entity, isA<AuthTokens>());
      expect(entity.accessToken, 'access-123');
      expect(entity.refreshToken, 'refresh-456');
      expect(entity.expiresIn, 7200);
    });
  });

  // ── UserModel ──

  group('UserModel', () {
    // 完整字段 → 全部解析，包括可选的 departmentId 和 mustChangePassword
    test('fromJson parses all fields correctly', () {
      const json = <String, dynamic>{
        'id': 'user-1',
        'name': '张三',
        'email': 'zhangsan@propos.com',
        'role': 'operations_manager',
        'department_id': 'dept-99',
        'must_change_password': true,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-1');
      expect(model.name, '张三');
      expect(model.email, 'zhangsan@propos.com');
      expect(model.role, 'operations_manager');
      expect(model.departmentId, 'dept-99');
      expect(model.mustChangePassword, true);
    });

    // 可选字段缺失时使用默认值
    test('fromJson uses default false for must_change_password when absent', () {
      const json = <String, dynamic>{
        'id': 'user-2',
        'name': '李四',
        'email': 'lisi@propos.com',
        'role': 'finance_staff',
      };

      final model = UserModel.fromJson(json);

      expect(model.mustChangePassword, false);
      expect(model.departmentId, isNull);
    });

    // toEntity() → UserRole 枚举映射正确
    test('toEntity converts role string to UserRole enum', () {
      const model = UserModel(
        id: 'user-3',
        name: '王五',
        email: 'wangwu@propos.com',
        role: 'sub_landlord',
        mustChangePassword: true,
      );

      final entity = model.toEntity();

      expect(entity, isA<User>());
      expect(entity.role, UserRole.subLandlord);
      expect(entity.mustChangePassword, true);
    });

    // toEntity() 覆盖所有 UserRole 枚举值的解析
    test('toEntity maps all role strings to correct UserRole values', () {
      final roleMappings = <String, UserRole>{
        'super_admin': UserRole.superAdmin,
        'operations_manager': UserRole.operationsManager,
        'leasing_specialist': UserRole.leasingSpecialist,
        'finance_staff': UserRole.financeStaff,
        'maintenance_staff': UserRole.maintenanceStaff,
        'property_inspector': UserRole.propertyInspector,
        'report_viewer': UserRole.reportViewer,
        'sub_landlord': UserRole.subLandlord,
      };

      for (final entry in roleMappings.entries) {
        final model = UserModel(
          id: 'u',
          name: 'n',
          email: 'e@e.com',
          role: entry.key,
        );
        expect(
          model.toEntity().role,
          entry.value,
          reason: 'role "${entry.key}" should map to ${entry.value}',
        );
      }
    });
  });

  // ── CurrentUserModel ──

  group('CurrentUserModel', () {
    // 完整字段 → 全部正确解析
    test('fromJson parses all fields correctly', () {
      const json = <String, dynamic>{
        'id': 'user-1',
        'name': '张三',
        'email': 'zhangsan@propos.com',
        'role': 'operations_manager',
        'department_id': 'dept-1',
        'department_name': '运营部',
        'permissions': ['contracts:read', 'invoices:read', 'users:write'],
        'bound_contract_id': null,
        'is_active': true,
        'last_login_at': '2026-04-19T10:00:00Z',
      };

      final model = CurrentUserModel.fromJson(json);

      expect(model.id, 'user-1');
      expect(model.name, '张三');
      expect(model.departmentName, '运营部');
      expect(model.permissions, ['contracts:read', 'invoices:read', 'users:write']);
      expect(model.isActive, true);
      expect(model.lastLoginAt, '2026-04-19T10:00:00Z');
    });

    // 可选字段缺失 → 解析不抛出，字段为 null
    test('fromJson handles missing optional fields gracefully', () {
      const json = <String, dynamic>{
        'id': 'user-2',
        'name': '李四',
        'email': 'lisi@propos.com',
        'role': 'finance_staff',
        'permissions': <String>[],
        'is_active': true,
      };

      final model = CurrentUserModel.fromJson(json);

      expect(model.departmentId, isNull);
      expect(model.departmentName, isNull);
      expect(model.boundContractId, isNull);
      expect(model.lastLoginAt, isNull);
    });

    // toEntity() → lastLoginAt 字符串正确解析为 DateTime
    test('toEntity parses lastLoginAt string to DateTime', () {
      const json = <String, dynamic>{
        'id': 'user-1',
        'name': '张三',
        'email': 'zhangsan@propos.com',
        'role': 'operations_manager',
        'permissions': <String>[],
        'is_active': true,
        'last_login_at': '2026-04-19T10:00:00Z',
      };

      final entity = CurrentUserModel.fromJson(json).toEntity();

      expect(entity.lastLoginAt, isNotNull);
      expect(entity.lastLoginAt!.year, 2026);
      expect(entity.lastLoginAt!.month, 4);
      expect(entity.lastLoginAt!.day, 19);
    });

    // toEntity() → lastLoginAt 为 null 时不抛出
    test('toEntity returns null lastLoginAt when field is absent', () {
      const json = <String, dynamic>{
        'id': 'user-1',
        'name': '张三',
        'email': 'zhangsan@propos.com',
        'role': 'finance_staff',
        'permissions': <String>[],
        'is_active': false,
      };

      final entity = CurrentUserModel.fromJson(json).toEntity();

      expect(entity.lastLoginAt, isNull);
    });

    // toEntity() → permissions 列表正确映射，hasPermission 工作正常
    test('toEntity preserves permissions list and hasPermission works', () {
      const json = <String, dynamic>{
        'id': 'user-1',
        'name': '张三',
        'email': 'zhangsan@propos.com',
        'role': 'operations_manager',
        'permissions': ['contracts:read', 'contracts:write'],
        'is_active': true,
      };

      final entity = CurrentUserModel.fromJson(json).toEntity();

      expect(entity.hasPermission('contracts:read'), true);
      expect(entity.hasPermission('contracts:write'), true);
      // 未授权的权限应返回 false
      expect(entity.hasPermission('users:admin'), false);
    });
  });
}
