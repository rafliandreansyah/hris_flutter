import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

/// Kartu item Pengumuman (Announcement Card) sesuai desain Stitch M3 "Teal Oasis".
/// Menampilkan banner Pinned jika `isPinned == true`, badge kategori & prioritas,
/// cuplikan konten adaptif, cover gambar (jika tersedia), serta status konfirmasi.
class AnnouncementCard extends StatelessWidget {
  final AnnouncementItem announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textPrimaryCol =
        isDark ? AppColors.darkOnSurface : AppColors.textPrimary;
    final textSecondaryCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.textSecondary;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final description = announcement.displayDescription;
    final hasImage = announcement.imageUrl != null &&
        announcement.imageUrl!.trim().isNotEmpty;
    final formattedDate = announcement.formattedDate;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pinned Banner (Hanya muncul jika isPinned == true)
              if (announcement.isPinned) _buildPinnedBanner(isDark),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Header Row: Kategori, Prioritas, & Tanggal Publikasi
                    _buildHeaderRow(
                      isDark: isDark,
                      textSecondaryCol: textSecondaryCol,
                      formattedDate: formattedDate,
                    ),
                    const SizedBox(height: 10),

                    // 3. Judul Pengumuman
                    Text(
                      announcement.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: textPrimaryCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 4. Deskripsi / Cuplikan Konten (Dihilangkan jika null atau kosong)
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textSecondaryCol,
                          fontSize: 13,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 5. Gambar Cover (Dihilangkan jika imageUrl null atau kosong)
                    if (hasImage) ...[
                      const SizedBox(height: 12),
                      _buildImageCover(announcement.imageUrl!, isDark),
                    ],

                    // 6. Footer Strip: Status Konfirmasi & Aksi "Lihat Detail"
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: borderCol.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Acknowledgment (hanya jika requiresAcknowledgment == true)
                          if (announcement.requiresAcknowledgment)
                            _buildAcknowledgmentBadge(
                              isAcknowledged: announcement.isAcknowledged,
                              isDark: isDark,
                            )
                          else
                            const SizedBox.shrink(),

                          // Aksi Lihat Detail
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: AppTypography.labelMedium.copyWith(
                                  color: brandColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.arrowRight,
                                size: 15,
                                color: brandColor,
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildPinnedBanner(bool isDark) {
    final bannerBg = isDark
        ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
        : AppColors.primaryContainer;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(
            color: brandColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.pin,
            size: 13,
            color: brandColor,
          ),
          const SizedBox(width: 6),
          Text(
            'PINNED ANNOUNCEMENT',
            style: AppTypography.labelSmall.copyWith(
              color: brandColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow({
    required bool isDark,
    required Color textSecondaryCol,
    required String formattedDate,
  }) {
    final categoryBg = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF1F5F9);
    final categoryFg =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Row(
      children: [
        // Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: categoryBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            announcement.categoryBadgeText,
            style: AppTypography.labelSmall.copyWith(
              color: categoryFg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Priority Badge
        _buildPriorityBadge(announcement.priority, isDark),

        const Spacer(),

        // Tanggal & Unread Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!announcement.isRead) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            if (formattedDate.isNotEmpty)
              Text(
                formattedDate,
                style: AppTypography.bodySmall.copyWith(
                  color: textSecondaryCol,
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority, bool isDark) {
    Color bg;
    Color fg;
    String label;
    bool showDot = false;

    switch (priority.toLowerCase()) {
      case 'urgent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Urgent';
        showDot = true;
        break;
      case 'high':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Tinggi';
        showDot = true;
        break;
      case 'medium':
        bg = isDark
            ? AppColors.darkSurfaceContainer
            : const Color(0xFFE2E8F0);
        fg = isDark
            ? AppColors.darkOnSurface
            : AppColors.onSurfaceVariant;
        label = 'Menengah';
        break;
      case 'low':
      default:
        bg = isDark
            ? AppColors.darkSurfaceContainerLow
            : const Color(0xFFF8FAFC);
        fg = isDark
            ? AppColors.darkOnSurfaceVariant
            : const Color(0xFF64748B);
        label = 'Rendah';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCover(String imageUrl, bool isDark) {
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: borderCol, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFE2E8F0),
          highlightColor: isDark
              ? AppColors.darkSurfaceContainerHigh
              : const Color(0xFFF8FAFC),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: 130,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.backgroundSubtle,
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.imageOff,
            size: 28,
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.outlineVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgmentBadge({
    required bool isAcknowledged,
    required bool isDark,
  }) {
    if (isAcknowledged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.onSuccessContainer.withValues(alpha: 0.3)
              : AppColors.successContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.checkCheck,
              size: 13,
              color: isDark ? AppColors.success : AppColors.onSuccessContainer,
            ),
            const SizedBox(width: 4),
            Text(
              'Sudah Dikonfirmasi',
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? AppColors.success : AppColors.onSuccessContainer,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.info,
            size: 13,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: 4),
          Text(
            'Perlu Konfirmasi',
            style: AppTypography.labelSmall.copyWith(
              color: const Color(0xFF92400E),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
