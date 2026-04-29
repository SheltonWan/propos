/// 业态枚举，与 API 合约 property_type 字段对应（office/retail/apartment/mixed）。
enum PropertyType {
  office,
  retail,
  apartment,
  mixed;

  /// 从 API 字符串解析枚举值，未知值回退至 [PropertyType.mixed]。
  static PropertyType fromString(String value) => switch (value) {
        'office' => PropertyType.office,
        'retail' => PropertyType.retail,
        'apartment' => PropertyType.apartment,
        'mixed' => PropertyType.mixed,
        _ => PropertyType.mixed,
      };

  /// 中文显示名称
  String get label => switch (this) {
        PropertyType.office => '写字楼',
        PropertyType.retail => '商铺',
        PropertyType.apartment => '公寓',
        PropertyType.mixed => '综合',
      };
}
