import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_image_preview_dialog.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/reimbursement_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/reimbursement_detail/reimbursement_detail_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/disburse_action_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/reimbursement_action_dialog.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Reimbursement & Aksi Approval/Pencairan Kasir.
class ReimbursementDetailScreen extends StatelessWidget {
  final String id;
  final ReimbursementRepository? repository;

  const ReimbursementDetailScreen({
    super.key,
    required this.id,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReimbursementDetailBloc>(
      create: (context) => ReimbursementDetailBloc(
        repository: repository ?? context.read<ReimbursementRepository>(),
      )..add(ReimbursementDetailFetched(id)),
      child: _ReimbursementDetailView(id: id),
    );
  }
}

class _ReimbursementDetailView extends StatefulWidget {
  final String id;

  const _ReimbursementDetailView({required this.id});

  @override
  State<_ReimbursementDetailView> createState() =>
      _ReimbursementDetailViewState();
}

class _ReimbursementDetailViewState extends State<_ReimbursementDetailView> {
  bool _hasMutated = false;

  void _handleShare(ReimbursementDetailModel detail) {
    final text = StringBuffer()
      ..writeln('🧾 DETAIL REIMBURSEMENT')
      ..writeln('Nomor Klaim: ${detail.claimNumber}')
      ..writeln('Judul: ${detail.title}')
      ..writeln('Pemohon: ${detail.employee.fullName}')
      ..writeln('Status: ${detail.status}')
      ..writeln('Total Klaim: ${formatRupiah(detail.requestedAmount)}')
      ..writeln('Rekening: ${detail.bankName ?? '-'} - ${detail.bankAccountNumber ?? '-'} a.n ${detail.bankAccountHolder ?? '-'}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Reimbursement ${detail.claimNumber}',
      ),
    );
  }

  void _onApproveAction(bool isApproved) async {
    final note = await ReimbursementActionDialog.show(
      context,
      isApproved: isApproved,
      title: isApproved
          ? 'Setujui Pengajuan Reimbursement'
          : 'Tolak Pengajuan Reimbursement',
      description: isApproved
          ? 'Pengajuan akan diteruskan ke kasir untuk proses pencairan dana.'
          : 'Pengajuan akan ditolak dan pemohon akan menerima pemberitahuan.',
      notesHint: isApproved
          ? 'Catatan persetujuan (opsional)...'
          : 'Alasan penolakan pengajuan...',
    );

    if (note != null && mounted) {
      _hasMutated = true;
      context.read<ReimbursementDetailBloc>().add(
            ReimbursementDetailApproved(
              isApproved: isApproved,
              approverNotes: isApproved ? note : null,
              rejectionReason: !isApproved ? note : null,
            ),
          );
    }
  }

