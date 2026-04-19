import 'package:flutter/material.dart';

import 'custom_colors.dart';

/// Build the global Material 3 [ThemeData] for the PropOS app.
///
/// Seed color: Apple Blue `#0071E3`.
/// Semantic colors available via `Theme.of(context).extension<CustomColors>()!`.
ThemeData buildAppTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0071E3),
        brightness: Brightness.light,
      ),
      extensions: const <ThemeExtension<dynamic>>[lightCustomColors],
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
