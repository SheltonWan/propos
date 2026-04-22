import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../models/renovation_record.dart';
import '../repositories/renovation_repository.dart';
import '../repositories/unit_repository.dart';
import '../../../core/pagination.dart';

/// RenovationService — 改造记录与照片管理业务逻辑。
///
/// 约束：
///   1. 改造记录不在 4 类审计日志范围内，不产生 audit_log
///   2. 照片存储于 FILE_STORAGE_PATH/renovations/{record_id}/{index}.jpg
///   3. 文件追加使用 array_append，避免并发覆盖
class RenovationService {
  final Pool _db;
  final String _fileStoragePath;

  static const _uuid = Uuid();

  RenovationService(this._db, this._fileStoragePath);

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<PaginatedResult<RenovationRecord>> listRenovations({
    String? unitId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return RenovationRepository(_db).findAll(
      unitId: unitId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<RenovationRecord> getRenovation(String id) async {
    final record = await RenovationRepository(_db).findById(id);
    if (record == null) {
      throw const NotFoundException('NOT_FOUND', '改造记录不存在');
    }
    return record;
  }

  Future<RenovationRecord> createRenovation({
    required String unitId,
    required String renovationType,
    required DateTime startedAt,
    DateTime? completedAt,
    double? cost,
    String? contractor,
    String? description,
    required String createdBy,
  }) async {
    // 校验单元存在
    final unit = await UnitRepository(_db).findById(unitId);
    if (unit == null) {
      throw const NotFoundException('UNIT_NOT_FOUND', '单元不存在');
    }
    if (cost != null && cost < 0) {
      throw const ValidationException('VALIDATION_ERROR', '施工造价不能为负数');
    }
    if (completedAt != null && completedAt.isBefore(startedAt)) {
      throw const ValidationException('VALIDATION_ERROR', '完成日期不能早于开始日期');
    }

    return RenovationRepository(_db).create(
      unitId: unitId,
      renovationType: renovationType,
      startedAt: startedAt,
      completedAt: completedAt,
      cost: cost,
      contractor: contractor,
      description: description,
      createdBy: createdBy,
    );
  }

  Future<RenovationRecord> updateRenovation(
    String id, {
    String? renovationType,
    DateTime? startedAt,
    DateTime? completedAt,
    bool completedAtSet = false,
    double? cost,
    String? contractor,
    String? description,
  }) async {
    if (cost != null && cost < 0) {
      throw const ValidationException('VALIDATION_ERROR', '施工造价不能为负数');
    }
    final updated = await RenovationRepository(_db).update(
      id,
      renovationType: renovationType,
      startedAt: startedAt,
      completedAt: completedAt,
      completedAtSet: completedAtSet,
      cost: cost,
      contractor: contractor,
      description: description,
    );
    if (updated == null) {
      throw const NotFoundException('NOT_FOUND', '改造记录不存在');
    }
    return updated;
  }

  // ─── 照片上传 ─────────────────────────────────────────────────────────────

  /// 上传改造照片，存储到 FILE_STORAGE_PATH/renovations/{id}/{uuid}.jpg
  /// 返回存储路径（相对路径）与 photo_stage
  Future<Map<String, String>> uploadPhoto({
    required String renovationId,
    required List<int> fileBytes,
    required String originalFilename,
    required String photoStage,
  }) async {
    // 校验记录存在
    final record = await RenovationRepository(_db).findById(renovationId);
    if (record == null) {
      throw const NotFoundException('NOT_FOUND', '改造记录不存在');
    }
    if (photoStage != 'before' && photoStage != 'after') {
      throw const ValidationException(
          'VALIDATION_ERROR', 'photo_stage 必须为 before 或 after');
    }

    // 校验文件类型（仅接受图片）
    final ext = _imageExtension(originalFilename);
    if (ext == null) {
      throw const ValidationException('VALIDATION_ERROR', '只接受 jpg/jpeg/png 格式图片');
    }

    // 生成唯一文件名
    final filename = '${_uuid.v4()}$ext';
    final dir = Directory(
        p.join(_fileStoragePath, 'renovations', renovationId));
    await dir.create(recursive: true);

    final fullPath = p.join(dir.path, filename);
    await File(fullPath).writeAsBytes(Uint8List.fromList(fileBytes));

    // 相对存储路径（供 GET /api/files/{path} 使用）
    final storagePath = 'renovations/$renovationId/$filename';

    // 追加到对应数组列
    final repo = RenovationRepository(_db);
    if (photoStage == 'before') {
      await repo.appendBeforePhotoPath(renovationId, storagePath);
    } else {
      await repo.appendAfterPhotoPath(renovationId, storagePath);
    }

    return {'storage_path': storagePath, 'photo_stage': photoStage};
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  static const _allowedImageExts = {'.jpg', '.jpeg', '.png'};

  String? _imageExtension(String filename) {
    final ext = p.extension(filename).toLowerCase();
    return _allowedImageExts.contains(ext) ? ext : null;
  }
}
