/// CadImportService 单元测试
///
/// 覆盖范围：服务层同步校验分支与 assignUnmatched 全流程。
///
/// 不在覆盖范围（涉及外部进程，应在集成测试中验证）：
///   - _runSplit 异步切分逻辑（Process.run python3 split_dxf_by_floor.py）
///   - 私有楼层匹配辅助函数（通过 assignUnmatched 间接覆盖）
///
/// 覆盖场景：
///   uploadDxf()       — 楼栋不存在 / 非 .dxf 扩展名 / 大小写不敏感校验
///   getJob()          — 不存在 → CAD_IMPORT_JOB_NOT_FOUND
///   assignUnmatched() — 任务不存在 / 状态非 done / 楼层不存在 / 跨楼栋 /
///                       SVG label 不在未匹配列表 / 成功路径
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:propos_backend/core/errors/app_exception.dart';
import 'package:propos_backend/modules/assets/services/cad_import_service.dart';

import 'helpers/asset_fakes.dart';
import 'helpers/fakes.dart';

// cad_import_jobs 表查询返回的列（与 CadImportJobRepository SELECT 顺序一致）
const _kJobCols = [
  'id',
  'building_id',
  'status',
  'dxf_path',
  'prefix',
  'matched_count',
  'unmatched_svgs',
  'error_message',
  'created_by',
  'created_by_name',
  'created_at',
  'updated_at',
];

final _t = DateTime.utc(2026, 4, 28);

/// 构造一行 cad_import_jobs 查询结果
List<Object?> _jobRow({
  String id = 'job-1',
  String buildingId = 'b-1',
  String status = 'uploaded',
  String dxfPath = 'cad/b-1/job-1.dxf',
  String prefix = 'plan',
  int matchedCount = 0,
  List<Map<String, String>> unmatchedSvgs = const [],
  String? errorMessage,
  String? createdBy = 'u-1',
  String? createdByName = 'Tester',
}) =>
    [
      id,
      buildingId,
      status,
      dxfPath,
      prefix,
      matchedCount,
      // 与 fromColumnMap 接受 List<dynamic> 一致：直接给原生 List<Map>
      unmatchedSvgs,
      errorMessage,
      createdBy,
      createdByName,
      _t,
      _t,
    ];

