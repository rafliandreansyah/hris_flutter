import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand & Core Colors
  static const Color primary = Color(0xFF00685F);
  static const Color primaryHover = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color inversePrimary = Color(0xFF6BD8CB);

  static const Color secondary = Color(0xFF904D00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE932C);
  static const Color onSecondaryContainer = Color(0xFF663500);

  static const Color tertiary = Color(0xFF924628);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB05E3D);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface & Background Colors
  static const Color background = Color(0xFFF0FDFD);
  static const Color onBackground = Color(0xFF171D1C);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD6DBD9);
  static const Color surfaceBright = Color(0xFFF5FAF8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F5F2);
  static const Color surfaceContainer = Color(0xFFEAEFED);
  static const Color surfaceContainerHigh = Color(0xFFE4E9E7);
  static const Color surfaceContainerHighest = Color(0xFFDEE4E1);
  static const Color onSurface = Color(0xFF171D1C);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color surfaceVariant = Color(0xFFDEE4E1);
  static const Color inverseSurface = Color(0xFF2C3130);
  static const Color inverseOnSurface = Color(0xFFEDF2F0);

  // Borders & Outlines
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color border = Color(0xFFCCFBF1);
  static const Color surfaceTint = Color(0xFF006A61);

  // Text Colors
  static const Color textPrimary = Color(0xFF064E3B);
  static const Color textSecondary = Color(0xFF475569);

  // Fixed Tones
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);

  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  static const Color tertiaryFixed = Color(0xFFFFDBCE);
  static const Color tertiaryFixedDim = Color(0xFFFFB59A);
  static const Color onTertiaryFixed = Color(0xFF370E00);
  static const Color onTertiaryFixedVariant = Color(0xFF773215);
}
