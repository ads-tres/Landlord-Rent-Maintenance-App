import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF0F6E4F);

  /// Latin text uses the platform font; Ge'ez script falls back to Noto Sans Ethiopic.
  static const _fontFallback = ['NotoSansEthiopic'];

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: _fontFallback),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamilyFallback: _fontFallback,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
    );
  }
}
