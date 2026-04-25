import 'dart:convert';

import 'package:postgres/postgres.dart';

/// ImportBatchRepository — `import_batches` 表写入。
///
/// 仅暴露 create 方法。批次记录一旦写入即只读，不支持更新或删除。
class ImportBatchRepository {
  final Session _db;

  ImportBatchRepository(this._db);

  /// 写入一条导入批次记录，返回完整列映射。
  /// 当处于事务中时可由调用方传入 [tx]；否则使用持久化 Session。
  Future<Map<String, dynamic>> create({
    required String batchName,
    required String dataType,
    required int totalRecords,
    required int successCount,
    required int failureCount,
    required String rollbackStatus,
    required bool isDryRun,
    List<Map<String, dynamic>>? errorDetails,
    String? sourceFilePath,
    String? createdBy,
    Session? tx,
  }) async {
    final db = tx ?? _db;
    final result = await db.execute(
      Sql.named('''
        INSERT INTO import_batches (
          batch_name, data_type, total_records,
          success_count, failure_count, rollback_status,
          error_details, is_dry_run, source_file_path, created_by
        )
        VALUES (
          @batchName, @dataType::import_data_type, @totalRecords,
          @successCount, @failureCount, @rollbackStatus::import_rollback_status,
          @errorDetails::JSONB, @isDryRun, @sourceFilePath, @createdBy::UUID
        )
        RETURNING
          id::TEXT,
          batch_name,
          data_type::TEXT          AS data_type,
          total_records,
          success_count,
          failure_count,
          rollback_status::TEXT    AS rollback_status,
          error_details,
          is_dry_run,
          source_file_path,
          created_by::TEXT         AS created_by,
          created_at
      '''),
      parameters: {
        'batchName': batchName,
        'dataType': dataType,
        'totalRecords': totalRecords,
        'successCount': successCount,
        'failureCount': failureCount,
        'rollbackStatus': rollbackStatus,
        'errorDetails':
            errorDetails == null ? null : jsonEncode(errorDetails),
        'isDryRun': isDryRun,
        'sourceFilePath': sourceFilePath,
        'createdBy': createdBy,
      },
    );
    return result.first.toColumnMap();
  }
}
