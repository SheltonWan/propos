import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../shared/widgets/status_tag.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/renovation.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_status.dart';
import '../bloc/unit_detail_cubit.dart';
import '../bloc/unit_detail_state.dart';

/// 房源详情页（子页面，含独立 Scaffold）。
///
/// 布局对齐 PAGE_SPEC_FLUTTER v1.9 §3.4 UnitDetailPage：
/// - 状态 Tag + 业态 Tag
/// - 基础信息区（面积、朝向、层高、装修）
/// - 租赁信息区（状态为 leased 时展示）
/// - 改造记录区
class UnitDetailPage extends StatefulWidget {
  final String unitId;

  const UnitDetailPage({super.key, required this.unitId});

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<UnitDetailCubit>().fetch(widget.unitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('房源详情'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<UnitDetailCubit, UnitDetailState>(
        builder: (context, state) => switch (state) {
          UnitDetailStateInitial() || UnitDetailStateLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
          UnitDetailStateError(:final message) => Center(
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
                        context.read<UnitDetailCubit>().fetch(widget.unitId),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          UnitDetailStateLoaded(:final unit, :final renovations) =>
            _buildContent(context, unit, renovations),
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UnitDetail unit,
    List<RenovationSummary> renovations,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _UnitHeader(unit: unit),
        const SizedBox(height: 16),
        _BasicInfoSection(unit: unit),
        if (unit.extFields != null && unit.extFields!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TypeSpecificSection(unit: unit),
        ],
        if (unit.currentStatus == UnitStatus.leased) ...[
          const SizedBox(height: 16),
          _LeaseInfoSection(unit: unit),
        ],
        if (unit.currentContractId != null) ...[
          const SizedBox(height: 16),
          _ContractSummaryPlaceholder(contractId: unit.currentContractId!),
        ],
        if (renovations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RenovationSection(renovations: renovations),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

/// 房源头部（房源号 + 状态/业态 Tag）。
class _UnitHeader extends StatelessWidget {
  final UnitDetail unit;

  const _UnitHeader({required this.unit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // UnitStatus → API 字符串映射
    final statusStr = switch (unit.currentStatus) {
      UnitStatus.leased => 'leased',
      UnitStatus.vacant => 'vacant',
      UnitStatus.expiringSoon => 'expiring_soon',
      UnitStatus.nonLeasable => 'non_leasable',
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.unitNumber,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text(
                '${unit.buildingName}${unit.floorName != null ? " · ${unit.floorName}" : ""}',
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        StatusTag(status: statusStr),
        const SizedBox(width: 8),
        StatusTag(status: 'active', label: unit.propertyType.label),
      ],
    );
  }
}

/// 基础信息区（面积/朝向/层高/装修/参考租金）。
class _BasicInfoSection extends StatelessWidget {
  final UnitDetail unit;

  const _BasicInfoSection({required this.unit});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '基础信息',
      children: [
        if (unit.grossArea != null)
          _InfoRow(
              label: '建筑面积',
              value: '${unit.grossArea!.toStringAsFixed(1)} m²'),
        if (unit.netArea != null)
          _InfoRow(
              label: '使用面积',
              value: '${unit.netArea!.toStringAsFixed(1)} m²'),
        if (unit.orientation != null)
          _InfoRow(label: '朝向', value: unit.orientation!),
        if (unit.ceilingHeight != null)
          _InfoRow(
              label: '净高',
              value: '${unit.ceilingHeight!.toStringAsFixed(1)} m'),
        _InfoRow(label: '装修状态', value: unit.decorationStatus.label),
        if (unit.marketRentReference != null)
          _InfoRow(
              label: '参考租金',
              value:
                  '¥${unit.marketRentReference!.toStringAsFixed(0)}/m²/月',
              highlight: true),
      ],
    );
  }
}

/// 三业态差异化扩展字段区段。
///
/// 使用 Dart 3 switch pattern matching 按 [UnitDetail.propertyType] 分支渲染
/// 写字楼（工位/格局）/ 商铺（临街/格局）/ 公寓（卧室/户型）的专属字段。
/// 字段值来自 [UnitDetail.extFields] JSONB，key 命名与后端契约一致。
class _TypeSpecificSection extends StatelessWidget {
  final UnitDetail unit;

  const _TypeSpecificSection({required this.unit});

  @override
  Widget build(BuildContext context) {
    final ext = unit.extFields!;
    final rows = switch (unit.propertyType) {
      PropertyType.office => _officeRows(ext),
      PropertyType.retail => _retailRows(ext),
      PropertyType.apartment => _apartmentRows(ext),
      PropertyType.mixed => <Widget>[],
    };
    if (rows.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: switch (unit.propertyType) {
        PropertyType.office => '写字楼扩展信息',
        PropertyType.retail => '商铺扩展信息',
        PropertyType.apartment => '公寓扩展信息',
        _ => '扩展信息',
      },
      children: rows,
    );
  }

  /// 写字楼：工位数、格局、是否可分割。
  List<Widget> _officeRows(Map<String, dynamic> ext) => [
        if (ext['workstations'] != null)
          _InfoRow(label: '工位数', value: '${ext['workstations']} 个'),
        if (ext['layout'] != null)
          _InfoRow(label: '格局', value: '${ext['layout']}'),
        if (ext['divisible'] != null)
          _InfoRow(
              label: '可分割',
              value: (ext['divisible'] as bool) ? '是' : '否'),
      ];

  /// 商铺：是否临街、格局、层高备注。
  List<Widget> _retailRows(Map<String, dynamic> ext) => [
        if (ext['street_facing'] != null)
          _InfoRow(
              label: '临街',
              value: (ext['street_facing'] as bool) ? '是' : '否'),
        if (ext['shop_layout'] != null)
          _InfoRow(label: '商铺格局', value: '${ext['shop_layout']}'),
        if (ext['floor_height_note'] != null)
          _InfoRow(label: '层高备注', value: '${ext['floor_height_note']}'),
      ];

  /// 公寓：卧室数、户型、朝向。
  List<Widget> _apartmentRows(Map<String, dynamic> ext) => [
        if (ext['bedrooms'] != null)
          _InfoRow(label: '卧室数', value: '${ext['bedrooms']} 室'),
        if (ext['apartment_layout'] != null)
          _InfoRow(label: '户型', value: '${ext['apartment_layout']}'),
        if (ext['facing'] != null)
          _InfoRow(label: '朝向', value: '${ext['facing']}'),
      ];
}

/// 租赁信息区（仅 leased 状态展示）。
///
/// TODO(M2): PAGE_SPEC §5.4 规范要求展示租户名称、月租金、合同到期日，
/// 但 UnitDetail（API_CONTRACT §2.14）未包含 tenant_name / monthly_rent / contract_end_date。
/// M2 合同模块 API 就绪后，在此 _SectionCard 中补充 _InfoRow 展示上述三字段。
class _LeaseInfoSection extends StatelessWidget {
  final UnitDetail unit;

  const _LeaseInfoSection({required this.unit});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '租赁信息',
      children: [
        if (unit.currentContractId != null)
          _InfoRow(label: '合同编号', value: unit.currentContractId!),
      ],
    );
  }
}

/// 改造记录区。
class _RenovationSection extends StatelessWidget {
  final List<RenovationSummary> renovations;

  const _RenovationSection({required this.renovations});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    return _SectionCard(
      title: '改造记录（${renovations.length}条）',
      children: renovations.map((r) {
        final started = fmt.format(r.startedAt.toLocal());
        final completed = r.completedAt != null
            ? fmt.format(r.completedAt!.toLocal())
            : '进行中';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(r.renovationType,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600))),
                if (r.cost != null)
                  Text(
                    '¥${(r.cost! / 10000).toStringAsFixed(1)}万',
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
            Text('$started → $completed',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
            if (r.contractor != null)
              Text('施工方：${r.contractor}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)),
            const Divider(height: 20),
          ],
        );
      }).toList(),
    );
  }
}

/// 合同摘要占位区段（M2 联动后替换为真实合同数据）。
///
/// 当前仅显示合同 ID 及"M2 待接入"提示，待 M2 实现后删除此 Widget，
/// 替换为真正的 ContractSummaryWidget（从合同 API 拉取数据）。
class _ContractSummaryPlaceholder extends StatelessWidget {
  final String contractId;

  const _ContractSummaryPlaceholder({required this.contractId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.doc_text, size: 20, color: scheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '合同详情',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface),
                ),
                Text(
                  '合同信息将在 M2 模块接入后展示',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_forward,
              size: 14, color: scheme.outline),
        ],
      ),
    );
  }
}

/// 通用信息区段卡片（含色条标题指示器）。
///
/// 对标前端原型 UnitDetail.tsx section card 样式。
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    return Container(
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
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行（含左侧色条）
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          // 内容区
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  /// 是否高亮（对标前端 highlight prop）
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                color: highlight ? scheme.primary : scheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
