import '../../../../core/api/api_list_response.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../shared/bloc/paginated_cubit.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_status.dart';
import '../../domain/repositories/assets_repository.dart';

/// 房源列表 Cubit，继承 [PaginatedCubit]。
///
/// 支持按业态 / 出租状态 / 楼栋三维过滤，过滤条件变更时调用 [applyFilters] 重载第1页。
class UnitListCubit extends PaginatedCubit<UnitSummary> {
  final AssetsRepository _repository;

  PropertyType? _filterPropertyType;
  UnitStatus? _filterStatus;
  String? _filterBuildingId;

  UnitListCubit(this._repository);

  @override
  Future<ApiListResponse<UnitSummary>> fetchPage(
      int page, int pageSize) async {
    final result = await _repository.fetchUnits(
      page: page,
      pageSize: pageSize,
      propertyType: _filterPropertyType,
      status: _filterStatus,
      buildingId: _filterBuildingId,
    );
    return ApiListResponse(
      items: result.items,
      meta: PaginationMeta(
        page: page,
        pageSize: pageSize,
        total: result.total,
      ),
    );
  }

  /// 更新过滤条件并从第1页重新加载。
  Future<void> applyFilters({
    PropertyType? propertyType,
    UnitStatus? status,
    String? buildingId,
    bool clearFilters = false,
  }) async {
    if (clearFilters) {
      _filterPropertyType = null;
      _filterStatus = null;
      _filterBuildingId = null;
    } else {
      _filterPropertyType = propertyType;
      _filterStatus = status;
      _filterBuildingId = buildingId;
    }
    await load(pageSize: UiConstants.defaultPageSize);
  }

  /// 当前激活的过滤条件（供 UI 层展示筛选态）。
  PropertyType? get filterPropertyType => _filterPropertyType;
  UnitStatus? get filterStatus => _filterStatus;
  String? get filterBuildingId => _filterBuildingId;
}
