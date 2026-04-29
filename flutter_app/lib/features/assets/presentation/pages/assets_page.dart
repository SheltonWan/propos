import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../shared/widgets/status_tag.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/property_type.dart';
import '../bloc/asset_overview_cubit.dart';
import '../bloc/asset_overview_state.dart';
import '../widgets/property_type_stat_card.dart';

/// 资产概览页（Tab 页，无独立 Scaffold，由 MainShell 提供外壳）。
///
/// 布局对齐 PAGE_SPEC_FLUTTER v1.9 §3.1 AssetsPage：
/// - 深色头部卡片（总体出租率 + WALE）
/// - 三业态统计卡片横排
/// - 业态筛选 Chip 行
/// - 楼栋列表
class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  /// 当前选中的业态过滤器（null = 全部）
  PropertyType? _selectedType;

  @override
  void initState() {
    super.initState();
    context.read<AssetOverviewCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetOverviewCubit, AssetOverviewState>(
      builder: (context, state) => switch (state) {
        AssetOverviewStateInitial() || AssetOverviewStateLoading() => const Center(
            child: CupertinoActivityIndicator(),
          ),
        AssetOverviewStateError(:final message) => Center(
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
                  onPressed: () =>
                      context.read<AssetOverviewCubit>().fetch(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        AssetOverviewStateLoaded(:final overview, :final buildings) =>
          _buildContent(context, overview, buildings),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssetOverview overview,
    List<Building> buildings,
  ) {
    final filtered = _selectedType == null
        ? buildings
        : buildings.where((b) => b.propertyType == _selectedType).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _SummaryHeader(overview: overview)),
        SliverToBoxAdapter(
          child: _PropertyTypeStatsRow(stats: overview.byPropertyType),
        ),
        SliverToBoxAdapter(
          child: _FilterChipRow(
            selected: _selectedType,
            onSelected: (t) => setState(() => _selectedType = t),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _BuildingCard(building: filtered[index]),
          ),
        ),
      ],
    );
  }
}

/// 深色汇总头部卡片。
class _SummaryHeader extends StatelessWidget {
  final AssetOverview overview;

  const _SummaryHeader({required this.overview});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: colors.dashboardHeaderBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '资产总览',
            style: TextStyle(
              color: colors.onDashboardHeader.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: '出租率',
                  value:
                      '${(overview.totalOccupancyRate * 100).toStringAsFixed(1)}%',
                  color: colors.onDashboardHeader,
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  label: 'WALE（收入）',
                  value: '${overview.waleIncomeWeighted.toStringAsFixed(1)}年',
                  color: colors.onDashboardHeader,
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  label: '总房源',
                  value: '${overview.totalUnits}套',
                  color: colors.onDashboardHeader,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.6), fontSize: 12)),
        ],
      );
}

/// 三业态统计卡片横排。
class _PropertyTypeStatsRow extends StatelessWidget {
  final List<PropertyTypeStats> stats;

  const _PropertyTypeStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 106,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) =>
              PropertyTypeStatCard(stat: stats[index]),
        ),
      );
}

/// 业态筛选 Chip 行。
class _FilterChipRow extends StatelessWidget {
  final PropertyType? selected;
  final void Function(PropertyType?) onSelected;

  const _FilterChipRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final types = [null, ...PropertyType.values.where((t) => t != PropertyType.mixed)];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final label = type?.label ?? '全部';
          final isSelected = selected == type;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(type),
            selectedColor: scheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

/// 楼栋卡片。
class _BuildingCard extends StatelessWidget {
  final Building building;

  const _BuildingCard({required this.building});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        final path = RoutePaths.buildingDetail
            .replaceAll(':id', building.id);
        context.push(path);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    building.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${building.totalFloors}层  GFA ${building.gfa.toStringAsFixed(0)} m²',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusTag(status: 'active', label: building.propertyType.label),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right,
                size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
