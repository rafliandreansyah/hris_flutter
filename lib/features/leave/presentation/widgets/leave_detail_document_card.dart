import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Dokumen Pendukung / Surat Dokter sesuai desain Stitch:
/// - Hanya dirender jika filePath != null && filePath.isNotEmpty
/// - Thumbnail foto bukti dengan tombol zoom di tengah
/// - Tap membuka dialog preview foto ukuran penuh dengan pinch-to-zoom
class LeaveDetailDocumentCard extends StatelessWidget {
  final String imageUrl;

  const LeaveDetailDocumentCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUPPORTING DOCUMENT',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          AppImageThumbnailPreview(
            imageUrl: imageUrl,
            title: 'Dokumen Pendukung Cuti',
            hintText:
                "Doctor's Note / Medical Proof Photo • Tap to view full image",
            hintIcon: LucideIcons.camera,
          ),
        ],
      ),
    );
  }
}
