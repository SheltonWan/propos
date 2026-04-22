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
      grossArea: (map['gross_area'] as num?)?.toDouble(),
      netArea: (map['net_area'] as num?)?.toDouble(),
      orientation: map['orientation'] as String?,
      ceilingHeight: (map['ceiling_height'] as num?)?.toDouble(),
      decorationStatus: map['decoration_status'] as String,
      currentStatus: map['current_status'] as String,
      isLeasable: map['is_leasable'] as bool,
      extFields: (map['ext_fields'] as Map<String, dynamic>?) ?? {},
      currentContractId: map['current_contract_id'] as String?,
      qrCode: map['qr_code'] as String?,
      marketRentReference: (map['market_rent_reference'] as num?)?.toDouble(),
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
class AssetOverviewStats {
  final List<PropertyTypeStats> byPropertyType;
  final int totalUnits;
  final int totalLeased;
  final int totalVacant;
  final double occupancyRate;

  const AssetOverviewStats({
    required this.byPropertyType,
    required this.totalUnits,
    required this.totalLeased,
    required this.totalVacant,
    required this.occupancyRate,
  });

  Map<String, dynamic> toJson() => {
        'by_property_type': byPropertyType.map((s) => s.toJson()).toList(),
        'total_units': totalUnits,
        'total_leased': totalLeased,
        'total_vacant': totalVacant,
        'occupancy_rate': occupancyRate,
      };
}

/// PropertyTypeStats 单业态统计摘要
class PropertyTypeStats {
  final String propertyType;
  final int total;
  final int leased;
  final int vacant;
  final int expiringSoon;
  final double occupancyRate;

  const PropertyTypeStats({
    required this.propertyType,
    required this.total,
    required this.leased,
    required this.vacant,
    required this.expiringSoon,
    required this.occupancyRate,
  });

  factory PropertyTypeStats.fromColumnMap(Map<String, dynamic> map) {
    final total = map['total'] as int? ?? 0;
    final leased = map['leased'] as int? ?? 0;
    return PropertyTypeStats(
      propertyType: map['property_type'] as String,
      total: total,
      leased: leased,
      vacant: map['vacant'] as int? ?? 0,
      expiringSoon: map['expiring_soon'] as int? ?? 0,
      occupancyRate: total > 0 ? leased / total : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'property_type': propertyType,
        'total': total,
        'leased': leased,
        'vacant': vacant,
        'expiring_soon': expiringSoon,
        'occupancy_rate': occupancyRate,
      };
}
