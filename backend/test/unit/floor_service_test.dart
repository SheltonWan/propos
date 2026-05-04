/// FloorService 单元测试
///
/// 覆盖场景：
///   listFloors()     — 空列表 / 非空列表 / 按 buildingId 过滤
///   getFloor()       — 不存在 → FLOOR_NOT_FOUND
///   createFloor()    — 楼栋不存在 / 楼层号重复 → FLOOR_ALREADY_EXISTS / 成功
///   getHeatmap()     — 不存在 → FLOOR_NOT_FOUND / 返回热区数据
///   listPlans()      — 楼层不存在 → FLOOR_NOT_FOUND / 返回列表
///   uploadCad()      — 楼层不存在 / 非 .dwg 扩展名 → INVALID_CAD_FILE
///   setCurrentPlan() — 不存在 → FLOOR_NOT_FOUND
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/floor_service.dart';

import 'helpers/asset_fakes.dart';
import 'helpers/fakes.dart';

void main() {
  late FakePool pool;
  late Directory tmpDir;
  late FloorService svc;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('floor_svc_test_');
  });

  setUp(() {
    pool = FakePool();
    svc = FloorService(pool, tmpDir.path);
  });

  tearDownAll(() async {
    await tmpDir.delete(recursive: true);
  });

  // ─── getFloor ─────────────────────────────────────────────────────────────

  group('getFloor()', () {
    test('DB 返回空 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getFloor('f-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('DB 返回 1 行 → 返回 Floor', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kFloorCols, [floorRow(id: 'f-1', floorNumber: 2)]);
      final f = await svc.getFloor('f-1');
      expect(f.id, 'f-1');
      expect(f.floorNumber, 2);
    });
  });

  // ─── createFloor ─────────────────────────────────────────────────────────

  group('createFloor()', () {
    test('楼栋不存在 → NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []); // building not found
      await expectLater(
        svc.createFloor(buildingId: 'b-x', floorNumber: 1),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')),
      );
    });

    test('楼层号在同楼栋已存在 → ConflictException(FLOOR_ALREADY_EXISTS)', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) {
          // BuildingRepository.findById → 找到楼栋
          return makeResult(kBuildingCols, [buildingRow()]);
        }
        // FloorRepository.existsByBuildingAndNumber → 非空 = 已存在
        return makeResult(['col'], [[1]]);
      };
      await expectLater(
        svc.createFloor(buildingId: 'b-1', floorNumber: 1),
        throwsA(isA<ConflictException>()
            .having((e) => e.code, 'code', 'FLOOR_ALREADY_EXISTS')),
      );
    });

    test('合法参数 → 返回 Floor', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        if (callIdx == 2) return makeResult([], []); // not exists
        return makeResult(kFloorCols, [floorRow(floorNumber: 3)]);
      };
      final f = await svc.createFloor(
        buildingId: 'b-1',
        floorNumber: 3,
        floorName: '3F',
        nla: 800,
      );
      expect(f.floorNumber, 3);
    });
  });

  // ─── getHeatmap ──────────────────────────────────────────────────────────

  group('getHeatmap()', () {
    test('楼层不存在 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getHeatmap('f-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('楼层存在但无房源 → 返回空 units 列表', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        // 第1次: FloorRepository.getHeatmap 内部 SELECT id::TEXT AS floor_id, svg_path
        if (callIdx == 1) return makeResult(['floor_id', 'svg_path'], [['f-1', null]]);
        // 第2次: heatmap 单元查询 → 无房源
        return makeResult([], []);
      };
      final heatmap = await svc.getHeatmap('f-1');
      expect(heatmap.floorId, 'f-1');
      expect(heatmap.units, isEmpty);
    });

    test('有房源时 → areaSqm 和 contractId 被正确解析', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) {
          return makeResult([
            'floor_id',
            'svg_path'
          ], [
            ['f-1', 'floors/b-1/f-1.svg']
          ]);
        }
        // 第2次: 返回一个已租单元（含 area_sqm 和 contract_id）
        return makeResult(
          kHeatmapUnitCols,
          [
            heatmapUnitRow(
              unitId: 'u-1',
              currentStatus: 'leased',
              tenantName: '字节跳动',
              contractEndDate: '2027-12-31',
              areaSqm: 88.5,
              contractId: 'c-1',
            ),
          ],
        );
      };
      final heatmap = await svc.getHeatmap('f-1');
      expect(heatmap.svgPath, 'floors/b-1/f-1.svg');
      expect(heatmap.units, hasLength(1));
      final unit = heatmap.units.first;
      expect(unit.currentStatus, 'leased');
      expect(unit.tenantName, '字节跳动');
      expect(unit.areaSqm, 88.5);
      expect(unit.contractId, 'c-1');
    });
  });

  // ─── listPlans ───────────────────────────────────────────────────────────

  group('listPlans()', () {
    test('楼层不存在 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []); // floor not found
      await expectLater(
        svc.listPlans('f-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('楼层存在 → 返回图纸列表', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kFloorCols, [floorRow()]);
        return makeResult(kFloorPlanCols, [floorPlanRow(), floorPlanRow(id: 'fp-2')]);
      };
      final plans = await svc.listPlans('f-1');
      expect(plans, hasLength(2));
    });
  });

  // ─── uploadCad 验证 ───────────────────────────────────────────────────────

  group('uploadCad()', () {
    test('楼层不存在 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.uploadCad(
          floorId: 'f-x',
          versionLabel: 'v1',
          fileBytes: [1, 2, 3],
          originalFilename: 'plan.dwg',
          uploadedBy: 'user-1',
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('文件扩展名非 .dwg → ValidationException(INVALID_CAD_FILE)', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kFloorCols, [floorRow()]);
      await expectLater(
        svc.uploadCad(
          floorId: 'f-1',
          versionLabel: 'v1',
          fileBytes: [1, 2, 3],
          originalFilename: 'plan.pdf', // 非 .dwg
          uploadedBy: 'user-1',
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_CAD_FILE')),
      );
    });

    test('合法 .dwg 文件 → 返回 converting 状态', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kFloorCols, [floorRow()]);
        return makeResult(kFloorPlanCols, [floorPlanRow(isCurrent: false)]);
      };
      final result = await svc.uploadCad(
        floorId: 'f-1',
        versionLabel: 'v1',
        fileBytes: [0x41, 0x43, 0x31, 0x30], // AC10 DWG magic bytes
        originalFilename: 'floor_plan.dwg',
        uploadedBy: 'user-1',
      );
      expect(result['status'], 'converting');
      expect(result['floor_plan_id'], isA<String>());
    });
  });

  // ─── setCurrentPlan ──────────────────────────────────────────────────────

  group('setCurrentPlan()', () {
    test('图纸版本不存在 → NotFoundException', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.setCurrentPlan('fp-x'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  // ─── listFloors ───────────────────────────────────────────────────────────

  group('listFloors()', () {
    test('DB 返回空 → 空列表', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      expect(await svc.listFloors(), isEmpty);
    });

    test('DB 返回 2 行 → 列表长度 2', () async {
      pool.executeHandler = (q, p) => makeResult(
            kFloorCols,
            [
              floorRow(id: 'f-1', floorNumber: 1),
              floorRow(id: 'f-2', floorNumber: 2),
            ],
          );
      final result = await svc.listFloors();
      expect(result, hasLength(2));
      expect(result.first.id, 'f-1');
      expect(result.last.id, 'f-2');
    });

    test('传入 buildingId 过滤 → 返回该楼栋的楼层', () async {
      pool.executeHandler = (q, p) => makeResult(
            kFloorCols,
            [floorRow(id: 'f-3', buildingId: 'b-2', floorNumber: 3)],
          );
      final result = await svc.listFloors(buildingId: 'b-2');
      expect(result, hasLength(1));
      expect(result.first.buildingId, 'b-2');
    });
  });

  // ─── floor_map (M1 楼层结构标注 v2) ──────────────────────────────────────

  // 测试用合法 UUID（_ensureUuid 必须通过）
  const kFloorUuid = '00000000-0000-0000-0000-000000000001';
  final kVersionTime = DateTime.utc(2026, 4, 5, 10, 0, 0);

  // floors 表行（含 render_mode / floor_map_schema_version / floor_map_updated_at）
  const kFloorColsWithMap = [
    'id', 'building_id', 'building_name', 'floor_number',
    'floor_name', 'svg_path', 'png_path', 'nla',
    'render_mode', 'floor_map_schema_version', 'floor_map_updated_at',
    'created_at', 'updated_at',
  ];
  List<Object?> floorRowWithMap({
    String id = kFloorUuid,
    String renderMode = 'vector',
    String? schemaVersion,
    DateTime? floorMapUpdatedAt,
  }) {
    final t = DateTime.utc(2026, 1, 1);
    return [
      id, 'b-1', 'Test Tower', 1, '1F', null, null, null,
      renderMode, schemaVersion, floorMapUpdatedAt,
      t, t,
    ];
  }

  // floor_maps 表 SELECT/RETURNING 列
  const kFloorMapCols = [
    'floor_id', 'schema_version',
    'viewport', 'outline', 'structures', 'windows', 'north',
    'candidates', 'candidates_extracted_at',
    'updated_at', 'updated_by',
  ];
  List<Object?> floorMapRow({
    Map<String, dynamic>? viewport,
    Map<String, dynamic>? outline,
    List<Map<String, dynamic>> structures = const [],
    List<Map<String, dynamic>> windows = const [],
    Map<String, dynamic>? north,
  }) =>
      [
        kFloorUuid, '2.0',
        viewport, outline, structures, windows, north,
        null, null,
        kVersionTime, null,
      ];

  // 合法 saveStructures payload 工厂
  Map<String, dynamic> validPayload({
    int structuresCount = 1,
    List<Map<String, dynamic>>? overrideStructures,
    Map<String, dynamic>? overrideViewport,
  }) {
    final structures = overrideStructures ??
        List.generate(
          structuresCount,
          (i) => {
            'type': 'core',
            'source': 'manual',
            'rect': {'x': 10, 'y': 10, 'w': 50, 'h': 50},
          },
        );
    return {
      'schema_version': '2.0',
      'viewport': overrideViewport ?? {'width': 1000, 'height': 800},
      'outline': {
        'type': 'rect',
        'rect': {'x': 0, 'y': 0, 'w': 1000, 'h': 800},
      },
      'structures': structures,
      'windows': const [],
    };
  }

  // ─── getCandidates ──────────────────────────────────────────────────────

  group('getCandidates()', () {
    test('UUID 非法 → INVALID_UUID', () async {
      await expectLater(
        svc.getCandidates('not-uuid'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_UUID')),
      );
    });

    test('楼层不存在 → FLOOR_NOT_FOUND', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getCandidates(kFloorUuid),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('candidates 为空 → FLOOR_MAP_CANDIDATES_NOT_GENERATED', () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(kFloorColsWithMap, [floorRowWithMap()]);
        }
        // findCandidates → 行存在但 candidates 列为 null
        return makeResult(['candidates'], [[null]]);
      };
      await expectLater(
        svc.getCandidates(kFloorUuid),
        throwsA(isA<NotFoundException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_CANDIDATES_NOT_GENERATED')),
      );
    });

    test('candidates 存在 → 返回 map', () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(kFloorColsWithMap, [floorRowWithMap()]);
        }
        return makeResult(['candidates'], [
          [
            {'walls': [], 'columns': []}
          ]
        ]);
      };
      final result = await svc.getCandidates(kFloorUuid);
      expect(result, contains('walls'));
    });
  });

  // ─── getConfirmedStructures ─────────────────────────────────────────────

  group('getConfirmedStructures()', () {
    test('楼层不存在 → FLOOR_NOT_FOUND', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getConfirmedStructures(kFloorUuid),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('floor_maps 行不存在 → 返回空壳 + 楼层版本号', () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(kFloorColsWithMap,
              [floorRowWithMap(floorMapUpdatedAt: kVersionTime)]);
        }
        return makeResult([], []); // findByFloorId 空
      };
      final r = await svc.getConfirmedStructures(kFloorUuid);
      expect(r.map.structures, isEmpty);
      expect(r.version, kVersionTime);
    });
  });

  // ─── saveStructures ─────────────────────────────────────────────────────

  group('saveStructures()', () {
    test('schema_version != 2.0 → FLOOR_MAP_SCHEMA_UNSUPPORTED', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: {...validPayload(), 'schema_version': '1.0'},
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_SCHEMA_UNSUPPORTED')),
      );
    });

    test('viewport 缺失 → VALIDATION_ERROR', () async {
      final payload = {...validPayload()}..remove('viewport');
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: payload,
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('viewport 尺寸越界 → VALIDATION_ERROR', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(
              overrideViewport: {'width': 50, 'height': 50}),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('rect 超出 viewport → FLOOR_MAP_COORDINATE_OUT_OF_RANGE', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(overrideStructures: [
            {
              'type': 'core',
              'source': 'manual',
              'rect': {'x': 900, 'y': 700, 'w': 500, 'h': 500},
            }
          ]),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_COORDINATE_OUT_OF_RANGE')),
      );
    });

    test('elevator 缺 code → VALIDATION_ERROR', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(overrideStructures: [
            {
              'type': 'elevator',
              'source': 'manual',
              'rect': {'x': 10, 'y': 10, 'w': 50, 'h': 50},
              // 缺 code
            }
          ]),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('column.point 越界 → FLOOR_MAP_COORDINATE_OUT_OF_RANGE', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(overrideStructures: [
            {
              'type': 'column',
              'source': 'manual',
              'point': [2000, 100], // x 越界
            }
          ]),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_COORDINATE_OUT_OF_RANGE')),
      );
    });

    test('structure.type 非法 → FLOOR_MAP_INVALID_STRUCTURE_TYPE', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(overrideStructures: [
            {
              'type': 'unknown_type',
              'source': 'manual',
              'rect': {'x': 10, 'y': 10, 'w': 50, 'h': 50},
            }
          ]),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_INVALID_STRUCTURE_TYPE')),
      );
    });

    test('structures > 200 → FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED', () async {
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(structuresCount: 201),
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_STRUCTURE_LIMIT_EXCEEDED')),
      );
    });

    test('ifMatch 不匹配 → FLOOR_MAP_VERSION_CONFLICT', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kFloorColsWithMap,
              [floorRowWithMap(floorMapUpdatedAt: kVersionTime)]);
      await expectLater(
        svc.saveStructures(
          floorId: kFloorUuid,
          payload: validPayload(),
          ifMatch: '"2026-01-01T00:00:00.000Z"', // 不匹配
          updatedBy: kFloorUuid,
        ),
        throwsA(isA<ConflictException>()
            .having((e) => e.code, 'code', 'FLOOR_MAP_VERSION_CONFLICT')),
      );
    });
  });

  // ─── switchRenderMode ───────────────────────────────────────────────────

  group('switchRenderMode()', () {
    test('render_mode 非法 → INVALID_RENDER_MODE', () async {
      await expectLater(
        svc.switchRenderMode(
          floorId: kFloorUuid,
          renderMode: 'invalid',
          userId: kFloorUuid,
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_RENDER_MODE')),
      );
    });

    test('楼层不存在 → FLOOR_NOT_FOUND', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.switchRenderMode(
          floorId: kFloorUuid,
          renderMode: 'vector',
          userId: kFloorUuid,
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('semantic 但 floor_map 不存在 → FLOOR_MAP_NOT_READY_FOR_SEMANTIC',
        () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(kFloorColsWithMap, [floorRowWithMap()]);
        }
        return makeResult([], []); // findByFloorId 空
      };
      await expectLater(
        svc.switchRenderMode(
          floorId: kFloorUuid,
          renderMode: 'semantic',
          userId: kFloorUuid,
        ),
        throwsA(isA<AppException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_NOT_READY_FOR_SEMANTIC')),
      );
    });

    test('semantic 但缺 core/corridor → FLOOR_MAP_NOT_READY_FOR_SEMANTIC',
        () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(kFloorColsWithMap, [floorRowWithMap()]);
        }
        return makeResult(kFloorMapCols, [
          floorMapRow(
            outline: {
              'type': 'rect',
              'rect': {'x': 0, 'y': 0, 'w': 1000, 'h': 800}
            },
            structures: [
              {
                'type': 'restroom',
                'source': 'manual',
                'rect': {'x': 10, 'y': 10, 'w': 50, 'h': 50},
                'gender': 'M',
              }
            ],
          )
        ]);
      };
      await expectLater(
        svc.switchRenderMode(
          floorId: kFloorUuid,
          renderMode: 'semantic',
          userId: kFloorUuid,
        ),
        throwsA(isA<AppException>().having(
          (e) => e.code, 'code', 'FLOOR_MAP_NOT_READY_FOR_SEMANTIC')),
      );
    });

    test('vector 切换 → 成功', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kFloorColsWithMap, [floorRowWithMap()]);
      final r = await svc.switchRenderMode(
        floorId: kFloorUuid,
        renderMode: 'vector',
        userId: kFloorUuid,
      );
      expect(r['render_mode'], 'vector');
      expect(r['floor_id'], kFloorUuid);
    });
  });
}