  void _navigateToDisburse(ReimbursementDetailModel detail) async {
    final args = DisburseScreenArgs(
      claimId: detail.id,
      claimNumber: detail.claimNumber,
      amount: detail.approvedAmount ?? detail.requestedAmount,
      employeeName: detail.employee.fullName,
      bankName: detail.bankName,
      bankAccountNumber: detail.bankAccountNumber,
      bankAccountHolder: detail.bankAccountHolder,
    );

    final res = await context.push<bool>(Routes.DISBURSE_ACTION, extra: args);
    if (res == true && mounted) {
      _hasMutated = true;
      context
          .read<ReimbursementDetailBloc>()
          .add(ReimbursementDetailFetched(widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.background;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: Text(
            'Detail Reimbursement',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 18,
            ),
          ),
          elevation: 0,
          backgroundColor: scaffoldBg,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textCol),
            onPressed: () => context.pop(_hasMutated),
          ),
          actions: [
            BlocBuilder<ReimbursementDetailBloc, ReimbursementDetailState>(
              builder: (context, state) {
                if (state.detail == null) return const SizedBox();
                return IconButton(
                  icon: Icon(LucideIcons.share2, color: textCol),
                  onPressed: () => _handleShare(state.detail!),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar:
            BlocBuilder<ReimbursementDetailBloc, ReimbursementDetailState>(
          builder: (context, state) {
            final detail = state.detail;
            if (detail == null) return const SizedBox();

            final status = detail.status.toLowerCase();

            // Status Requested: Munculkan Tombol Setujui & Tolak
            if (status == 'requested') {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderCol)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Tolak',
                          leadingIcon: LucideIcons.x,
                          variant: AppButtonVariant.outlined,
                          foregroundColor: const Color(0xFFEF4444),
                          borderColor: const Color(0xFFEF4444),
                          height: 48,
                          isLoading: state.isActionLoading,
                          onPressed: state.isActionLoading
                              ? null
                              : () => _onApproveAction(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Setujui',
                          leadingIcon: LucideIcons.check,
                          variant: AppButtonVariant.primary,
                          height: 48,
                          isLoading: state.isActionLoading,
                          onPressed: state.isActionLoading
                              ? null
                              : () => _onApproveAction(true),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Status Approved: Munculkan Tombol Cairkan Dana
            if (status == 'approved') {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderCol)),
                ),
                child: SafeArea(
                  child: AppButton(
                    text: 'Cairkan Dana (Kasir / Finance)',
                    leadingIcon: LucideIcons.banknote,
                    variant: AppButtonVariant.primary,
                    height: 48,
                    onPressed: () => _navigateToDisburse(detail),
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
        body: BlocConsumer<ReimbursementDetailBloc, ReimbursementDetailState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            if (state.actionSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccessMessage!),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ReimbursementDetailStatus.loading &&
                state.detail == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final detail = state.detail;
            if (detail == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.fileX,
                        size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat detail reimbursement',
                      style: AppTypography.titleMedium.copyWith(color: textCol),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Coba Lagi',
                      width: 140,
                      onPressed: () {
                        context
                            .read<ReimbursementDetailBloc>()
                            .add(ReimbursementDetailFetched(widget.id));
                      },
                    ),
                  ],
                ),
              );
            }

            final statusEnum = parseExpenseStatus(detail.status);

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ReimbursementDetailBloc>()
                    .add(ReimbursementDetailFetched(widget.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Card (Nomor Klaim, Status, Judul, Total)
                    _buildOverviewCard(
                      detail: detail,
                      statusEnum: statusEnum,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      brandColor: brandColor,
                    ),
                    const SizedBox(height: 14),

                    // 2. Info Pemohon
                    _buildEmployeeCard(
                      employee: detail.employee,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                    ),
                    const SizedBox(height: 14),

                    // 3. Rekening Bank Penerima
                    if (detail.bankAccountNumber != null &&
                        detail.bankAccountNumber!.isNotEmpty) ...[
                      _buildBankCard(
                        detail: detail,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. Rincian Nota Pengeluaran (Line Items)
                    _buildItemsCard(
                      items: detail.items,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      brandColor: brandColor,
                    ),
                    const SizedBox(height: 14),

                    // 5. Lampiran Bukti Nota (Attachments)
                    if (detail.attachments.isNotEmpty) ...[
                      _buildAttachmentsCard(
                        attachments: detail.attachments,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 6. Catatan Approver / Penolakan jika ada
                    if ((detail.approverNotes != null &&
                            detail.approverNotes!.isNotEmpty) ||
                        (detail.rejectionReason != null &&
                            detail.rejectionReason!.isNotEmpty)) ...[
                      _buildNotesCard(
                        approverNotes: detail.approverNotes,
                        rejectionReason: detail.rejectionReason,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 7. Timeline Persetujuan (Approval Histories)
                    if (detail.approvalHistories.isNotEmpty) ...[
                      _buildApprovalHistoryCard(
                        histories: detail.approvalHistories,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required ReimbursementDetailModel detail,
    required ExpenseStatus statusEnum,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    final isSettlement = detail.type == 'cash_advance_settlement';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  detail.claimNumber,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: textCol,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusEnum.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusEnum.label,
                  style: TextStyle(
                    color: statusEnum.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isSettlement
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF0D9488))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSettlement ? 'Settlement Kasbon' : 'Out-of-Pocket',
                  style: TextStyle(
                    color: isSettlement
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (detail.submittedAt != null)
                Text(
                  DateFormat('dd MMM yyyy').format(detail.submittedAt!),
                  style: TextStyle(color: subtitleCol, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            detail.title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 16,
            ),
          ),
          if (detail.description != null &&
              detail.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail.description!,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Nominal Klaim',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(detail.requestedAmount),
                      style: AppTypography.titleMedium.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                if (detail.approvedAmount != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Nominal Disetujui',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(detail.approvedAmount!),
                        style: AppTypography.titleMedium.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard({
    required ExpenseEmployeeModel employee,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: resolveFileUrl(employee.photoUrl),
            name: employee.fullName,
            size: 46,
            showBorder: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${employee.position ?? '-'} • ${employee.department ?? '-'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 12,
                  ),
                ),
                if (employee.employeeId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'NIP: ${employee.employeeId}',
                    style: TextStyle(color: subtitleCol, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard({
    required ReimbursementDetailModel detail,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, size: 18, color: brandColor),
              const SizedBox(width: 8),
              Text(
                'Rekening Penerima',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail.bankName ?? '-',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${detail.bankAccountNumber ?? '-'} a.n. ${detail.bankAccountHolder ?? '-'}',
            style: AppTypography.bodyMedium.copyWith(
              color: subtitleCol,
              fontSize: 13,
            ),
          ),
          if (detail.paymentMethod != null &&
              detail.paymentMethod!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Metode: ${formatDisbursementMethod(detail.paymentMethod)}',
              style: TextStyle(
                color: brandColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard({
    required List<ReimbursementLineItemModel> items,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian Nota Biaya (${items.length})',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.receipt,
                        size: 16, color: brandColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textCol,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.merchant ?? 'Non-merchant'} • ${item.formattedDate}',
                          style: TextStyle(color: subtitleCol, fontSize: 12),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: subtitleCol,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRupiah(item.requestedAmount),
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: brandColor,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard({
    required List<ReimbursementAttachmentModel> attachments,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lampiran Bukti Nota (${attachments.length})',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final att = attachments[index];
                final fullUrl = resolveFileUrl(att.fileUrl) ?? '';

                return InkWell(
                  onTap: () {
                    AppImagePreviewDialog.show(
                      context,
                      imageUrl: fullUrl,
                      title: att.fileName,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.backgroundSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderCol),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              LucideIcons.fileText,
                              size: 28,
                              color: subtitleCol,
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        const Center(
                          child: Icon(
                            LucideIcons.eye,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard({
    String? approverNotes,
    String? rejectionReason,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
  }) {
    final isRejected = rejectionReason != null && rejectionReason.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRejected ? const Color(0xFFEF4444) : borderCol,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRejected ? LucideIcons.alertTriangle : LucideIcons.messageSquare,
                size: 18,
                color: isRejected ? const Color(0xFFEF4444) : AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                isRejected ? 'Alasan Penolakan' : 'Catatan Approver',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isRejected ? const Color(0xFFEF4444) : textCol,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (isRejected ? rejectionReason : approverNotes) ?? '-',
            style: AppTypography.bodySmall.copyWith(
              color: textCol,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalHistoryCard({
    required List<ReimbursementApprovalHistoryModel> histories,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Persetujuan',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: histories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final h = histories[index];
              final isApp = h.status.toLowerCase() == 'approved';

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isApp
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isApp ? LucideIcons.check : LucideIcons.x,
                      size: 14,
                      color: isApp
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.approverName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textCol,
                            fontSize: 13,
                          ),
                        ),
                        if (h.notes != null && h.notes!.isNotEmpty)
                          Text(
                            h.notes!,
                            style: TextStyle(color: subtitleCol, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (h.createdAtDateTime != null)
                    Text(
                      DateFormat('dd/MM/yy HH:mm')
                          .format(h.createdAtDateTime!),
                      style: TextStyle(color: subtitleCol, fontSize: 11),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
