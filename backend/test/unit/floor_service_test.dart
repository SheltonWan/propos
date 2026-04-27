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
}
