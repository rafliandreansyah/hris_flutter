import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/reimbursement/data/models/cash_advance_detail_model.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/cash_advance_detail/cash_advance_detail_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/pages/disburse_action_screen.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/cash_advance_refund_dialog.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/reimbursement_action_dialog.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Halaman Detail Permohonan Kasbon (Cash Advance) & Pengembalian Dana.
class CashAdvanceDetailScreen extends StatelessWidget {
  final String id;
  final ReimbursementRepository? repository;

  const CashAdvanceDetailScreen({
    super.key,
    required this.id,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CashAdvanceDetailBloc>(
      create: (context) => CashAdvanceDetailBloc(
        repository: repository ?? context.read<ReimbursementRepository>(),
      )..add(CashAdvanceDetailFetched(id)),
      child: _CashAdvanceDetailView(id: id),
    );
  }
}

class _CashAdvanceDetailView extends StatefulWidget {
  final String id;

  const _CashAdvanceDetailView({required this.id});

  @override
  State<_CashAdvanceDetailView> createState() => _CashAdvanceDetailViewState();
}

class _CashAdvanceDetailViewState extends State<_CashAdvanceDetailView> {
  bool _hasMutated = false;

  void _handleShare(CashAdvanceDetailModel detail) {
    final text = StringBuffer()
      ..writeln('💵 DETAIL KASBON (CASH ADVANCE)')
      ..writeln('Nomor Kasbon: ${detail.advanceNumber}')
      ..writeln('Judul: ${detail.title}')
      ..writeln('Keperluan: ${detail.purpose}')
      ..writeln('Pemohon: ${detail.employee.fullName}')
      ..writeln('Status: ${detail.status}')
      ..writeln('Nominal Diajukan: ${formatRupiah(detail.requestedAmount)}')
      ..writeln('Sisa Belum Selesai: ${formatRupiah(detail.remainingAmount)}');

    SharePlus.instance.share(
      ShareParams(
        text: text.toString(),
        subject: 'Kasbon ${detail.advanceNumber}',
      ),
    );
  }

  void _onApproveAction(CashAdvanceDetailModel detail, bool isApproved) async {
    final note = await ReimbursementActionDialog.show(
      context,
      isApproved: isApproved,
      title: isApproved ? 'Setujui Permohonan Kasbon' : 'Tolak Kasbon',
      description: isApproved
          ? 'Permohonan kasbon akan disetujui sebesar ${formatRupiah(detail.requestedAmount)} dan diteruskan ke kasir.'
          : 'Permohonan kasbon akan ditolak.',
      notesHint: isApproved
          ? 'Catatan persetujuan (opsional)...'
          : 'Alasan penolakan kasbon...',
    );

    if (note != null && mounted) {
      _hasMutated = true;
      context.read<CashAdvanceDetailBloc>().add(
            CashAdvanceDetailApproved(
              isApproved: isApproved,
              approvedAmount: isApproved ? detail.requestedAmount : null,
              approverNotes: note,
            ),
          );
    }
  }

  void _navigateToDisburse(CashAdvanceDetailModel detail) async {
    final args = DisburseScreenArgs(
      claimId: detail.id,
      claimNumber: detail.advanceNumber,
      amount: detail.approvedAmount ?? detail.requestedAmount,
      employeeName: detail.employee.fullName,
      isCashAdvance: true,
    );

    final res = await context.push<bool>(Routes.DISBURSE_ACTION, extra: args);
    if (res == true && mounted) {
      _hasMutated = true;
      context
          .read<CashAdvanceDetailBloc>()
          .add(CashAdvanceDetailFetched(widget.id));
    }
  }

