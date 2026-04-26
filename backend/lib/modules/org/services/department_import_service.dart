import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../../assets/repositories/import_batch_repository.dart';
import '../repositories/department_repository.dart';

/// DepartmentImportService — 批量导入组织架构。
///
/// 文件列：name / parent_path / level / sort_order
///   - 顶级部门 parent_path 留空
///   - level 必须与 parent_path 匹配（顶级=1）
///   - dry_run 时不落库
///   - 失败时整批回滚
class DepartmentImportService {
  final Pool _db;

  DepartmentImportService(this._db);

  static const List<String> _expectedHeaders = [
    'name',
    'parent_path',
    'level',
    'sort_order',
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
        batchName ?? 'departments_import_${DateTime.now().toUtc().toIso8601String()}';

    if (dataRows.isEmpty) {
      // 空文件直接写一条空批次记录
      final batch = await ImportBatchRepository(_db).create(
        batchName: actualBatchName,
        dataType: 'departments',
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
        // 按 level 升序处理，确保父部门先于子部门写入
        final sorted = List<Map<String, dynamic>>.from(
          dataRows.asMap().entries.map(
                (e) => {
                  'rowIndex': e.key + 2, // +2: 含表头 + 1-based
                  'name': _str(e.value, 0),
                  'parent_path': _str(e.value, 1),
                  'level': _int(e.value, 2),
                  'sort_order': _int(e.value, 3, defaultValue: 0),
                },
              ),
        )..sort((a, b) =>
            ((a['level'] ?? 99) as int).compareTo((b['level'] ?? 99) as int));

        final repo = DepartmentRepository(tx);

        for (final row in sorted) {
          final rowIndex = row['rowIndex'] as int;
          try {
            final name = (row['name'] as String?)?.trim() ?? '';
            if (name.isEmpty) {
              throw const ValidationException(
                  'VALIDATION_ERROR', '部门名称不能为空');
            }
            final level = row['level'] as int?;
            if (level == null || level < 1 || level > 3) {
              throw const ValidationException(
                  'MAX_DEPTH_EXCEEDED', '层级必须在 1~3 之间');
            }
            final parentPath = (row['parent_path'] as String?)?.trim() ?? '';

            String? parentId;
            if (level == 1) {
              if (parentPath.isNotEmpty) {
                throw const ValidationException(
                    'VALIDATION_ERROR', '顶级部门不能指定 parent_path');
              }
            } else {
              if (parentPath.isEmpty) {
                throw const ValidationException(
                    'VALIDATION_ERROR', '非顶级部门必须指定 parent_path');
              }
              parentId = await _resolveParentId(repo, parentPath, tx: tx);
              if (parentId == null) {
                throw const NotFoundException(
                    'PARENT_DEPARTMENT_NOT_FOUND', '父部门路径不存在');
              }
            }

            // 同 parent 下重名校验（导入幂等：已存在则跳过同名节点）
            final existing = await repo.findByNameUnderParent(
              name,
              parentId,
              tx: tx,
            );
            if (existing != null) {
              successCount++;
              continue;
            }

            await repo.create(
              name: name,
              parentId: parentId,
              level: level,
              sortOrder: row['sort_order'] as int,
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
      // 预期内的回滚信号
    }

    batch = await ImportBatchRepository(_db).create(
      batchName: actualBatchName,
      dataType: 'departments',
      totalRecords: dataRows.length,
      successCount: errorDetails.isEmpty ? successCount : 0,
      failureCount: errorDetails.length,
      rollbackStatus: rollbackStatus,
      isDryRun: dryRun,
      errorDetails: errorDetails.isEmpty ? null : errorDetails,
      sourceFilePath: filename,
      createdBy: createdBy,
    );

    if (errorDetails.isNotEmpty && !dryRun) {
      // 业务失败：整批回滚后仍需返回结构化数据，所以这里抛 ConflictException
      // 让 Controller 收敛错误码，但响应 body 携带详情。
      // 这里直接返回 result，由 Controller 决定 HTTP 状态。
    }

    return _buildResult(batch, dryRun, errorDetails);
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  Future<String?> _resolveParentId(
    DepartmentRepository repo,
    String path, {
    required Session tx,
  }) async {
    final parts = path.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    String? currentParentId;
    for (final part in parts) {
      final node = await repo.findByNameUnderParent(
        part,
        currentParentId,
        tx: tx,
      );
      if (node == null) return null;
      currentParentId = node.id;
    }
    return currentParentId;
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

  int? _int(List<dynamic> row, int idx, {int? defaultValue}) {
    if (idx >= row.length) return defaultValue;
    final v = row[idx];
    if (v == null || (v is String && v.trim().isEmpty)) return defaultValue;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? defaultValue;
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
