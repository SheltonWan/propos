import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
        middle: const Text('楼层平面图'),
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
    return Stack(
      children: [
        Column(
          children: [
            _LegendBar(),
            Expanded(
              child: heatmap.svgPath != null
                  ? _FloorImageViewer(imagePath: heatmap.svgPath!)
                  : _UnitGrid(
                      units: heatmap.units,
                      selectedUnit: _selectedUnit,
                      onUnitTap: (unit) => setState(() {
                        _selectedUnit = unit;
                        _showUnitBottomSheet(context, unit);
                      }),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUnitBottomSheet(BuildContext context, HeatmapUnit unit) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(unit.unitNumber),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusTag(status: unit.currentStatus.name == 'expiringSoon'
                ? 'expiring_soon'
                : unit.currentStatus.name),
            if (unit.tenantName != null) ...[
              const SizedBox(height: 8),
              Text('租户：${unit.tenantName}'),
            ],
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              final path =
                  RoutePaths.unitDetail.replaceAll(':id', unit.unitId);
              context.push(path);
            },
            child: const Text('查看房源详情'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

/// 图片平面图（有 SVG/PNG 路径时使用）。
class _FloorImageViewer extends StatelessWidget {
  final String imagePath;

  const _FloorImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) => InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text('平面图加载失败，请检查网络连接'),
            ),
          ),
        ),
      );
}

/// 状态色例 Legend 条。
class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          _LegendItem(status: UnitStatus.leased),
          const SizedBox(width: 12),
          _LegendItem(status: UnitStatus.vacant),
          const SizedBox(width: 12),
          _LegendItem(status: UnitStatus.expiringSoon),
          const SizedBox(width: 12),
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
              color: color.withOpacity(isSelected ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.4),
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
                          color: color.withOpacity(0.8)),
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
