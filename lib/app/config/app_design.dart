import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double sm = 8.0; // 8px
  static const double md = 12.0; // 12px
  static const double lg = 20.0; // 20px
  static const double xl = 24.0; // 24px
  static const double full = 9999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );
}

abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double x2l = 32.0;

  static const double marginMobile = 20.0;
  static const double gutterMobile = 16.0;
}
