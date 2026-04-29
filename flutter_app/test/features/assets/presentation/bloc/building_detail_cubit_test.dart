import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propos_app/core/api/api_exception.dart';
import 'package:propos_app/features/assets/domain/entities/building.dart';
import 'package:propos_app/features/assets/domain/entities/floor.dart';
import 'package:propos_app/features/assets/domain/entities/property_type.dart';
import 'package:propos_app/features/assets/domain/repositories/assets_repository.dart';
import 'package:propos_app/features/assets/presentation/bloc/building_detail_cubit.dart';
import 'package:propos_app/features/assets/presentation/bloc/building_detail_state.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

void main() {
  late MockAssetsRepository mockRepository;

  final testNow = DateTime(2026, 4, 20);

  final testBuilding = Building(
    id: 'bld-001',
    name: 'A座写字楼',
    propertyType: PropertyType.office,
    totalFloors: 25,
    basementFloors: 2,
    gfa: 25000,
    nla: 22000,
    createdAt: testNow,
    updatedAt: testNow,
  );

  final testFloors = [
    Floor(
      id: 'flr-001',
      buildingId: 'bld-001',
      buildingName: 'A座写字楼',
      floorNumber: 10,
      floorName: null,
      svgPath: null,
      createdAt: testNow,
      updatedAt: testNow,
    ),
    Floor(
      id: 'flr-002',
      buildingId: 'bld-001',
      buildingName: 'A座写字楼',
      floorNumber: 11,
      floorName: null,
      svgPath: null,
      createdAt: testNow,
      updatedAt: testNow,
    ),
  ];

  // BuildingDetailCubit 单元测试：验证 fetch(buildingId) 的状态流转
  setUp(() {
    mockRepository = MockAssetsRepository();
  });

  group('BuildingDetailCubit', () {
    test('initial state is BuildingDetailState.initial', () {
      final cubit = BuildingDetailCubit(mockRepository);
      expect(cubit.state, const BuildingDetailState.initial());
      cubit.close();
    });

    // ── fetch ──

    // 楼栋 + 楼层均成功 → loading → loaded
    blocTest<BuildingDetailCubit, BuildingDetailState>(
      'fetch emits [loading, loaded] when both futures succeed',
      build: () {
        when(() => mockRepository.fetchBuilding('bld-001'))
            .thenAnswer((_) async => testBuilding);
        when(() => mockRepository.fetchFloors('bld-001'))
            .thenAnswer((_) async => testFloors);
        return BuildingDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('bld-001'),
      expect: () => [
        const BuildingDetailState.loading(),
        BuildingDetailState.loaded(
          building: testBuilding,
          floors: testFloors,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchBuilding('bld-001')).called(1);
        verify(() => mockRepository.fetchFloors('bld-001')).called(1);
      },
    );

    // fetchBuilding 抛出 ApiException → loading → error
    blocTest<BuildingDetailCubit, BuildingDetailState>(
      'fetch emits [loading, error] when fetchBuilding throws ApiException',
      build: () {
        when(() => mockRepository.fetchBuilding('bld-999')).thenThrow(
          const ApiException(code: 'BUILDING_NOT_FOUND', message: '楼栋不存在', statusCode: 404),
        );
        when(() => mockRepository.fetchFloors('bld-999'))
            .thenAnswer((_) async => []);
        return BuildingDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('bld-999'),
      expect: () => [
        const BuildingDetailState.loading(),
        const BuildingDetailState.error('楼栋不存在'),
      ],
    );

    // 未知异常 → 通用错误消息
    blocTest<BuildingDetailCubit, BuildingDetailState>(
      'fetch emits [loading, error] with fallback message on unknown exception',
      build: () {
        when(() => mockRepository.fetchBuilding('bld-001'))
            .thenThrow(Exception('connection refused'));
        when(() => mockRepository.fetchFloors('bld-001'))
            .thenAnswer((_) async => []);
        return BuildingDetailCubit(mockRepository);
      },
      act: (cubit) => cubit.fetch('bld-001'),
      expect: () => [
        const BuildingDetailState.loading(),
        const BuildingDetailState.error('操作失败，请重试'),
      ],
    );
  });
}
