import 'package:flutter/material.dart';

/// Konfigurasi token radius geometri berdasarkan Google Stitch Design System.
abstract class AppRadius {
  static const double sm = 4.0; // 0.25rem (rounded-sm)
  static const double md = 8.0; // 0.5rem (rounded default)
  static const double input = 12.0; // 12px (text field radius)
  static const double lg = 16.0; // 1rem (medium cards)
  static const double xl = 24.0; // 1.5rem (large cards & widgets)
  static const double full = 9999.0; // Pill / Stadium shape (Buttons, Chips)

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderInput = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );
}

/// Konfigurasi token layout grid dan spacing berdasarkan Google Stitch Design System.
abstract class AppSpacing {
  /// Unit dasar grid 4px
  static const double unit = 4.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  /// Margins & Gutters
  static const double marginMobile = 16.0;
  static const double marginTablet = 24.0;
  static const double gutter = 16.0;
  static const double containerMaxWidth = 1200.0;
}
