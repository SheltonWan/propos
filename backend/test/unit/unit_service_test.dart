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
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/unit_import_service.dart';
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
  late UnitImportService importSvc;

  setUp(() {
    pool = FakePool();
    svc = UnitService(pool);
    importSvc = UnitImportService(pool);
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
    /// 通用伪结果生成器：模拟 import_batches RETURNING 行
    Result fakeBatchRow({
      required int totalRecords,
      required int successCount,
      required int failureCount,
      required String rollbackStatus,
      required bool isDryRun,
      List<Map<String, dynamic>>? errorDetails,
    }) {
      return makeResult(
        [
          'id',
          'batch_name',
          'data_type',
          'total_records',
          'success_count',
          'failure_count',
          'rollback_status',
          'is_dry_run',
          'error_details',
          'source_file_path',
          'created_by',
          'created_at',
        ],
        [
          [
            'batch-id',
            'units_test',
            'units',
            totalRecords,
            successCount,
            failureCount,
            rollbackStatus,
            isDryRun,
            errorDetails,
            null,
            null,
            DateTime.utc(2026, 1, 1),
          ],
        ],
      );
    }

    test('只含标题行（无数据）→ 抛出 ValidationException(VALIDATION_ERROR)', () async {
      final bytes = _makeExcel(emptyBody: true);
      await expectLater(
        importSvc.importUnits(filename: 'test.xlsx', fileBytes: bytes),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')),
      );
    });

    test('含一行必填字段缺失的行 → failure_count>0 & rollback_status=rolled_back',
        () async {
      pool.executeHandler = (q, p) => fakeBatchRow(
            totalRecords: 1,
            successCount: 0,
            failureCount: 1,
            rollbackStatus: 'rolled_back',
            isDryRun: false,
            errorDetails: [
              {'row': 2, 'field': 'floor_id', 'error': '楼层ID不能为空'},
            ],
          );
      final bytes = _makeExcel(rows: [
        ['b-1', null, null, 'office'],
      ]);
      final result =
          await importSvc.importUnits(filename: 'test.xlsx', fileBytes: bytes);
      expect(result['failure_count'], greaterThan(0));
      expect(result['rollback_status'], 'rolled_back');
    });

    test('含无效 propertyType → failure_count=1', () async {
      // 该行会触发楼栋/楼层查询后才进行业态校验；需要按调用顺序返回不同结果
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        // call 1: 楼栋名称查询
        if (callIdx == 1) {
          return makeResult([
            'id',
            'property_type'
          ], [
            ['b-1', 'office']
          ]);
        }
        // call 2: 楼层名称查询
        if (callIdx == 2) {
          return makeResult([
            'id'
          ], [
            ['f-1']
          ]);
        }
        // call 3: import_batches RETURNING（属性类型 'shop' 校验失败后写入回滚批次）
        return fakeBatchRow(
          totalRecords: 1,
          successCount: 0,
          failureCount: 1,
          rollbackStatus: 'rolled_back',
          isDryRun: false,
          errorDetails: [
            {'row': 2, 'field': 'property_type', 'error': '无效业态值: shop'},
          ],
        );
      };
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'shop'],
      ]);
      final result =
          await importSvc.importUnits(filename: 'test.xlsx', fileBytes: bytes);
      expect(result['failure_count'], 1);
      expect(result['error_details'], isA<List>());
    });

    test('dry_run=true → is_dry_run=true 且 success_count=有效行数', () async {
      // 合法行需要先查楼栋/楼层，再写入 dry_run 批次记录
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1)
          return makeResult([
            'id',
            'property_type'
          ], [
            ['b-1', 'office']
          ]);
        if (callIdx == 2)
          return makeResult([
            'id'
          ], [
            ['f-1']
          ]);
        return fakeBatchRow(
          totalRecords: 1,
          successCount: 1,
          failureCount: 0,
          rollbackStatus: 'committed',
          isDryRun: true,
        );
      };
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'office'],
      ]);
      final result = await importSvc.importUnits(
          filename: 'test.xlsx', fileBytes: bytes, dryRun: true);
      expect(result['is_dry_run'], isTrue);
      expect(result['success_count'], 1);
    });

    test('含合法行且 dryRun=false → 走事务路径（runTx 被调用）', () async {
      // call 1/2: 楼栋/楼层查询；call 3: bulkCreate INSERT；call 4: import_batches RETURNING
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1)
          return makeResult([
            'id',
            'property_type'
          ], [
            ['b-1', 'retail']
          ]);
        if (callIdx == 2)
          return makeResult([
            'id'
          ], [
            ['f-1']
          ]);
        if (callIdx == 3)
          return makeResult([], []); // bulkCreate INSERT，affectedRows=0
        return fakeBatchRow(
          totalRecords: 1,
          successCount: 1,
          failureCount: 0,
          rollbackStatus: 'committed',
          isDryRun: false,
        );
      };
      final bytes = _makeExcel(rows: [
        ['b-1', 'f-1', '101', 'retail'],
      ]);
      await importSvc.importUnits(
          filename: 'test.xlsx', fileBytes: bytes, dryRun: false);
      expect(pool.runTxCalled, isTrue);
    });
  });

  // ─── getOverview 统计 ─────────────────────────────────────────────────────

  group('getOverview()', () {
    // 工具：按调用顺序派发
    //   1) getOverviewStats   → byType
    //   2) getWaleStats       → wale
    //   3) countLeasableUnits → leasableCount
    Result Function(Object q, Object? p) dispatcher({
      required Result byType,
      Result? wale,
      Result? leasableCount,
    }) {
      var callCount = 0;
      return (q, p) {
        callCount++;
        if (callCount == 1) return byType;
        if (callCount == 2) {
          return wale ??
              makeResult(
                ['wale_income_weighted', 'wale_area_weighted'],
                [
                  [0.0, 0.0],
                ],
              );
        }
        return leasableCount ??
            makeResult(['cnt'], [
              [0],
            ]);
      };
    }

    test('10 套 5 出租 1 即将到期 → totalOccupancyRate=(5+1)/(5+3+1)=0.6667',
        () async {
      pool.executeHandler = dispatcher(
        byType: makeResult(
          [
            'property_type',
            'total_units',
            'leased_units',
            'vacant_units',
            'expiring_soon_units',
            'total_nla',
            'leased_nla',
          ],
          [
            ['office', 10, 5, 3, 1, 1000.0, 600.0],
          ],
        ),
        leasableCount: makeResult(['cnt'], [
          [9],
        ]),
      );
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 10);
      expect(stats.totalLeasableUnits, 9); // 5+3+1
      expect(stats.totalOccupancyRate, closeTo(6 / 9, 0.001));
      expect(stats.waleIncomeWeighted, 0.0);
      expect(stats.waleAreaWeighted, 0.0);
    });

    test('office(10) + retail(20) 已被占用合计 18 → totalOccupancyRate ≈ 18/28',
        () async {
      pool.executeHandler = dispatcher(
        byType: makeResult(
          [
            'property_type',
            'total_units',
            'leased_units',
            'vacant_units',
            'expiring_soon_units',
            'total_nla',
            'leased_nla',
          ],
          [
            ['office', 10, 5, 3, 1, 1000.0, 600.0],
            ['retail', 20, 10, 7, 2, 2000.0, 1200.0],
          ],
        ),
        wale: makeResult(
          ['wale_income_weighted', 'wale_area_weighted'],
          [
            [2.5, 2.3],
          ],
        ),
        leasableCount: makeResult(['cnt'], [
          [28],
        ]),
      );
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 30);
      expect(stats.totalLeasableUnits, 28); // 9+19
      expect(stats.totalOccupancyRate, closeTo(18 / 28, 0.001));
      expect(stats.waleIncomeWeighted, closeTo(2.5, 0.001));
      expect(stats.waleAreaWeighted, closeTo(2.3, 0.001));
      expect(stats.byPropertyType, hasLength(2));
    });

    test('无单元 → totalOccupancyRate=0', () async {
      pool.executeHandler = dispatcher(byType: makeResult([], []));
      final stats = await svc.getOverview();
      expect(stats.totalUnits, 0);
      expect(stats.totalOccupancyRate, 0.0);
    });
  });
}
