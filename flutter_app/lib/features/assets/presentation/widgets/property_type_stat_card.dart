import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../domain/entities/asset_overview.dart';
import '../../domain/entities/property_type.dart';

/// 单业态统计卡片（资产概览页横排三张，可点击切换筛选）。
///
/// 对标前端原型 Assets.tsx property-type comparison cards。
class PropertyTypeStatCard extends StatelessWidget {
  final PropertyTypeStats stat;

  const PropertyTypeStatCard({super.key, required this.stat});

  /// 业态强调色。
  Color _accentColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    return switch (stat.propertyType) {
      PropertyType.office => scheme.primary,
      PropertyType.retail => colors.warning,
      PropertyType.apartment => const Color(0xFF0EA5E9),
      PropertyType.mixed => scheme.secondary,
    };
  }

  /// 业态图标。
  IconData _icon() => switch (stat.propertyType) {
        PropertyType.office => Icons.business,
        PropertyType.retail => Icons.storefront,
        PropertyType.apartment => Icons.apartment,
        PropertyType.mixed => Icons.location_city,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    final accent = _accentColor(context);
    final vacancyRate = stat.totalUnits > 0
        ? (stat.vacantUnits / stat.totalUnits * 100)
        : 0.0;

    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标 + 业态名
          Row(
            children: [
              Icon(_icon(), size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                stat.propertyType.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // NLA 面积
          Text(
            '${(stat.totalNla / 10000).toStringAsFixed(1)}万㎡ · ${stat.totalUnits}套',
            style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // 空置率（对应前端 vacancyRate 显示）
          Text(
            '空置 ${vacancyRate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: vacancyRate > 15
                  ? colors.danger
                  : vacancyRate > 5
                      ? colors.warning
                      : colors.success,
            ),
          ),
        ],
      ),
    );
  }
}
