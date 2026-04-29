import 'package:dio/dio.dart';

import '../api_paths.dart';

/// Mock interceptor for development.
///
/// Enabled when `FLUTTER_USE_MOCK=true` in `.env`.
/// Intercepts matching requests and returns mock data in the standard envelope.
/// Unmatched URLs fall through to real network requests.
class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final mockResponse = _matchMock(options);
    if (mockResponse != null) {
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: mockResponse,
        ),
      );
      return;
    }
    handler.next(options);
  }

  Map<String, dynamic>? _matchMock(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // ── Auth: POST /api/auth/login ──
    if (method == 'POST' && path == ApiPaths.authLogin) {
      return _mockLoginResponse();
    }

    // ── Auth: GET /api/auth/me ──
    if (method == 'GET' && path == ApiPaths.authMe) {
      return _mockCurrentUser();
    }

    // ── Auth: POST /api/auth/refresh ──
    if (method == 'POST' && path == ApiPaths.authRefresh) {
      return _mockRefreshResponse();
    }

    // ── Auth: POST /api/auth/logout ──
    if (method == 'POST' && path == ApiPaths.authLogout) {
      return {
        'data': {'message': '已注销'},
      };
    }

    // ── Assets: GET /api/assets/overview ──
    if (method == 'GET' && path == ApiPaths.assetsOverview) {
      return _mockAssetOverview();
    }

    // ── Assets: GET /api/buildings ──
    if (method == 'GET' && path == ApiPaths.buildings) {
      return _mockBuildingList();
    }

    // ── Assets: GET /api/buildings/:id ──
    if (method == 'GET' && path.startsWith('${ApiPaths.buildings}/')) {
      final id = path.substring('${ApiPaths.buildings}/'.length);
      if (!id.contains('/')) {
        return _mockBuildingDetail(id);
      }
    }

    // ── Assets: GET /api/floors ──
    if (method == 'GET' && path == ApiPaths.floors) {
      final buildingId = options.queryParameters['building_id'] as String?;
      return _mockFloorList(buildingId);
    }

    // ── Assets: GET /api/floors/:id/heatmap ──
    if (method == 'GET' &&
        path.startsWith('${ApiPaths.floors}/') &&
        path.endsWith('/heatmap')) {
      final floorId = path
          .substring('${ApiPaths.floors}/'.length)
          .replaceAll('/heatmap', '');
      return _mockFloorHeatmap(floorId);
    }

    // ── Assets: GET /api/floors/:id ──
    if (method == 'GET' && path.startsWith('${ApiPaths.floors}/')) {
      final id = path.substring('${ApiPaths.floors}/'.length);
      if (!id.contains('/')) {
        return _mockFloorDetail(id);
      }
    }

    // ── Assets: GET /api/units（分页列表）──
    if (method == 'GET' && path == ApiPaths.units) {
      final page = int.tryParse(
              options.queryParameters['page']?.toString() ?? '1') ??
          1;
      final pageSize = int.tryParse(
              options.queryParameters['pageSize']?.toString() ?? '20') ??
          20;
      return _mockUnitList(page: page, pageSize: pageSize);
    }

    // ── Assets: POST /api/units/import ──
    if (method == 'POST' && path == ApiPaths.unitsImport) {
      return {
        'data': {
          'success_count': 18,
          'failed_rows': [
            {
              'row': 5,
              'field': 'gross_area',
              'error': '面积必须大于 0',
            },
            {
              'row': 12,
              'field': 'unit_number',
              'error': '房源编号重复',
            },
          ],
        },
      };
    }

    // ── Assets: GET /api/units/:id ──
    if (method == 'GET' && path.startsWith('${ApiPaths.units}/')) {
      final id = path.substring('${ApiPaths.units}/'.length);
      if (!id.contains('/')) {
        return _mockUnitDetail(id);
      }
    }

    // ── Assets: GET /api/renovations ──
    if (method == 'GET' && path == ApiPaths.renovations) {
      return _mockRenovationList();
    }

    return null; // Unmatched — fall through to real request
  }

  // ── Mock data generators ──

  Map<String, dynamic> _mockLoginResponse() => {
        'data': {
          'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'expires_in': 86400,
          'user': _mockUserBrief(),
        },
      };

  Map<String, dynamic> _mockRefreshResponse() => {
        'data': {
          'access_token': 'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token': 'mock_new_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'expires_in': 86400,
        },
      };

  Map<String, dynamic> _mockCurrentUser() => {
        'data': {
          'id': '00000000-0000-0000-0000-000000000001',
          'name': '测试管理员',
          'email': 'admin@propos.dev',
          'role': 'super_admin',
          'department_id': null,
          'department_name': null,
          'permissions': [
            'assets.read',
            'assets.write',
            'contracts.read',
            'contracts.write',
            'finance.read',
            'finance.write',
            'workorders.read',
            'workorders.write',
            'sublease.read',
            'sublease.write',
            'kpi.view',
            'kpi.manage',
            'kpi.appeal',
            'alerts.read',
            'alerts.write',
            'org.read',
            'org.manage',
            'ops.read',
            'ops.write',
            'import.execute',
            'notifications.read',
            'approvals.manage',
            'dashboard.read',
            'deposit.read',
            'deposit.write',
            'meterReading.write',
            'turnoverReview.approve',
          ],
          'bound_contract_id': null,
          'is_active': true,
          'last_login_at': '2026-04-20T08:00:00Z',
        },
      };

  Map<String, dynamic> _mockUserBrief() => {
        'id': '00000000-0000-0000-0000-000000000001',
        'name': '测试管理员',
        'email': 'admin@propos.dev',
        'role': 'super_admin',
        'department_id': null,
        'must_change_password': false,
      };

  // ── Assets mock data ──

  Map<String, dynamic> _mockAssetOverview() => {
        'data': {
          'total_units': 639,
          'total_leasable_units': 590,
          'total_occupancy_rate': 0.877,
          'wale_income_weighted': 2.4,
          'wale_area_weighted': 2.1,
          'by_property_type': [
            {
              'property_type': 'office',
              'total_units': 441,
              'leased_units': 390,
              'vacant_units': 41,
              'expiring_soon_units': 10,
              'occupancy_rate': 0.884,
              'total_nla': 22000.0,
              'leased_nla': 19448.0,
            },
            {
              'property_type': 'retail',
              'total_units': 25,
              'leased_units': 22,
              'vacant_units': 2,
              'expiring_soon_units': 1,
              'occupancy_rate': 0.88,
              'total_nla': 3200.0,
              'leased_nla': 2816.0,
            },
            {
              'property_type': 'apartment',
              'total_units': 173,
              'leased_units': 148,
              'vacant_units': 20,
              'expiring_soon_units': 5,
              'occupancy_rate': 0.855,
              'total_nla': 14800.0,
              'leased_nla': 12654.0,
            },
          ],
        },
      };

  Map<String, dynamic> _mockBuildingList() => {
        'data': [
          _buildingData('bld-001', 'A座写字楼', 'office', 25, 22000.0, 19800.0),
          _buildingData('bld-002', '商铺区', 'retail', 3, 5000.0, 3200.0),
          _buildingData('bld-003', '公寓楼', 'apartment', 18, 16000.0, 14800.0),
        ],
        'meta': {'page': 1, 'page_size': 20, 'total': 3},
      };

  Map<String, dynamic> _mockBuildingDetail(String id) => {
        'data': switch (id) {
          'bld-001' =>
            _buildingData('bld-001', 'A座写字楼', 'office', 25, 22000.0, 19800.0),
          'bld-002' =>
            _buildingData('bld-002', '商铺区', 'retail', 3, 5000.0, 3200.0),
          'bld-003' =>
            _buildingData('bld-003', '公寓楼', 'apartment', 18, 16000.0, 14800.0),
          _ =>
            _buildingData('bld-001', 'A座写字楼', 'office', 25, 22000.0, 19800.0),
        },
      };

  Map<String, dynamic> _buildingData(
    String id,
    String name,
    String propertyType,
    int totalFloors,
    double gfa,
    double nla,
  ) =>
      {
        'id': id,
        'name': name,
        'property_type': propertyType,
        'total_floors': totalFloors,
        'basement_floors': 2,
        'gfa': gfa,
        'nla': nla,
        'address': '深圳市南山区科技园南区',
        'built_year': 2008,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2026-04-01T00:00:00Z',
      };

  Map<String, dynamic> _mockFloorList(String? buildingId) {
    final floors = <Map<String, dynamic>>[];
    final bldId = buildingId ?? 'bld-001';
    final total = bldId == 'bld-001' ? 25 : (bldId == 'bld-002' ? 3 : 18);
    for (var i = 1; i <= total; i++) {
      floors.add({
        'id': 'floor-$bldId-$i',
        'building_id': bldId,
        'building_name': bldId == 'bld-001'
            ? 'A座写字楼'
            : (bldId == 'bld-002' ? '商铺区' : '公寓楼'),
        'floor_number': i,
        'floor_name': null,
        'svg_path': null,
        'png_path': null,
        'nla': 880.0,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2026-04-01T00:00:00Z',
      });
    }
    return {
      'data': floors,
      'meta': {'page': 1, 'page_size': 100, 'total': total},
    };
  }

  Map<String, dynamic> _mockFloorDetail(String id) => {
        'data': {
          'id': id,
          'building_id': 'bld-001',
          'building_name': 'A座写字楼',
          'floor_number': 12,
          'floor_name': null,
          'svg_path': null,
          'png_path': null,
          'nla': 880.0,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2026-04-01T00:00:00Z',
        },
      };

  Map<String, dynamic> _mockFloorHeatmap(String floorId) => {
        'data': {
          'floor_id': floorId,
          'svg_path': null,
          'units': [
            _heatmapUnit('unit-001', 'A-12-01', 'leased', 'office', '腾讯科技', '2026-12-31T00:00:00Z'),
            _heatmapUnit('unit-002', 'A-12-02', 'leased', 'office', '字节跳动', '2025-06-30T00:00:00Z'),
            _heatmapUnit('unit-003', 'A-12-03', 'expiring_soon', 'office', '华为技术', '2025-05-15T00:00:00Z'),
            _heatmapUnit('unit-004', 'A-12-04', 'vacant', 'office', null, null),
            _heatmapUnit('unit-005', 'A-12-05', 'leased', 'office', '小米科技', '2027-03-31T00:00:00Z'),
            _heatmapUnit('unit-006', 'A-12-06', 'non_leasable', 'office', null, null),
          ],
        },
      };

  Map<String, dynamic> _heatmapUnit(
    String unitId,
    String unitNumber,
    String status,
    String propertyType,
    String? tenantName,
    String? contractEndDate,
  ) =>
      {
        'unit_id': unitId,
        'unit_number': unitNumber,
        'current_status': status,
        'property_type': propertyType,
        'tenant_name': tenantName,
        'contract_end_date': contractEndDate,
      };

  Map<String, dynamic> _mockUnitDetail(String id) => {
        'data': {
          'id': id,
          'building_id': 'bld-001',
          'building_name': 'A座写字楼',
          'floor_id': 'floor-bld-001-12',
          'floor_name': null,
          'unit_number': 'A-12-01',
          'property_type': 'office',
          'gross_area': 135.0,
          'net_area': 120.5,
          'orientation': '南',
          'ceiling_height': 2.8,
          'decoration_status': 'refined',
          'current_status': 'leased',
          'is_leasable': true,
          'ext_fields': null,
          'current_contract_id': 'contract-001',
          'qr_code': null,
          'market_rent_reference': 280.0,
          'predecessor_unit_ids': <String>[],
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2026-04-01T00:00:00Z',
        },
      };

  Map<String, dynamic> _mockRenovationList() => {
        'data': [
          {
            'id': 'reno-001',
            'unit_id': 'unit-001',
            'unit_number': 'A-12-01',
            'renovation_type': '精装修',
            'started_at': '2023-06-01T00:00:00Z',
            'completed_at': '2023-08-15T00:00:00Z',
            'cost': 85000.0,
            'contractor': '深圳市优质装饰有限公司',
            'created_at': '2023-06-01T00:00:00Z',
          },
          {
            'id': 'reno-002',
            'unit_id': 'unit-001',
            'unit_number': 'A-12-01',
            'renovation_type': '水电改造',
            'started_at': '2021-03-10T00:00:00Z',
            'completed_at': '2021-03-25T00:00:00Z',
            'cost': 12000.0,
            'contractor': '深圳市水电工程队',
            'created_at': '2021-03-10T00:00:00Z',
          },
        ],
        'meta': {'page': 1, 'page_size': 20, 'total': 2},
      };

  /// Mock 房源列表（支持简单分页，固定返回12条数据）。
  Map<String, dynamic> _mockUnitList({int page = 1, int pageSize = 20}) {
    const totalUnits = 12;
    final allUnits = <Map<String, dynamic>>[
      _unitItem('unit-001', 'A-12-01', 'bld-001', 'A座写字楼', 'flr-001', '12F', 'office', 135.0, 'leased', 120.0),
      _unitItem('unit-002', 'A-12-02', 'bld-001', 'A座写字楼', 'flr-001', '12F', 'office', 98.0, 'vacant', 115.0),
      _unitItem('unit-003', 'A-12-03', 'bld-001', 'A座写字楼', 'flr-001', '12F', 'office', 112.5, 'expiring_soon', 118.0),
      _unitItem('unit-004', 'A-11-01', 'bld-001', 'A座写字楼', 'flr-002', '11F', 'office', 145.0, 'leased', 125.0),
      _unitItem('unit-005', 'A-11-02', 'bld-001', 'A座写字楼', 'flr-002', '11F', 'office', 200.0, 'non_leasable', null),
      _unitItem('unit-006', 'B-01-01', 'bld-002', '商铺区', 'flr-010', '1F', 'retail', 80.0, 'leased', 280.0),
      _unitItem('unit-007', 'B-01-02', 'bld-002', '商铺区', 'flr-010', '1F', 'retail', 65.0, 'vacant', 260.0),
      _unitItem('unit-008', 'B-02-01', 'bld-002', '商铺区', 'flr-011', '2F', 'retail', 90.0, 'leased', 200.0),
      _unitItem('unit-009', 'C-05-01', 'bld-003', '公寓楼', 'flr-020', '5F', 'apartment', 56.0, 'leased', 85.0),
      _unitItem('unit-010', 'C-05-02', 'bld-003', '公寓楼', 'flr-020', '5F', 'apartment', 72.0, 'vacant', 88.0),
      _unitItem('unit-011', 'C-06-01', 'bld-003', '公寓楼', 'flr-021', '6F', 'apartment', 56.0, 'leased', 86.0),
      _unitItem('unit-012', 'C-06-02', 'bld-003', '公寓楼', 'flr-021', '6F', 'apartment', 68.0, 'expiring_soon', 87.0),
    ];
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, totalUnits);
    final pageItems = start < totalUnits ? allUnits.sublist(start, end) : <Map<String, dynamic>>[];
    return {
      'data': pageItems,
      'meta': {'page': page, 'pageSize': pageSize, 'total': totalUnits},
    };
  }

  Map<String, dynamic> _unitItem(
    String id,
    String unitNumber,
    String buildingId,
    String buildingName,
    String floorId,
    String floorName,
    String propertyType,
    double grossArea,
    String status,
    double? rentRef,
  ) => {
    'id': id,
    'building_id': buildingId,
    'building_name': buildingName,
    'floor_id': floorId,
    'floor_name': floorName,
    'unit_number': unitNumber,
    'property_type': propertyType,
    'gross_area': grossArea,
    'net_area': grossArea * 0.9,
    'current_status': status,
    'is_leasable': status != 'non_leasable',
    'decoration_status': 'refined',
    'market_rent_reference': rentRef,
    'created_at': '2024-01-01T00:00:00Z',
  };
}
