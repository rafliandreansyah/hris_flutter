import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTypography {
  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 26, // 1.625rem * 16px
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 18, // 1.125rem * 16px
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14, // 0.875rem * 16px
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 12, // 0.75rem * 16px
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.6, // 0.05em * 12px
  );

  static TextStyle headlineLargeMobile = GoogleFonts.plusJakartaSans(
    fontSize: 24, // 1.5rem * 16px
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
