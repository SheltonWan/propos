/// 工单 MockData — 覆盖全部 7 种工单状态
class MockWorkorderData {
  static const List<Map<String, dynamic>> workorders = [
    {
      'id': 'wo-001', 'orderNo': 'WO2026-001', 'title': '空调噪音维修',
      'unitId': 'u-001', 'status': 'submitted',
      'createdAt': '2026-04-08T10:00:00Z', 'priority': 'medium',
      'description': '租客反映空调运行声音过大',
    },
    {
      'id': 'wo-002', 'orderNo': 'WO2026-002', 'title': '水龙头漏水',
      'unitId': 'u-201', 'status': 'approved',
      'createdAt': '2026-04-07T09:00:00Z', 'priority': 'high',
      'description': '卫生间水龙头持续滴水',
    },
    {
      'id': 'wo-003', 'orderNo': 'WO2026-003', 'title': '门锁更换',
      'unitId': 'u-005', 'status': 'in_progress',
      'createdAt': '2026-04-06T14:00:00Z', 'priority': 'medium',
      'description': '前门锁损坏，需整体更换',
    },
    {
      'id': 'wo-004', 'orderNo': 'WO2026-004', 'title': '消防通道灯更换',
      'unitId': null, 'status': 'pending_acceptance',
      'createdAt': '2026-04-05T11:00:00Z', 'priority': 'low',
      'description': 'B1层消防通道应急灯损坏',
    },
    {
      'id': 'wo-005', 'orderNo': 'WO2026-005', 'title': '电梯轿厢异响',
      'unitId': null, 'status': 'completed',
      'createdAt': '2026-04-01T08:00:00Z', 'priority': 'high',
      'description': '2号电梯运行时有异响',
    },
    {
      'id': 'wo-006', 'orderNo': 'WO2026-006', 'title': '窗户玻璃裂缝',
      'unitId': 'u-101', 'status': 'rejected',
      'createdAt': '2026-04-03T15:00:00Z', 'priority': 'medium',
      'description': '商铺玻璃门出现裂缝',
    },
    {
      'id': 'wo-007', 'orderNo': 'WO2026-007', 'title': '网络线路整改',
      'unitId': 'u-006', 'status': 'on_hold',
      'createdAt': '2026-04-04T10:00:00Z', 'priority': 'low',
      'description': '待供应商确认材料后继续',
    },
    {
      'id': 'wo-008', 'orderNo': 'WO2026-008', 'title': '暖气管道维修',
      'unitId': 'u-202', 'status': 'completed',
      'createdAt': '2026-03-28T09:00:00Z', 'priority': 'high',
      'description': '暖气片不热，需检修管道',
    },
  ];
}
