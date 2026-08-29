import 'package:flutter/material.dart';

/// Palet warna resmi Oasish Flutter M3 HRIS yang disinkronkan langsung
/// dengan Google Stitch Design System ("Teal Oasis" - Project ID: 17152850901645837896).
abstract class AppColors {
  // ==========================================
  // --- BRAND & TEAL CORE TOKENS ---
  // ==========================================
  static const Color primary = Color(0xFF00685F);
  static const Color brandTeal = Color(0xFF0D9488);
  static const Color primaryHover = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF0FDFA);
  static const Color onPrimaryContainer = Color(0xFF115E59);
  static const Color inversePrimary = Color(0xFF6BD8CB);

  // ==========================================
  // --- SECONDARY & TERTIARY TOKENS ---
  // ==========================================
  static const Color secondary = Color(0xFF006B5F);
  static const Color brandTealSecondary = Color(0xFF14B8A6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF6DF5E1);
  static const Color onSecondaryContainer = Color(0xFF006F64);

  static const Color tertiary = Color(0xFF924628);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB05E3D);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);

  // ==========================================
  // --- STATUS & FEEDBACK TOKENS ---
  // ==========================================
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ==========================================
  // --- LIGHT MODE CANVAS & SURFACES ---
  // ==========================================
  static const Color background = Color(0xFFFAF8FF);
  static const Color backgroundSubtle = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF131B2E);

  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color surfaceVariant = Color(0xFF64748B);
  static const Color inverseSurface = Color(0xFF283044);
  static const Color inverseOnSurface = Color(0xFFEEF0FF);
  static const Color surfaceTint = Color(0xFF006A61);

  // ==========================================
  // --- DARK MODE CANVAS & SURFACES ---
  // ==========================================
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkBackgroundSubtle = Color(0xFF0F172A);
  static const Color darkOnBackground = Color(0xFFE2E8F0);

  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceDim = Color(0xFF0B1120);
  static const Color darkSurfaceBright = Color(0xFF1E293B);
  static const Color darkSurfaceContainerLowest = Color(0xFF090D16);
  static const Color darkSurfaceContainerLow = Color(0xFF0F172A);
  static const Color darkSurfaceContainer = Color(0xFF1E293B);
  static const Color darkSurfaceContainerHigh = Color(0xFF334155);
  static const Color darkSurfaceContainerHighest = Color(0xFF475569);

  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF6BD8CB);
  static const Color darkOnPrimary = Color(0xFF003732);
  static const Color darkPrimaryContainer = Color(0xFF005049);
  static const Color darkOnPrimaryContainer = Color(0xFF89F5E7);

  static const Color darkOutline = Color(0xFF475569);
  static const Color darkOutlineVariant = Color(0xFF334155);
  static const Color darkOutlineMuted = Color(0xFF1E293B);

  // ==========================================
  // --- BORDERS, OUTLINES & ACCENTS ---
  // ==========================================
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color outlineMuted = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accentTealLight = Color(0xFFCCFBF1);

  // ==========================================
  // --- TEXT COLORS ---
  // ==========================================
  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);

  // ==========================================
  // --- FIXED TONES (M3 Design Tokens) ---
  // ==========================================
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);

  static const Color secondaryFixed = Color(0xFF71F8E4);
  static const Color secondaryFixedDim = Color(0xFF4FDBC8);
  static const Color onSecondaryFixed = Color(0xFF00201C);
  static const Color onSecondaryFixedVariant = Color(0xFF005048);

  static const Color tertiaryFixed = Color(0xFFFFDBCE);
  static const Color tertiaryFixedDim = Color(0xFFFFB59A);
  static const Color onTertiaryFixed = Color(0xFF370E00);
  static const Color onTertiaryFixedVariant = Color(0xFF773215);
}
