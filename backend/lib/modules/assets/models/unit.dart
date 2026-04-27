/// PostgreSQL NUMERIC 列可能以 String 形式返回，统一兼容转换
double? _pd(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.parse(v.toString());
}

/// Unit 房源单元数据模型 — 对应 units 表（migration 004 + 021）
/// building_name / floor_name 为 JOIN 冗余字段
class Unit {
  final String id;
  final String buildingId;
  /// JOIN buildings.name
  final String? buildingName;
  final String floorId;
  /// JOIN floors.floor_name
  final String? floorName;
  final String unitNumber;
  /// 业态：'office' | 'retail' | 'apartment'
  final String propertyType;
  /// 建筑面积（m²）
  final double? grossArea;
  /// 套内面积（m²）
  final double? netArea;
  /// 朝向：'east' | 'south' | 'west' | 'north'
  final String? orientation;
  /// 层高（m）
  final double? ceilingHeight;
  /// 装修状态：'blank' | 'simple' | 'refined' | 'raw'
  final String decorationStatus;
  /// 出租状态：'leased' | 'vacant' | 'expiring_soon' | 'non_leasable' | 'renovating' | 'pre_lease'
  final String currentStatus;
  final bool isLeasable;
  /// 业态扩展字段（JSONB），含 svg 热区坐标 + 业态专属属性
  final Map<String, dynamic> extFields;
  final String? currentContractId;
  final String? qrCode;
  /// 参考市场租金（元/m²/月）
  final double? marketRentReference;
  /// 前序单元 ID 列表（拆分/合并历史追溯）
  final List<String> predecessorUnitIds;
  /// 归档时间，非空表示已归档（不参与出租率计算）
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Unit({
    required this.id,
    required this.buildingId,
    this.buildingName,
    required this.floorId,
    this.floorName,
    required this.unitNumber,
    required this.propertyType,
    this.grossArea,
    this.netArea,
    this.orientation,
    this.ceilingHeight,
    required this.decorationStatus,
    required this.currentStatus,
    required this.isLeasable,
    required this.extFields,
    this.currentContractId,
    this.qrCode,
    this.marketRentReference,
    required this.predecessorUnitIds,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromColumnMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as String,
      buildingId: map['building_id'] as String,
      buildingName: map['building_name'] as String?,
      floorId: map['floor_id'] as String,
      floorName: map['floor_name'] as String?,
      unitNumber: map['unit_number'] as String,
      propertyType: map['property_type'] as String,
      grossArea: _pd(map['gross_area']),
      netArea: _pd(map['net_area']),
      orientation: map['orientation'] as String?,
      ceilingHeight: _pd(map['ceiling_height']),
      decorationStatus: map['decoration_status'] as String,
      currentStatus: map['current_status'] as String,
      isLeasable: map['is_leasable'] as bool,
      extFields: (map['ext_fields'] as Map<String, dynamic>?) ?? {},
      currentContractId: map['current_contract_id'] as String?,
      qrCode: map['qr_code'] as String?,
      marketRentReference: _pd(map['market_rent_reference']),
      predecessorUnitIds: (map['predecessor_unit_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      archivedAt: map['archived_at'] as DateTime?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'building_id': buildingId,
        'building_name': buildingName,
        'floor_id': floorId,
        'floor_name': floorName,
        'unit_number': unitNumber,
        'property_type': propertyType,
        'gross_area': grossArea,
        'net_area': netArea,
        'orientation': orientation,
        'ceiling_height': ceilingHeight,
        'decoration_status': decorationStatus,
        'current_status': currentStatus,
        'is_leasable': isLeasable,
        'ext_fields': extFields,
        'current_contract_id': currentContractId,
        'qr_code': qrCode,
        'market_rent_reference': marketRentReference,
        'predecessor_unit_ids': predecessorUnitIds,
        'archived_at': archivedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// AssetOverviewStats 资产概览统计 — 用于 GET /api/assets/overview 响应
/// 字段定义严格遵循 docs/backend/API_CONTRACT_v1.7.md §2.23
class AssetOverviewStats {
  final int totalUnits;
  final int totalLeasableUnits;
  final double totalOccupancyRate;
  final double waleIncomeWeighted;
  final double waleAreaWeighted;
  final List<PropertyTypeStats> byPropertyType;

  const AssetOverviewStats({
    required this.totalUnits,
    required this.totalLeasableUnits,
    required this.totalOccupancyRate,
    required this.waleIncomeWeighted,
    required this.waleAreaWeighted,
    required this.byPropertyType,
  });

  Map<String, dynamic> toJson() => {
        'total_units': totalUnits,
        'total_leasable_units': totalLeasableUnits,
        'occupancy_rate':
            double.parse(totalOccupancyRate.toStringAsFixed(4)),
        'wale_income_weighted':
            double.parse(waleIncomeWeighted.toStringAsFixed(2)),
        'wale_area_weighted': double.parse(waleAreaWeighted.toStringAsFixed(2)),
        'by_property_type': byPropertyType.map((s) => s.toJson()).toList(),
      };
}

/// PropertyTypeStats 单业态统计摘要 — §2.23 PropertyTypeStats
class PropertyTypeStats {
  final String propertyType;
  final int totalUnits;
  final int leasedUnits;
  final int vacantUnits;
  final int expiringSoonUnits;
  final double occupancyRate;
  final double totalNla;
  final double leasedNla;

  const PropertyTypeStats({
    required this.propertyType,
    required this.totalUnits,
    required this.leasedUnits,
    required this.vacantUnits,
    required this.expiringSoonUnits,
    required this.occupancyRate,
    required this.totalNla,
    required this.leasedNla,
  });

  factory PropertyTypeStats.fromColumnMap(Map<String, dynamic> map) {
    final totalUnits = (map['total_units'] as num?)?.toInt() ?? 0;
    // 已租 + 即将到期 都视为已被占用，统一计入出租率分子
    final leasedUnits = (map['leased_units'] as num?)?.toInt() ?? 0;
    final expiringSoonUnits =
        (map['expiring_soon_units'] as num?)?.toInt() ?? 0;
    final occupied = leasedUnits + expiringSoonUnits;
    return PropertyTypeStats(
      propertyType: map['property_type'] as String,
      totalUnits: totalUnits,
      leasedUnits: leasedUnits,
      vacantUnits: (map['vacant_units'] as num?)?.toInt() ?? 0,
      expiringSoonUnits: expiringSoonUnits,
      occupancyRate: totalUnits > 0 ? occupied / totalUnits : 0.0,
      totalNla: (map['total_nla'] as num?)?.toDouble() ?? 0.0,
      leasedNla: (map['leased_nla'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'property_type': propertyType,
        'total_units': totalUnits,
        'leased_units': leasedUnits,
        'vacant_units': vacantUnits,
        'expiring_soon_units': expiringSoonUnits,
        'occupancy_rate': double.parse(occupancyRate.toStringAsFixed(4)),
        'total_nla': double.parse(totalNla.toStringAsFixed(2)),
        'leased_nla': double.parse(leasedNla.toStringAsFixed(2)),
      };
}

/// WALE 聚合结果（仅 Repository 内部使用）
class WaleStats {
  final double incomeWeighted;
  final double areaWeighted;
  const WaleStats({required this.incomeWeighted, required this.areaWeighted});

  static const empty = WaleStats(incomeWeighted: 0, areaWeighted: 0);
}
