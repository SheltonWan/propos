/// BuildingService 单元测试
///
/// 覆盖场景：
///   listBuildings()                — 空列表 / 非空列表
///   getBuilding()                  — 不存在 → BUILDING_NOT_FOUND / 成功返回
///   createBuilding()               — 无效 propertyType / 零楼层数 / 零面积 / 成功
///   updateBuilding()               — 无效 propertyType / DB 返回空 → NOT_FOUND /
///                                    basementFloors 越界 / totalFloors 越界 /
///                                    层数递减 → BUILDING_FLOOR_DECREASE_NOT_ALLOWED /
///                                    成功（runTx 路径）
///   createBuildingWithFloors()     — totalFloors 越界 / basementFloors 越界 / gfa=0 /
///                                    成功（2F+B1 共 3 楼层）
///   deleteBuilding()               — 不存在 / 有单元 / 有工单 / 有账单 / 成功
library;

import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/building_service.dart';

import 'helpers/asset_fakes.dart';
import 'helpers/fakes.dart';

void main() {
  late FakePool pool;
  late BuildingService svc;

  setUp(() {
    pool = FakePool();
    svc = BuildingService(pool);
  });

  // ─── listBuildings ────────────────────────────────────────────────────────

  group('listBuildings()', () {
    test('DB 返回空 → 空列表', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      expect(await svc.listBuildings(), isEmpty);
    });

    test('DB 返回 2 行 → 列表长度 2', () async {
      pool.executeHandler = (q, p) => makeResult(
            kBuildingCols,
            [
              buildingRow(id: 'b-1', name: 'A楼'),
              buildingRow(id: 'b-2', name: 'B楼'),
            ],
          );
      final result = await svc.listBuildings();
      expect(result, hasLength(2));
      expect(result.first.id, 'b-1');
      expect(result.last.id, 'b-2');
    });
  });

  // ─── getBuilding ─────────────────────────────────────────────────────────

  group('getBuilding()', () {
    test('DB 返回空 → NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getBuilding('b-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('DB 返回 1 行 → 返回正确 Building', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kBuildingCols, [buildingRow(id: 'b-1', propertyType: 'retail')]);
      final b = await svc.getBuilding('b-1');
      expect(b.id, 'b-1');
      expect(b.propertyType, 'retail');
    });
  });

  // ─── createBuilding 验证 ──────────────────────────────────────────────────

  group('createBuilding() 参数校验', () {
    test('propertyType=hotel → ValidationException', () async {
      await expectLater(
        svc.createBuilding(
          name: 'T',
          propertyType: 'hotel',
          totalFloors: 5,
          gfa: 1000,
          nla: 800,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('totalFloors=0 → ValidationException', () async {
      await expectLater(
        svc.createBuilding(
          name: 'T',
          propertyType: 'office',
          totalFloors: 0,
          gfa: 1000,
          nla: 800,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('gfa=0 → ValidationException', () async {
      await expectLater(
        svc.createBuilding(
          name: 'T',
          propertyType: 'office',
          totalFloors: 5,
          gfa: 0,
          nla: 800,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nla 为负数 → ValidationException', () async {
      await expectLater(
        svc.createBuilding(
          name: 'T',
          propertyType: 'apartment',
          totalFloors: 5,
          gfa: 1000,
          nla: -1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('合法参数 → DB INSERT 被调用，返回 Building', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kBuildingCols, [buildingRow(name: '新楼')]);
      final b = await svc.createBuilding(
        name: '新楼',
        propertyType: 'apartment',
        totalFloors: 8,
        gfa: 3000,
        nla: 2400,
        address: '深圳南山',
        builtYear: 2020,
      );
      expect(b.name, '新楼');
      expect(b.propertyType, 'office'); // row 默认 office
    });
  });

  // ─── updateBuilding 验证 ──────────────────────────────────────────────────

  group('updateBuilding() 参数校验', () {
    test('propertyType=mall → ValidationException', () async {
      await expectLater(
        svc.updateBuilding('b-1', propertyType: 'mall'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('totalFloors=-1 → ValidationException', () async {
      await expectLater(
        svc.updateBuilding('b-1', totalFloors: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('DB 返回空（记录不存在）→ NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.updateBuilding('b-x', name: '新名称'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')),
      );
    });

    test('合法更新 → 返回更新后 Building', () async {
      // updateBuilding 在事务中先查楼层列表再更新 buildings 表
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) {
          return makeResult(kFloorCols, []); // findAll floors（空列表）
        }
        return makeResult(kBuildingCols, [buildingRow(name: '更新后名称')]);
      };
      final b = await svc.updateBuilding('b-1', name: '更新后名称');
      expect(b.name, '更新后名称');
      expect(pool.runTxCalled, isTrue);
    });

    test('basementFloors=-1 → ValidationException(地下层数不能为负)', () async {
      await expectLater(
        svc.updateBuilding('b-1', basementFloors: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('basementFloors=21 → ValidationException(地下层数不得超过 20)', () async {
      await expectLater(
        svc.updateBuilding('b-1', basementFloors: 21),
        throwsA(isA<ValidationException>()),
      );
    });

    test('totalFloors=201 → ValidationException(地上层数不得超过 200)', () async {
      await expectLater(
        svc.updateBuilding('b-1', totalFloors: 201),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'totalFloors 小于当前层数 → ValidationException(BUILDING_FLOOR_DECREASE_NOT_ALLOWED)',
        () async {
      // 当前有 5 层地上，尝试减少到 3 层 → BUILDING_FLOOR_DECREASE_NOT_ALLOWED
      pool.executeHandler = (q, p) => makeResult(
            kFloorCols,
            [for (var i = 1; i <= 5; i++) floorRow(id: 'f-$i', floorNumber: i)],
          );
      await expectLater(
        svc.updateBuilding('b-1', totalFloors: 3),
        throwsA(isA<ValidationException>().having(
            (e) => e.code, 'code', 'BUILDING_FLOOR_DECREASE_NOT_ALLOWED')),
      );
    });
  });

  // ─── createBuildingWithFloors ─────────────────────────────────────────────

  group('createBuildingWithFloors() 参数校验', () {
    test('totalFloors=0 → ValidationException', () async {
      await expectLater(
        svc.createBuildingWithFloors(
            name: 'T',
            propertyType: 'office',
            totalFloors: 0,
            gfa: 1000,
            nla: 800),
        throwsA(isA<ValidationException>()),
      );
    });

    test('totalFloors=201 → ValidationException', () async {
      await expectLater(
        svc.createBuildingWithFloors(
            name: 'T',
            propertyType: 'office',
            totalFloors: 201,
            gfa: 1000,
            nla: 800),
        throwsA(isA<ValidationException>()),
      );
    });

    test('basementFloors=-1 → ValidationException', () async {
      await expectLater(
        svc.createBuildingWithFloors(
            name: 'T',
            propertyType: 'office',
            totalFloors: 5,
            gfa: 1000,
            nla: 800,
            basementFloors: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('basementFloors=21 → ValidationException', () async {
      await expectLater(
        svc.createBuildingWithFloors(
            name: 'T',
            propertyType: 'office',
            totalFloors: 5,
            gfa: 1000,
            nla: 800,
            basementFloors: 21),
        throwsA(isA<ValidationException>()),
      );
    });

    test('gfa=0 → ValidationException', () async {
      await expectLater(
        svc.createBuildingWithFloors(
            name: 'T',
            propertyType: 'office',
            totalFloors: 5,
            gfa: 0,
            nla: 800),
        throwsA(isA<ValidationException>()),
      );
    });

    test('合法参数(2F+B1) → runTx 被调用，返回楼栋及 3 个楼层', () async {
      // call 1: buildings INSERT
      // call 2: floor B1 INSERT
      // call 3: floor 1F INSERT
      // call 4: floor 2F INSERT
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        return makeResult(kFloorCols, [floorRow(id: 'f-$callIdx')]);
      };
      final result = await svc.createBuildingWithFloors(
        name: 'New Tower',
        propertyType: 'office',
        totalFloors: 2,
        gfa: 1000,
        nla: 800,
        basementFloors: 1,
      );
      expect(result.building.id, 'b-1');
      expect(result.floors, hasLength(3)); // B1 + 1F + 2F
      expect(pool.runTxCalled, isTrue);
    });
  });

  // ─── deleteBuilding ───────────────────────────────────────────────────────

  group('deleteBuilding()', () {
    test('楼栋不存在 → NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.deleteBuilding('b-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')),
      );
    });

    test('楼栋有单元 → ValidationException(BUILDING_HAS_UNITS)', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        return makeResult([
          'c'
        ], [
          [3]
        ]); // COUNT units = 3
      };
      await expectLater(
        svc.deleteBuilding('b-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'BUILDING_HAS_UNITS')),
      );
    });

    test('楼栋有工单 → ValidationException(BUILDING_HAS_WORKORDERS)', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        if (callIdx == 2) {
          return makeResult([
            'c'
          ], [
            [0]
          ]); // COUNT units = 0
        }
        return makeResult([
          'c'
        ], [
          [2]
        ]); // COUNT workorders = 2
      };
      await expectLater(
        svc.deleteBuilding('b-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'BUILDING_HAS_WORKORDERS')),
      );
    });

    test('楼栋有账单 → ValidationException(BUILDING_HAS_INVOICES)', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        if (callIdx == 2) {
          return makeResult([
            'c'
          ], [
            [0]
          ]); // COUNT units = 0
        }
        if (callIdx == 3) {
          return makeResult([
            'c'
          ], [
            [0]
          ]); // COUNT workorders = 0
        }
        return makeResult([
          'c'
        ], [
          [1]
        ]); // COUNT invoices = 1
      };
      await expectLater(
        svc.deleteBuilding('b-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'BUILDING_HAS_INVOICES')),
      );
    });

    test('无关联数据 → 删除成功，runTx 被调用', () async {
      // call 1: findById; call 2/3/4: COUNT units/workorders/invoices;
      // call 5/6: DELETE floor_plans/floors; call 7: DELETE buildings
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        if (callIdx <= 4) {
          return makeResult([
            'c'
          ], [
            [0]
          ]); // 全部 COUNT = 0
        }
        if (callIdx <= 6) {
          return makeResult([], []); // DELETE floor_plans / DELETE floors
        }
        return makeResult([
          'id'
        ], [
          ['b-1']
        ]); // DELETE buildings（affectedRows=1）
      };
      await svc.deleteBuilding('b-1'); // 不应抛出异常
      expect(pool.runTxCalled, isTrue);
    });
  });
}
