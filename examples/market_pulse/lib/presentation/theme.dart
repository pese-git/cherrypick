import 'package:flutter/material.dart';

/// Terminal-ish dark palette. Kept in one place so the widgets stay about DI.
abstract final class MarketColors {
  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF161B22);
  static const surfaceAlt = Color(0xFF1C232C);
  static const border = Color(0xFF2A323C);
  static const accent = Color(0xFF4CC2FF);
  static const up = Color(0xFF3FB950);
  static const down = Color(0xFFF85149);
  static const muted = Color(0xFF8B949E);
}

ThemeData buildMarketTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: MarketColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: MarketColors.surface,
      primary: MarketColors.accent,
    ),
    dividerColor: MarketColors.border,
    textTheme: base.textTheme.apply(fontFamily: 'monospace'),
    cardTheme: const CardThemeData(
      color: MarketColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}
