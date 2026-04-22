import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/floor.dart';
import '../models/floor_plan.dart';
import '../repositories/building_repository.dart';
import '../repositories/floor_repository.dart';

/// FloorService — 楼层与楼层图纸版本管理业务逻辑。
///
/// 约束：
///   1. CAD 上传后异步触发转换（Phase 1 仅存储原始文件，标记 converting 状态）
///   2. set-current 操作需同步更新 floors.svg_path / png_path
///   3. 楼层创建前校验楼栋是否存在
class FloorService {
  final Pool _db;
  final String _fileStoragePath;

  FloorService(this._db, this._fileStoragePath);

  // ─── floors ─────────────────────────────────────────────────────────────

  Future<List<Floor>> listFloors({String? buildingId}) async {
    return FloorRepository(_db).findAll(buildingId: buildingId);
  }

  Future<Floor> getFloor(String id) async {
    final floor = await FloorRepository(_db).findById(id);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return floor;
  }

  Future<Floor> createFloor({
    required String buildingId,
    required int floorNumber,
    String? floorName,
    double? nla,
  }) async {
    // 校验楼栋存在
    final building = await BuildingRepository(_db).findById(buildingId);
    if (building == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    // 校验同楼栋楼层号唯一
    final exists = await FloorRepository(_db)
        .existsByBuildingAndNumber(buildingId, floorNumber);
    if (exists) {
      throw const ConflictException(
          'FLOOR_ALREADY_EXISTS', '该楼栋下此楼层号已存在');
    }
    return FloorRepository(_db).create(
      buildingId: buildingId,
      floorNumber: floorNumber,
      floorName: floorName,
      nla: nla,
    );
  }

  // ─── 热区 ─────────────────────────────────────────────────────────────────

  Future<FloorHeatmap> getHeatmap(String floorId) async {
    final heatmap = await FloorRepository(_db).getHeatmap(floorId);
    if (heatmap == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return heatmap;
  }

  // ─── floor_plans ─────────────────────────────────────────────────────────

  Future<List<FloorPlan>> listPlans(String floorId) async {
    // 校验楼层存在
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }
    return FloorRepository(_db).findPlansByFloor(floorId);
  }

  /// 上传 CAD 文件并创建图纸版本记录。
  /// Phase 1：仅存储原始文件，返回 status='converting'；
  ///           转换任务由后台 Job 实际处理，此处同步存为 svg_path（占位）。
  Future<Map<String, dynamic>> uploadCad({
    required String floorId,
    required String versionLabel,
    required List<int> fileBytes,
    required String originalFilename,
    required String uploadedBy,
  }) async {
    // 校验楼层存在
    final floor = await FloorRepository(_db).findById(floorId);
    if (floor == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '楼层不存在');
    }

    // 校验文件扩展名
    final ext = p.extension(originalFilename).toLowerCase();
    if (ext != '.dwg') {
      throw const ValidationException('INVALID_CAD_FILE', '只接受 .dwg 格式文件');
    }

    // 持久化原始 DWG 文件
    final cadDir = Directory(
        p.join(_fileStoragePath, 'floors', floor.buildingId, floorId));
    await cadDir.create(recursive: true);

    final safeLabel = versionLabel
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .toLowerCase();
    final cadPath = p.join(cadDir.path, '$safeLabel.dwg');
    await File(cadPath).writeAsBytes(Uint8List.fromList(fileBytes));

    // 使用占位 svg_path（待后台 Job 转换后更新）
    final svgRelPath =
        'floors/${floor.buildingId}/$floorId/$safeLabel.svg';

    final plan = await FloorRepository(_db).createPlan(
      floorId: floorId,
      versionLabel: versionLabel,
      svgPath: svgRelPath,
      isCurrent: false,
      uploadedBy: uploadedBy,
    );

    return {
      'floor_plan_id': plan.id,
      'version_label': plan.versionLabel,
      'status': 'converting',
    };
  }

  /// 将指定图纸版本设为当前生效版本，并同步更新 floors.svg_path
  Future<FloorPlan> setCurrentPlan(String planId) async {
    final plan = await FloorRepository(_db).setCurrentPlan(planId);
    if (plan == null) {
      throw const NotFoundException('FLOOR_NOT_FOUND', '图纸版本不存在');
    }
    return plan;
  }
}
