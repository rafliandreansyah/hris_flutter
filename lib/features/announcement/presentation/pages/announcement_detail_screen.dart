import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';
import 'package:hris_flutter/features/announcement/domain/repositories/announcement_repository.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_bloc.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_event.dart';
import 'package:hris_flutter/features/announcement/presentation/bloc/announcement_detail/announcement_detail_state.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_detail_attachment_card.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_detail_author_card.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_detail_html_content.dart';
import 'package:hris_flutter/features/announcement/presentation/widgets/announcement_detail_shimmer_loading.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

/// Halaman Detail Pengumuman (Announcement Detail Screen)
/// Dirancang sesuai Google Stitch M3 "Teal Oasis" (Screen ID: `394b30e7761846f3abe9fa94b6298a1a`).
class AnnouncementDetailScreen extends StatelessWidget {
  final String id;
  final AnnouncementRepository? repository;
  final AnnouncementDetailBloc? bloc;

  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<AnnouncementDetailBloc>.value(
        value: bloc!,
        child: _AnnouncementDetailView(id: id),
      );
    }

    return BlocProvider<AnnouncementDetailBloc>(
      create: (context) => AnnouncementDetailBloc(
        repository: repository,
      )..add(AnnouncementDetailStarted(id)),
      child: _AnnouncementDetailView(id: id),
    );
  }
}

class _AnnouncementDetailView extends StatefulWidget {
  final String id;

  const _AnnouncementDetailView({required this.id});

