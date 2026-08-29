import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografi resmi Oasish Flutter M3 HRIS yang disinkronkan langsung
/// dengan Google Stitch Design System (Font: Plus Jakarta Sans).
abstract class AppTypography {
  /// Headline Large - Desktop / Tablet (28px / 36px line height, Bold)
  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.5,
  );

  /// Headline Large - Mobile (24px / 32px line height, Bold)
  static TextStyle headlineLargeMobile = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.3,
  );

  /// Headline Medium (20px / 28px line height, SemiBold)
  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  /// Title Medium (18px / 24px line height, SemiBold)
  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
  );

  /// Title Small (16px / 22px line height, SemiBold)
  static TextStyle titleSmall = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
  );

  /// Body Large (16px / 24px line height, Regular)
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Body Medium (14px / 20px line height, Regular)
  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// Body Small (12px / 18px line height, Regular)
  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );

  /// Label Medium (12px / 16px line height, SemiBold, +0.5px tracking)
  static TextStyle labelMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
  );

  /// Label Small (11px / 16px line height, Medium)
  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
  );
}
