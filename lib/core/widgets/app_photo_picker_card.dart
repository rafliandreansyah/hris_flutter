import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget picker foto interaktif terstandarisasi untuk seluruh **Halaman Form Pengajuan**
/// (Pengajuan Lembur, Pengajuan Cuti, Pengajuan Aktivitas, Rencana Aktivitas).
///
/// Menyediakan tampilan dashed box saat kosong, dan card preview 140px penuh saat foto
/// telah dipilih, lengkap dengan badge kompresi, tombol intip, tombol hapus, dan tombol
/// "Ganti Foto" sesuai acuan desain Pengajuan Aktivitas.
class AppPhotoPickerCard extends StatefulWidget {
  /// Berkas gambar terpilih saat ini
  final XFile? file;

  /// URL sampel atau gambar daring awal jika ada
  final String? sampleUrl;

  /// Hasil kompresi gambar saat ini
  final ImageCompressResult? compressResult;

  /// Status apakah proses kompresi non-blocking sedang berjalan
  final bool isCompressing;

  /// Batas ukuran kompresi dalam byte (default: 100 KB)
  final int maxSizeBytes;

  /// Callback ketika berkas foto atau hasil kompresi berubah
  final void Function(XFile? file, ImageCompressResult? compressResult)? onFileChanged;

  /// Callback ketika proses kompresi foto mulai/selesai
  final void Function(bool isCompressing)? onLoadingChanged;

  /// Callback error
  final void Function(String error)? onError;

  /// Teks judul placeholder saat belum ada foto
  final String uploadPlaceholderTitle;

  /// Teks subtitle placeholder saat belum ada foto
  final String uploadPlaceholderSubtitle;

  /// Judul sheet pemilihan sumber berkas
  final String sheetTitle;

  /// Judul pratinjau pada dialog
  final String previewTitle;

  /// Apakah mengizinkan opsi sampel gambar untuk testing/development
  final bool allowSample;

  /// Label tombol sampel
  final String sampleTitle;

  /// Subtitle tombol sampel
  final String sampleSubtitle;

  /// Nama berkas dummy sampel
  final String sampleFileName;

  /// Kunci pengujian
  final Key? uploadBoxKey;
  final Key? previewButtonKey;
  final Key? previewThumbnailKey;
  final Key? deleteButtonKey;
  final Key? changeButtonKey;

  const AppPhotoPickerCard({
    super.key,
    this.file,
    this.sampleUrl,
    this.compressResult,
    this.isCompressing = false,
    this.maxSizeBytes = ImageCompressUtil.defaultMaxSizeBytes,
    this.onFileChanged,
    this.onLoadingChanged,
    this.onError,
    this.uploadPlaceholderTitle = 'Tap to Capture or Upload Photo',
    this.uploadPlaceholderSubtitle = 'Kamera atau Galeri (Maksimal 100 KB)',
    this.sheetTitle = 'Pilih Sumber Dokumen / Foto',
    this.previewTitle = 'Foto Bukti',
    this.allowSample = true,
    this.sampleTitle = 'Gunakan Sampel Bukti',
    this.sampleSubtitle = 'Simulasi lampiran dokumen pendukung',
    this.sampleFileName = 'sample_evidence.jpg',
    this.uploadBoxKey,
    this.previewButtonKey,
    this.previewThumbnailKey,
    this.deleteButtonKey,
    this.changeButtonKey,
  });

  @override
  State<AppPhotoPickerCard> createState() => _AppPhotoPickerCardState();
}

class _AppPhotoPickerCardState extends State<AppPhotoPickerCard> {
  XFile? _internalFile;
  ImageCompressResult? _internalCompressResult;
  bool _internalIsCompressing = false;
  String? _internalSampleUrl;

  @override
  void initState() {
    super.initState();
    _internalFile = widget.file;
    _internalCompressResult = widget.compressResult;
    _internalIsCompressing = widget.isCompressing;
    _internalSampleUrl = widget.sampleUrl;
  }

