import 'package:flutter/material.dart';

import 'finch_colors.dart';
import 'finch_motion.dart';
import 'finch_spacing.dart';
import 'finch_typography.dart';

class FinchTheme extends ThemeExtension<FinchTheme> {
  const FinchTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.motion,
  });

  final FinchColors colors;
  final FinchTypography typography;
  final FinchSpacing spacing;
  final FinchRadii radii;
  final FinchMotion motion;

  static FinchTheme get light {
    const colors = FinchColors.light;
    return const FinchTheme(
      colors: colors,
      typography: FinchTypography(colors: colors),
      spacing: FinchSpacing(),
      radii: FinchRadii(),
      motion: FinchMotion(),
    );
  }

  static FinchTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<FinchTheme>();
    assert(theme != null, 'FinchTheme not found in the widget tree.');
    return theme!;
  }

  @override
  FinchTheme copyWith({
    FinchColors? colors,
    FinchTypography? typography,
    FinchSpacing? spacing,
    FinchRadii? radii,
    FinchMotion? motion,
  }) {
    return FinchTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      motion: motion ?? this.motion,
    );
  }

  @override
  FinchTheme lerp(ThemeExtension<FinchTheme>? other, double t) {
    // Single light theme for v1 — no lerp target.
    return this;
  }
}

ThemeData buildFinchMaterialTheme() {
  final finch = FinchTheme.light;
  final colors = finch.colors;
  final typo = finch.typography;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: [finch],
    scaffoldBackgroundColor: colors.paper,
    canvasColor: colors.paper,
    colorScheme: ColorScheme.light(
      primary: colors.sage,
      onPrimary: const Color(0xFFFDFBF5),
      secondary: colors.clay,
      onSecondary: const Color(0xFFFDFBF5),
      surface: colors.paper,
      onSurface: colors.ink,
      error: colors.danger,
      onError: const Color(0xFFFDFBF5),
    ),
    fontFamily: FinchTypography.fontUi,
    textTheme: TextTheme(
      displayLarge: typo.display,
      displayMedium: typo.displayLarge,
      displaySmall: typo.h1,
      headlineLarge: typo.h1,
      headlineMedium: typo.h2,
      headlineSmall: typo.h3,
      titleLarge: typo.h3,
      titleMedium: typo.body.copyWith(fontWeight: FontWeight.w600),
      titleSmall: typo.small.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: typo.body,
      bodyMedium: typo.small,
      bodySmall: typo.caption,
      labelLarge: typo.button,
      labelMedium: typo.label,
      labelSmall: typo.micro,
    ),
    splashColor: colors.sageSoft.withValues(alpha: 0.3),
    highlightColor: colors.linen,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
