import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';

/// Spinner standar aplikasi: ukuran & ketebalan seragam, tanpa teks pendamping.
///
/// - [AppLoadingIndicator.regular] (28dp) untuk area konten / halaman.
/// - [AppLoadingIndicator.small] (20dp) untuk inline: load-more, tombol, field.
/// Warna default mengikuti tema (brandTeal / inversePrimary); isi [color] hanya
/// bila latar gelap/berwarna (mis. di atas kamera atau tombol teal).
class AppLoadingIndicator extends StatelessWidget {
  static const double regularSize = 28;
  static const double smallSize = 20;
  static const double strokeWidth = 2.5;

  final double size;
  final Color? color;

  const AppLoadingIndicator({super.key, this.size = regularSize, this.color});

  const AppLoadingIndicator.small({super.key, this.color}) : size = smallSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? (isDark ? AppColors.inversePrimary : AppColors.brandTeal),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
