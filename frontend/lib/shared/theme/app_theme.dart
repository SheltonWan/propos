import 'package:flutter/material.dart';

/// PropOS Design Token — Material 3 主题
/// 颜色语义严格按 copilot-instructions.md 状态色规范
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0), // 品牌蓝
      brightness: Brightness.light,
      // secondary → 已租/已核销（绿色系）
      secondary: const Color(0xFF2E7D32),
      // tertiary → 即将到期/预警（橙色系）
      tertiary: const Color(0xFFF57C00),
      // error → 空置/逾期/错误（红色系）
      error: const Color(0xFFC62828),
      // outlineVariant → 非可租区域（中性灰）
      outlineVariant: const Color(0xFF9E9E9E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
