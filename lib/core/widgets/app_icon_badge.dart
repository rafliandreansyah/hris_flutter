import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_design.dart';

/// Pembungkus ikon seragam: kotak membulat dengan latar warna lembut dan ikon
/// di tengah. Dipakai untuk semua ikon opsi (email, WhatsApp, salin, dll.) agar
/// bentuk, ukuran, dan padding-nya konsisten, termasuk untuk logo brand.
class AppIconBadge extends StatelessWidget {
  /// Ikon bawaan; abaikan bila [child] diberikan.
  final IconData? icon;

  /// Widget ikon kustom (mis. `WhatsAppIcon`).
  final Widget? child;

  /// Warna ikon bawaan sekaligus dasar warna latar (alpha 12%).
  final Color color;

  final double size;
  final double iconSize;

  const AppIconBadge({
    super.key,
    this.icon,
    this.child,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      // Center wajib: tanpa ini anak ikut dipaksa selebar kotak (logo SVG melar).
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: AppRadius.borderInput,
      ),
      child: child ?? Icon(icon, color: color, size: iconSize),
    );
  }
}