void main() {
  late FakePool pool;
  late Directory tmpDir;
  late CadImportService svc;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('cad_import_svc_test_');
  });

  setUp(() {
    pool = FakePool();
    svc = CadImportService(
      pool,
      tmpDir.path,
      // 提供一个肯定不存在的脚本路径，避免 _runSplit 真实执行 python3
      splitScriptPath: '/nonexistent/split_dxf.py',
    );
  });

  tearDownAll(() async {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  // ─── uploadDxf ──────────────────────────────────────────────────────────

  group('uploadDxf()', () {
    test('楼栋不存在 → NotFoundException(BUILDING_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.uploadDxf(
          buildingId: 'b-x',
          fileBytes: const [1, 2, 3],
          originalFilename: 'plan.dxf',
        ),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'BUILDING_NOT_FOUND')),
      );
    });

    test('扩展名非 .dxf → ValidationException(INVALID_CAD_FILE)', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kBuildingCols, [buildingRow()]);
      await expectLater(
        svc.uploadDxf(
          buildingId: 'b-1',
          fileBytes: const [1, 2, 3],
          originalFilename: 'plan.dwg',
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_CAD_FILE')),
      );
    });

    test('扩展名为 .pdf 同样拒绝', () async {
      pool.executeHandler = (q, p) =>
          makeResult(kBuildingCols, [buildingRow()]);
      await expectLater(
        svc.uploadDxf(
          buildingId: 'b-1',
          fileBytes: const [1, 2, 3],
          originalFilename: 'plan.pdf',
        ),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_CAD_FILE')),
      );
    });

    test('大小写不敏感校验：.DXF 通过扩展名校验', () async {
      // 此用例只断言不抛 INVALID_CAD_FILE。后续 create / file write / findById
      // 都需要 mock；为避免 _runSplit 触达真实 IO，这里准备 4 次 execute 返回。
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        switch (idx) {
          case 1:
            // BuildingRepository.findById
            return makeResult(kBuildingCols, [buildingRow()]);
          case 2:
            // CadImportJobRepository.create
            return makeResult(_kJobCols, [_jobRow()]);
          case 3:
            // UPDATE dxf_path
            return makeResult([], []);
          default:
            // 末尾 findById 返回最新任务（_runSplit 在 unawaited 中也会走多次，
            // 同样的返回足够让其链路安全失败 → updateResult 仍是 [] 结果）
            return makeResult(_kJobCols, [_jobRow()]);
        }
      };

      // 提供最小合法 DXF 内容：纯文本 + 包含 SECTION 关键字，满足 _validateDxfMagic 校验
      final validDxfBytes =
          '  0\r\nSECTION\r\n  2\r\nHEADER\r\n  0\r\nENDSEC\r\n  0\r\nEOF\r\n'.codeUnits;
      final job = await svc.uploadDxf(
        buildingId: 'b-1',
        fileBytes: validDxfBytes,
        originalFilename: 'PLAN.DXF',
      );
      expect(job.id, 'job-1');
      expect(job.buildingId, 'b-1');
    });
  });

  // ─── getJob ─────────────────────────────────────────────────────────────

  group('getJob()', () {
    test('任务不存在 → NotFoundException(CAD_IMPORT_JOB_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.getJob('job-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'CAD_IMPORT_JOB_NOT_FOUND')),
      );
    });

    test('任务存在 → 返回 CadImportJob', () async {
      pool.executeHandler = (q, p) => makeResult(_kJobCols, [_jobRow()]);
      final job = await svc.getJob('job-1');
      expect(job.id, 'job-1');
      expect(job.status, 'uploaded');
    });
  });

  // ─── assignUnmatched ────────────────────────────────────────────────────

  group('assignUnmatched()', () {
    test('任务不存在 → NotFoundException(CAD_IMPORT_JOB_NOT_FOUND)', () async {
      pool.executeHandler = (q, p) => makeResult([], []);
      await expectLater(
        svc.assignUnmatched('job-x', svgLabel: 'F1', floorId: 'f-1'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'CAD_IMPORT_JOB_NOT_FOUND')),
      );
    });

    test('任务状态非 done → ValidationException(CAD_IMPORT_JOB_NOT_DONE)',
        () async {
      pool.executeHandler = (q, p) =>
          makeResult(_kJobCols, [_jobRow(status: 'splitting')]);
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F1', floorId: 'f-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'CAD_IMPORT_JOB_NOT_DONE')),
      );
    });

    test('楼层不存在 → NotFoundException(FLOOR_NOT_FOUND)', () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(_kJobCols, [
            _jobRow(status: 'done', unmatchedSvgs: const [
              {'label': 'F1', 'tmp_path': 'cad/b-1/jobs/job-1/plan_F1.svg'},
            ])
          ]);
        }
        return makeResult([], []); // FloorRepository.findById → empty
      };
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F1', floorId: 'f-x'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'FLOOR_NOT_FOUND')),
      );
    });

    test('楼层属于其他楼栋 → ValidationException(FLOOR_BUILDING_MISMATCH)',
        () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(_kJobCols, [
            _jobRow(status: 'done', unmatchedSvgs: const [
              {'label': 'F1', 'tmp_path': 'cad/b-1/jobs/job-1/plan_F1.svg'},
            ])
          ]);
        }
        // FloorRepository.findById 返回属于其他楼栋的楼层
        return makeResult(kFloorCols, [floorRow(buildingId: 'b-OTHER')]);
      };
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F1', floorId: 'f-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'FLOOR_BUILDING_MISMATCH')),
      );
    });

    test('SVG label 不在未匹配列表 → NotFoundException(UNMATCHED_SVG_NOT_FOUND)',
        () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(_kJobCols, [
            _jobRow(status: 'done', unmatchedSvgs: const [
              {'label': 'F1', 'tmp_path': 'cad/b-1/jobs/job-1/plan_F1.svg'},
            ])
          ]);
        }
        return makeResult(kFloorCols, [floorRow(buildingId: 'b-1')]);
      };
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F999', floorId: 'f-1'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'UNMATCHED_SVG_NOT_FOUND')),
      );
    });

    test('原始 SVG 临时文件不存在 → NotFoundException(UNMATCHED_SVG_FILE_LOST)',
        () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(_kJobCols, [
            _jobRow(status: 'done', unmatchedSvgs: const [
              {
                'label': 'F1',
                'tmp_path': 'cad/b-1/jobs/job-1/plan_F1.svg',
              },
            ])
          ]);
        }
        return makeResult(kFloorCols, [floorRow(buildingId: 'b-1')]);
      };
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F1', floorId: 'f-1'),
        throwsA(isA<NotFoundException>()
            .having((e) => e.code, 'code', 'UNMATCHED_SVG_FILE_LOST')),
      );
    });

    test('成功路径：复制 SVG 到 floors/{buildingId}/{floorId}.svg 并更新任务',
        () async {
      // 准备临时 SVG 源文件
      final srcRel = 'cad/b-1/jobs/job-1/plan_F1.svg';
      final srcAbs = File('${tmpDir.path}/$srcRel');
      await srcAbs.parent.create(recursive: true);
      await srcAbs.writeAsString('<svg/>');

      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        switch (idx) {
          case 1:
            // CadImportJobRepository.findById
            return makeResult(_kJobCols, [
              _jobRow(status: 'done', matchedCount: 2, unmatchedSvgs: [
                {'label': 'F1', 'tmp_path': srcRel},
                {'label': '屋顶', 'tmp_path': 'cad/b-1/jobs/job-1/plan_屋顶.svg'},
              ])
            ]);
          case 2:
            // FloorRepository.findById（同楼栋）
            return makeResult(kFloorCols, [floorRow(id: 'f-1', buildingId: 'b-1')]);
          case 3:
            // FloorRepository.createPlan
            return makeResult(kFloorPlanCols, [
              floorPlanRow(id: 'fp-new', floorId: 'f-1', isCurrent: false)
            ]);
          case 4:
            // FloorRepository.setCurrentPlan 内部可能多步：返回空即可
            return makeResult([], []);
          case 5:
            // setCurrentPlan 第二步 / updateAssignments
            return makeResult([], []);
          default:
            // 末尾 repo.findById(jobId) 返回最新状态
            return makeResult(_kJobCols, [
              _jobRow(status: 'done', matchedCount: 3, unmatchedSvgs: [
                {'label': '屋顶', 'tmp_path': 'cad/b-1/jobs/job-1/plan_屋顶.svg'},
              ])
            ]);
        }
      };

      final job = await svc.assignUnmatched(
        'job-1',
        svgLabel: 'F1',
        floorId: 'f-1',
      );

      // 任务返回值反映已指派
      expect(job.matchedCount, 3);
      expect(job.unmatchedSvgs, hasLength(1));
      expect(job.unmatchedSvgs.first.label, '屋顶');

      // SVG 已复制到正式路径
      final dest = File('${tmpDir.path}/floors/b-1/f-1.svg');
      expect(dest.existsSync(), isTrue);
      expect(await dest.readAsString(), '<svg/>');
    });

    test('禁止路径穿越：tmp_path 含 .. 应抛 INVALID_FILE_PATH', () async {
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        if (idx == 1) {
          return makeResult(_kJobCols, [
            _jobRow(status: 'done', unmatchedSvgs: const [
              {'label': 'F1', 'tmp_path': '../../etc/passwd'},
            ])
          ]);
        }
        return makeResult(kFloorCols, [floorRow(buildingId: 'b-1')]);
      };
      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F1', floorId: 'f-1'),
        throwsA(isA<ValidationException>()
            .having((e) => e.code, 'code', 'INVALID_FILE_PATH')),
      );
    });
  });

  // ─── Unit 自动创建（通过 assignUnmatched 触发 _writeAndAttach）──────────

  group('Unit 自动创建', () {
    // setCurrentPlan 内部 SQL 序列（5 步），共享辅助函数：
    //   步骤 N+0: INSERT floor_plans（createPlan）
    //   步骤 N+1: SELECT floor_id FROM floor_plans（setCurrentPlan step1）
    //   步骤 N+2: UPDATE floor_plans is_current=FALSE（setCurrentPlan step2）
    //   步骤 N+3: UPDATE floor_plans is_current=TRUE（setCurrentPlan step3）
    //   步骤 N+4: UPDATE floors（updatePaths）
    //   步骤 N+5: SELECT floor_plans（findPlanById）

    /// setCurrentPlan SELECT floor_plans 返回值（step1 需要 floor_id + svg_path）
    setPlanSelect(String floorId, String svgPath) => makeResult([
          'floor_id',
          'svg_path',
          'png_path'
        ], [
          [floorId, svgPath, null]
        ]);

    test('JSON 含 units → 创建对应 Unit 记录（跳过已存在编号）', () async {
      // ── 准备文件 ──
      final svgRel = 'cad/b-1/jobs/job-1/plan_F11.svg';
      final svgAbs = File('${tmpDir.path}/$svgRel');
      await svgAbs.parent.create(recursive: true);
      await svgAbs.writeAsString('<svg/>');
      final jsonAbs = File('${tmpDir.path}/cad/b-1/jobs/job-1/plan_F11.json');
      await jsonAbs.writeAsString(jsonEncode({
        'dxf_region': {'min_x': 0, 'min_y': 0, 'max_x': 100, 'max_y': 100},
        'viewport': {'width': 1000, 'height': 1000},
        'units': [
          // unit_id 已存在 → 跳过
          {
            'unit_id': '11-01',
            'unit_number': '01',
            'room_name': '产业研发用房',
            'area_m2': 52.01,
            'hotspot': {'type': 'circle', 'cx': 100, 'cy': 200, 'r': 30},
          },
          // 新建
          {
            'unit_id': '11-02',
            'unit_number': '02',
            'room_name': '会议室',
            'area_m2': 30.5,
            'hotspot': {'type': 'circle', 'cx': 200, 'cy': 200, 'r': 30},
          },
          // unit_id 空 → 跳过
          {'unit_id': '', 'unit_number': '', 'room_name': '公共走廊'},
        ],
      }));

      // ── SQL 序列：共 13 步 ──
      // 1  CadImportJobRepository.findById
      // 2  FloorRepository.findById
      // 3  FloorRepository.createPlan (INSERT floor_plans)
      // 4  setCurrentPlan SELECT floor_plans
      // 5  setCurrentPlan UPDATE floor_plans is_current=FALSE
      // 6  setCurrentPlan UPDATE floor_plans is_current=TRUE
      // 7  setCurrentPlan.updatePaths UPDATE floors
      // 8  setCurrentPlan.findPlanById SELECT floor_plans
      // 9  BuildingRepository.findById
      // 10 UnitRepository.findExistingUnitNumbers
      // 11 UnitRepository.create ('11-02')
      // 12 repo.updateAssignments UPDATE cad_import_jobs
      // 13 repo.findById SELECT cad_import_jobs
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        switch (idx) {
          case 1:
            return makeResult(_kJobCols, [
              _jobRow(status: 'done', unmatchedSvgs: [
                {'label': 'F11', 'tmp_path': svgRel},
              ])
            ]);
          case 2:
            return makeResult(kFloorCols, [floorRow(id: 'f-11', buildingId: 'b-1')]);
          case 3:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-11', floorId: 'f-11', isCurrent: false)]);
          case 4:
            return setPlanSelect('f-11', 'floors/b-1/f-11.svg');
          case 5:
          case 6:
          case 7:
            return makeResult([], []);
          case 8:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-11', floorId: 'f-11', isCurrent: true)]);
          case 9:
            return makeResult(kBuildingCols, [buildingRow()]);
          case 10:
            // findExistingUnitNumbers：'11-01' 已存在
            return makeResult([
              'unit_number'
            ], [
              ['11-01']
            ]);
          case 11:
            // UnitRepository.create for '11-02'
            return makeResult(
                kUnitCols, [unitRow(buildingId: 'b-1', floorId: 'f-11', unitNumber: '11-02')]);
          case 12:
            return makeResult([], []);
          default:
            return makeResult(
                _kJobCols, [_jobRow(status: 'done', matchedCount: 1, unmatchedSvgs: [])]);
        }
      };

      final job = await svc.assignUnmatched(
        'job-1',
        svgLabel: 'F11',
        floorId: 'f-11',
      );

      expect(job, isNotNull);
      // SVG 已复制到正式路径
      expect(
        File('${tmpDir.path}/floors/b-1/f-11.svg').existsSync(),
        isTrue,
      );
    });

    test('JSON 无 units 字段 → 静默跳过，不抛异常', () async {
      // 写一个没有 units 字段的 JSON
      final svgRel = 'cad/b-1/jobs/job-1/plan_F12.svg';
      final svgAbs = File('${tmpDir.path}/$svgRel');
      await svgAbs.parent.create(recursive: true);
      await svgAbs.writeAsString('<svg/>');
      await File('${tmpDir.path}/cad/b-1/jobs/job-1/plan_F12.json').writeAsString(jsonEncode({
        'dxf_region': {'min_x': 0, 'min_y': 0, 'max_x': 100, 'max_y': 100},
        'viewport': {'width': 1000, 'height': 1000},
        // 无 units 字段 → 不触发 UnitRepository
      }));

      // SQL 序列：共 10 步（无 BuildingRepo/UnitRepo 调用）
      // 1  CadImportJobRepository.findById
      // 2  FloorRepository.findById
      // 3  FloorRepository.createPlan
      // 4  setCurrentPlan SELECT floor_plans
      // 5-7 setCurrentPlan UPDATEs + updatePaths
      // 8  setCurrentPlan.findPlanById
      // 9  repo.updateAssignments
      // 10 repo.findById
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        switch (idx) {
          case 1:
            return makeResult(_kJobCols, [
              _jobRow(status: 'done', unmatchedSvgs: [
                {'label': 'F12', 'tmp_path': svgRel},
              ])
            ]);
          case 2:
            return makeResult(kFloorCols, [floorRow(id: 'f-12', buildingId: 'b-1')]);
          case 3:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-12', floorId: 'f-12', isCurrent: false)]);
          case 4:
            return setPlanSelect('f-12', 'floors/b-1/f-12.svg');
          case 5:
          case 6:
          case 7:
            return makeResult([], []);
          case 8:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-12', floorId: 'f-12', isCurrent: true)]);
          case 9:
            return makeResult([], []);
          default:
            return makeResult(
                _kJobCols, [_jobRow(status: 'done', matchedCount: 1, unmatchedSvgs: [])]);
        }
      };

      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F12', floorId: 'f-12'),
        completes,
      );
    });

    test('无同名 JSON 文件 → 静默跳过，不抛异常', () async {
      // 只有 SVG，无 JSON 骨架文件
      final svgRel = 'cad/b-1/jobs/job-1/plan_F13.svg';
      final svgAbs = File('${tmpDir.path}/$svgRel');
      await svgAbs.parent.create(recursive: true);
      await svgAbs.writeAsString('<svg/>');
      // 故意不写 plan_F13.json

      // SQL 序列：共 10 步（jsonSiblingFile=null，整个 JSON 块跳过）
      var idx = 0;
      pool.executeHandler = (q, p) {
        idx++;
        switch (idx) {
          case 1:
            return makeResult(_kJobCols, [
              _jobRow(status: 'done', unmatchedSvgs: [
                {'label': 'F13', 'tmp_path': svgRel},
              ])
            ]);
          case 2:
            return makeResult(kFloorCols, [floorRow(id: 'f-13', buildingId: 'b-1')]);
          case 3:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-13', floorId: 'f-13', isCurrent: false)]);
          case 4:
            return setPlanSelect('f-13', 'floors/b-1/f-13.svg');
          case 5:
          case 6:
          case 7:
            return makeResult([], []);
          case 8:
            return makeResult(
                kFloorPlanCols, [floorPlanRow(id: 'fp-13', floorId: 'f-13', isCurrent: true)]);
          case 9:
            return makeResult([], []);
          default:
            return makeResult(
                _kJobCols, [_jobRow(status: 'done', matchedCount: 1, unmatchedSvgs: [])]);
        }
      };

      await expectLater(
        svc.assignUnmatched('job-1', svgLabel: 'F13', floorId: 'f-13'),
        completes,
      );
    });
  });

  // ─── 序列化健康度 ───────────────────────────────────────────────────────

  group('CadImportJob.toJson()', () {
    test('unmatched_svgs 完整序列化为 List<Map>', () async {
      pool.executeHandler = (q, p) => makeResult(_kJobCols, [
            _jobRow(status: 'done', matchedCount: 5, unmatchedSvgs: const [
              {'label': 'F-1', 'tmp_path': 'cad/b-1/jobs/job-1/plan_F-1.svg'},
            ])
          ]);
      final job = await svc.getJob('job-1');
      final json = job.toJson();
      expect(json['status'], 'done');
      expect(json['matched_count'], 5);
      expect(json['unmatched_svgs'], hasLength(1));
      expect(jsonEncode(json['unmatched_svgs']),
          contains('"label":"F-1"'));
    });
  });
}
