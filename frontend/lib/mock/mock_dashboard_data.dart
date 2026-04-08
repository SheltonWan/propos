/// Dashboard MockData
/// 字段命名与 data_model.md 数据库列名（转 camelCase）完全一致
class MockDashboardData {
  static const Map<String, dynamic> noiSummary = {
    'pgi': 2850000.0,        // 潜在毛收入
    'vacancyLoss': 142500.0, // 空置损失
    'otherIncome': 48000.0,
    'egi': 2755500.0,        // 有效毛收入
    'opex': 620000.0,        // 运营支出
    'noi': 2135500.0,        // 净营业收入
    'occupancyRate': 0.95,   // 出租率
    'byPropertyType': {
      'office': {'noi': 1200000.0, 'occupancyRate': 0.96},
      'retail': {'noi': 580000.0, 'occupancyRate': 0.93},
      'apartment': {'noi': 355500.0, 'occupancyRate': 0.98},
    },
  };

  static const Map<String, dynamic> wale = {
    'overall': 2.7,   // 加权平均租约到期年限
    'office': 3.1,
    'retail': 2.2,
    'apartment': 1.8,
  };

  static const List<Map<String, dynamic>> kpiCurrentValues = [
    {'code': 'K01', 'name': '出租率', 'actual': 0.95, 'pass': 0.85, 'perfect': 0.95, 'weight': 0.15},
    {'code': 'K02', 'name': 'NOI完成率', 'actual': 0.91, 'pass': 0.80, 'perfect': 0.95, 'weight': 0.20},
    {'code': 'K03', 'name': '租金到收率', 'actual': 0.97, 'pass': 0.90, 'perfect': 0.98, 'weight': 0.15},
    {'code': 'K04', 'name': '逾期清收率', 'actual': 0.88, 'pass': 0.80, 'perfect': 0.95, 'weight': 0.10},
    {'code': 'K05', 'name': '工单及时完工率', 'actual': 0.90, 'pass': 0.85, 'perfect': 0.95, 'weight': 0.10},
    {'code': 'K06', 'name': '合同续签率', 'actual': 0.75, 'pass': 0.70, 'perfect': 0.90, 'weight': 0.10},
    {'code': 'K07', 'name': '新租签约周期(天)', 'actual': 18.0, 'pass': 30.0, 'perfect': 15.0, 'weight': 0.05},
    {'code': 'K08', 'name': '费用控制率', 'actual': 0.92, 'pass': 0.85, 'perfect': 0.95, 'weight': 0.05},
    {'code': 'K09', 'name': '租客满意度', 'actual': 4.2, 'pass': 3.5, 'perfect': 4.5, 'weight': 0.05},
    {'code': 'K10', 'name': '二房东数据准确率', 'actual': 0.95, 'pass': 0.90, 'perfect': 0.98, 'weight': 0.05},
  ];
}