  void _openRefundDialog(CashAdvanceDetailModel detail) async {
    final result = await CashAdvanceRefundDialog.show(
      context,
      maxAmount: detail.remainingAmount,
    );

    if (result != null && mounted) {
      _hasMutated = true;
      context.read<CashAdvanceDetailBloc>().add(
            CashAdvanceRefundSubmitted(
              amount: result.amount,
              method: result.paymentMethod,
              notes: result.notes,
              proofFile: result.receiptFile,
            ),
          );
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
            'Detail Kasbon',
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
            BlocBuilder<CashAdvanceDetailBloc, CashAdvanceDetailState>(
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
            BlocBuilder<CashAdvanceDetailBloc, CashAdvanceDetailState>(
          builder: (context, state) {
            final detail = state.detail;
            if (detail == null) return const SizedBox();

            final status = detail.status.toLowerCase();

            // 1. Status Requested: Tombol Approval
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
                              : () => _onApproveAction(detail, false),
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
                              : () => _onApproveAction(detail, true),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Status Approved: Tombol Pencairan Dana
            if (status == 'approved') {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderCol)),
                ),
                child: SafeArea(
                  child: AppButton(
                    text: 'Cairkan Kasbon (Kasir / Finance)',
                    leadingIcon: LucideIcons.banknote,
                    variant: AppButtonVariant.primary,
                    height: 48,
                    onPressed: () => _navigateToDisburse(detail),
                  ),
                ),
              );
            }

            // 3. Status Disbursed: Tombol Settlement & Refund
            if (status == 'disbursed' && detail.remainingAmount > 0) {
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
                          text: 'Kembalikan Sisa',
                          leadingIcon: LucideIcons.handCoins,
                          variant: AppButtonVariant.outlined,
                          height: 48,
                          isLoading: state.isActionLoading,
                          onPressed: state.isActionLoading
                              ? null
                              : () => _openRefundDialog(detail),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Selesaikan Nota',
                          leadingIcon: LucideIcons.receiptText,
                          variant: AppButtonVariant.primary,
                          height: 48,
                          onPressed: () async {
                            final res = await context.push<bool>(
                              Routes.CREATE_REIMBURSEMENT,
                              extra: detail.id,
                            );
                            if (!context.mounted) return;
                            if (res == true) {
                              _hasMutated = true;
                              context
                                  .read<CashAdvanceDetailBloc>()
                                  .add(CashAdvanceDetailFetched(widget.id));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
        body: BlocConsumer<CashAdvanceDetailBloc, CashAdvanceDetailState>(
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
            if (state.status == CashAdvanceDetailStatus.loading &&
                state.detail == null) {
              return const Center(child: CircularProgressIndicator());
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
                      'Gagal memuat detail kasbon',
                      style: AppTypography.titleMedium.copyWith(color: textCol),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Coba Lagi',
                      width: 140,
                      onPressed: () {
                        context
                            .read<CashAdvanceDetailBloc>()
                            .add(CashAdvanceDetailFetched(widget.id));
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
                    .read<CashAdvanceDetailBloc>()
                    .add(CashAdvanceDetailFetched(widget.id));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Overview Card
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

                    // 3. Status Penyelesaian & Sisa Kasbon
                    if (detail.status.toLowerCase() == 'disbursed' ||
                        detail.status.toLowerCase() == 'settled') ...[
                      _buildSettlementProgressCard(
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

                    // 4. Riwayat Pengembalian Dana Kasbon (Refunds)
                    if (detail.refunds.isNotEmpty) ...[
                      _buildRefundsCard(
                        refunds: detail.refunds,
                        isDark: isDark,
                        cardBg: cardBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        subtitleCol: subtitleCol,
                        brandColor: brandColor,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 5. Catatan Approver jika ada
                    if (detail.approverNotes != null &&
                        detail.approverNotes!.isNotEmpty) ...[
                      Container(
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
                                const Icon(LucideIcons.messageSquare,
                                    size: 18, color: AppColors.brandTeal),
                                const SizedBox(width: 8),
                                Text(
                                  'Catatan Approver',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: textCol,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              detail.approverNotes!,
                              style: AppTypography.bodySmall.copyWith(
                                color: textCol,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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
    required CashAdvanceDetailModel detail,
    required ExpenseStatus statusEnum,
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
              Expanded(
                child: Text(
                  detail.advanceNumber,
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Kasbon Operasional',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
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
          const SizedBox(height: 4),
          Text(
            detail.purpose,
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (detail.settlementDeadline != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  LucideIcons.calendarClock,
                  size: 15,
                  color: detail.isOverdue
                      ? const Color(0xFFEF4444)
                      : subtitleCol,
                ),
                const SizedBox(width: 6),
                Text(
                  'Batas Settlement: ${detail.deadlineDateTime != null ? DateFormat('dd MMMM yyyy').format(detail.deadlineDateTime!) : (detail.settlementDeadline ?? '-')}',
                  style: TextStyle(
                    color: detail.isOverdue
                        ? const Color(0xFFEF4444)
                        : subtitleCol,
                    fontWeight: detail.isOverdue
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
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
                      'Nominal Diajukan',
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
                        'Telah Dicairkan',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiah(detail.disbursedAmount),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementProgressCard({
    required CashAdvanceDetailModel detail,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    final progress = detail.settlementProgress.clamp(0.0, 1.0);

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
                'Status Penyelesaian Kasbon',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 14.5,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: brandColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainer
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0
                    ? const Color(0xFF10B981)
                    : brandColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telah Dipertanggungjawabkan',
                      style: TextStyle(color: subtitleCol, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(detail.settledAmount + detail.refundedAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sisa Kasbon',
                      style: TextStyle(color: subtitleCol, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(detail.remainingAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: detail.remainingAmount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefundsCard({
    required List<CashAdvanceRefundModel> refunds,
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
            'Riwayat Pengembalian Sisa (${refunds.length})',
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
            itemCount: refunds.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, index) {
              final r = refunds[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowDownLeft,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatRupiah(r.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textCol,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${r.paymentMethod.toUpperCase()} • ${r.formattedDate}',
                          style: TextStyle(color: subtitleCol, fontSize: 11.5),
                        ),
                        if (r.notes != null && r.notes!.isNotEmpty)
                          Text(
                            r.notes!,
                            style: TextStyle(color: subtitleCol, fontSize: 11.5),
                          ),
                      ],
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
}
