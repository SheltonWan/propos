import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../shared/bloc/paginated_state.dart';
import '../../../../shared/widgets/status_tag.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_status.dart';
import '../bloc/unit_list_cubit.dart';

/// 房源列表页（子页面，含独立 Scaffold）。
///
/// 布局：筛选条件 Chip 行 + 分页列表（下拉刷新 + 无限滚动加载更多）。
class UnitListPage extends StatelessWidget {
  /// 可选预设楼栋 ID 过滤（从楼栋详情页进入时传入）
  final String? buildingId;

  const UnitListPage({super.key, this.buildingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('房源列表'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(),
          const Divider(height: 1),
          Expanded(child: _UnitListBody()),
        ],
      ),
    );
  }
}

/// 筛选条件栏：业态 + 状态 + 清空。
class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UnitListCubit>();
    return BlocBuilder<UnitListCubit, PaginatedState<UnitSummary>>(
      builder: (context, _) {
        final filterType = cubit.filterPropertyType;
        final filterStatus = cubit.filterStatus;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 业态筛选
              for (final type in PropertyType.values)
                if (type != PropertyType.mixed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: filterType == type,
                      onSelected: (_) => cubit.applyFilters(
                        propertyType: filterType == type ? null : type,
                        status: filterStatus,
                      ),
                    ),
                  ),
              const SizedBox(width: 4),
              const VerticalDivider(width: 16),
              const SizedBox(width: 4),
              // 状态筛选
              for (final st in UnitStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(st.label),
                    selected: filterStatus == st,
                    onSelected: (_) => cubit.applyFilters(
                      propertyType: filterType,
                      status: filterStatus == st ? null : st,
                    ),
                  ),
                ),
              // 清空按钮
              if (filterType != null || filterStatus != null) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('清空'),
                  avatar: const Icon(CupertinoIcons.xmark, size: 14),
                  onPressed: () => cubit.applyFilters(clearFilters: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 列表主体：下拉刷新 + 无限滚动。
class _UnitListBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitListCubit, PaginatedState<UnitSummary>>(
      builder: (context, state) => switch (state) {
        PaginatedInitial<UnitSummary>() => const Center(
            child: CupertinoActivityIndicator(),
          ),
        PaginatedLoading<UnitSummary>() => const Center(
            child: CupertinoActivityIndicator(),
          ),
        PaginatedError<UnitSummary>(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message,
                    style: TextStyle(
                        color: Theme.of(context)
                            .extension<CustomColors>()!
                            .danger)),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: () => context.read<UnitListCubit>().load(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        PaginatedLoaded<UnitSummary>(:final items, :final meta) =>
          RefreshIndicator(
            onRefresh: () => context.read<UnitListCubit>().refresh(),
            child: items.isEmpty
                ? const Center(child: Text('暂无匹配的房源'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      // 滚动到底部 80px 内时触发加载更多
                      if (n is ScrollEndNotification &&
                          meta.hasMore &&
                          n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 80) {
                        context.read<UnitListCubit>().loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length + (meta.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          // 底部加载指示器
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CupertinoActivityIndicator()),
                          );
                        }
                        return _UnitListTile(unit: items[index]);
                      },
                    ),
                  ),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

/// 单条房源列表项。
class _UnitListTile extends StatelessWidget {
  final UnitSummary unit;

  const _UnitListTile({required this.unit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusStr = switch (unit.currentStatus) {
      UnitStatus.leased => 'leased',
      UnitStatus.vacant => 'vacant',
      UnitStatus.expiringSoon => 'expiring_soon',
      UnitStatus.nonLeasable => 'non_leasable',
    };
    return CupertinoListTile(
      title: Text(unit.unitNumber,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${unit.buildingName}${unit.floorName != null ? " · ${unit.floorName}" : ""}'
        '${unit.grossArea != null ? " · ${unit.grossArea!.toStringAsFixed(0)}m²" : ""}',
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusTag(status: statusStr),
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_forward,
              size: 14, color: scheme.outline),
        ],
      ),
      onTap: () => context.push(
        RoutePaths.unitDetail.replaceAll(':id', unit.id),
      ),
    );
  }
}
