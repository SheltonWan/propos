/// 账单 MockData — 覆盖 pending/paid/overdue/waived 状态
class MockInvoiceData {
  static const List<Map<String, dynamic>> invoices = [
    {'id': 'inv-001', 'contractId': 'c-001', 'amount': 15600.0, 'dueDate': '2026-04-01', 'status': 'paid', 'paidAt': '2026-03-28'},
    {'id': 'inv-002', 'contractId': 'c-001', 'amount': 15600.0, 'dueDate': '2026-05-01', 'status': 'pending', 'paidAt': null},
    {'id': 'inv-003', 'contractId': 'c-002', 'amount': 26000.0, 'dueDate': '2026-04-01', 'status': 'overdue', 'paidAt': null},
    {'id': 'inv-004', 'contractId': 'c-003', 'amount': 8500.0, 'dueDate': '2026-03-01', 'status': 'waived', 'paidAt': null},
    {'id': 'inv-005', 'contractId': 'c-004', 'amount': 2800.0, 'dueDate': '2026-04-01', 'status': 'paid', 'paidAt': '2026-04-01'},
    {'id': 'inv-006', 'contractId': 'c-007', 'amount': 9200.0, 'dueDate': '2026-04-01', 'status': 'paid', 'paidAt': '2026-03-30'},
    {'id': 'inv-007', 'contractId': 'c-008', 'amount': 2600.0, 'dueDate': '2026-04-01', 'status': 'overdue', 'paidAt': null},
    {'id': 'inv-008', 'contractId': 'c-010', 'amount': 2750.0, 'dueDate': '2026-04-01', 'status': 'paid', 'paidAt': '2026-04-02'},
    {'id': 'inv-009', 'contractId': 'c-001', 'amount': 15600.0, 'dueDate': '2026-03-01', 'status': 'paid', 'paidAt': '2026-02-28'},
    {'id': 'inv-010', 'contractId': 'c-002', 'amount': 26000.0, 'dueDate': '2026-03-01', 'status': 'overdue', 'paidAt': null},
    {'id': 'inv-011', 'contractId': 'c-004', 'amount': 2800.0, 'dueDate': '2026-03-01', 'status': 'paid', 'paidAt': '2026-03-01'},
    {'id': 'inv-012', 'contractId': 'c-007', 'amount': 9200.0, 'dueDate': '2026-03-01', 'status': 'paid', 'paidAt': '2026-02-27'},
    {'id': 'inv-013', 'contractId': 'c-005', 'amount': 42000.0, 'dueDate': '2026-05-01', 'status': 'pending', 'paidAt': null},
    {'id': 'inv-014', 'contractId': 'c-003', 'amount': 8500.0, 'dueDate': '2026-02-01', 'status': 'waived', 'paidAt': null},
    {'id': 'inv-015', 'contractId': 'c-009', 'amount': 18000.0, 'dueDate': '2026-05-01', 'status': 'pending', 'paidAt': null},
    {'id': 'inv-016', 'contractId': 'c-001', 'amount': 15600.0, 'dueDate': '2026-02-01', 'status': 'paid', 'paidAt': '2026-01-30'},
    {'id': 'inv-017', 'contractId': 'c-008', 'amount': 2600.0, 'dueDate': '2026-03-01', 'status': 'paid', 'paidAt': '2026-03-05'},
    {'id': 'inv-018', 'contractId': 'c-004', 'amount': 2800.0, 'dueDate': '2026-02-01', 'status': 'paid', 'paidAt': '2026-01-31'},
    {'id': 'inv-019', 'contractId': 'c-002', 'amount': 26000.0, 'dueDate': '2026-02-01', 'status': 'paid', 'paidAt': '2026-02-03'},
    {'id': 'inv-020', 'contractId': 'c-010', 'amount': 2750.0, 'dueDate': '2026-03-01', 'status': 'paid', 'paidAt': '2026-02-28'},
  ];
}
