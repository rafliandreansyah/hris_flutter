import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 4: Work Evidence Photo
/// Sesuai spesifikasi Google Stitch: "Section 4: Work Evidence"
class OvertimeDetailEvidenceCard extends StatelessWidget {
  final String? imageUrl;

  const OvertimeDetailEvidenceCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORK EVIDENCE PHOTO',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          if (hasImage) ...[
            AppImageThumbnailPreview(
              imageUrl: imageUrl,
              title: 'Foto Bukti Lembur',
              hintText:
                  'Task Progress Screenshot / Evidence • Tap to view full image',
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imageOff, size: 36, color: subtitleCol),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada foto bukti dilampirkan.',
                    style: AppTypography.bodySmall.copyWith(color: subtitleCol),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
