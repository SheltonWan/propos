import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';
import '../../domain/entities/property_type.dart';
import '../bloc/building_detail_cubit.dart';
import '../bloc/building_detail_state.dart';

/// 楼栋详情页（子页面，含独立 Scaffold + CupertinoNavigationBar）。
///
/// 布局对标前端原型 BuildingFloors.tsx：
/// - 楼栋名称 + 业态 Badge 头部
/// - 三列汇总卡片（楼层数 / GFA / NLA）
/// - 楼层列表（含左侧强调色条，点击进入平面图）
class BuildingDetailPage extends StatefulWidget {
  final String buildingId;

  const BuildingDetailPage({super.key, required this.buildingId});

  @override
  State<BuildingDetailPage> createState() => _BuildingDetailPageState();
}

class _BuildingDetailPageState extends State<BuildingDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<BuildingDetailCubit>().fetch(widget.buildingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('楼栋详情'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<BuildingDetailCubit, BuildingDetailState>(
        builder: (context, state) => switch (state) {
          BuildingDetailStateInitial() || BuildingDetailStateLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
          BuildingDetailStateError(:final message) => Center(
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
                        context.read<BuildingDetailCubit>().fetch(widget.buildingId),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          BuildingDetailStateLoaded(:final building, :final floors) =>
            _buildContent(context, building, floors),
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Building building,
    List<Floor> floors,
  ) {
    // 楼层按层号倒序（高层在上）
    final sorted = [...floors]
      ..sort((a, b) => b.floorNumber.compareTo(a.floorNumber));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _BuildingInfoCard(building: building)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _accentColor(context, building.propertyType),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '楼层索引',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '点击楼层查看平面图',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) => _FloorRow(
              floor: sorted[index],
              buildingId: building.id,
              accentColor: _accentColor(context, building.propertyType),
            ),
          ),
        ),
      ],
    );
  }

  /// 楼栋业态强调色（与 assets_page 保持一致）。
  Color _accentColor(BuildContext context, PropertyType type) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    return switch (type) {
      PropertyType.office => scheme.primary,
      PropertyType.retail => colors.warning,
      PropertyType.apartment => const Color(0xFF0EA5E9),
      PropertyType.mixed => scheme.secondary,
    };
  }
}

/// 楼栋三列汇总卡片（总楼层 / GFA / NLA）。
///
/// 对标前端原型 BuildingFloors.tsx Summary card。
class _BuildingInfoCard extends StatelessWidget {
  final Building building;

  const _BuildingInfoCard({required this.building});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    final accentColor = switch (building.propertyType) {
      PropertyType.office => scheme.primary,
      PropertyType.retail => colors.warning,
      PropertyType.apartment => const Color(0xFF0EA5E9),
      PropertyType.mixed => scheme.secondary,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 楼栋名称 + 地址
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (building.address != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(CupertinoIcons.location,
                              size: 11,
                              color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              building.address!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 业态标签
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  building.propertyType.label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 三列统计格
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _SummaryCell(
                  label: '总楼层',
                  value: '${building.totalFloors}',
                  unit: '层',
                ),
                _SummaryCellDivider(),
                _SummaryCell(
                  label: '建筑面积',
                  value: (building.gfa / 1000).toStringAsFixed(1),
                  unit: 'k㎡',
                  valueColor: accentColor,
                ),
                _SummaryCellDivider(),
                _SummaryCell(
                  label: '净使用面积',
                  value: (building.nla / 1000).toStringAsFixed(1),
                  unit: 'k㎡',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 总览卡片内三列统计格。
class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _SummaryCell({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
          Text(unit,
              style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// 总览卡片竖分割线。
class _SummaryCellDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.5),
      );
}

/// 单行楼层条目，左侧含业态强调色条，点击跳转楼层平面图页。
class _FloorRow extends StatelessWidget {
  final Floor floor;
  final String buildingId;
  final Color accentColor;

  const _FloorRow({
    required this.floor,
    required this.buildingId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        final path = RoutePaths.floorPlan
            .replaceAll(':bid', buildingId)
            .replaceAll(':fid', floor.id);
        context.push(path);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // 左侧强调色条
            Container(
              width: 4,
              height: 56,
              color: accentColor,
            ),
            const SizedBox(width: 12),
            // 层号
            SizedBox(
              width: 44,
              child: Text(
                floor.displayName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            // NLA 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (floor.nla != null)
                    Text(
                      'NLA ${floor.nla!.toStringAsFixed(0)} m²',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant),
                    ),
                  if (floor.svgPath != null || floor.pngPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '含平面图',
                          style: TextStyle(
                              fontSize: 9,
                              color: accentColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 15,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// 楼栋详情页（子页面，含独立 Scaffold + CupertinoNavigationBar）。
