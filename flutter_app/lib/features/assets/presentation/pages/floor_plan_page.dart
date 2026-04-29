import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../shared/widgets/status_tag.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/entities/unit_status.dart';
import '../bloc/floor_map_cubit.dart';
import '../bloc/floor_map_state.dart';

/// 楼层平面图页（子页面，含独立 Scaffold）。
///
/// 当楼层有 SVG/PNG 时用 InteractiveViewer + Image.network 展示；
/// 否则展示房源状态网格列表（备用方案）。
///
/// TODO(dev): 当 CAD 转换流水线就绪后，升级为 webview_flutter 渲染 SVG 热区。
class FloorPlanPage extends StatefulWidget {
  final String buildingId;
  final String floorId;

  const FloorPlanPage({
    super.key,
    required this.buildingId,
    required this.floorId,
  });

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  HeatmapUnit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    context.read<FloorMapCubit>().fetch(widget.floorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('楼层热区图'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<FloorMapCubit, FloorMapState>(
        builder: (context, state) => switch (state) {
          FloorMapStateInitial() || FloorMapStateLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
          FloorMapStateError(:final message) => Center(
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
                        context.read<FloorMapCubit>().fetch(widget.floorId),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          FloorMapStateLoaded(heatmap: final heatmap) =>
            _buildContent(context, heatmap),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FloorHeatmap heatmap) {
    return Column(
      children: [
        Expanded(
          child: heatmap.svgPath != null
              ? _FloorImageViewer(
                  imagePath: heatmap.svgPath!,
                  units: heatmap.units,
                  onUnitTap: (unit) => setState(() {
                    _selectedUnit = unit;
                    _showUnitBottomSheet(context, unit);
                  }),
                )
              : _UnitGrid(
                  units: heatmap.units,
                  selectedUnit: _selectedUnit,
                  onUnitTap: (unit) => setState(() {
                    _selectedUnit = unit;
                    _showUnitBottomSheet(context, unit);
                  }),
                ),
        ),
        _LegendBar(),
      ],
    );
  }

  void _showUnitBottomSheet(BuildContext context, HeatmapUnit unit) {
    final statusStr = unit.currentStatus.name == 'expiringSoon'
        ? 'expiring_soon'
        : unit.currentStatus.name;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.38,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // 拖动指示条
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 单元号 + 状态标签
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        unit.unitNumber,
                        style: CupertinoTheme.of(
                          ctx,
                        ).textTheme.navTitleTextStyle,
                      ),
                    ),
                    StatusTag(status: statusStr),
                  ],
                ),
              ),
              if (unit.tenantName != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '租户：',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        unit.tenantName!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              if (unit.contractEndDate != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '到期日：',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(unit.contractEndDate!.toLocal()),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // 查看详情按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: CupertinoButton.filled(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final path = RoutePaths.unitDetail.replaceAll(
                      ':id',
                      unit.unitId,
                    );
                    context.push(path);
                  },
                  child: const Text('查看详情'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图片平面图（有 SVG/PNG 路径时使用）。
///
/// 在图片上叠加透明可点击热区（mock Rect 坐标），
/// 实际生产中坐标来自 SVG `<rect data-unit-id="...">` 属性解析。
class _FloorImageViewer extends StatelessWidget {
  final String imagePath;

  /// 热区单元列表（用于叠加点击层）。
  final List<HeatmapUnit> units;

  /// 选中某个单元的回调。
  final void Function(HeatmapUnit) onUnitTap;

  const _FloorImageViewer({
    required this.imagePath,
    required this.units,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) => InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Image.network(
                    imagePath,
                    width: constraints.maxWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('平面图加载失败，请检查网络连接'),
                    ),
                  ),
                  // 热区覆盖层（mock 矩形坐标均匀分布）
                  ..._buildHotspots(constraints.maxWidth, constraints.maxHeight),
                ],
              );
            },
          ),
        ),
      );

  /// 生成 mock 矩形热区列表。
  ///
  /// 按网格均匀排布，每行最多 4 列。实际生产应从 SVG 解析坐标。
  List<Widget> _buildHotspots(double w, double h) {
    const cols = 4;
    const cellW = 0.22;
    const cellH = 0.15;
    const colGap = 0.02;
    const rowGap = 0.02;
    const startX = 0.03;
    const startY = 0.05;

    return List.generate(units.length, (i) {
      final col = i % cols;
      final row = i ~/ cols;
      final left = (startX + col * (cellW + colGap)) * w;
      final top = (startY + row * (cellH + rowGap)) * h;
      final width = cellW * w;
      final height = cellH * h;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: () => onUnitTap(units[i]),
          // 透明热区，不遮挡图片视觉内容
          child: Container(
            color: Colors.transparent,
          ),
        ),
      );
    });
  }
}

/// 状态色例 Legend 条。
class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const Row(
        children: [
          _LegendItem(status: UnitStatus.leased),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.vacant),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.expiringSoon),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.nonLeasable),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final UnitStatus status;

  const _LegendItem({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final color = switch (status) {
      UnitStatus.leased => colors.success,
      UnitStatus.expiringSoon => colors.warning,
      UnitStatus.vacant => colors.danger,
      UnitStatus.nonLeasable => colors.neutral,
    };
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(status.label,
            style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// 房源状态网格（无平面图时的备用方案）。
class _UnitGrid extends StatelessWidget {
  final List<HeatmapUnit> units;
  final HeatmapUnit? selectedUnit;
  final void Function(HeatmapUnit) onUnitTap;

  const _UnitGrid({
    required this.units,
    required this.selectedUnit,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final color = switch (unit.currentStatus) {
          UnitStatus.leased => colors.success,
          UnitStatus.expiringSoon => colors.warning,
          UnitStatus.vacant => colors.danger,
          UnitStatus.nonLeasable => colors.neutral,
        };
        final isSelected = selectedUnit?.unitId == unit.unitId;
        return GestureDetector(
          onTap: () => onUnitTap(unit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    unit.unitNumber,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color),
                    textAlign: TextAlign.center,
                  ),
                  if (unit.tenantName != null)
                    Text(
                      unit.tenantName!,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
