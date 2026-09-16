import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceProofCard extends StatelessWidget {
  final AttendanceDetailModel detail;

  const AttendanceProofCard({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    // Hide if not photo method or if photo file path is absent
    if (!detail.isPhotoMethod) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final photoUrl = detail.filePath!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              const Icon(
                LucideIcons.camera,
                size: 18,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.proofAttachment ?? 'Bukti Foto Presensi',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Clickable Photo Container with Watermark Overlay & Center Zoom Icon
          AppImageThumbnailPreview(
            imageUrl: photoUrl,
            height: 200,
            title: l10n?.proofAttachment ?? 'Bukti Foto Presensi',
            hintText: l10n?.tapToPreview ?? 'Ketuk untuk memperbesar foto',
            customOverlay: Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${detail.formattedDate} • ${detail.formattedTime24}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
