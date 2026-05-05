import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/assets/data/services/floor_map_cache_service.dart';
import 'package:propos_app/features/assets/domain/entities/floor.dart';
import 'package:propos_app/features/assets/domain/entities/heatmap.dart';
import 'package:propos_app/features/assets/domain/entities/property_type.dart';
import 'package:propos_app/features/assets/domain/entities/unit_status.dart';
import 'package:propos_app/features/assets/domain/repositories/assets_repository.dart';
import 'package:propos_app/features/assets/presentation/bloc/floor_map_cubit.dart';
import 'package:propos_app/features/assets/presentation/bloc/floor_map_state.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

class MockFloorMapCacheService extends Mock implements FloorMapCacheService {}

void main() {
  late MockAssetsRepository mockRepository;
  late MockFloorMapCacheService mockCache;

  final testNow = DateTime(2026, 4, 20);

  final testFloor = Floor(
    id: 'flr-001',
    buildingId: 'bld-001',
    buildingName: 'A座写字楼',
    floorNumber: 12,
    floorName: null,
    svgPath: null,
    createdAt: testNow,
    updatedAt: testNow,
  );

  final testHeatmap = FloorHeatmap(
    floorId: 'flr-001',
    svgPath: null,
    units: [
      HeatmapUnit(
        unitId: 'unit-001',
        unitNumber: 'A-12-01',
        currentStatus: UnitStatus.leased,
        propertyType: PropertyType.office,
        tenantName: '测试租户',
        contractEndDate: DateTime(2027, 6, 30),
      ),
      const HeatmapUnit(
        unitId: 'unit-002',
        unitNumber: 'A-12-02',
        currentStatus: UnitStatus.vacant,
        propertyType: PropertyType.office,
      ),
    ],
  );

  // FloorMapCubit 单元测试：验证 fetch(floorId) 的状态流转
  setUp(() {
    mockRepository = MockAssetsRepository();
    mockCache = MockFloorMapCacheService();
  });

  group('FloorMapCubit', () {
    test('initial state is FloorMapState.initial', () {
      final cubit = FloorMapCubit(mockRepository, mockCache);
      expect(cubit.state, const FloorMapState.initial());
      cubit.close();
    });

    // ── fetch ──

    // 楼层 + 热区均成功 → loading → loaded
    blocTest<FloorMapCubit, FloorMapState>(
      'fetch emits [loading, loaded] when both futures succeed',
      build: () {
        when(() => mockCache.getHeatmap('flr-001')).thenReturn(null);
        when(() => mockRepository.fetchFloor('flr-001'))
            .thenAnswer((_) async => testFloor);
        when(() => mockRepository.fetchFloorHeatmap('flr-001'))
            .thenAnswer((_) async => testHeatmap);
        when(() => mockRepository.fetchFloors('bld-001'))
            .thenAnswer((_) async => []);
        return FloorMapCubit(mockRepository, mockCache);
      },
      act: (cubit) => cubit.fetch('flr-001'),
      expect: () => [
        const FloorMapState.loading(),
        FloorMapState.loaded(floor: testFloor, heatmap: testHeatmap),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchFloor('flr-001')).called(1);
        verify(() => mockRepository.fetchFloorHeatmap('flr-001')).called(1);
      },
    );

    // fetchFloor 抛出 ApiException → loading → error
    blocTest<FloorMapCubit, FloorMapState>(
      'fetch emits [loading, error] when fetchFloor throws ApiException',
      build: () {
        when(() => mockCache.getHeatmap('flr-999')).thenReturn(null);
        when(() => mockRepository.fetchFloor('flr-999')).thenThrow(
          const ApiException(code: 'FLOOR_NOT_FOUND', message: '楼层不存在', statusCode: 404),
        );
        when(() => mockRepository.fetchFloorHeatmap('flr-999'))
            .thenAnswer((_) async => const FloorHeatmap(
                  floorId: 'flr-999',
                  units: [],
                ));
        return FloorMapCubit(mockRepository, mockCache);
      },
      act: (cubit) => cubit.fetch('flr-999'),
      expect: () => [
        const FloorMapState.loading(),
        const FloorMapState.error('楼层不存在'),
      ],
    );

    // 未知异常 → 通用错误消息
    blocTest<FloorMapCubit, FloorMapState>(
      'fetch emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockCache.getHeatmap('flr-001')).thenReturn(null);
        when(() => mockRepository.fetchFloor('flr-001'))
            .thenThrow(Exception('timeout'));
        when(() => mockRepository.fetchFloorHeatmap('flr-001'))
            .thenAnswer((_) async => const FloorHeatmap(
                  floorId: 'flr-001',
                  units: [],
                ));
        return FloorMapCubit(mockRepository, mockCache);
      },
      act: (cubit) => cubit.fetch('flr-001'),
      expect: () => [
        const FloorMapState.loading(),
        const FloorMapState.error('操作失败，请重试'),
      ],
    );
  });
}
