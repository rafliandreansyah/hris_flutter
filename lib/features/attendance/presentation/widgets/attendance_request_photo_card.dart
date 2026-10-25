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
    if (!detail.isPhotoMethod && !detail.isLivenessMethod) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.darkOnBackground;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                detail.isLivenessMethod
                    ? 'VERIFIKASI WAJAH LIVENESS AI'
                    : 'FOTO BUKTI KEHADIRAN / KUNJUNGAN',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (detail.isLivenessMethod)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 13,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Terverifikasi Liveness AI',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (detail.isLivenessMethod &&
              (detail.livenessScore != null || detail.similarityScore != null)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.brandTeal.withValues(alpha: 0.1)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 14, color: AppColors.brandTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Skor Liveness: ${_formatScore(detail.livenessScore)} • Kemiripan: ${_formatScore(detail.similarityScore)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (detail.isInOut && hasInImage && hasOutImage) ...[
            // Tampilkan foto masuk dan pulang jika kedua foto ada
            AppImageThumbnailPreview(
              imageUrl: detail.filePath,
              title: 'Foto Bukti Masuk',
              subtitle: detail.formattedDate,
              hintText:
                  'Foto Presensi Masuk • Ketuk untuk memperbesar foto',
              height: 280.0,
            ),
            const SizedBox(height: 12),
            AppImageThumbnailPreview(
              imageUrl: detail.filePathOut,
              title: 'Foto Bukti Pulang',
              subtitle: detail.formattedDate,
              hintText:
                  'Foto Presensi Pulang • Ketuk untuk memperbesar foto',
              height: 280.0,
            ),
          ] else if (isOutOnly && hasPrimaryOutImage) ...[
            AppImageThumbnailPreview(
              imageUrl: primaryOutImage,
              title: 'Foto Bukti Presensi Pulang',
              subtitle: detail.formattedDate,
              hintText:
                  'Selfie / Foto Lokasi Kunjungan • Ketuk untuk memperbesar foto',
              height: 280.0,
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
              height: 280.0,
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : AppColors.backgroundSubtle,
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

/// Skor null (mis. tidak dihitung server) ditampilkan "-", bukan 100%.
String _formatScore(double? value) =>
    value == null ? '-' : '${(value * 100).toStringAsFixed(1)}%';
