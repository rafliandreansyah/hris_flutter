import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/share_link_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/whatsapp_icon.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/core/widgets/request_card_shimmer_loading.dart';
import 'package:hris_flutter/features/approver_share/data/models/approver_model.dart';
import 'package:hris_flutter/features/approver_share/domain/repositories/approver_share_repository.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_bloc.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_event.dart';
import 'package:hris_flutter/features/approver_share/presentation/bloc/approver_share_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Halaman daftar atasan yang berhak approve sebuah pengajuan.
/// Pengaju memilih atasan lalu mengirim link via WhatsApp / Email (kontak dari data pegawai).
/// Link selalu bisa disalin / dibagikan manual, termasuk saat daftar kosong atau gagal dimuat.
class ApproverShareScreen extends StatelessWidget {
  final ApproverShareArgs args;
  final ApproverShareRepository? repository;

  const ApproverShareScreen({super.key, required this.args, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApproverShareBloc(repository: repository)
        ..add(FetchApprovers(
          module: args.module.apiKey,
          requestId: args.requestId,
        )),
      child: _ApproverShareView(args: args),
    );
  }
}

class _ApproverShareView extends StatelessWidget {
  final ApproverShareArgs args;

  const _ApproverShareView({required this.args});

  Future<void> _open(BuildContext context, Uri uri, String appName) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppDialogUtil.showError(
        context,
        message: 'Tidak dapat membuka $appName di perangkat ini.',
      );
    }
  }

  void _shareElsewhere() {
    SharePlus.instance.share(
      ShareParams(text: args.message, subject: args.subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.background;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldBg,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bagikan ke Atasan',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: textCol,
            fontSize: 18,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderCol)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Salin Link',
                  height: 50,
                  leadingIcon: LucideIcons.link,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => ShareLinkUtil.copyLink(context, args.url),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: 'Bagikan Lainnya',
                  height: 50,
                  leadingIcon: LucideIcons.share2,
                  onPressed: _shareElsewhere,
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<ApproverShareBloc, ApproverShareState>(
        listener: (context, state) {
          if (state is ApproverShareError) {
            AppDialogUtil.showError(context, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is ApproverShareInitial || state is ApproverShareLoading) {
            return const RequestCardShimmerLoading(itemCount: 3);
          }

          final bloc = context.read<ApproverShareBloc>();
          Future<void> refresh() async => bloc.add(const RefreshApprovers());

          if (state is ApproverShareError) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: AppEmptyState(
                icon: LucideIcons.circleAlert,
                title: 'Gagal Memuat Atasan',
                subtitle: state.message,
                helperText:
                    'Anda tetap bisa menyalin link atau membagikannya lewat aplikasi lain.',
                actionText: 'Coba Lagi',
                actionIcon: LucideIcons.rotateCcw,
                onAction: () => bloc.add(FetchApprovers(
                  module: args.module.apiKey,
                  requestId: args.requestId,
                )),
              ),
            );
          }

          final approvers = (state as ApproverShareLoaded).approvers;
          if (approvers.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: AppEmptyState(
                icon: LucideIcons.userX,
                title: 'Belum Ada Atasan',
                subtitle:
                    'Belum ada atasan yang dapat menyetujui pengajuan ${args.module.label.toLowerCase()} ini. '
                    'Salin link lalu bagikan lewat aplikasi apa pun.',
                actionText: 'Salin Link',
                actionIcon: LucideIcons.link,
                onAction: () => ShareLinkUtil.copyLink(context, args.url),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              itemCount: approvers.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      'Pilih atasan yang akan menerima link pengajuan ${args.module.label.toLowerCase()}.',
                      style: AppTypography.bodySmall.copyWith(color: subtitleCol),
                    ),
                  );
                }
                return _ApproverCard(
                  approver: approvers[index - 1],
                  cardBg: cardBg,
                  borderCol: borderCol,
                  subtitleCol: subtitleCol,
                  onWhatsApp: (a) => _open(
                    context,
                    ShareLinkUtil.whatsAppUri(a.phone!, args.message),
                    'WhatsApp',
                  ),
                  onEmail: (a) => _open(
                    context,
                    ShareLinkUtil.emailUri(
                      a.email!,
                      subject: args.subject,
                      body: args.message,
                    ),
                    'aplikasi email',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApproverCard extends StatelessWidget {
  final ApproverModel approver;
  final Color cardBg;
  final Color borderCol;
  final Color subtitleCol;
  final ValueChanged<ApproverModel> onWhatsApp;
  final ValueChanged<ApproverModel> onEmail;

  const _ApproverCard({
    required this.approver,
    required this.cardBg,
    required this.borderCol,
    required this.subtitleCol,
    required this.onWhatsApp,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeInfoRow(
            name: approver.fullName,
            role: approver.position,
            department: approver.department,
            company: approver.company,
            employeeId: approver.employeeNumber,
            avatarUrl: approver.avatarUrl,
            avatarSize: 44,
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          if (!approver.hasPhone && !approver.hasEmail)
            Text(
              'Nomor HP & email atasan belum tersedia di data pegawai.',
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
            )
          else
            Row(
              children: [
                if (approver.hasPhone)
                  Expanded(
                    child: AppButton(
                      text: 'WhatsApp',
                      height: 44,
                      leading: const WhatsAppIcon(size: 18),
                      variant: AppButtonVariant.outlined,
                      onPressed: () => onWhatsApp(approver),
                    ),
                  ),
                if (approver.hasPhone && approver.hasEmail)
                  const SizedBox(width: AppSpacing.sm),
                if (approver.hasEmail)
                  Expanded(
                    child: AppButton(
                      text: 'Email',
                      height: 44,
                      leadingIcon: LucideIcons.mail,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => onEmail(approver),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
