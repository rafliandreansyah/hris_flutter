import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder cards yang mencerminkan struktur kartu pengumuman (Announcement Card).
class AnnouncementShimmerLoading extends StatelessWidget {
  final int count;

  const AnnouncementShimmerLoading({
    super.key,
    this.count = 4,
  });

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
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: AppSpacing.md,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, index) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer banner (for the first card to mimic pinned announcement)
              if (index == 0)
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Category & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 90,
                          height: 14,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title placeholder (2 lines)
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 200,
                      height: 18,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description placeholder
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer line
                    Container(
                      height: 1,
                      color: baseColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 22,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
