import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Pengumuman / Feed Updates Dashboard.
/// Menampilkan pengumuman terbaru, atau pesan info jika belum ada pengumuman.
class UpdatesFeedCard extends StatelessWidget {
  final bool hasAnnouncement;
  final String? title;
  final String? timeAndCategory;
  final VoidCallback? onSeeAll;
  final VoidCallback? onItemTap;

  const UpdatesFeedCard({
    super.key,
    this.hasAnnouncement = true,
    this.title = 'Townhall Meeting this Friday at 4 PM',
    this.timeAndCategory = '2h ago · Company Announcement',
    this.onSeeAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF1F5F9);
    final iconBoxBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final isAvailable = hasAnnouncement && title != null && title!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Updates',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isAvailable)
              GestureDetector(
                onTap: onSeeAll ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua Pengumuman segera dibuka'),
                        ),
                      );
                    },
                child: Text(
                  'See All',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Jika Belum Ada Pengumuman
        if (!isAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineMuted
                    : AppColors.outlineMuted.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.bellOff,
                    size: 20,
                    color: labelCol,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tidak ada pengumuman',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saat ini belum ada pengumuman terbaru dari perusahaan',
                        style: AppTypography.labelSmall.copyWith(
                          color: labelCol,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Announcement Item
          Material(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onItemTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(title!)),
                    );
                  },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineMuted
                        : AppColors.outlineMuted.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBoxBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.megaphone,
                        size: 20,
                        color: iconCol,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAndCategory ?? 'Company Announcement',
                            style: AppTypography.labelSmall.copyWith(
                              color: labelCol,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