  @override
  void didUpdateWidget(covariant AppPhotoPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file != oldWidget.file) {
      _internalFile = widget.file;
    }
    if (widget.compressResult != oldWidget.compressResult) {
      _internalCompressResult = widget.compressResult;
    }
    if (widget.isCompressing != oldWidget.isCompressing) {
      _internalIsCompressing = widget.isCompressing;
    }
    if (widget.sampleUrl != oldWidget.sampleUrl) {
      _internalSampleUrl = widget.sampleUrl;
    }
  }

  XFile? get _effectiveFile => _internalFile;
  ImageCompressResult? get _effectiveCompressResult => _internalCompressResult;
  bool get _effectiveIsCompressing => _internalIsCompressing;
  String? get _effectiveSampleUrl => _internalSampleUrl;

  String get _displayFileName {
    final raw = _effectiveFile?.name;
    if (raw != null && raw.isNotEmpty) {
      return raw.split(RegExp(r'[/\\]')).last;
    }
    return '';
  }

  bool get _hasPhoto => _effectiveFile != null || (_effectiveSampleUrl != null && _effectiveSampleUrl!.isNotEmpty);

  void _notifyLoading(bool loading) {
    setState(() => _internalIsCompressing = loading);
    widget.onLoadingChanged?.call(loading);
  }

  void _notifyChanged(XFile? file, ImageCompressResult? result) {
    setState(() {
      _internalFile = file;
      _internalCompressResult = result;
      if (file != null) {
        _internalSampleUrl = null;
      }
    });
    widget.onFileChanged?.call(file, result);
  }

  void _handlePreview(BuildContext context) {
    final targetFile = _effectiveCompressResult?.file ?? _effectiveFile;
    final name = targetFile?.name.split(RegExp(r'[/\\]')).last;

    AppImagePreviewDialog.show(
      context,
      xFile: targetFile,
      imageUrl: _effectiveSampleUrl,
      fileSizeBytes: _effectiveCompressResult?.compressedSizeBytes,
      title: (name != null && name.isNotEmpty) ? name : widget.previewTitle,
    );
  }

  void _handleDelete() {
    _notifyLoading(false);
    _notifyChanged(null, null);
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
        }).catchError((error) {
          if (mounted) {
            _notifyLoading(false);
            _notifyChanged(photo, null);
          }
        });
      }
    } catch (e) {
      if (mounted && widget.onError != null) {
        widget.onError!('Gagal mengambil foto: $e');
      }
    }
  }

  void _useSamplePhoto() {
    try {
      final tempFile = File('${Directory.systemTemp.path}/${widget.sampleFileName}');
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
    } catch (_) {
      setState(() {
        _internalSampleUrl = 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=600';
      });
    }
  }

  void _showPhotoOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                widget.sheetTitle,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(LucideIcons.camera, color: AppColors.brandTeal),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Gunakan kamera langsung'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(LucideIcons.image, color: AppColors.brandTeal),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Pilih gambar yang sudah ada'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (widget.allowSample)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(LucideIcons.sparkles, color: Color(0xFFD97706)),
                  ),
                  title: Text(widget.sampleTitle),
                  subtitle: Text(widget.sampleSubtitle),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _useSamplePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final subtitleCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    if (_hasPhoto) {
      return _buildSelectedPhotoCard(isDark, borderCol, subtitleCol);
    }

    return _buildEmptyDottedBox(isDark);
  }

  Widget _buildEmptyDottedBox(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: widget.uploadBoxKey ?? const ValueKey('upload_document_photo_box'),
        onTap: () => _showPhotoOptionsSheet(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.brandTeal.withValues(alpha: 0.1),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: AppColors.brandTeal,
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
            radius: const Radius.circular(12),
          ),
          childOnTop: true,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.brandTeal.withValues(alpha: 0.08)
                  : const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.camera,
                  size: 32,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.uploadPlaceholderTitle,
                  style: const TextStyle(
                    color: AppColors.brandTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.uploadPlaceholderSubtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPhotoCard(bool isDark, Color borderCol, Color subtitleCol) {
    final compressResult = _effectiveCompressResult;

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 1),
        color: isDark ? AppColors.darkSurfaceContainer : const Color(0xFFF1F5F9),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Tappable Photo Preview
          GestureDetector(
            key: widget.previewThumbnailKey ?? const ValueKey('preview_photo_thumbnail'),
            onTap: () => _handlePreview(context),
            child: _effectiveFile != null
                ? Image.file(
                    File(_effectiveFile!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(LucideIcons.image, size: 36, color: subtitleCol),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: _effectiveSampleUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Center(
                      child: Icon(LucideIcons.image, size: 36, color: subtitleCol),
                    ),
                  ),
          ),

          // 2. Top Left: Compressed File Size Badge
          if (compressResult != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.fileCheck,
                      size: 12,
                      color: AppColors.brandTealSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      kDebugMode
                          ? '${compressResult.compressedSizeFormatted} (Maks 100 KB • Hemat ${compressResult.savedPercentage.toStringAsFixed(0)}%)'
                          : '${compressResult.compressedSizeFormatted} (Maks 100 KB)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Loading Overlay saat Kompresi
          if (_effectiveIsCompressing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandTeal,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mengompresi foto...',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandTeal,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mohon tunggu sebentar (Maks 100 KB)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Top Right: Preview & Remove Action Buttons
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Intip Foto
                GestureDetector(
                  key: widget.previewButtonKey ?? const ValueKey('preview_photo_btn'),
                  onTap: () => _handlePreview(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.eye,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Hapus Foto
                GestureDetector(
                  key: widget.deleteButtonKey ?? const ValueKey('delete_photo_btn'),
                  onTap: _handleDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Left: File name badge
          if (_displayFileName.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        _displayFileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Bottom Right: "Ganti Foto" Pill Button
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              key: widget.changeButtonKey ?? const ValueKey('change_photo_btn'),
              onTap: () => _showPhotoOptionsSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.camera, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Ganti Foto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
