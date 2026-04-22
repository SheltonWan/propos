import 'package:flutter/material.dart';

/// Material 3 semantic color extension for business states.
///
/// Access via: `Theme.of(context).extension<CustomColors>()!`
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  /// Leased / paid / approved / active
  final Color success;

  /// Expiring soon / pending / warning
  final Color warning;

  /// Vacant / overdue / rejected / terminated
  final Color danger;

  /// Non-leasable / draft / cancelled
  final Color neutral;

  /// Dashboard 专属 AppBar 背景色（深海蓝，与 uni-app --color-card-dark 保持一致）
  final Color dashboardHeaderBg;

  /// Dashboard AppBar 前景色（文字、图标）
  final Color onDashboardHeader;

  const CustomColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.dashboardHeaderBg,
    required this.onDashboardHeader,
  });

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? neutral,
    Color? dashboardHeaderBg,
    Color? onDashboardHeader,
  }) =>
      CustomColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        neutral: neutral ?? this.neutral,
        dashboardHeaderBg: dashboardHeaderBg ?? this.dashboardHeaderBg,
        onDashboardHeader: onDashboardHeader ?? this.onDashboardHeader,
      );

  @override
  CustomColors lerp(covariant ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      dashboardHeaderBg:
          Color.lerp(dashboardHeaderBg, other.dashboardHeaderBg, t)!,
      onDashboardHeader:
          Color.lerp(onDashboardHeader, other.onDashboardHeader, t)!,
    );
  }
}

/// Default light theme custom colors.
const lightCustomColors = CustomColors(
  success: Color(0xFF52C41A),
  warning: Color(0xFFFAAD14),
  danger: Color(0xFFFF4D4F),
  neutral: Color(0xFF8C8C8C),
  dashboardHeaderBg: Color(0xFF001D3D),
  onDashboardHeader: Color(0xFFFFFFFF),
);
