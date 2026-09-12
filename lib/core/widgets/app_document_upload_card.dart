import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';

/// Komponen terpusat untuk kartu pengunggahan dokumen pendukung / bukti kerja
/// (digunakan pada Pengajuan Lembur, Pengajuan Cuti / Izin, dan Aktivitas).
class AppDocumentUploadCard extends StatefulWidget {
  final String title;
  final IconData titleIcon;
  final bool isRequired;
  final String requiredTagText;
  final String optionalTagText;
  final String uploadPlaceholderTitle;
  final String uploadPlaceholderSubtitle;
  final String sheetTitle;
  final String sampleTitle;
  final String sampleSubtitle;
  final String sampleFileName;
  final bool allowSample;
  final XFile? file;
  final ImageCompressResult? compressResult;
  final bool isCompressing;
  final int maxSizeBytes;
  final ValueChanged<XFile?>? onFileChanged;
  final void Function(XFile? file, ImageCompressResult? result)?
      onFileWithCompressionChanged;
  final void Function(String errorMessage)? onError;
  final VoidCallback? onCancel;
  final Key? uploadBoxKey;
  final Key? deleteButtonKey;
  final Key? previewButtonKey;
  final Key? previewThumbnailKey;

  const AppDocumentUploadCard({
    super.key,
    this.title = 'DOKUMEN PENDUKUNG',
    this.titleIcon = LucideIcons.paperclip,
    this.isRequired = false,
    this.requiredTagText = 'Wajib Diunggah',
    this.optionalTagText = 'Opsional',
    this.uploadPlaceholderTitle = 'Lampirkan Foto Bukti',
    this.uploadPlaceholderSubtitle = 'Kamera atau Galeri (Maksimal 100 KB)',
    this.sheetTitle = 'Pilih Sumber Dokumen / Foto',
    this.sampleTitle = 'Gunakan Sampel Bukti',
    this.sampleSubtitle = 'Simulasi lampiran dokumen pendukung',
    this.sampleFileName = 'sample_proof.jpg',
    this.allowSample = true,
    this.file,
    this.compressResult,
    this.isCompressing = false,
    this.maxSizeBytes = ImageCompressUtil.defaultMaxSizeBytes,
    this.onFileChanged,
    this.onFileWithCompressionChanged,
    this.onError,
    this.onCancel,
    this.uploadBoxKey,
    this.deleteButtonKey,
    this.previewButtonKey,
    this.previewThumbnailKey,
  });

  @override
  State<AppDocumentUploadCard> createState() => _AppDocumentUploadCardState();
}

class _AppDocumentUploadCardState extends State<AppDocumentUploadCard> {
  XFile? _localFile;
  ImageCompressResult? _localCompressResult;
  bool _localIsCompressing = false;

  XFile? get _effectiveFile => widget.file ?? _localFile;
  ImageCompressResult? get _effectiveCompressResult =>
      widget.compressResult ?? _localCompressResult;
  bool get _effectiveIsCompressing =>
      widget.isCompressing || _localIsCompressing;

  void _notifyLoading(bool loading) {
    if (mounted) {
      setState(() => _localIsCompressing = loading);
    }
  }

  void _notifyChanged(XFile? file, ImageCompressResult? result) {
    if (mounted) {
      setState(() {
        _localFile = file;
        _localCompressResult = result;
      });
    }
    widget.onFileChanged?.call(file);
    widget.onFileWithCompressionChanged?.call(file, result);
  }

  void _handleDelete() {
    _notifyLoading(false);
    _notifyChanged(null, null);
  }

