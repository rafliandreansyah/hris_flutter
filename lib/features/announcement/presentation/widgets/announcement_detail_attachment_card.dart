import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kartu item lampiran dokumen sesuai Google Stitch M3.
/// Jika lampiran bertipe PDF, mengetuk kartu akan membuka `PdfViewerScreen`
/// yang dilengkapi dengan fitur zoom, download, dan share.
class AnnouncementDetailAttachmentCard extends StatelessWidget {
  final AnnouncementAttachment attachment;
  final String announcementTitle;

  const AnnouncementDetailAttachmentCard({
    super.key,
    required this.attachment,
    required this.announcementTitle,
  });

  void _handleOpen(BuildContext context) async {
    if (attachment.isPdf) {
      context.push(
        Routes.PDF_VIEWER,
        extra: {
          'title': announcementTitle,
          'fileName': attachment.fileName,
          'fileUrl': attachment.fileUrl,
        },
      );
    } else {
      final uri = Uri.tryParse(attachment.fileUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

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
          onTap: () => _handleOpen(context),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: attachment.isPdf
                        ? const Color(0xFFFEE2E2)
                        : (isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.primaryContainer),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    attachment.isPdf
                        ? LucideIcons.fileText
                        : LucideIcons.paperclip,
                    size: 22,
                    color: attachment.isPdf
                        ? const Color(0xFFB91C1C)
                        : brandColor,
                  ),
                ),
                const SizedBox(width: 12),

                // File Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: AppTypography.titleSmall.copyWith(
                          color: textPrimaryCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        attachment.subtitleLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: textSecondaryCol,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Action Button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        attachment.isPdf
                            ? LucideIcons.eye
                            : LucideIcons.download,
                        size: 14,
                        color: brandColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attachment.isPdf ? 'Lihat' : 'Unduh',
                        style: AppTypography.labelSmall.copyWith(
                          color: brandColor,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
