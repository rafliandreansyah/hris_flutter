import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';

/// Komponen kartu pengunggahan dokumen pendukung / bukti kerja
/// (digunakan pada Pengajuan Lembur, Pengajuan Cuti / Izin, dll).
///
/// Menggunakan [AppPhotoPickerCard] untuk interaksi unggah, kompresi, dan pratinjau foto.
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
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      widget.titleIcon,
                      color: AppColors.brandTeal,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
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
              ),
              const SizedBox(width: 8),
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

          // Reusable Photo Picker Card
          AppPhotoPickerCard(
            file: _effectiveFile,
            compressResult: _effectiveCompressResult,
            isCompressing: _effectiveIsCompressing,
            maxSizeBytes: widget.maxSizeBytes,
            sheetTitle: widget.sheetTitle,
            allowSample: widget.allowSample,
            sampleTitle: widget.sampleTitle,
            sampleFileName: widget.sampleFileName,
            uploadPlaceholderTitle: widget.uploadPlaceholderTitle,
            uploadPlaceholderSubtitle: widget.uploadPlaceholderSubtitle,
            previewTitle: widget.title,
            uploadBoxKey: widget.uploadBoxKey ??
                const ValueKey('upload_document_photo_box'),
            deleteButtonKey: widget.deleteButtonKey ??
                const ValueKey('delete_photo_btn'),
            previewButtonKey: widget.previewButtonKey ??
                const ValueKey('preview_photo_btn'),
            previewThumbnailKey: widget.previewThumbnailKey ??
                const ValueKey('preview_photo_thumbnail'),
            onFileChanged: (file, result) {
              _notifyChanged(file, result);
            },
            onLoadingChanged: (loading) {
              _notifyLoading(loading);
            },
            onError: (err) {
              widget.onError?.call(err);
            },
          ),
        ],
      ),
    );
  }
}
