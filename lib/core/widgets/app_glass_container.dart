import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';

/// Panel kaca (glassmorphism): blur latar di belakangnya, isian tembus pandang
/// bergradasi, garis tepi terang tipis, dan bayangan lembut. Cocok untuk elemen
/// yang melayang di atas peta atau gambar.
class AppGlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Kekuatan blur latar (sigma).
  final double blur;

  /// Tingkat ketebalan kaca (0 = bening, 1 = solid).
  final double opacity;

  /// Warna kaca; default putih (terang) / surface gelap (mode gelap).
  final Color? tint;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.borderXl,
    this.padding,
    this.blur = 18,
    this.opacity = 0.62,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint =
        this.tint ??
        (isDark ? AppColors.darkSurfaceContainerLowest : Colors.white);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              // Sorotan di sudut kiri atas memudar ke bawah: kesan kaca yang nyata
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: (opacity + 0.15).clamp(0.0, 1.0)),
                  tint.withValues(alpha: opacity),
                  tint.withValues(alpha: (opacity - 0.12).clamp(0.0, 1.0)),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.7),
                width: 1.2,
              ),
            ),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
