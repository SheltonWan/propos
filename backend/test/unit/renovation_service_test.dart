/// RenovationService 单元测试
///
/// 覆盖场景：
///   getRenovation()    — 不存在 → NOT_FOUND / 成功返回
///   createRenovation() — 单元不存在 / 施工造价为负 /
///                        完成日期早于开始日期 / 成功
///   updateRenovation() — 不存在 → NOT_FOUND / 施工造价为负
///   uploadPhoto()      — 改造记录不存在 / 无效 photoStage /
///                        非图片扩展名 / 合法 .jpg 文件
library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/renovation_service.dart';

import 'helpers/asset_fakes.dart';
import 'helpers/fakes.dart';

void main() {
  late FakePool pool;
  late Directory tmpDir;
  late RenovationService svc;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('renov_svc_test_');
  });

  setUp(() {
    pool = FakePool();
    svc = RenovationService(pool, tmpDir.path);
  });

  tearDownAll(() async {
    await tmpDir.delete(recursive: true);
  });

  // ─── getRenovation ────────────────────────────────────────────────────────

  group('getRenovation()', () {
    test('DB 返回空 → NotFoundException(NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getRenovation('r-x'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('DB 返回 1 行 → 返回 RenovationRecord', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kRenovationCols, [renovationRow(id: 'r-1')]);
      final r = await svc.getRenovation('r-1');
      expect(r.id, 'r-1');
      expect(r.renovationType, '隔断改造');
    });
  });

  // ─── createRenovation 验证 ────────────────────────────────────────────────

  group('createRenovation() 参数校验', () {
    test('单元不存在 → NotFoundException(UNIT_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.createRenovation(
          unitId: 'u-x',
          renovationType: '改造',
          startedAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'UNIT_NOT_FOUND')),
      );
    });

    test('施工造价为负数 → ValidationException', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kUnitCols, [unitRow()]); // unit found
      await expectLater(
        svc.createRenovation(
          unitId: 'u-1',
          renovationType: '改造',
          startedAt: DateTime.utc(2026, 1, 1),
          cost: -500,
          createdBy: 'user-1',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('完成日期早于开始日期 → ValidationException', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kUnitCols, [unitRow()]);
      await expectLater(
        svc.createRenovation(
          unitId: 'u-1',
          renovationType: '改造',
          startedAt: DateTime.utc(2026, 3, 1),
          completedAt: DateTime.utc(2026, 1, 1), // 早于 startedAt
          createdBy: 'user-1',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('合法参数 → DB INSERT 被调用，返回 RenovationRecord', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kUnitCols, [unitRow()]);
        return makeResult(kRenovationCols, [renovationRow()]);
      };
      final r = await svc.createRenovation(
        unitId: 'u-1',
        renovationType: '水电改造',
        startedAt: DateTime.utc(2026, 1, 1),
        completedAt: DateTime.utc(2026, 2, 1),
        cost: 50000,
        contractor: '某施工队',
        createdBy: 'user-1',
      );
      expect(r.renovationType, '隔断改造'); // fake row 固定值
    });
  });

  // ─── updateRenovation 验证 ────────────────────────────────────────────────

  group('updateRenovation() 参数校验', () {
    test('记录不存在 → NotFoundException', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.updateRenovation('r-x', renovationType: '升级改造'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('施工造价为负数 → ValidationException', () async {
      await expectLater(
        svc.updateRenovation('r-1', cost: -1),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ─── uploadPhoto 验证 ─────────────────────────────────────────────────────

  group('uploadPhoto()', () {
    test('改造记录不存在 → NotFoundException', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.uploadPhoto(
          renovationId: 'r-x',
          fileBytes: [1, 2, 3],
          originalFilename: 'photo.jpg',
          photoStage: 'before',
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('无效 photoStage → ValidationException', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kRenovationCols, [renovationRow()]); // record found
      await expectLater(
        svc.uploadPhoto(
          renovationId: 'r-1',
          fileBytes: [1, 2, 3],
          originalFilename: 'photo.jpg',
          photoStage: 'during', // 非 before/after
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('非图片扩展名 → ValidationException', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kRenovationCols, [renovationRow()]);
      await expectLater(
        svc.uploadPhoto(
          renovationId: 'r-1',
          fileBytes: [1, 2, 3],
          originalFilename: 'document.pdf', // 非图片
          photoStage: 'before',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('合法 .jpg 文件 → 返回 storage_path 与 photo_stage', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kRenovationCols, [renovationRow()]);
        // appendBeforePhotoPath → execute UPDATE
        return makeResult(kRenovationCols, [renovationRow()]);
      };
      final result = await svc.uploadPhoto(
        renovationId: 'r-1',
        fileBytes: [0xFF, 0xD8, 0xFF], // JPEG magic bytes
        originalFilename: 'before_shot.jpg',
        photoStage: 'before',
      );
      expect(result['photo_stage'], 'before');
      expect(result['storage_path'], contains('renovations/r-1/'));
    });

    test('合法 .png 文件（photoStage=after）→ 路径包含 renovations/r-1', () async {
      var callIdx = 0;
      pool.executeHandler = (q, p) {
        callIdx++;
        if (callIdx == 1) return makeResult(kRenovationCols, [renovationRow()]);
        return makeResult(kRenovationCols, [renovationRow()]);
      };
      final result = await svc.uploadPhoto(
        renovationId: 'r-1',
        fileBytes: [0x89, 0x50, 0x4E, 0x47], // PNG magic bytes
        originalFilename: 'after_shot.png',
        photoStage: 'after',
      );
      expect(result['photo_stage'], 'after');
      expect(result['storage_path'], startsWith('renovations/r-1/'));
    });
  });
}
