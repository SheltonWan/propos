import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/assets/domain/entities/property_type.dart';
import 'package:propos_app/features/assets/domain/entities/renovation.dart';
import 'package:propos_app/features/assets/domain/entities/unit.dart';
import 'package:propos_app/features/assets/domain/entities/unit_status.dart';
import 'package:propos_app/features/assets/domain/repositories/assets_repository.dart';
import 'package:propos_app/features/assets/presentation/bloc/unit_detail_cubit.dart';
import 'package:propos_app/features/assets/presentation/bloc/unit_detail_state.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

void main() {
  late MockAssetsRepository mockRepository;

  final testNow = DateTime(2026, 4, 20);

  final testUnit = UnitDetail(
    id: 'unit-001',
    buildingId: 'bld-001',
    buildingName: 'A座写字楼',
    floorId: 'flr-001',
    floorName: '12F',
    unitNumber: 'A-12-01',
    propertyType: PropertyType.office,
    grossArea: 135.0,
    netArea: 122.0,
    orientation: '南',
    ceilingHeight: 2.8,
    decorationStatus: DecorationStatus.refined,
    currentStatus: UnitStatus.leased,
    isLeasable: true,
    marketRentReference: 120.0,
    createdAt: testNow,
    updatedAt: testNow,
  );

  final testRenovations = [
    RenovationSummary(
      id: 'ren-001',
      unitId: 'unit-001',
      unitNumber: 'A-12-01',
      renovationType: '隔墙改造',
      startedAt: DateTime(2024, 3, 1),
      completedAt: DateTime(2024, 4, 15),
      cost: 85000,
      contractor: '某装修公司',
      createdAt: testNow,
    ),
  ];

  // UnitDetailCubit 单元测试：验证 fetch(unitId) 的状态流转
  setUp(() {
    mockRepository = MockAssetsRepository();
  });

  group('UnitDetailCubit', () {
    test('initial state is UnitDetailState.initial', () {
      final cubit = UnitDetailCubit(mockRepository);
      expect(cubit.state, const UnitDetailState.initial());
      cubit.close();
    });

    // ── fetch ──

    // 房源 + 改造记录均成功 → loading → loaded
    blocTest<UnitDetailCubit, UnitDetailState>(
      'fetch emits [loading, loaded] when both futures succeed',
      build: () {
        when(() => mockRepository.fetchUnit('unit-001'))
            .thenAnswer((_) async => testUnit);
        when(() => mockRepository.fetchRenovations('unit-001'))
            .thenAnswer((_) async => testRenovations);
        return UnitDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('unit-001'),
      expect: () => [
        const UnitDetailState.loading(),
        UnitDetailState.loaded(
          unit: testUnit,
          renovations: testRenovations,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchUnit('unit-001')).called(1);
        verify(() => mockRepository.fetchRenovations('unit-001')).called(1);
      },
    );

    // loaded 时改造记录可为空列表
    blocTest<UnitDetailCubit, UnitDetailState>(
      'fetch emits [loading, loaded] with empty renovations',
      build: () {
        when(() => mockRepository.fetchUnit('unit-002'))
            .thenAnswer((_) async => testUnit.copyWith(id: 'unit-002'));
        when(() => mockRepository.fetchRenovations('unit-002'))
            .thenAnswer((_) async => []);
        return UnitDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('unit-002'),
      expect: () => [
        const UnitDetailState.loading(),
        UnitDetailState.loaded(
          unit: testUnit.copyWith(id: 'unit-002'),
          renovations: const [],
        ),
      ],
    );

    // fetchUnit 抛出 ApiException → loading → error（透传 message）
    blocTest<UnitDetailCubit, UnitDetailState>(
      'fetch emits [loading, error] when fetchUnit throws ApiException',
      build: () {
        when(() => mockRepository.fetchUnit('unit-999')).thenThrow(
          const ApiException(code: 'UNIT_NOT_FOUND', message: '房源不存在', statusCode: 404),
        );
        when(() => mockRepository.fetchRenovations('unit-999'))
            .thenAnswer((_) async => []);
        return UnitDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('unit-999'),
      expect: () => [
        const UnitDetailState.loading(),
        const UnitDetailState.error('房源不存在'),
      ],
    );

    // 未知异常 → 通用错误消息
    blocTest<UnitDetailCubit, UnitDetailState>(
      'fetch emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockRepository.fetchUnit('unit-001'))
            .thenThrow(Exception('server unavailable'));
        when(() => mockRepository.fetchRenovations('unit-001'))
            .thenAnswer((_) async => []);
        return UnitDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('unit-001'),
      expect: () => [
        const UnitDetailState.loading(),
        const UnitDetailState.error('操作失败，请重试'),
      ],
    );
  });
}
