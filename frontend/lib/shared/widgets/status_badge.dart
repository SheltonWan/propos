import 'package:flutter/material.dart';

/// 状态色块徽章 — 严格遵循 copilot-instructions.md 颜色语义映射
/// 不得使用硬编码颜色，统一通过 colorScheme token 取值
enum UnitStatus { leased, expiringSoon, vacant, nonLeasable }

class StatusBadge extends StatelessWidget {
  final UnitStatus status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, text) = switch (status) {
      UnitStatus.leased => (cs.secondary, label ?? '已租'),
      UnitStatus.expiringSoon => (cs.tertiary, label ?? '即将到期'),
      UnitStatus.vacant => (cs.error, label ?? '空置'),
      UnitStatus.nonLeasable => (cs.outlineVariant, label ?? '非可租'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