  void _handlePreview(BuildContext context) {
    final targetFile = _effectiveCompressResult?.file ?? _effectiveFile;
    if (targetFile == null) return;
    AppImagePreviewDialog.show(
      context,
      xFile: targetFile,
      fileSizeBytes: _effectiveCompressResult?.compressedSizeBytes,
      title: targetFile.name.isNotEmpty
          ? targetFile.name
          : 'Dokumen Bukti',
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        _notifyLoading(true);
        _notifyChanged(photo, null);

        ImageCompressUtil.compressXFile(
          photo,
          maxSizeBytes: widget.maxSizeBytes,
          onLoadingChanged: (loading) {
            if (mounted) _notifyLoading(loading);
          },
        ).then((result) {
          if (mounted) {
            _notifyLoading(false);
            _notifyChanged(result.file, result);
          }
        }).catchError((_) {
          if (mounted) {
            _notifyLoading(false);
            _notifyChanged(photo, null);
          }
        });
      } else if (photo == null && mounted) {
        widget.onCancel?.call();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.info, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Unggah gambar dibatalkan'),
              ],
            ),
            backgroundColor: AppColors.onBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && widget.onError != null) {
        widget.onError!('Gagal mengambil foto: $e');
      }
    }
  }

  void _useSamplePhoto() {
    try {
      final tempFile =
          File('${Directory.systemTemp.path}/${widget.sampleFileName}');
      if (!tempFile.existsSync()) {
        const dummyBytes = [
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
          0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
          0x00, 0x43, 0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00,
          0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x09, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
          0x00, 0x00, 0x3F, 0x00, 0x7F, 0x00, 0xFF, 0xD9,
        ];
        tempFile.writeAsBytesSync(dummyBytes);
      }
      final sampleXFile = XFile(tempFile.path);
      _notifyLoading(true);
      _notifyChanged(sampleXFile, null);

      ImageCompressUtil.compressXFile(
        sampleXFile,
        maxSizeBytes: widget.maxSizeBytes,
        onLoadingChanged: (loading) {
          if (mounted) _notifyLoading(loading);
        },
      ).then((result) {
        if (mounted) {
          _notifyLoading(false);
          _notifyChanged(result.file, result);
        }
      }).catchError((_) {
        if (mounted) {
          _notifyLoading(false);
          _notifyChanged(sampleXFile, null);
        }
      });
    } catch (e) {
      if (mounted && widget.onError != null) {
        widget.onError!('Gagal memuat sampel foto: $e');
      }
    }
  }

  void _showPhotoOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.sheetTitle,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDFA),
                  child: Icon(LucideIcons.camera, color: Color(0xFF0D9488)),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Gunakan kamera perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDFA),
                  child: Icon(LucideIcons.image, color: Color(0xFF0D9488)),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Pilih foto dari penyimpanan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (widget.allowSample)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDFA),
                    child:
                        Icon(LucideIcons.fileCheck2, color: Color(0xFF0D9488)),
                  ),
                  title: Text(widget.sampleTitle),
                  subtitle: Text(widget.sampleSubtitle),
                  onTap: () {
                    Navigator.pop(ctx);
                    _useSamplePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final inputBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.titleIcon,
                    color: AppColors.brandTeal,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (widget.isRequired)
                _buildTag(
                  label: widget.requiredTagText,
                  bgColor: const Color(0xFFFEF2F2),
                  textColor: const Color(0xFFDC2626),
                )
              else
                _buildTag(
                  label: widget.optionalTagText,
                  bgColor: const Color(0xFFF1F5F9),
                  textColor: const Color(0xFF64748B),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload Dotted Box or Selected Preview Card
          if (_effectiveFile == null) ...[
            InkWell(
              key: widget.uploadBoxKey ??
                  const ValueKey('upload_document_photo_box'),
              onTap: () => _showPhotoOptionsSheet(context),
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: widget.isRequired
                      ? const Color(0xFFF87171)
                      : borderCol,
                  strokeWidth: 1.5,
                  dashPattern: const [6, 4],
                  radius: const Radius.circular(AppRadius.input),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.brandTeal.withValues(alpha: 0.1),
                        child: const Icon(
                          LucideIcons.camera,
                          color: AppColors.brandTeal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.uploadPlaceholderTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.uploadPlaceholderSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  // Thumbnail (dapat diklik untuk pratinjau foto)
                  GestureDetector(
                    key: widget.previewThumbnailKey ??
                        const ValueKey('preview_photo_thumbnail'),
                    onTap: () => _handlePreview(context),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.file(
                            File(_effectiveFile!.path),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : Colors.grey.shade300,
                              child: Icon(
                                LucideIcons.fileText,
                                color: subtitleCol,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            color: Colors.black.withValues(
                              alpha: _effectiveIsCompressing ? 0.55 : 0.28,
                            ),
                          ),
                          child: Center(
                            child: _effectiveIsCompressing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.maximize2,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Informasi Berkas & Ukuran Kompresi
                  Expanded(
                    child: GestureDetector(
                      onTap: _effectiveIsCompressing
                          ? null
                          : () => _handlePreview(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _effectiveFile!.name.isNotEmpty
                                ? _effectiveFile!.name
                                : 'dokumen_bukti.jpg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_effectiveIsCompressing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.brandTeal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mengompresi foto...',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.brandTeal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mohon tunggu sebentar (Maks 100 KB)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            )
                          else if (_effectiveCompressResult != null)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  'Ukuran: ${_effectiveCompressResult!.compressedSizeFormatted}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _effectiveCompressResult!.compressedSizeBytes <= ImageCompressUtil.defaultMaxSizeBytes
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFD97706),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // Informasi persentase hemat hanya ditampilkan pada mode development (kDebugMode)
                                if (kDebugMode)
                                  Text(
                                    '(Hemat ${_effectiveCompressResult!.savedPercentage.toStringAsFixed(0)}%)',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            )
                          else
                            Text(
                              'Ketuk untuk pratinjau foto',
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Tombol Aksi: Pratinjau Foto & Hapus
                  IconButton(
                    key: widget.previewButtonKey ??
                        const ValueKey('preview_photo_btn'),
                    tooltip: 'Lihat Foto',
                    icon: Icon(
                      LucideIcons.eye,
                      color: _effectiveIsCompressing
                          ? borderCol
                          : AppColors.brandTeal,
                      size: 20,
                    ),
                    onPressed: _effectiveIsCompressing
                        ? null
                        : () => _handlePreview(context),
                  ),
                  IconButton(
                    key: widget.deleteButtonKey ??
                        const ValueKey('delete_photo_btn'),
                    tooltip: 'Hapus Foto',
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    onPressed: _handleDelete,
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
