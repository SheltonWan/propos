/// 房源出租状态，与 API 合约 current_status 字段对应。
enum UnitStatus {
  leased,
  vacant,
  expiringSoon,
  nonLeasable;

  static UnitStatus fromString(String value) => switch (value) {
        'leased' => UnitStatus.leased,
        'vacant' => UnitStatus.vacant,
        'expiring_soon' => UnitStatus.expiringSoon,
        'non_leasable' => UnitStatus.nonLeasable,
        _ => UnitStatus.vacant,
      };

  String get label => switch (this) {
        UnitStatus.leased => '已租',
        UnitStatus.vacant => '空置',
        UnitStatus.expiringSoon => '即将到期',
        UnitStatus.nonLeasable => '非可租',
      };
}

/// 装修状态，与 API 合约 decoration_status 字段对应。
enum DecorationStatus {
  blank,
  simple,
  refined,
  raw;

  static DecorationStatus fromString(String value) => switch (value) {
        'blank' => DecorationStatus.blank,
        'simple' => DecorationStatus.simple,
        'refined' => DecorationStatus.refined,
        'raw' => DecorationStatus.raw,
        _ => DecorationStatus.blank,
      };

  String get label => switch (this) {
        DecorationStatus.blank => '清水',
        DecorationStatus.simple => '简装',
        DecorationStatus.refined => '精装',
        DecorationStatus.raw => '毛坯',
      };
}
