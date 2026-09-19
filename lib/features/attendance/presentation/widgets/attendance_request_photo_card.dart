import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 5: Photo Proof Card (Foto Bukti Kehadiran / Kunjungan)
/// Sesuai spesifikasi Google Stitch Screen ID: `c0c581134c61461a8585cf77a66f1dd7`.
///
/// **Catatan**: Jika metode presensi (`method`) bukan foto, komponen ini
/// otomatis disembunyikan ([SizedBox.shrink]) sesuai instruksi sistem.
class AttendanceRequestPhotoCard extends StatelessWidget {
  final AttendanceRequestDetailData detail;

  const AttendanceRequestPhotoCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    // ── KONDISI KHUSUS: Sembunyikan jika bukan metode foto ─────────────
    if (!detail.isPhotoMethod) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);

    final hasInImage =
        detail.filePath != null && detail.filePath!.trim().isNotEmpty;
    final hasOutImage =
        detail.filePathOut != null && detail.filePathOut!.trim().isNotEmpty;
    final isOutOnly = detail.isOut;

    final primaryOutImage = detail.filePathOut ?? detail.filePath;
    final hasPrimaryOutImage =
        primaryOutImage != null && primaryOutImage.trim().isNotEmpty;

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOTO BUKTI KEHADIRAN / KUNJUNGAN',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.isInOut && hasInImage && hasOutImage) ...[
            // Tampilkan foto masuk dan pulang jika kedua foto ada
            AppImageThumbnailPreview(
              imageUrl: detail.filePath,
              title: 'Foto Bukti Masuk',
              subtitle: detail.formattedDate,
              hintText:
                  'Foto Presensi Masuk • Ketuk untuk memperbesar foto',
              height: 180.0,
            ),
            const SizedBox(height: 12),
            AppImageThumbnailPreview(
              imageUrl: detail.filePathOut,
              title: 'Foto Bukti Pulang',
              subtitle: detail.formattedDate,
              hintText:
                  'Foto Presensi Pulang • Ketuk untuk memperbesar foto',
              height: 180.0,
            ),
          ] else if (isOutOnly && hasPrimaryOutImage) ...[
            AppImageThumbnailPreview(
              imageUrl: primaryOutImage,
              title: 'Foto Bukti Presensi Pulang',
              subtitle: detail.formattedDate,
              hintText:
                  'Selfie / Foto Lokasi Kunjungan • Ketuk untuk memperbesar foto',
              height: 190.0,
            ),
          ] else if (hasInImage) ...[
            AppImageThumbnailPreview(
              imageUrl: detail.filePath,
              title: detail.isIn
                  ? 'Foto Bukti Presensi Masuk'
                  : 'Foto Bukti Presensi',
              subtitle: detail.formattedDate,
              hintText:
                  'Selfie / Foto Lokasi Kunjungan • Ketuk untuk memperbesar foto',
              height: 190.0,
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderCol.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 36,
                    color: subtitleCol.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada foto bukti dilampirkan.',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                    ),
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
