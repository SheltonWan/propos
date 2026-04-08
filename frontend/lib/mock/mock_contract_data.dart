/// 合同 MockData — 覆盖全部 7 种状态机状态
class MockContractData {
  static const List<Map<String, dynamic>> contracts = [
    {
      'id': 'c-001', 'contractNo': 'CT2026-001',
      'tenantName': '某科技有限公司', 'unitIds': ['u-001'],
      'startDate': '2024-01-01', 'endDate': '2026-12-31',
      'monthlyRent': 15600.0, 'status': 'active',
    },
    {
      'id': 'c-002', 'contractNo': 'CT2026-002',
      'tenantName': '某贸易有限公司', 'unitIds': ['u-003'],
      'startDate': '2023-06-01', 'endDate': '2026-05-31',
      'monthlyRent': 26000.0, 'status': 'expiring_soon',
    },
    {
      'id': 'c-003', 'contractNo': 'CT2025-003',
      'tenantName': '某餐饮有限公司', 'unitIds': ['u-101'],
      'startDate': '2022-01-01', 'endDate': '2025-12-31',
      'monthlyRent': 8500.0, 'status': 'expired',
    },
    {
      'id': 'c-004', 'contractNo': 'CT2026-004',
      'tenantName': '张某某', 'unitIds': ['u-201'],
      'startDate': '2025-09-01', 'endDate': '2026-08-31',
      'monthlyRent': 2800.0, 'status': 'active',
    },
    {
      'id': 'c-005', 'contractNo': 'CT2026-005',
      'tenantName': '某咨询有限公司', 'unitIds': ['u-005'],
      'startDate': '2026-04-01', 'endDate': '2028-03-31',
      'monthlyRent': 42000.0, 'status': 'pending_payment',
    },
    {
      'id': 'c-006', 'contractNo': 'CT2025-006',
      'tenantName': '某物流有限公司', 'unitIds': ['u-006'],
      'startDate': '2023-01-01', 'endDate': '2024-12-31',
      'monthlyRent': 38000.0, 'status': 'terminated',
    },
    {
      'id': 'c-007', 'contractNo': 'CT2026-007',
      'tenantName': '某零售有限公司', 'unitIds': ['u-102'],
      'startDate': '2026-03-01', 'endDate': '2029-02-28',
      'monthlyRent': 9200.0, 'status': 'active',
    },
    {
      'id': 'c-008', 'contractNo': 'CT2026-008',
      'tenantName': '李某某', 'unitIds': ['u-202'],
      'startDate': '2025-07-01', 'endDate': '2026-06-30',
      'monthlyRent': 2600.0, 'status': 'expiring_soon',
    },
    {
      'id': 'c-009', 'contractNo': 'CT2026-009',
      'tenantName': '某教育有限公司', 'unitIds': ['u-002'],
      'startDate': '2026-04-01', 'endDate': '2027-03-31',
      'monthlyRent': 18000.0, 'status': 'pending_deposit',
    },
    {
      'id': 'c-010', 'contractNo': 'CT2026-010',
      'tenantName': '王某某', 'unitIds': ['u-203'],
      'startDate': '2025-12-01', 'endDate': '2026-11-30',
      'monthlyRent': 2750.0, 'status': 'active',
    },
  ];
}
