import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/core/api/api_list_response.dart';
import 'package:propos_app/features/assets/domain/entities/asset_overview.dart';
import 'package:propos_app/features/assets/domain/entities/building.dart';
import 'package:propos_app/features/assets/domain/entities/property_type.dart';
import 'package:propos_app/features/assets/domain/repositories/assets_repository.dart';
import 'package:propos_app/features/assets/presentation/bloc/asset_overview_cubit.dart';
import 'package:propos_app/features/assets/presentation/bloc/asset_overview_state.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

void main() {
  late MockAssetsRepository mockRepository;

  final testNow = DateTime(2026, 4, 20);

  final testOverview = AssetOverview(
    totalUnits: 639,
    totalLeasableUnits: 600,
    totalOccupancyRate: 0.88,
    waleIncomeWeighted: 3.5,
    waleAreaWeighted: 3.2,
    byPropertyType: [
      PropertyTypeStats(
        propertyType: PropertyType.office,
        totalUnits: 200,
        leasedUnits: 180,
        vacantUnits: 20,
        expiringSoonUnits: 10,
        occupancyRate: 0.9,
        totalNla: 12000,
        leasedNla: 10800,
      ),
    ],
  );

  final testBuildings = [
    Building(
      id: 'bld-001',
      name: 'A座写字楼',
      propertyType: PropertyType.office,
      totalFloors: 25,
      basementFloors: 2,
      gfa: 25000,
      nla: 22000,
      createdAt: testNow,
      updatedAt: testNow,
    ),
  ];

  // AssetOverviewCubit 单元测试：验证 fetch() 的状态流转
  setUp(() {
    mockRepository = MockAssetsRepository();
  });

  group('AssetOverviewCubit', () {
    // 初始状态应为 initial
    test('initial state is AssetOverviewState.initial', () {
      final cubit = AssetOverviewCubit(mockRepository);
      expect(cubit.state, const AssetOverviewState.initial());
      cubit.close();
    });

    // ── fetch ──

    // 两个 Future 均成功 → loading → loaded（overview + buildings）
    blocTest<AssetOverviewCubit, AssetOverviewState>(
      'fetch emits [loading, loaded] when both futures succeed',
      build: () {
        when(() => mockRepository.fetchOverview())
            .thenAnswer((_) async => testOverview);
        when(() => mockRepository.fetchBuildings())
            .thenAnswer((_) async => testBuildings);
        return AssetOverviewCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch(),
      expect: () => [
        const AssetOverviewState.loading(),
        AssetOverviewState.loaded(
          overview: testOverview,
          buildings: testBuildings,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchOverview()).called(1);
        verify(() => mockRepository.fetchBuildings()).called(1);
      },
    );

    // fetchOverview 抛出 ApiException → loading → error（透传 message）
    blocTest<AssetOverviewCubit, AssetOverviewState>(
      'fetch emits [loading, error] when fetchOverview throws ApiException',
      build: () {
        when(() => mockRepository.fetchOverview()).thenThrow(
          const ApiException(code: 'INTERNAL_ERROR', message: '服务器错误', statusCode: 500),
        );
        when(() => mockRepository.fetchBuildings())
            .thenAnswer((_) async => []);
        return AssetOverviewCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch(),
      expect: () => [
        const AssetOverviewState.loading(),
        const AssetOverviewState.error('服务器错误'),
      ],
    );

    // 抛出未知异常 → 错误消息降级为通用文案
    blocTest<AssetOverviewCubit, AssetOverviewState>(
      'fetch emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockRepository.fetchOverview())
            .thenThrow(Exception('network timeout'));
        when(() => mockRepository.fetchBuildings())
            .thenAnswer((_) async => []);
        return AssetOverviewCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch(),
      expect: () => [
        const AssetOverviewState.loading(),
        const AssetOverviewState.error('操作失败，请重试'),
      ],
    );
  });
}
