import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_photo_picker_card.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/disburse_action/disburse_action_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Argumen navigasi menuju [DisburseActionScreen].
class DisburseScreenArgs {
  final String claimId;
  final String claimNumber;
  final double amount;
  final String employeeName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final bool isCashAdvance;

  const DisburseScreenArgs({
    required this.claimId,
    required this.claimNumber,
    required this.amount,
    required this.employeeName,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.isCashAdvance = false,
  });
}

/// Halaman Aksi Pencairan Kasir Multi-Metode (Transfer, Tunai, Payroll).
class DisburseActionScreen extends StatelessWidget {
  final DisburseScreenArgs args;
  final ReimbursementRepository? repository;

  const DisburseActionScreen({
    super.key,
    required this.args,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DisburseActionBloc>(
      create: (context) => DisburseActionBloc(
        repository: repository ?? context.read<ReimbursementRepository>(),
      ),
      child: _DisburseActionView(args: args),
    );
  }
}

class _DisburseActionView extends StatefulWidget {
  final DisburseScreenArgs args;

  const _DisburseActionView({required this.args});

  @override
  State<_DisburseActionView> createState() => _DisburseActionViewState();
}

class _DisburseActionViewState extends State<_DisburseActionView> {
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit(String method) {
    context.read<DisburseActionBloc>().add(
          DisburseSubmitted(
            claimId: widget.args.claimId,
            paymentReference: _refController.text.trim().isEmpty
                ? null
                : _refController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            bankName: widget.args.bankName,
            bankAccountNumber: widget.args.bankAccountNumber,
            bankAccountHolder: widget.args.bankAccountHolder,
          ),
        );
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Pencairan Dana',
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
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderCol)),
        ),
        child: SafeArea(
          child: BlocBuilder<DisburseActionBloc, DisburseActionState>(
            builder: (context, state) {
              return AppButton(
                text: 'Konfirmasi Pencairan Dana',
                leadingIcon: LucideIcons.checkCircle2,
                variant: AppButtonVariant.primary,
                height: 48,
                isLoading: state.isSubmitting,
                onPressed:
                    state.isSubmitting ? null : () => _submit(state.method),
              );
            },
          ),
        ),
      ),
      body: BlocConsumer<DisburseActionBloc, DisburseActionState>(
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

          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dana berhasil dicairkan!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop(true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ringkasan Pengajuan
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.args.claimNumber,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textCol,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Siap Dicairkan',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Penerima: ${widget.args.employeeName}',
                        style: TextStyle(color: subtitleCol, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nominal Cair:',
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleCol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatRupiah(widget.args.amount),
                            style: AppTypography.titleMedium.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Pilihan Metode Pencairan (3 Opsi)
                Text(
                  'Pilih Metode Pencairan',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMethodSelector(state, isDark, brandColor, textCol),
                const SizedBox(height: 18),

                // 3. Detail Sesuai Metode Terpilih
                if (state.method == 'manual_transfer') ...[
                  _buildTransferForm(
                    state: state,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    subtitleCol: subtitleCol,
                    brandColor: brandColor,
                  ),
                ] else if (state.method == 'cash') ...[
                  _buildCashForm(
                    state: state,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    subtitleCol: subtitleCol,
                    brandColor: brandColor,
                  ),
                ] else ...[
                  _buildPayrollForm(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    subtitleCol: subtitleCol,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodSelector(
    DisburseActionState state,
    bool isDark,
    Color brandColor,
    Color textCol,
  ) {
    return Column(
      children: [
        _buildMethodCard(
          title: 'Transfer Manual (Bank Transfer)',
          subtitle: 'Transfer via m-Banking/ATM ke rekening pegawai',
          icon: LucideIcons.arrowLeftRight,
          isSelected: state.method == 'manual_transfer',
          onTap: () {
            context
                .read<DisburseActionBloc>()
                .add(const DisburseMethodChanged('manual_transfer'));
          },
          isDark: isDark,
          brandColor: brandColor,
          textCol: textCol,
        ),
        const SizedBox(height: 10),
        _buildMethodCard(
          title: 'Uang Tunai (Petty Cash / Kasir)',
          subtitle: 'Penyerahan uang tunai fisik dengan kwitansi',
          icon: LucideIcons.banknote,
          isSelected: state.method == 'cash',
          onTap: () {
            context
                .read<DisburseActionBloc>()
                .add(const DisburseMethodChanged('cash'));
          },
          isDark: isDark,
          brandColor: brandColor,
          textCol: textCol,
        ),
        const SizedBox(height: 10),
        _buildMethodCard(
          title: 'Masuk Siklus Payroll (Slip Gaji)',
          subtitle: 'Dipotong/ditambahkan pada siklus penggajian aktif',
          icon: LucideIcons.receipt,
          isSelected: state.method == 'payroll',
          onTap: () {
            context
                .read<DisburseActionBloc>()
                .add(const DisburseMethodChanged('payroll'));
          },
          isDark: isDark,
          brandColor: brandColor,
          textCol: textCol,
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color brandColor,
    required Color textCol,
  }) {
    final borderCol = isSelected
        ? brandColor
        : (isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted);
    final bgCol = isSelected
        ? brandColor.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.surfaceContainerLowest);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? brandColor.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.backgroundSubtle),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? brandColor : textCol,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? brandColor : textCol,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 20,
              color: isSelected ? brandColor : borderCol,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferForm({
    required DisburseActionState state,
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
            'Informasi Rekening Tujuan',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.args.bankName ?? 'Belum ada data bank',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.args.bankAccountNumber ?? '-'} a.n. ${widget.args.bankAccountHolder ?? widget.args.employeeName}',
                  style: TextStyle(color: subtitleCol, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Nomor Referensi Bank / Transfer',
            hintText: 'Contoh: TRF-20260922-88219',
            controller: _refController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Catatan Kasir (Opsional)',
            hintText: 'Keterangan tambahan pencairan transfer...',
            controller: _notesController,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Text(
            'Bukti Transfer m-Banking *',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
          const SizedBox(height: 6),
          AppPhotoPickerCard(
            file: state.proofFile,
            uploadPlaceholderTitle: 'Tap untuk Upload Bukti Transfer',
            uploadPlaceholderSubtitle:
                'Screenshot resi transfer bank (Maks 100 KB)',
            onFileChanged: (file, _) {
              context
                  .read<DisburseActionBloc>()
                  .add(DisburseProofFileChanged(file));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCashForm({
    required DisburseActionState state,
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
            'Penyerahan Uang Tunai (Petty Cash)',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan pegawai menandatangani formulir tanda terima / kwitansi kasir fisik saat penyerahan uang tunai.',
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Nomor Voucher Kasir / Kwitansi Fisik',
            hintText: 'Contoh: PCV-2026-0042',
            controller: _refController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Catatan Penyerahan',
            hintText: 'Diserahkan langsung ke staf terkait di meja kasir...',
            controller: _notesController,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          Text(
            'Foto Kwitansi Tanda Terima Fisik',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
          const SizedBox(height: 6),
          AppPhotoPickerCard(
            file: state.proofFile,
            uploadPlaceholderTitle: 'Tap untuk Foto Kwitansi Fisik',
            uploadPlaceholderSubtitle:
                'Foto kwitansi bermaterai/tanda tangan (Maks 100 KB)',
            onFileChanged: (file, _) {
              context
                  .read<DisburseActionBloc>()
                  .add(DisburseProofFileChanged(file));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollForm({
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
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
              const Icon(LucideIcons.calendarCheck2,
                  size: 20, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Inklusi Slip Gaji / Siklus Payroll',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Klaim ini akan otomatis dijadwalkan cair pada siklus penggajian bulan berjalan. Tidak ada pencairan kas langsung yang perlu ditransfer hari ini.',
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Catatan Tambahan untuk Tim Payroll',
            hintText: 'Contoh: Masukkan ke komponen tunjangan khusus...',
            controller: _notesController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
