/// 二房东 MockData — 主合同 + 子租赁列表（含空置单元）
class MockSubleaseData {
  /// 主合同（从二房东视角）
  static const Map<String, dynamic> masterContract = {
    'id': 'c-001',
    'contractNo': 'CT2026-001',
    'tenantName': '某科技有限公司（二房东）',
    'unitIds': ['u-005', 'u-006'],
    'startDate': '2024-01-01',
    'endDate': '2026-12-31',
    'monthlyRent': 80000.0,
    'status': 'active',
  };

  /// 子租赁列表
  static const List<Map<String, dynamic>> subleases = [
    {
      'id': 'sl-001',
      'masterContractId': 'c-001',
      'subTenantName': '甲公司',
      'unitId': 'u-005',
      'unitNo': '201',
      'startDate': '2024-02-01',
      'endDate': '2025-01-31',
      'monthlyRent': 38000.0,
      'reviewStatus': 'approved',
    },
    {
      'id': 'sl-002',
      'masterContractId': 'c-001',
      'subTenantName': '乙公司',
      'unitId': 'u-006',
      'unitNo': '202',
      'startDate': '2024-03-01',
      'endDate': '2025-02-28',
      'monthlyRent': 35000.0,
      'reviewStatus': 'approved',
    },
    {
      'id': 'sl-003',
      'masterContractId': 'c-001',
      'subTenantName': null,
      'unitId': null,
      'unitNo': '203',          // 空置单元
      'startDate': null,
      'endDate': null,
      'monthlyRent': null,
      'reviewStatus': null,     // 未填报
    },
    {
      'id': 'sl-004',
      'masterContractId': 'c-001',
      'subTenantName': '丙公司',
      'unitId': 'u-007',
      'unitNo': '204',
      'startDate': '2024-04-01',
      'endDate': '2025-03-31',
      'monthlyRent': 22000.0,
      'reviewStatus': 'pending_review',
    },
  ];
}
