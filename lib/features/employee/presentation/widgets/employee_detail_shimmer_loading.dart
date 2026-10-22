import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton shimmer halaman Detail Pegawai (hero, metrik, dan kartu data),
/// meniru struktur konten agar tidak terjadi layout shift saat data tiba.
class EmployeeDetailShimmerLoading extends StatelessWidget {
  const EmployeeDetailShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceContainer : AppColors.darkOnBackground;
    final highlightColor =
        isDark ? AppColors.darkSurfaceContainerHigh : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    Widget bar(double width, {double height = 12}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    Widget card({required Widget child}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: child,
        );

    Widget infoCard({int rows = 4}) => card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(120, height: 14),
              const SizedBox(height: 16),
              for (var i = 0; i < rows; i++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [bar(90), bar(130)],
                ),
                if (i != rows - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        );

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Hero profil
            card(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration:
                        BoxDecoration(color: baseColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(height: 14),
                  bar(160, height: 18),
                  const SizedBox(height: 8),
                  bar(110),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [bar(80, height: 24), const SizedBox(width: 8), bar(80, height: 24)],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Metrik lembur & cuti
            Row(
              children: [
                Expanded(child: card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(70), const SizedBox(height: 10), bar(50, height: 20)],
                ))),
                const SizedBox(width: 12),
                Expanded(child: card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [bar(70), const SizedBox(height: 10), bar(50, height: 20)],
                ))),
              ],
            ),
            const SizedBox(height: 16),
            infoCard(rows: 3),
            const SizedBox(height: 16),
            infoCard(rows: 5),
            const SizedBox(height: 16),
            infoCard(rows: 3),
          ],
        ),
      ),
    );
  }
}
