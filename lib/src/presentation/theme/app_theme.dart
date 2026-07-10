import 'package:flutter/material.dart';
import 'package:igyal2/src/presentation/theme/app_colors.dart';

/// Az app témája: fekete alapú sötét séma zöld accentekkel, és a comic display
/// font neve a címekhez (Bangers, assetből beágyazva).
abstract final class AppTheme {
  /// A comic display-fontcsalád neve — a címekhez (Vírus, KEZDÉS, csapatnevek).
  /// A törzsszöveg a rendszer sans-ját (Roboto) használja.
  static const displayFontFamily = 'Bangers';

  /// Az app sötét témája: fekete háttér, zöld accentek.
  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.cta,
        secondary: AppColors.brand,
        surface: AppColors.background,
      ),
    );
  }
}
