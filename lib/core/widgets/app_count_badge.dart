import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';

/// Badge angka merah (jumlah menunggu/belum dibaca). Tidak tampil bila [count] <= 0;
/// di atas 99 ditampilkan "99+". Letakkan di dalam `Stack` lewat `Positioned`.
class AppCountBadge extends StatelessWidget {
  final int count;

  const AppCountBadge({super.key, required this.count});

  /// Teks yang ditampilkan untuk [count].
  static String labelFor(int count) => count > 99 ? '99+' : count.toString();

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$count menunggu',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1.5),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: AppRadius.borderFull,
          border: Border.all(
            color: isDark ? AppColors.darkBackground : AppColors.surfaceContainerLowest,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            labelFor(count),
            style: const TextStyle(
              color: AppColors.onError,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
