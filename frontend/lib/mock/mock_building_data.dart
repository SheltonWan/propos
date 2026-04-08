/// 资产楼栋 MockData
/// 3 栋楼 × 多楼层 × 单元列表（含四种状态的单元）
class MockBuildingData {
  static const List<Map<String, dynamic>> buildings = [
    {
      'id': 'b-001',
      'name': 'A座写字楼',
      'address': '某路1号A座',
      'propertyType': 'office',
      'totalArea': 18000.0,
      'floors': [
        {
          'id': 'f-001-01', 'buildingId': 'b-001', 'floorNo': 1,
          'units': [
            {'id': 'u-001', 'unitNo': '101', 'area': 120.0, 'status': 'leased', 'propertyType': 'office'},
            {'id': 'u-002', 'unitNo': '102', 'area': 150.0, 'status': 'vacant', 'propertyType': 'office'},
            {'id': 'u-003', 'unitNo': '103', 'area': 200.0, 'status': 'expiring_soon', 'propertyType': 'office'},
            {'id': 'u-004', 'unitNo': '104', 'area': 80.0, 'status': 'non_leasable', 'propertyType': 'office'},
          ],
        },
        {
          'id': 'f-001-02', 'buildingId': 'b-001', 'floorNo': 2,
          'units': [
            {'id': 'u-005', 'unitNo': '201', 'area': 300.0, 'status': 'leased', 'propertyType': 'office'},
            {'id': 'u-006', 'unitNo': '202', 'area': 300.0, 'status': 'leased', 'propertyType': 'office'},
          ],
        },
      ],
    },
    {
      'id': 'b-002',
      'name': '商铺区',
      'address': '某路1号商铺区',
      'propertyType': 'retail',
      'totalArea': 8000.0,
      'floors': [
        {
          'id': 'f-002-01', 'buildingId': 'b-002', 'floorNo': 1,
          'units': [
            {'id': 'u-101', 'unitNo': 'S01', 'area': 50.0, 'status': 'leased', 'propertyType': 'retail'},
            {'id': 'u-102', 'unitNo': 'S02', 'area': 60.0, 'status': 'leased', 'propertyType': 'retail'},
            {'id': 'u-103', 'unitNo': 'S03', 'area': 45.0, 'status': 'vacant', 'propertyType': 'retail'},
          ],
        },
      ],
    },
    {
      'id': 'b-003',
      'name': '公寓楼',
      'address': '某路1号公寓楼',
      'propertyType': 'apartment',
      'totalArea': 14000.0,
      'floors': [
        {
          'id': 'f-003-01', 'buildingId': 'b-003', 'floorNo': 1,
          'units': [
            {'id': 'u-201', 'unitNo': 'A101', 'area': 38.0, 'status': 'leased', 'propertyType': 'apartment'},
            {'id': 'u-202', 'unitNo': 'A102', 'area': 42.0, 'status': 'expiring_soon', 'propertyType': 'apartment'},
            {'id': 'u-203', 'unitNo': 'A103', 'area': 38.0, 'status': 'leased', 'propertyType': 'apartment'},
          ],
        },
      ],
    },
  ];
}
