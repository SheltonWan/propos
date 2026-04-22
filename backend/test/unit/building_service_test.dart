/// BuildingService 单元测试
///
/// 覆盖场景：
///   listBuildings()   — 空列表 / 非空列表
///   getBuilding()     — 不存在 → BUILDING_NOT_FOUND / 成功返回
///   createBuilding()  — 无效 propertyType / 零楼层数 / 零面积 / 成功
///   updateBuilding()  — 无效 propertyType / DB 返回空 → NOT_FOUND / 成功
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
      pool.executeHandler = (q, p) =>
          makeResult(kBuildingCols, [buildingRow(name: '更新后名称')]);
      final b = await svc.updateBuilding('b-1', name: '更新后名称');
      expect(b.name, '更新后名称');
    });
  });
}
