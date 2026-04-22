import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_colors.dart';

/// 构建 PropOS 应用全局 [ThemeData]（苹果风格）。
///
/// 种子色：Apple Blue `#0071E3`。
/// 语义色通过 `Theme.of(context).extension<CustomColors>()!` 访问。
/// [cupertinoOverrideTheme] 确保 [CupertinoButton.filled] / [CupertinoActivityIndicator] 等控件颜色一致。
ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0071E3),
        brightness: Brightness.light,
      ),
      extensions: const <ThemeExtension<dynamic>>[lightCustomColors],
  // 注入 Cupertino 主题令牌，与 MaterialApp 共用根组件时对 Cupertino 控件生效
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: Color(0xFF0071E3),
    primaryContrastingColor: CupertinoColors.white,
  ),
  appBarTheme: const AppBarTheme(centerTitle: true),
    );
