import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:hris_flutter/core/widgets/app_image_thumbnail_preview.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/warning_letter/data/models/warning_letter_detail_model.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_bloc.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_event.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/warning_letter_detail/warning_letter_detail_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class WarningLetterDetailScreen extends StatefulWidget {
  final String id;

  const WarningLetterDetailScreen({
    super.key,
    required this.id,
  });

  @override
  State<WarningLetterDetailScreen> createState() =>
      _WarningLetterDetailScreenState();
}

class _WarningLetterDetailScreenState extends State<WarningLetterDetailScreen> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    context.read<WarningLetterDetailBloc>().add(
          FetchWarningLetterDetail(widget.id),
        );
  }

  Future<void> _handleDownloadAttachment(WarningLetterDetail detail) async {
    if (_isDownloading) return;

    final url = detail.attachmentUrl;
    if (url == null || url.trim().isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Tidak Ada Lampiran',
        message:
            'Surat peringatan ini belum memiliki lampiran berkas resmi untuk diunduh.',
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName =
          detail.attachmentFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final savePath = '${dir.path}/$sanitizedName';

      final dio = Dio();
      await dio.download(url, savePath);

      if (mounted) {
        final itemLabel = detail.isAttachmentImage ? 'Foto' : 'Dokumen';
        AppDialogUtil.showSuccess(
          context,
          title: 'Berhasil Diunduh',
          message: '$itemLabel "$sanitizedName" telah berhasil disimpan di perangkat.',
        );
      }
    } catch (_) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        AppDialogUtil.showError(
          context,
          title: 'Gagal Mengunduh',
          message: 'Terjadi gangguan saat mengunduh salinan lampiran surat peringatan.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _handleShare(WarningLetterDetail detail) async {
    final title = detail.displayTitle;
    final ref = detail.referenceNumber ?? '-';
    final recipient = detail.employee?.fullName ?? 'Pegawai';
    final validPeriod = detail.formattedPeriod;
    final url = detail.attachmentUrl ?? '';

    final shareText = StringBuffer()
      ..writeln('Surat Peringatan: $title')
      ..writeln('No. Referensi: $ref')
      ..writeln('Penerima: $recipient')
      ..writeln('Masa Berlaku: $validPeriod');

    if (url.isNotEmpty) {
      shareText.writeln('Tautan Dokumen: $url');
    }

    await SharePlus.instance.share(
      ShareParams(
        text: shareText.toString(),
        subject: 'Surat Peringatan - $ref',
      ),
    );
  }

  void _openPdfViewer(WarningLetterDetail detail) {
    final url = detail.attachmentUrl;
    if (url == null || url.trim().isEmpty) {
      AppDialogUtil.showWarning(
        context,
        title: 'Dokumen Belum Tersedia',
        message: 'Tautan dokumen lampiran tidak valid atau belum diunggah.',
      );
      return;
    }

    context.push(
      Routes.PDF_VIEWER,
      extra: {
        'title': 'Surat Peringatan - ${detail.referenceNumber ?? detail.displayTitle}',
        'fileName': detail.attachmentFileName,
        'fileUrl': url,
      },
    );
  }

  Widget _buildLevelBadge(WarningLetterDetail detail, bool isDark) {
    final level = detail.warningLetterType.level;
    Color bg;
    Color text;
    Color dot;

    switch (level) {
      case 1:
        bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        text = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        dot = const Color(0xFFF59E0B);
        break;
      case 2:
        bg = isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5);
        text = isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
        dot = const Color(0xFFF97316);
        break;
      case 3:
      default:
        bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        text = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        dot = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              detail.levelBadgeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(WarningLetterDetail detail, bool isDark) {
    final isActive = detail.isActive;
    final bg = isActive
        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final text = isActive
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final dot = isActive
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isActive ? 'Masih Berlaku' : 'Kadaluarsa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBannerCard(WarningLetterDetail detail, bool isDark) {
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final periodBoxBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.backgroundSubtle;
    final iconBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLevelBadge(detail, isDark),
              _buildStatusBadge(detail, isDark),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            detail.displayTitle,
            style: AppTypography.titleMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nomor Referensi: ${detail.referenceNumber ?? '-'}',
            style: AppTypography.bodyMedium.copyWith(
              color: subtitleCol,
              fontSize: 13.5,
            ),
          ),
          if (detail.sanction != null && detail.sanction!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF431407).withValues(alpha: 0.3)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF78350F)
                      : const Color(0xFFFDE68A),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SANKSI / KETENTUAN KHUSUS',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.sanction!.trim(),
                          style: AppTypography.bodySmall.copyWith(
                            color: textCol,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: periodBoxBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    LucideIcons.calendar,
                    color: brandColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MASA BERLAKU SANKSI',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail.formattedPeriod,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                LucideIcons.history,
                size: 16,
                color: subtitleCol,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diterbitkan pada ${detail.formattedCreatedAt} • Zona Waktu: ${detail.timezone}',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: subtitleCol,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRecipientCard(WarningLetterDetail detail, bool isDark) {
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final employee = detail.employee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: EmployeeInfoRow(
        name: employee?.fullName ?? 'Pegawai',
        role: employee?.position?.name ?? '',
        department: employee?.department?.name ?? '',
        company: employee?.company?.name,
        employeeId: employee?.employeeNumber ?? employee?.idNumber ?? '',
        avatarUrl: employee?.photoUrl,
        initials: employee?.initials,
        avatarSize: 44,
      ),
    );
  }

  Widget _buildIssuerCard(WarningLetterDetail detail, bool isDark) {
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final issuer = detail.issuedByEmployee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: EmployeeInfoRow(
        name: issuer?.fullName ?? 'Pejabat Penerbit',
        role: issuer?.position?.name ?? 'Manajemen Sumber Daya Manusia',
        department: issuer?.department?.name ?? '',
        company: issuer?.company?.name,
        employeeId: issuer?.employeeNumber ?? issuer?.idNumber ?? '',
        avatarUrl: issuer?.photoUrl,
        initials: issuer?.initials,
        avatarSize: 44,
      ),
    );
  }

  Widget _buildAttachmentCard(WarningLetterDetail detail, bool isDark) {
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final iconBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    if (!detail.hasAttachment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceCol,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                LucideIcons.fileQuestion,
                color: subtitleCol,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Dokumen Lampiran',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Surat peringatan diterbitkan tanpa dokumen atau foto fisik terlampir.',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (detail.isAttachmentImage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceCol,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    LucideIcons.image,
                    color: brandColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.attachmentFileName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Foto Lampiran Resmi',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.download,
                    color: brandColor,
                    size: 18,
                  ),
                  tooltip: 'Unduh Foto',
                  onPressed: () => _handleDownloadAttachment(detail),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppImageThumbnailPreview(
              imageUrl: detail.attachmentUrl,
              title: 'Foto Surat Peringatan',
              subtitle: 'Ref: ${detail.referenceNumber ?? detail.displayTitle}',
              height: 190,
              hintText: 'Ketuk foto untuk memperbesar tampilan (zoom)',
              hintIcon: LucideIcons.zoomIn,
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (detail.isAttachmentPdf) {
            _openPdfViewer(detail);
          } else {
            _handleDownloadAttachment(detail);
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: surfaceCol,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  detail.isAttachmentPdf
                      ? LucideIcons.fileText
                      : LucideIcons.file,
                  color: brandColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.attachmentFileName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.isAttachmentPdf
                          ? 'Dokumen PDF • Ketuk untuk melihat'
                          : 'Dokumen Resmi • Ketuk untuk mengunduh',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  LucideIcons.download,
                  color: brandColor,
                  size: 20,
                ),
                tooltip: 'Unduh Dokumen',
                onPressed: () => _handleDownloadAttachment(detail),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF8FAFC);
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 190,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    int? statusCode,
    bool isDark,
  ) {
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final is404 = statusCode == 404;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF450A0A)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                is404 ? LucideIcons.fileX : LucideIcons.alertCircle,
                color: const Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              is404 ? 'Surat Peringatan Tidak Ditemukan' : 'Gagal Memuat Detail',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!is404)
              AppButton(
                text: 'Coba Lagi',
                variant: AppButtonVariant.secondary,
                leadingIcon: LucideIcons.refreshCw,
                onPressed: () {
                  context.read<WarningLetterDetailBloc>().add(
                        FetchWarningLetterDetail(widget.id),
                      );
                },
              )
            else
              AppButton(
                text: 'Kembali',
                variant: AppButtonVariant.outlined,
                leadingIcon: LucideIcons.arrowLeft,
                onPressed: () => context.pop(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return BlocBuilder<WarningLetterDetailBloc, WarningLetterDetailState>(
      builder: (context, state) {
        WarningLetterDetail? detail;
        if (state is WarningLetterDetailLoaded) {
          detail = state.detail;
        }

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: surfaceCol,
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
                  'Detail Surat Peringatan',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail != null
                      ? 'Ref: ${detail.referenceNumber ?? '-'} • ${detail.displayTitle}'
                      : 'Memuat informasi...',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              if (detail != null) ...[
                IconButton(
                  icon: Icon(
                    LucideIcons.share2,
                    color: textCol,
                    size: 20,
                  ),
                  tooltip: 'Bagikan',
                  onPressed: () => _handleShare(detail!),
                ),
                if (detail.hasAttachment)
                  IconButton(
                    icon: Icon(
                      detail.isAttachmentImage
                          ? LucideIcons.image
                          : (detail.isAttachmentPdf
                              ? LucideIcons.printer
                              : LucideIcons.download),
                      color: textCol,
                      size: 20,
                    ),
                    tooltip: detail.isAttachmentImage
                        ? 'Lihat Foto'
                        : (detail.isAttachmentPdf
                            ? 'Lihat Dokumen'
                            : 'Unduh Dokumen'),
                    onPressed: () {
                      if (detail!.isAttachmentImage) {
                        AppImagePreviewDialog.show(
                          context,
                          imageUrl: detail.attachmentUrl,
                          title: 'Foto Surat Peringatan',
                          subtitle:
                              'Ref: ${detail.referenceNumber ?? detail.displayTitle}',
                        );
                      } else if (detail.isAttachmentPdf) {
                        _openPdfViewer(detail);
                      } else {
                        _handleDownloadAttachment(detail);
                      }
                    },
                  ),
              ],
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: borderCol,
              ),
            ),
          ),
          body: () {
            if (state is WarningLetterDetailLoading ||
                state is WarningLetterDetailInitial) {
              return _buildShimmerLoading(isDark);
            }

            if (state is WarningLetterDetailError) {
              return _buildErrorState(
                context,
                state.message,
                state.statusCode,
                isDark,
              );
            }

            if (detail == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              color: AppColors.brandTeal,
              onRefresh: () async {
                context.read<WarningLetterDetailBloc>().add(
                      const RefreshWarningLetterDetail(),
                    );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: AppSpacing.marginMobile,
                  right: AppSpacing.marginMobile,
                  top: AppSpacing.lg,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainBannerCard(detail, isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'PENERIMA SURAT PERINGATAN',
                      isDark,
                    ),
                    _buildRecipientCard(detail, isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'PEJABAT PENERBIT (ISSUED BY)',
                      isDark,
                    ),
                    _buildIssuerCard(detail, isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'LAMPIRAN DOKUMEN RESMI',
                      isDark,
                    ),
                    _buildAttachmentCard(detail, isDark),
                  ],
                ),
              ),
            );
          }(),
          bottomNavigationBar: detail == null
              ? null
              : Container(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  decoration: BoxDecoration(
                    color: surfaceCol,
                    border: Border(
                      top: BorderSide(color: borderCol, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: AppButton(
                      text: detail.isAttachmentImage
                          ? 'Unduh Foto Surat Peringatan'
                          : (detail.isAttachmentPdf
                              ? 'Unduh Salinan Surat Peringatan (PDF)'
                              : 'Unduh Salinan Lampiran Dokumen'),
                      leadingIcon: LucideIcons.download,
                      isLoading: _isDownloading,
                      onPressed: () => _handleDownloadAttachment(detail!),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
