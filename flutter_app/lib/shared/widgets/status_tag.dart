import 'package:flutter/material.dart';

import '../../core/theme/custom_colors.dart';

/// A semantic color tag for displaying entity statuses.
///
/// Maps status strings to [CustomColors] semantic tokens:
/// - success (leased, paid, active, approved, completed)
/// - warning (expiring_soon, pending_sign, pending_inspection, on_hold)
/// - danger (vacant, overdue, terminated, rejected, cancelled)
/// - neutral (non_leasable, draft, quoting, initial, exempt)
class StatusTag extends StatelessWidget {
  final String status;
  final String? label;

  const StatusTag({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final (bgColor, fgColor) = _resolveColors(colors);
    final displayText = label ?? _defaultLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: fgColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (Color bg, Color fg) _resolveColors(CustomColors colors) => switch (status) {
        'leased' ||
        'paid' ||
        'active' ||
        'approved' ||
        'completed' =>
          (colors.success, colors.success),
        'expiring_soon' ||
        'pending_sign' ||
        'pending_inspection' ||
        'in_progress' ||
        'on_hold' ||
        'submitted' ||
        'issued' =>
          (colors.warning, colors.warning),
        'vacant' ||
        'overdue' ||
        'terminated' ||
        'rejected' ||
        'cancelled' ||
        'expired' =>
          (colors.danger, colors.danger),
        _ => (colors.neutral, colors.neutral),
      };

  String _defaultLabel() => switch (status) {
        'leased' => '已租',
        'vacant' => '空置',
        'non_leasable' => '非可租',
        'expiring_soon' => '即将到期',
        'active' => '生效中',
        'pending_sign' => '待签约',
        'quoting' => '报价中',
        'expired' => '已到期',
        'renewed' => '已续签',
        'terminated' => '已终止',
        'draft' => '草稿',
        'issued' => '已出账',
        'paid' => '已核销',
        'overdue' => '逾期',
        'cancelled' => '已作废',
        'exempt' => '减免',
        'submitted' => '已提交',
        'approved' => '已审核',
        'in_progress' => '处理中',
        'pending_inspection' => '待验收',
        'completed' => '已完成',
        'rejected' => '已驳回',
        'on_hold' => '已挂起',
        _ => status,
      };
}
