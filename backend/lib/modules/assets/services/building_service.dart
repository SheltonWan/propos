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

  /// 更新楼栋，不存在则抛 BUILDING_NOT_FOUND。
  ///
  /// 当 [totalFloors] / [basementFloors] 大于楼栋当前的地上/地下层数时，
  /// 自动在事务中补齐缺失的楼层（floor_name = 1F~NF / B1~Bn）。
  /// 当传入值小于当前层数时，抛出 [ValidationException]，禁止减少
  /// （避免误删存量楼层及关联单元数据；如需减层，请人工先删除单元再删楼层）。
  Future<Building> updateBuilding(
    String id, {
    String? name,
    String? propertyType,
    int? totalFloors,
    int? basementFloors,
    double? gfa,
    double? nla,
    String? address,
    bool addressSet = false,
    int? builtYear,
  }) async {
    if (propertyType != null) _validatePropertyType(propertyType);
    if (totalFloors != null && totalFloors <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '地上层数必须大于 0');
    }
    if (totalFloors != null && totalFloors > 200) {
      throw const ValidationException('VALIDATION_ERROR', '地上层数不得超过 200');
    }
    if (basementFloors != null && basementFloors < 0) {
      throw const ValidationException('VALIDATION_ERROR', '地下层数不能为负');
    }
    if (basementFloors != null && basementFloors > 20) {
      throw const ValidationException('VALIDATION_ERROR', '地下层数不得超过 20');
    }

    return await _db.runTx<Building>((tx) async {
      final floorRepo = FloorRepository(tx);

      // 1. 计算当前地上 / 地下层数
      final existing = await floorRepo.findAll(buildingId: id);
      final currentAbove = existing.where((f) => f.floorNumber > 0).length;
      final currentBelow = existing.where((f) => f.floorNumber < 0).length;

      // 2. 校验非递减
      if (totalFloors != null && totalFloors < currentAbove) {
        throw ValidationException(
          'BUILDING_FLOOR_DECREASE_NOT_ALLOWED',
          '当前地上层数为 $currentAbove，禁止降低到 $totalFloors；如需减层请先删除对应楼层及单元',
        );
      }
      if (basementFloors != null && basementFloors < currentBelow) {
        throw ValidationException(
          'BUILDING_FLOOR_DECREASE_NOT_ALLOWED',
          '当前地下层数为 $currentBelow，禁止降低到 $basementFloors',
        );
      }

      // 3. 更新 buildings 表
      final updated = await BuildingRepository(tx).update(
        id,
        name: name,
        propertyType: propertyType,
        totalFloors: totalFloors,
        basementFloors: basementFloors,
        gfa: gfa,
        nla: nla,
        address: address,
        addressSet: addressSet,
        builtYear: builtYear,
      );
      if (updated == null) {
        throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
      }

      // 4. 补齐缺失的地上层（仅创建当前没有的 floor_number）
      if (totalFloors != null && totalFloors > currentAbove) {
        final existingNumbers = existing.map((f) => f.floorNumber).toSet();
        for (var n = 1; n <= totalFloors; n++) {
          if (!existingNumbers.contains(n)) {
            await floorRepo.create(
              buildingId: id,
              floorNumber: n,
              floorName: '${n}F',
            );
          }
        }
      }

      // 5. 补齐缺失的地下层（floor_number 为负数）
      if (basementFloors != null && basementFloors > currentBelow) {
        final existingNumbers = existing.map((f) => f.floorNumber).toSet();
        for (var n = 1; n <= basementFloors; n++) {
          if (!existingNumbers.contains(-n)) {
            await floorRepo.create(
              buildingId: id,
              floorNumber: -n,
              floorName: 'B$n',
            );
          }
        }
      }

      return updated;
    });
  }

  /// 删除楼栋。
  ///
  /// 安全策略：仅允许删除「未关联业务数据」的楼栋。
  /// 关联数据指：units（任何单元）/ workorders / invoices。
  /// floors / floor_plans 在事务中自动级联删除（楼栋建立时由系统自动生成）。
  Future<void> deleteBuilding(String id) async {
    await _db.runTx<void>((tx) async {
      // 1. 存在性校验
      final building = await BuildingRepository(tx).findById(id);
      if (building == null) {
        throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
      }

      // 2. 业务关联校验：不允许删除已有单元/工单/账单的楼栋
      // 注意：此处使用独立命名查询，避免字符串拼接 SQL

      final unitRows = await tx.execute(
        Sql.named('SELECT COUNT(*)::INT AS c FROM units WHERE building_id = @id'),
        parameters: {'id': id},
      );
      final unitCount = unitRows.first.toColumnMap()['c'] as int;
      if (unitCount > 0) {
        throw ValidationException(
            'BUILDING_HAS_UNITS', '楼栋下仍有 $unitCount 个单元，请先删除单元再删除楼栋');
      }

      final workorderRows = await tx.execute(
        Sql.named('SELECT COUNT(*)::INT AS c FROM workorders WHERE building_id = @id'),
        parameters: {'id': id},
      );
      final workOrderCount = workorderRows.first.toColumnMap()['c'] as int;
      if (workOrderCount > 0) {
        throw ValidationException(
            'BUILDING_HAS_WORKORDERS', '楼栋下仍有 $workOrderCount 个工单，无法删除');
      }

      final invoiceRows = await tx.execute(
        Sql.named('SELECT COUNT(*)::INT AS c FROM invoices WHERE building_id = @id'),
        parameters: {'id': id},
      );
      final invoiceCount = invoiceRows.first.toColumnMap()['c'] as int;
      if (invoiceCount > 0) {
        throw ValidationException(
            'BUILDING_HAS_INVOICES', '楼栋下仍有 $invoiceCount 张账单,无法删除');
      }

      // 3. 级联删除楼栋自动生成的图纸/楼层（可能尚未上传图纸，floor_plans 可空）
      await FloorRepository(tx).deleteByBuildingId(id);

      // 4. 删除楼栋
      final affected = await BuildingRepository(tx).delete(id);
      if (affected == 0) {
        throw const NotFoundException('BUILDING_NOT_FOUND', '楼栋不存在');
      }
    });
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
    int basementFloors = 0,
  }) async {
    _validatePropertyType(propertyType);
    if (totalFloors <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数必须大于 0');
    }
    if (totalFloors > 200) {
      throw const ValidationException('VALIDATION_ERROR', '总楼层数不得超过 200');
    }
    if (basementFloors < 0) {
      throw const ValidationException('VALIDATION_ERROR', '地下层数不能为负');
    }
    if (basementFloors > 20) {
      throw const ValidationException('VALIDATION_ERROR', '地下层数不得超过 20');
    }
    if (gfa <= 0 || nla <= 0) {
      throw const ValidationException('VALIDATION_ERROR', '建筑面积/净可租面积必须大于 0');
    }

    return await _db.runTx<({Building building, List<Floor> floors})>((tx) async {
      final building = await BuildingRepository(tx).create(
        name: name,
        propertyType: propertyType,
        totalFloors: totalFloors,
        basementFloors: basementFloors,
        gfa: gfa,
        nla: nla,
        address: address,
        builtYear: builtYear,
      );

      final floors = <Floor>[];
      final floorRepo = FloorRepository(tx);
      // 地下层：B{N} ~ B1 对应 floor_number = -N ~ -1（按楼号升序入库便于排序）
      for (var n = basementFloors; n >= 1; n--) {
        final floor = await floorRepo.create(
          buildingId: building.id,
          floorNumber: -n,
          floorName: 'B$n',
        );
        floors.add(floor);
      }
      // 地上层：1F ~ NF
      for (var n = 1; n <= totalFloors; n++) {
        final floor = await floorRepo.create(
          buildingId: building.id,
          floorNumber: n,
          floorName: '${n}F',
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
