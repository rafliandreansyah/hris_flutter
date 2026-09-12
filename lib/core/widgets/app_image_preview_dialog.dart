import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modal dialog terpusat untuk menampilkan pratinjau foto secara penuh
/// dengan dukungan perbesaran (pinch-to-zoom 0.5x - 4.0x) dan pergeseran (pan).
///
/// Mendukung berkas lokal ([XFile] / [File]) maupun URL gambar daring ([imageUrl]).
class AppImagePreviewDialog extends StatelessWidget {
  final XFile? xFile;
  final File? file;
  final String? imageUrl;
  final String? title;
  final int? fileSizeBytes;
  final String? subtitle;

  const AppImagePreviewDialog({
    super.key,
    this.xFile,
    this.file,
    this.imageUrl,
    this.title,
    this.fileSizeBytes,
    this.subtitle,
  });

  /// Helper statis untuk menampilkan dialog pratinjau gambar secara praktis
  static Future<void> show(
    BuildContext context, {
    XFile? xFile,
    File? file,
    String? imageUrl,
    String? title,
    int? fileSizeBytes,
    String? subtitle,
  }) async {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) => AppImagePreviewDialog(
        xFile: xFile,
        file: file,
        imageUrl: imageUrl,
        title: title,
        fileSizeBytes: fileSizeBytes,
        subtitle: subtitle,
      ),
    );
  }

  File? get _effectiveFile {
    if (file != null) return file;
    if (xFile != null) return File(xFile!.path);
    return null;
  }

  String get _effectiveTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (xFile != null && xFile!.name.isNotEmpty) return xFile!.name;
    if (file != null) {
      return file!.path.split(RegExp(r'[/\\]')).last;
    }
    return 'Pratinjau Foto';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFile = _effectiveFile;
    final hasImage = effectiveFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Area Konten Gambar dengan InteractiveViewer
          Positioned.fill(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: hasImage
                      ? (effectiveFile != null
                          ? Image.file(
                              effectiveFile,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _buildErrorState(),
                            )
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _buildErrorState(),
                            ))
                      : _buildErrorState(),
                ),
              ),
            ),
          ),

          // Header Overlay Atas: Nama Berkas, Badge Ukuran, dan Tombol Tutup
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _effectiveTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (fileSizeBytes != null || subtitle != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (fileSizeBytes != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: fileSizeBytes! <= ImageCompressUtil.defaultMaxSizeBytes
                                        ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                                        : const Color(0xFFEAB308).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: fileSizeBytes! <= ImageCompressUtil.defaultMaxSizeBytes
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFFACC15),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        fileSizeBytes! <= ImageCompressUtil.defaultMaxSizeBytes
                                            ? LucideIcons.check
                                            : LucideIcons.alertCircle,
                                        size: 10,
                                        color: fileSizeBytes! <= ImageCompressUtil.defaultMaxSizeBytes
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFFFDE047),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ImageCompressResult.formatBytes(fileSizeBytes!)} (Maks 100 KB)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (subtitle != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  subtitle!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      key: const ValueKey('close_preview_dialog_btn'),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                      tooltip: 'Tutup Pratinjau',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Overlay Bawah: Petunjuk Zoom
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.zoomIn, color: Colors.white70, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'Cubit atau geser untuk memperbesar foto',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.imageOff, color: Colors.white70, size: 48),
          SizedBox(height: 12),
          Text(
            'Gagal memuat pratinjau gambar',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
