import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Komponen reusable untuk pratinjau gambar bukti pada **Halaman Detail**
/// (Detail Lembur, Detail Cuti, Detail Presensi, Timeline Progres Aktivitas).
///
/// Menyajikan thumbnail cover dengan **indikator ikon zoom lingkaran di tengah**
/// sesuai standar desain Google Stitch M3, serta membuka [AppImagePreviewDialog]
/// secara terpusat ketika diketuk.
class AppImageThumbnailPreview extends StatelessWidget {
  /// URL gambar daring
  final String? imageUrl;

  /// Berkas lokal berupa [File]
  final File? file;

  /// Berkas lokal berupa [XFile]
  final XFile? xFile;

  /// Judul yang ditampilkan pada modal dialog pratinjau
  final String? title;

  /// Subtitle atau teks keterangan pada modal dialog
  final String? subtitle;

  /// Tinggi thumbnail (default: 160.0)
  final double height;

  /// Lebar thumbnail (default: double.infinity)
  final double width;

  /// Radius sudut thumbnail (default: [AppRadius.input] = 12.0)
  final BorderRadius? borderRadius;

  /// Apakah menampilkan indikator zoom lingkaran di tengah (default: true)
  final bool showCenterIcon;

  /// Ikon di tengah (default: [LucideIcons.zoomIn])
  final IconData centerIcon;

  /// Ukuran ikon di tengah (default: 20.0)
  final double centerIconSize;

  /// Aksi kustom saat thumbnail diketuk (jika null, membuka [AppImagePreviewDialog])
  final VoidCallback? onTap;

  /// Widget overlay kustom di atas gambar (misal: watermark tanggal/jam presensi)
  final Widget? customOverlay;

  /// Teks petunjuk di bawah thumbnail (misal: 'Ketuk untuk memperbesar foto')
  final String? hintText;

  /// Ikon petunjuk di bawah thumbnail (default: [LucideIcons.info])
  final IconData? hintIcon;

  const AppImageThumbnailPreview({
    super.key,
    this.imageUrl,
    this.file,
    this.xFile,
    this.title,
    this.subtitle,
    this.height = 160.0,
    this.width = double.infinity,
    this.borderRadius,
    this.showCenterIcon = true,
    this.centerIcon = LucideIcons.zoomIn,
    this.centerIconSize = 20.0,
    this.onTap,
    this.customOverlay,
    this.hintText,
    this.hintIcon,
  });

  bool get _hasImage {
    if (file != null) return true;
    if (xFile != null) return true;
    return imageUrl != null && imageUrl!.trim().isNotEmpty;
  }

  bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    AppImagePreviewDialog.show(
      context,
      imageUrl: imageUrl,
      file: file,
      xFile: xFile,
      title: title ?? 'Pratinjau Foto Bukti',
      subtitle: subtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.input);
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final subtitleCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final placeholderBg = isDark ? AppColors.darkSurfaceContainer : AppColors.backgroundSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _handleTap(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Base Image Container
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: effectiveRadius,
                  border: Border.all(color: borderCol, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(placeholderBg, subtitleCol),
              ),

              // 2. Custom Overlay (misal Watermark Timestamp Absensi)
              ?customOverlay,

              // 3. Center Zoom Indicator (Stitch M3 Design)
              if (showCenterIcon && _hasImage)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    centerIcon,
                    color: const Color(0xFF131B2E),
                    size: centerIconSize,
                  ),
                ),
            ],
          ),
        ),

        // 4. Baris Petunjuk di Bawah Thumbnail (Opsional)
        if (hintText != null && hintText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hintIcon ?? LucideIcons.info,
                size: 14,
                color: subtitleCol,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hintText!,
                  style: TextStyle(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImage(Color placeholderBg, Color subtitleCol) {
    if (file != null) {
      return Image.file(
        file!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(placeholderBg, subtitleCol),
      );
    }

    if (xFile != null) {
      return Image.file(
        File(xFile!.path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(placeholderBg, subtitleCol),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: placeholderBg,
          child: Center(
            child: _isTest
                ? const SizedBox.shrink()
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandTeal,
                    ),
                  ),
          ),
        ),
        errorWidget: (_, _, _) => _buildErrorPlaceholder(placeholderBg, subtitleCol),
      );
    }

    return _buildErrorPlaceholder(placeholderBg, subtitleCol);
  }

  Widget _buildErrorPlaceholder(Color placeholderBg, Color subtitleCol) {
    return Container(
      color: placeholderBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 36,
              color: subtitleCol,
            ),
            const SizedBox(height: 8),
            Text(
              'Foto Bukti Terlampir',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
