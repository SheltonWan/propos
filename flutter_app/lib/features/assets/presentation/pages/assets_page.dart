import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/property_type.dart';
import '../bloc/asset_overview_cubit.dart';
import '../bloc/asset_overview_state.dart';
import '../widgets/property_type_stat_card.dart';

/// 资产概览页（Tab 页，无独立 Scaffold，由 MainShell 提供外壳）。
///
/// 布局对齐前端原型 Assets.tsx：
/// - 深色总览头部卡片（总 NLA / 总套数 / 空置套数 / 楼栋数）
/// - 三业态统计卡片横排（可点击过滤）
/// - 业态筛选 Chip 行
/// - 楼栋列表（含出租率进度条）
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
        // 深色总览卡片
        SliverToBoxAdapter(
          child: _OverviewSummaryCard(
            overview: overview,
            buildingCount: buildings.length,
          ),
        ),
        // 三业态统计卡片
        SliverToBoxAdapter(
          child: _PropertyTypeStatsRow(
            stats: overview.byPropertyType,
            onTypeSelected: (t) => setState(() => _selectedType = t),
          ),
        ),
        // 业态筛选 Chip
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

/// 深色总览卡片：展示管理总 NLA / 总套数 / 空置套数 / 楼栋数。
///
/// 对标前端原型 Assets.tsx Overview Stats 区块。
class _OverviewSummaryCard extends StatelessWidget {
  final AssetOverview overview;
  final int buildingCount;

  const _OverviewSummaryCard({
    required this.overview,
    required this.buildingCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    // 从各业态汇总 totalNla
    final totalNla = overview.byPropertyType
        .fold<double>(0.0, (sum, s) => sum + s.totalNla);
    // 空置套数 = 各业态 vacantUnits 之和
    final vacantUnits = overview.byPropertyType
        .fold<int>(0, (sum, s) => sum + s.vacantUnits);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.dashboardHeaderBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.dashboardHeaderBg.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 水印图标
            Positioned(
              right: -8,
              top: -8,
              child: Icon(
                CupertinoIcons.building_2_fill,
                size: 88,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总 NLA 大数字
                Text(
                  '管理总面积（㎡）',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalNla >= 10000
                      ? '${(totalNla / 10000).toStringAsFixed(1)}万'
                      : totalNla.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 三列统计小格
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _StatCell(
                        label: '总套数',
                        value: '${overview.totalUnits}',
                        unit: '套',
                      ),
                      _VerticalDivider(),
                      _StatCell(
                        label: '空置套数',
                        value: '$vacantUnits',
                        unit: '套',
                        valueColor: vacantUnits > 0
                            ? colors.warning
                            : Colors.white,
                      ),
                      _VerticalDivider(),
                      _StatCell(
                        label: '楼栋数',
                        value: '$buildingCount',
                        unit: '栋',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 总览卡片内的单格统计数字。
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// 总览卡片内的竖向分割线。
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.2),
      );
}

/// 三业态统计卡片横排（可点击以切换筛选）。
class _PropertyTypeStatsRow extends StatelessWidget {
  final List<PropertyTypeStats> stats;
  final void Function(PropertyType?) onTypeSelected;

  const _PropertyTypeStatsRow({
    required this.stats,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => onTypeSelected(stats[index].propertyType),
            child: PropertyTypeStatCard(stat: stats[index]),
          ),
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

/// 楼栋卡片（对标前端原型 BuildingCard）。
///
/// 展示楼栋名称、业态标签、地址、GFA/NLA/层数信息标签。
class _BuildingCard extends StatelessWidget {
  final Building building;

  const _BuildingCard({required this.building});

  /// 业态对应的强调色。
  Color _accentColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    return switch (building.propertyType) {
      PropertyType.office => scheme.primary,
      PropertyType.retail => colors.warning,
      PropertyType.apartment => const Color(0xFF0EA5E9),
      PropertyType.mixed => scheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(context);

    return GestureDetector(
      onTap: () {
        final path = RoutePaths.buildingDetail
            .replaceAll(':id', building.id);
        context.push(path);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 上半区：色块图标 + 楼栋信息 ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 业态色块
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.building_2_fill,
                            size: 26, color: accent),
                        const SizedBox(height: 4),
                        Text(
                          '${building.totalFloors}层',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 楼栋名称 + 业态标签 + 地址
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                building.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 业态标签
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                building.propertyType.label,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 地址（有则显示）
                        if (building.address != null) ...[
                          Row(
                            children: [
                              Icon(CupertinoIcons.location,
                                  size: 11,
                                  color: scheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  building.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ] else
                          const SizedBox(height: 8),
                        // GFA / NLA 小标签行
                        Wrap(
                          spacing: 6,
                          children: [
                            _MiniChip(
                                label:
                                    'GFA ${(building.gfa / 1000).toStringAsFixed(1)}k㎡'),
                            _MiniChip(
                                label:
                                    'NLA ${(building.nla / 1000).toStringAsFixed(1)}k㎡'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── 下半区：指标格 ─────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    _MetricCell(label: '楼层数',
                        value: '${building.totalFloors}',
                        unit: '层'),
                    _MetricDivider(),
                    _MetricCell(
                      label: '建筑面积',
                      value: (building.gfa / 1000).toStringAsFixed(1),
                      unit: 'k㎡',
                    ),
                    _MetricDivider(),
                    _MetricCell(
                      label: '净使用面积',
                      value: (building.nla / 1000).toStringAsFixed(1),
                      unit: 'k㎡',
                    ),
                    const Spacer(),
                    Icon(CupertinoIcons.chevron_right,
                        size: 14,
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 楼栋卡片底部指标格。
class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 楼栋卡片指标格间的竖分割线。
class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      );
}

/// GFA / NLA 小标签。
class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
