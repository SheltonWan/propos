import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../../assets/repositories/import_batch_repository.dart';
import '../repositories/user_admin_repository.dart';

/// UserImportService — 批量导入员工账号。
///
/// 文件列（中文表头）：姓名 / 邮箱 / 初始密码 / 角色 / 部门ID / 绑定主合同ID
///   - 邮箱：作为登录唯一标识，必须为有效 email 格式
///   - 初始密码：由导入人填写，后端直接进行 bcrypt(cost=12) 散列存储
///   - 角色：英文标识，如 leasing_specialist
///   - 部门ID：系统部门 UUID，sub_landlord 角色可留空
///   - 绑定主合同ID：仅 sub_landlord 角色必填，填写主合同 UUID
///   - dry_run 时不落库；有任意错误时整批回滚
class UserImportService {
  final Pool _db;

  UserImportService(this._db);

  static const List<String> _expectedHeaders = [
    '姓名',
    '邮箱',
    '初始密码',
    '角色',
    '部门ID',
    '绑定主合同ID',
  ];

  Future<Map<String, dynamic>> import({
    required String filename,
    required List<int> bytes,
    bool dryRun = false,
    String? batchName,
    required String createdBy,
  }) async {
    final rows = _parseFile(filename, bytes);
    if (rows.isEmpty) {
      throw const ValidationException('IMPORT_FILE_INVALID', '文件内容为空');
    }
    _validateHeader(rows.first);
    final dataRows = rows.skip(1).toList();

    final errorDetails = <Map<String, dynamic>>[];
    int successCount = 0;
    String rollbackStatus = 'committed';
    final actualBatchName =
        batchName ?? 'users_import_${DateTime.now().toUtc().toIso8601String()}';

    if (dataRows.isEmpty) {
      final batch = await ImportBatchRepository(_db).create(
        batchName: actualBatchName,
        dataType: 'users',
        totalRecords: 0,
        successCount: 0,
        failureCount: 0,
        rollbackStatus: 'committed',
        isDryRun: dryRun,
        sourceFilePath: filename,
        createdBy: createdBy,
      );
      return _buildResult(batch, dryRun, []);
    }

    Map<String, dynamic>? batch;
    try {
      await _db.runTx((tx) async {
        for (int i = 0; i < dataRows.length; i++) {
          final rowIndex = i + 2;
          final row = dataRows[i];
          try {
            final name = _str(row, 0)?.trim() ?? '';
            final email = _str(row, 1)?.trim() ?? '';
            final password = _str(row, 2)?.trim() ?? '';
            final role = _str(row, 3)?.trim() ?? '';
            final departmentId = _str(row, 4)?.trim() ?? '';
            final boundContractId = _str(row, 5)?.trim() ?? '';

            if (name.isEmpty) {
              throw const ValidationException(
                  'VALIDATION_ERROR', '员工姓名不能为空');
            }
            if (email.isEmpty ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              throw const ValidationException(
                  'VALIDATION_ERROR', '邮箱格式无效');
            }
            if (password.isEmpty) {
              throw const ValidationException('VALIDATION_ERROR', '初始密码不能为空');
            }
            _validateRole(role);
            if (role != 'sub_landlord' && departmentId.isEmpty) {
              throw const ValidationException(
                  'VALIDATION_ERROR', '部门ID不能为空');
            }
            if (role == 'sub_landlord' && boundContractId.isEmpty) {
              throw const ValidationException(
                  'BOUND_CONTRACT_REQUIRED', '二房东必须填写绑定主合同ID');
            }

            final repo = UserAdminRepository(tx);
            if (await repo.emailExists(email.toLowerCase(), tx: tx)) {
              throw const ConflictException(
                  'EMAIL_ALREADY_EXISTS', '邮箱已被注册');
            }

            // 使用导入文件中提供的初始密码进行散列存储
            final hash = BCrypt.hashpw(
              password,
              BCrypt.gensalt(logRounds: 12),
            );

            await repo.create(
              name: name,
              email: email.toLowerCase(),
              passwordHash: hash,
              role: role,
              departmentId: departmentId.isNotEmpty ? departmentId : null,
              boundContractId:
                  role == 'sub_landlord' && boundContractId.isNotEmpty
                      ? boundContractId
                      : null,
              tx: tx,
            );
            successCount++;
          } on AppException catch (e) {
            errorDetails.add({
              'row': rowIndex,
              'code': e.code,
              'message': e.message,
            });
          }
        }

        if (errorDetails.isNotEmpty && !dryRun) {
          rollbackStatus = 'rolled_back';
          throw _RollbackSignal();
        }
        if (dryRun) {
          rollbackStatus = 'committed';
          throw _RollbackSignal();
        }
      });
    } on _RollbackSignal {
      // 预期回滚信号
    }

    batch = await ImportBatchRepository(_db).create(
      batchName: actualBatchName,
      dataType: 'users',
      totalRecords: dataRows.length,
      successCount: errorDetails.isEmpty ? successCount : 0,
      failureCount: errorDetails.length,
      rollbackStatus: rollbackStatus,
      isDryRun: dryRun,
      errorDetails: errorDetails.isEmpty ? null : errorDetails,
      sourceFilePath: filename,
      createdBy: createdBy,
    );

    return _buildResult(batch, dryRun, errorDetails);
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Future<String?> _resolveDepartmentId(
    String path, {
    required Session tx,
  }) async {
    final parts = path
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    String? currentParent;
    for (final part in parts) {
      final result = await tx.execute(
        Sql.named('''
          SELECT id::TEXT
          FROM departments
          WHERE name = @name
            AND (
              (@parent::UUID IS NULL AND parent_id IS NULL)
              OR parent_id = @parent::UUID
            )
            AND is_active = TRUE
          LIMIT 1
        '''),
        parameters: {'name': part, 'parent': currentParent},
      );
      if (result.isEmpty) return null;
      currentParent = result.first.toColumnMap()['id'] as String;
    }
    return currentParent;
  }

  Future<String?> _resolveContractId(
    String contractNo, {
    required Session tx,
  }) async {
    // 兼容尚未实现的 contracts 模块：表存在但若无数据则返回 null
    try {
      final result = await tx.execute(
        Sql.named('''
          SELECT id::TEXT
          FROM contracts
          WHERE contract_no = @no
          LIMIT 1
        '''),
        parameters: {'no': contractNo},
      );
      if (result.isEmpty) return null;
      return result.first.toColumnMap()['id'] as String;
    } catch (_) {
      // contracts 表/列尚未存在时返回 null
      return null;
    }
  }

  void _validateRole(String role) {
    const valid = {
      'super_admin',
      'operations_manager',
      'leasing_specialist',
      'finance_staff',
      'maintenance_staff',
      'property_inspector',
      'report_viewer',
      'sub_landlord',
    };
    if (!valid.contains(role)) {
      throw ValidationException('VALIDATION_ERROR', '无效角色: $role');
    }
  }

  List<List<dynamic>> _parseFile(String filename, List<int> bytes) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.csv')) {
      final text = utf8.decode(bytes);
      return const CsvToListConverter(eol: '\n').convert(text);
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      final book = xlsx.Excel.decodeBytes(bytes);
      final sheet = book.tables.values.first;
      return sheet.rows
          .map((r) => r.map((c) => c?.value).toList())
          .toList();
    }
    throw const ValidationException(
        'IMPORT_FILE_INVALID', '仅支持 .csv / .xlsx 文件');
  }

  void _validateHeader(List<dynamic> header) {
    final actual = header.map((c) => c?.toString().trim()).toList();
    if (actual.length < _expectedHeaders.length) {
      throw const ValidationException(
          'IMPORT_HEADER_MISMATCH', '表头列与规范不一致');
    }
    for (int i = 0; i < _expectedHeaders.length; i++) {
      if (actual[i] != _expectedHeaders[i]) {
        throw ValidationException('IMPORT_HEADER_MISMATCH',
            '表头第 ${i + 1} 列应为 ${_expectedHeaders[i]}，实际为 ${actual[i]}');
      }
    }
  }

  String? _str(List<dynamic> row, int idx) {
    if (idx >= row.length) return null;
    final v = row[idx];
    if (v == null) return null;
    return v.toString();
  }

  Map<String, dynamic> _buildResult(
    Map<String, dynamic> batch,
    bool dryRun,
    List<Map<String, dynamic>> errorDetails,
  ) {
    return {
      'batch_id': batch['id'],
      'batch_name': batch['batch_name'],
      'dry_run': dryRun,
      'total_records': batch['total_records'],
      'success_count': batch['success_count'],
      'failure_count': batch['failure_count'],
      'rollback_status': batch['rollback_status'],
      'error_details': errorDetails,
    };
  }
}

class _RollbackSignal implements Exception {}
