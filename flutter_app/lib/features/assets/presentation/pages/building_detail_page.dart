import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/floor.dart';
import '../bloc/building_detail_cubit.dart';
import '../bloc/building_detail_state.dart';

/// 楼栋详情页（子页面，含独立 Scaffold + CupertinoNavigationBar）。
///
/// 布局对齐 PAGE_SPEC_FLUTTER v1.9 §3.2 BuildingDetailPage：
/// - 楼栋基础信息卡片
/// - 楼层列表（含出租率进度条）
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
            child: Text(
              '楼层列表（${floors.length}层）',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
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
            ),
          ),
        ),
      ],
    );
  }
}

/// 楼栋基础信息卡片。
class _BuildingInfoCard extends StatelessWidget {
  final Building building;

  const _BuildingInfoCard({required this.building});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            building.name,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (building.address != null) ...[
            const SizedBox(height: 4),
            Text(
              building.address!,
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoItem(
                  label: '总楼层', value: '${building.totalFloors}层'),
              _InfoItem(
                  label: '业态', value: building.propertyType.label),
              _InfoItem(
                  label: 'GFA',
                  value: '${building.gfa.toStringAsFixed(0)} m²'),
              _InfoItem(
                  label: 'NLA',
                  value: '${building.nla.toStringAsFixed(0)} m²'),
              if (building.builtYear != null)
                _InfoItem(
                    label: '建成年份',
                    value: '${building.builtYear}年'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// 单行楼层条目，点击跳转到楼层平面图页。
class _FloorRow extends StatelessWidget {
  final Floor floor;
  final String buildingId;

  const _FloorRow({required this.floor, required this.buildingId});

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                floor.displayName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (floor.nla != null)
                    Text(
                      'NLA ${floor.nla!.toStringAsFixed(0)} m²',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
