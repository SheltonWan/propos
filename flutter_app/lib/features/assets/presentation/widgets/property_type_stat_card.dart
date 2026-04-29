import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../domain/entities/asset_overview.dart';

/// 单业态统计卡片（资产概览页横排三张）。
class PropertyTypeStatCard extends StatelessWidget {
  final PropertyTypeStats stat;

  const PropertyTypeStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<CustomColors>()!;
    final occupancyPct = stat.occupancyRate * 100;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            stat.propertyType.label,
            style: TextStyle(
                fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '${occupancyPct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _occupancyColor(occupancyPct, colors),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stat.leasedUnits}/${stat.totalUnits} 套',
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Color _occupancyColor(double pct, CustomColors colors) {
    if (pct >= 90) return colors.success;
    if (pct >= 70) return colors.warning;
    return colors.danger;
  }
}
