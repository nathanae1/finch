import 'package:flutter/material.dart';

import 'starling_colors.dart';
import 'starling_motion.dart';
import 'starling_spacing.dart';
import 'starling_typography.dart';

class StarlingTheme extends ThemeExtension<StarlingTheme> {
  const StarlingTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.motion,
  });

  final StarlingColors colors;
  final StarlingTypography typography;
  final StarlingSpacing spacing;
  final StarlingRadii radii;
  final StarlingMotion motion;

  static StarlingTheme get light {
    const colors = StarlingColors.light;
    return const StarlingTheme(
      colors: colors,
      typography: StarlingTypography(colors: colors),
      spacing: StarlingSpacing(),
      radii: StarlingRadii(),
      motion: StarlingMotion(),
    );
  }

  static StarlingTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<StarlingTheme>();
    assert(theme != null, 'StarlingTheme not found in the widget tree.');
    return theme!;
  }

  @override
  StarlingTheme copyWith({
    StarlingColors? colors,
    StarlingTypography? typography,
    StarlingSpacing? spacing,
    StarlingRadii? radii,
    StarlingMotion? motion,
  }) {
    return StarlingTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      motion: motion ?? this.motion,
    );
  }

  @override
  StarlingTheme lerp(ThemeExtension<StarlingTheme>? other, double t) {
    // Single light theme for v1 — no lerp target.
    return this;
  }
}

ThemeData buildStarlingMaterialTheme() {
  final starling = StarlingTheme.light;
  final colors = starling.colors;
  final typo = starling.typography;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: [starling],
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
    fontFamily: StarlingTypography.fontUi,
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
