import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder loading untuk Announcement Detail Screen.
class AnnouncementDetailShimmerLoading extends StatelessWidget {
  const AnnouncementDetailShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF8FAFC);
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                Container(
                  width: 70,
                  height: 24,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 90,
                  height: 24,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 220,
              height: 24,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Published date
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Hero Image cover placeholder
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: 20),

            // Published By Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 16,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          height: 12,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