  @override
  State<_AnnouncementDetailView> createState() =>
      _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<_AnnouncementDetailView> {
  bool _hasAcknowledged = false;

  void _handlePop() {
    if (context.canPop()) {
      context.pop(_hasAcknowledged);
    } else {
      context.go('/announcement');
    }
  }

  void _handleShare(AnnouncementDetailModel detail) {
    final text = StringBuffer()
      ..writeln('📢 ${detail.title}')
      ..writeln('Kategori: ${detail.categoryBadgeText}')
      ..writeln('Prioritas: ${detail.priorityDisplayName}');

    if (detail.publishedAt != null || detail.createdAt != null) {
      text.writeln('Tanggal: ${detail.formattedDateTime}');
    }

    if (detail.summary != null && detail.summary!.isNotEmpty) {
      text.writeln('\n${detail.summary}');
    }

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: detail.title,
      ),
    );
  }

  Future<void> _handleConfirmAcknowledge(BuildContext context) async {
    final confirmed = await AppDialogUtil.showConfirmation(
      context,
      title: 'Konfirmasi Pembacaan',
      message:
          'Dengan menekan tombol ini, Anda menyatakan telah membaca, memahami, dan menyetujui isi pengumuman ini.',
      confirmText: 'Ya, Konfirmasi',
      cancelText: 'Kembali',
    );

    if (confirmed == true && context.mounted) {
      context.read<AnnouncementDetailBloc>().add(
            const AnnouncementDetailAcknowledgeSubmitted(),
          );
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

    return BlocConsumer<AnnouncementDetailBloc, AnnouncementDetailState>(
      listener: (context, state) {
        if (state.isAcknowledgedSuccess) {
          _hasAcknowledged = true;
          AppDialogUtil.showSuccess(
            context,
            title: 'Konfirmasi Berhasil',
            message: state.actionMessage ??
                'Pengumuman telah berhasil dikonfirmasi.',
          );
        } else if (state.errorMessage != null && state.detail != null) {
          AppDialogUtil.showError(
            context,
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final detail = state.detail;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handlePop();
          },
          child: Scaffold(
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
                onPressed: _handlePop,
              ),
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detail Pengumuman',
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    detail != null
                        ? detail.scopeAndCategorySubtitle
                        : 'Official Announcement',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                if (detail != null)
                  IconButton(
                    icon: Icon(
                      LucideIcons.share2,
                      color: textCol,
                      size: 20,
                    ),
                    tooltip: 'Bagikan',
                    onPressed: () => _handleShare(detail),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(context, state, isDark),
            bottomNavigationBar: (detail != null && detail.requiresAcknowledgment)
                ? _buildBottomActionBar(context, detail, state, isDark)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnnouncementDetailState state,
    bool isDark,
  ) {
    // 1. Loading State
    if (state.status == AnnouncementDetailStatus.loading) {
      return const AnnouncementDetailShimmerLoading();
    }

    // 2. Error State
    if (state.status == AnnouncementDetailStatus.failure &&
        state.detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.alertCircle,
                  color: AppColors.errorRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Detail',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ??
                    'Terjadi kesalahan saat memuat pengumuman.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Coba Lagi',
                variant: AppButtonVariant.primary,
                width: 160,
                height: 44,
                leadingIcon: LucideIcons.refreshCw,
                onPressed: () {
                  context.read<AnnouncementDetailBloc>().add(
                        AnnouncementDetailStarted(widget.id),
                      );
                },
              ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    final hasHeroImage =
        detail.imageUrl != null && detail.imageUrl!.trim().isNotEmpty;
    final hasAuthor = detail.author != null;
    final hasAttachments = detail.attachments.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        context.read<AnnouncementDetailBloc>().add(
              const AnnouncementDetailRefreshed(),
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          12,
          AppSpacing.marginMobile,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Tags & Title & Date
            _buildTagsRow(detail, isDark),
            const SizedBox(height: 12),

            Text(
              detail.title,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),

            if (detail.formattedDateTime.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Diterbitkan: ${detail.formattedDateTime}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Section 2: Hero Image (Dihilangkan jika imageUrl null/kosong)
            if (hasHeroImage) ...[
              _buildHeroImage(detail.imageUrl!, isDark),
              const SizedBox(height: 20),
            ],

            // Section 3: Published By Card (Dihilangkan jika author null)
            if (hasAuthor) ...[
              AnnouncementDetailAuthorCard(author: detail.author!),
              const SizedBox(height: 20),
            ],

            // Section 4: Content Card (Perender HTML)
            AnnouncementDetailHtmlContent(htmlContent: detail.content),
            const SizedBox(height: 20),

            // Section 5: Attachments (Dihilangkan jika attachments null/kosong)
            if (hasAttachments) ...[
              Text(
                'DOKUMEN LAMPIRAN (${detail.attachments.length})',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detail.attachments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final attachment = detail.attachments[index];
                  return AnnouncementDetailAttachmentCard(
                    attachment: attachment,
                    announcementTitle: detail.title,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsRow(AnnouncementDetailModel detail, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainerHigh
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            detail.categoryBadgeText,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),

        // Priority Badge
        _buildPriorityTag(detail.priority, isDark),

        // Scope Badge
        if (detail.scope != null && detail.scope!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              detail.scopeDisplayName,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),

        // Pinned Tag
        if (detail.isPinned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandTeal,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.pin,
                  size: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'PINNED',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityTag(String priority, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (priority.toLowerCase()) {
      case 'urgent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'URGENT NOTICE';
        break;
      case 'high':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'HIGH PRIORITY';
        break;
      case 'medium':
        bg = isDark ? AppColors.darkSurfaceContainer : const Color(0xFFE2E8F0);
        fg = isDark ? AppColors.darkOnSurface : AppColors.onSurfaceVariant;
        label = 'MEDIUM';
        break;
      case 'low':
      default:
        bg =
            isDark ? AppColors.darkSurfaceContainerLow : const Color(0xFFF8FAFC);
        fg = isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
        label = 'LOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildHeroImage(String imageUrl, bool isDark) {
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFE2E8F0),
          highlightColor: isDark
              ? AppColors.darkSurfaceContainerHigh
              : const Color(0xFFF8FAFC),
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: 190,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.backgroundSubtle,
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.imageOff,
            size: 32,
            color: isDark
                ? AppColors.darkOnSurfaceVariant
                : AppColors.outlineVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    AnnouncementDetailModel detail,
    AnnouncementDetailState state,
    bool isDark,
  ) {
    final isAcknowledged =
        detail.userReadStatus?.isAcknowledged == true || state.isAcknowledgedSuccess;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: isAcknowledged
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.onSuccessContainer.withValues(alpha: 0.25)
                    : AppColors.successContainer,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.checkCircle2,
                    size: 18,
                    color: AppColors.onSuccessContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detail.userReadStatus?.formattedAcknowledgedAt.isNotEmpty ==
                            true
                        ? 'Dikonfirmasi: ${detail.userReadStatus!.formattedAcknowledgedAt}'
                        : 'Anda telah membaca & mengonfirmasi pengumuman ini',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSuccessContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            )
          : AppButton(
              text: 'Saya Mengerti & Telah Membaca (Acknowledge)',
              leadingIcon: LucideIcons.badgeCheck,
              isLoading: state.isAcknowledging,
              onPressed: () => _handleConfirmAcknowledge(context),
            ),
    );
  }
}
