import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Layar penampil dokumen PDF in-app menggunakan `syncfusion_flutter_pdfviewer`.
/// Dilengkapi dengan opsi Zoom, Toolbar Download, dan Toolbar Share dokumen.
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String fileName;
  final String fileUrl;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.fileUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  bool _isDownloading = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  /// Mengunduh file PDF ke penyimpanan lokal
  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = '${dir.path}/$sanitizedName';

      final dio = Dio();
      await dio.download(widget.fileUrl, savePath);

      if (mounted) {
        AppDialogUtil.showSuccess(
          context,
          title: 'Berhasil Diunduh',
          message: 'File "$sanitizedName" telah disimpan di perangkat.',
        );
      }
    } catch (_) {
      // Fallback membuka tautan unduhan via browser sistem
      final uri = Uri.tryParse(widget.fileUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  /// Membagikan dokumen PDF via share_plus
  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final dir = await getTemporaryDirectory();
      final sanitizedName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = '${dir.path}/$sanitizedName';

      final file = File(savePath);
      if (!await file.exists()) {
        final dio = Dio();
        await dio.download(widget.fileUrl, savePath);
      }

      await SharePlus.instance.share(
        ShareParams(
          text: '${widget.fileName}\n${widget.fileUrl}',
          subject: widget.fileName,
        ),
      );
    } catch (_) {
      // Fallback share URL langsung
      await SharePlus.instance.share(
        ShareParams(
          text: '${widget.fileName}\n${widget.fileUrl}',
          subject: widget.fileName,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.textSecondary;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: textCol,
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.fileName,
              style: AppTypography.titleSmall.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.title,
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Tombol Share PDF
          IconButton(
            icon: _isSharing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: brandColor,
                    ),
                  )
                : Icon(
                    LucideIcons.share2,
                    color: textCol,
                    size: 20,
                  ),
            tooltip: 'Bagikan PDF',
            onPressed: _handleShare,
          ),

          // Tombol Download PDF
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: brandColor,
                    ),
                  )
                : Icon(
                    LucideIcons.download,
                    color: brandColor,
                    size: 20,
                  ),
            tooltip: 'Unduh PDF',
            onPressed: _handleDownload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SfPdfViewer.network(
        widget.fileUrl,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (details) {
          if (mounted) {
            AppDialogUtil.showError(
              context,
              title: 'Gagal Membuka PDF',
              message: details.description,
            );
          }
        },
      ),
    );
  }
}
