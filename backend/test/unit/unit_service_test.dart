/// UnitService 单元测试
///
/// 覆盖场景：
///   getUnit()       — 不存在 → UNIT_NOT_FOUND / 成功返回
///   createUnit()    — 无效 propertyType / 楼栋不存在 / 楼层不存在 /
///                     楼层不属于指定楼栋 / 成功
///   updateUnit()    — 不存在 → UNIT_NOT_FOUND / 成功
///   importUnits()   — 空 Excel / 含无效行 / 合法行数据
///   getOverview()   — 单业态出租率计算 / 多业态总计计算
library;

import 'package:excel/excel.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/unit_service.dart';

import 'helpers/asset_fakes.dart';
import 'helpers/fakes.dart';

// ─── 辅助：生成最小有效 Excel 字节（header + 数据行）─────────────────────────
List<int> _makeExcel({
  bool emptyBody = false,
  List<List<Object?>>? rows,
}) {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  // 标题行（与 unit_service.dart 第一行为标题的约定一致）
  sheet.appendRow([
    TextCellValue('楼栋ID'), TextCellValue('楼层ID'), TextCellValue('单元编号'), TextCellValue('业态'),
    TextCellValue('建筑面积'), TextCellValue('套内面积'), TextCellValue('装修状态'), TextCellValue('是否可租'),
  ]);
  if (!emptyBody) {
    for (final row in (rows ?? [])) {
      sheet.appendRow(row.map<CellValue?>((v) {
        if (v == null) return TextCellValue('');
        if (v is String) return TextCellValue(v);
        if (v is double) return DoubleCellValue(v);
        if (v is int) return IntCellValue(v);
        return TextCellValue(v.toString());
      }).toList());
    }
  }
  return excel.encode()!;
}

