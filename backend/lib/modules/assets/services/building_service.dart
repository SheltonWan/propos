import 'package:postgres/postgres.dart';

import '../../../core/errors/app_exception.dart';
import '../models/building.dart';
import '../models/floor.dart';
import '../repositories/building_repository.dart';
import '../repositories/floor_repository.dart';

/// BuildingService — 楼栋管理业务逻辑。
///
/// 约束：
///   1. 楼栋数量有限（<10），列表不分页
///   2. 不产生审计日志（楼栋变更不在 4 类审计范围内）
///   3. 禁止直接返回 Response，错误通过 AppException 抛出
class BuildingService {
  final Pool _db;

  BuildingService(this._db);

  /// 获取所有楼栋列表
  Future<List<Building>> listBuildings() async {
    return BuildingRepository(_db).findAll();
  }

  /// 获取楼栋详情，不存在则抛 BUILDING_NOT_FOUND
  Future<Building> getBuilding(String id) async {
    final building = await BuildingRepository(_db).findById(id);
    if (building == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    return building;
  }

  /// 创建楼栋
  Future<Building> createBuilding({
    required String name,
    required String propertyType,
    required int totalFloors,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
  }) async {
    _validatePropertyType(propertyType);
    if (totalFloors <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数必须大于 0');
    }
    if (gfa <= 0 || nla <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '建筑面积/净可租面积必须大于 0');
    }
    return BuildingRepository(_db).create(
      name: name,
      propertyType: propertyType,
      totalFloors: totalFloors,
      gfa: gfa,
      nla: nla,
      address: address,
      builtYear: builtYear,
    );
  }

  /// 更新楼栋，不存在则抛 BUILDING_NOT_FOUND
  Future<Building> updateBuilding(
    String id, {
    String? name,
    String? propertyType,
    int? totalFloors,
    double? gfa,
    double? nla,
    String? address,
    bool addressSet = false,
    int? builtYear,
  }) async {
    if (propertyType != null) _validatePropertyType(propertyType);
    if (totalFloors != null && totalFloors <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数必须大于 0');
    }
    final updated = await BuildingRepository(_db).update(
      id,
      name: name,
      propertyType: propertyType,
      totalFloors: totalFloors,
      gfa: gfa,
      nla: nla,
      address: addressSet ? address : null,
      builtYear: builtYear,
    );
    if (updated == null) {
      throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
    }
    return updated;
  }

  // ─── 辅助 ─────────────────────────────────────────────────────────────────

  /// 创建楼栋并同事务批量创建 N 个楼层（floor_number 从 1 到 totalFloors）。
  ///
  /// 用于 admin 后台「新建楼栋」对话框：管理员只需填写楼栋基本信息和总层数，
  /// 后端在单一事务中自动生成 1F~NF 共 N 条楼层记录。
  Future<({Building building, List<Floor> floors})> createBuildingWithFloors({
    required String name,
    required String propertyType,
    required int totalFloors,
    required double gfa,
    required double nla,
    String? address,
    int? builtYear,
  }) async {
    _validatePropertyType(propertyType);
    if (totalFloors <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数必须大于 0');
    }
    if (totalFloors > 200) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数不得超过 200');
    }
    if (gfa <= 0 || nla <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '建筑面积/净可租面积必须大于 0');
    }

    return await _db.runTx<({Building building, List<Floor> floors})>((tx) async {
      final building = await BuildingRepository(tx).create(
        name: name,
        propertyType: propertyType,
        totalFloors: totalFloors,
        gfa: gfa,
        nla: nla,
        address: address,
        builtYear: builtYear,
      );

      final floors = <Floor>[];
      final floorRepo = FloorRepository(tx);
      for (var n = 1; n <= totalFloors; n++) {
        final floor = await floorRepo.create(
          buildingId: building.id,
          floorNumber: n,
        );
        floors.add(floor);
      }
      return (building: building, floors: floors);
    });
  }

  // ─── 内部 ─────────────────────────────────────────────────────────────────

  /// buildings 层允许的业态标签值
  /// - office / retail / apartment：单一业态楼栋
  /// - mixed：综合体（楼栋下单元各自有具体业态，按行指定）
  /// 注意：units.property_type 仍只允许前三种，禁止使用 mixed。
  static const _validPropertyTypes = {'office', 'retail', 'apartment', 'mixed'};

  void _validatePropertyType(String pt) {
    if (!_validPropertyTypes.contains(pt)) {
      throw ValidationException(
          'VALIDATION_ERROR', '无效的业态值: $pt（合法值: office/retail/apartment/mixed）');
    }
  }
}