void main() {
  late FakePool pool;
  late UnitService svc;

  setUp(() {
    pool = FakePool();
    svc = UnitService(pool);
  });

  // ─── getUnit ─────────────────────────────────────────────────────────────

  group('getUnit()', () {
    test('DB 返回空 → NotFoundException(UNIT_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getUnit('u-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'UNIT_NOT_FOUND')),
      );
    });

    test('DB 返回 1 行 → 返回 Unit', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kUnitCols, [unitRow(id: 'u-1', unitNumber: '201')]);
      final u = await svc.getUnit('u-1');
      expect(u.id, 'u-1');
      expect(u.unitNumber, '201');
    });
  });

  // ─── createUnit 验证 ──────────────────────────────────────────────────────

  group('createUnit() 参数校验', () {
    test('无效 propertyType → ValidationException', () async {
      await expectLater(
        svc.createUnit(
          floorId: 'f-1',
          buildingId: 'b-1',
          unitNumber: '101',
          propertyType: 'shop',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('楼栋不存在 → NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.createUnit(
          floorId: 'f-1',
          buildingId: 'b-x',
          unitNumber: '101',
          propertyType: 'office',
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')),
      );
    });

    test('楼层不存在 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        return makeResult([], []); // floor not found
      };
      await expectLater(
        svc.createUnit(
          floorId: 'f-x',
          buildingId: 'b-1',
          unitNumber: '101',
          propertyType: 'office',
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('楼层 building_id 与传入 buildingId 不匹配 → ValidationException', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow(id: 'b-1')]);
        // 楼层属于 b-other
        return makeResult(kFloorCols, [floorRow(buildingId: 'b-other')]);
      };
      await expectLater(
        svc.createUnit(
          floorId: 'f-1',
          buildingId: 'b-1',
          unitNumber: '101',
          propertyType: 'retail',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('合法参数 → DB INSERT 被调用，返回 Unit', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kBuildingCols, [buildingRow()]);
        if (callIdx == 2) return makeResult(kFloorCols, [floorRow()]);
        return makeResult(kUnitCols, [unitRow(unitNumber: '305')]);
      };
      final u = await svc.createUnit(
        floorId: 'f-1',
        buildingId: 'b-1',
        unitNumber: '305',
        propertyType: 'office',
        grossArea: 100.0,
        netArea: 88.0,
      );
      expect(u.unitNumber, '305');
    });
  });

  // ─── updateUnit ──────────────────────────────────────────────────────────

  group('updateUnit()', () {
    test('DB 返回空（记录不存在）→ NotFoundException(UNIT_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.updateUnit('u-x', unitNumber: '999'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'UNIT_NOT_FOUND')),
      );
    });

    test('合法更新 → 返回更新后 Unit', () async {
      // updateUnit 调用 update()（返回 null 若不存在）+ findById（返回完整数据）
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        // update() 的 RETURNING 查询
        if (callIdx == 1) return makeResult(kUnitCols, [unitRow(unitNumber: '999')]);
        // findById 的查询
        return makeResult(kUnitCols, [unitRow(unitNumber: '999')]);
      };
      final u = await svc.updateUnit('u-1', unitNumber: '999');
      expect(u.unitNumber, '999');
    });
  });

  // ─── importUnits ─────────────────────────────────────────────────────────

  group('importUnits()', () {
    test('只含标题行（无数据）→ total_rows=0 / valid_rows=0', () async {
      final bytes = _makeExcel(emptyBody: true);
      final result = await svc.importUnits(fileBytes: bytes);
      expect(result['total_rows'], 0);
      expect(result['valid_rows'], 0);
    });

    test('含一行必填字段缺失的行 → error_rows=1', () async {
      final bytes = _makeExcel(rows: [
        ['b-1', null, null, 'office'], // 缺少 floor_id 和 unit_number
      ]);
      final result = await svc.importUnits(fileBytes: bytes);
      expect(result['error_rows'], greaterThan(0));
    });

    test('含无效 propertyType → error_rows > 0', () async {
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'shop'], // 无效业态
      ]);
      final result = await svc.importUnits(fileBytes: bytes);
      expect(result['error_rows'], 1);
      expect((result['errors'] as List).first,
          contains('无效业态值'));
    });

    test('dry_run=true → valid_rows > 0 但不调用 bulkCreate', () async {
      // 提供合法行，dryRun=true 不写 DB（pool.executeHandler 保持默认空返回）
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'office'],
      ]);
      final result = await svc.importUnits(fileBytes: bytes, dryRun: true);
      expect(result['dry_run'], isTrue);
      expect(result['valid_rows'], 1);
    });

    test('含合法行且 dryRun=false → bulkCreate 被调用（execute 至少调用一次）', () async {
      var executeCalled = false;
      pool.executeHandler = (q, p) {
        executeCalled = true;
        return makeResult([], []);
      };
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'retail'],
      ]);
      await svc.importUnits(fileBytes: bytes, dryRun: false);
      expect(executeCalled, isTrue);
    });
  });

  // ─── getOverview 统计 ─────────────────────────────────────────────────────

  group('getOverview()', () {
    test('10 套 5 出租 → occupancyRate=0.5', () async {
      pool.executeHandler = (q, p) => makeResult(
            ['property_type', 'total', 'leased', 'vacant', 'expiring_soon'],
            [
              ['office', 10, 5, 3, 1],
            ],
          );
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 10);
      expect(stats.totalLeased, 5);
      expect(stats.occupancyRate, closeTo(0.5, 0.001));
    });

    test('office(10) + retail(20) → total=30, leased=15', () async {
      pool.executeHandler = (q, p) => makeResult(
            ['property_type', 'total', 'leased', 'vacant', 'expiring_soon'],
            [
              ['office', 10, 5, 3, 1],
              ['retail', 20, 10, 7, 2],
            ],
          );
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 30);
      expect(stats.totalLeased, 15);
      expect(stats.occupancyRate, closeTo(0.5, 0.001));
      expect(stats.byPropertyType, hasLength(2));
    });

    test('无单元 → occupancyRate=0', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 0);
      expect(stats.occupancyRate, 0.0);
    });
  });
}
