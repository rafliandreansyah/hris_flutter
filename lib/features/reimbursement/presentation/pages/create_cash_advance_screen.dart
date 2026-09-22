import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/terbilang_helper.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_cash_advance/create_cash_advance_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/beneficiary_account_card.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman form pengajuan kasbon operasional (Cash Advance).
///
/// Mengikuti spesifikasi desain Google Stitch Project 17152850901645837896
/// Screen ID: 6c6d42e50d824f2093d9d19d6f010ea1 ("Oasish Ajukan Kasbon Screen")
/// dengan field yang 100% selaras dengan kontrak API backend muratech_hris_server.
class CreateCashAdvanceScreen extends StatelessWidget {
  final ReimbursementRepository? repository;

  const CreateCashAdvanceScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateCashAdvanceBloc>(
      create: (context) => CreateCashAdvanceBloc(
        repository: repository ?? context.read<ReimbursementRepository>(),
      )..add(const CreateCashAdvanceStarted()),
      child: const _CreateCashAdvanceView(),
    );
  }
}

class _CreateCashAdvanceView extends StatefulWidget {
  const _CreateCashAdvanceView();

  @override
  State<_CreateCashAdvanceView> createState() => _CreateCashAdvanceViewState();
}

class _CreateCashAdvanceViewState extends State<_CreateCashAdvanceView> {
  final _titleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  DateTime? _settlementDeadline;
  bool _agreementAccepted = true;

  String? _titleError;
  String? _purposeError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    // Default batas settlement 14 hari ke depan
    _settlementDeadline = DateTime.now().add(const Duration(days: 14));
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _currentAmount {
    final rawAmt = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(rawAmt) ?? 0.0;
  }

  void _addQuickAmount(int delta) {
    final current = _currentAmount.toInt();
    final newTotal = current + delta;
    _setFormattedAmount(newTotal);
  }

  void _resetAmount() {
    _setFormattedAmount(0);
  }

  void _setFormattedAmount(int value) {
    final formatted = NumberFormat('#,###', 'id_ID').format(value);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _submit() {
    setState(() {
      _titleError = null;
      _purposeError = null;
      _amountError = null;
    });

    final title = _titleController.text.trim();
    final purpose = _purposeController.text.trim();
    final amount = _currentAmount;

    bool hasError = false;

    if (title.isEmpty) {
      _titleError = 'Judul permohonan kasbon wajib diisi';
      hasError = true;
    }

    if (purpose.isEmpty) {
      _purposeError = 'Rincian keperluan dinas wajib diisi';
      hasError = true;
    }

    if (amount <= 0) {
      _amountError = 'Nominal kasbon harus lebih dari 0';
      hasError = true;
    }

    if (!_agreementAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap centang pernyataan persetujuan pertanggungjawaban SPJ.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final deadlineStr = _settlementDeadline != null
        ? DateFormat('yyyy-MM-dd').format(_settlementDeadline!)
        : null;

    context.read<CreateCashAdvanceBloc>().add(
          CreateCashAdvanceSubmitted(
            title: title,
            purpose: purpose,
            requestedAmount: amount,
            settlementDeadline: deadlineStr,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final brandColor =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajukan Kasbon',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Permohonan Uang Muka Operasional',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: scaffoldBg,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.circleHelp, color: subtitleCol, size: 22),
            tooltip: 'Bantuan Kasbon',
            onPressed: () => _showHelpModal(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderCol)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<CreateCashAdvanceBloc, CreateCashAdvanceState>(
                builder: (context, state) {
                  return AppButton(
                    text: 'Kirim Permohonan Kasbon',
                    leadingIcon: LucideIcons.send,
                    isLoading: state.isSubmitting,
                    height: 50,
                    onPressed: state.isSubmitting ? null : _submit,
                  );
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Batal & Kembali',
                  style: AppTypography.labelMedium.copyWith(
                    color: subtitleCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<CreateCashAdvanceBloc, CreateCashAdvanceState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.errorRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Kasbon berhasil diajukan dengan nomor ${state.createdAdvanceNumber ?? ''}',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop(true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Banner Ketentuan Kasbon (Stitch Top Banner)
                _buildPolicyBanner(isDark, brandColor),
                const SizedBox(height: 16),

                // 2. Card 1: Informasi Pengajuan & Nominal (Stitch Card 1)
                _buildNominalAndTitleCard(state, isDark, brandColor, textCol, subtitleCol, borderCol, cardBg),
                const SizedBox(height: 16),

                // 3. Card 2: Batas Waktu Pelaporan SPJ (Stitch Card 2 - Selaras API settlementDeadline)
                _buildSettlementDeadlineCard(isDark, brandColor, textCol, subtitleCol, borderCol, cardBg),
                const SizedBox(height: 16),

                // 4. Card 3: Rincian Estimasi Biaya / Keperluan (Stitch Card 3 - purpose)
                _buildPurposeCard(isDark, brandColor, textCol, subtitleCol, borderCol, cardBg),
                const SizedBox(height: 16),

                // 5. Card 4: Rekening Payroll Penerima (Stitch Card 4 - BeneficiaryAccountCard)
                BeneficiaryAccountCard(
                  bankName: state.employeeDetail?.bankName,
                  bankNumber: state.employeeDetail?.bankNumber,
                  bankAccount: state.employeeDetail?.bankAccount,
                  employeePosition: state.employeeDetail?.position?.name,
                  isLoading: state.isEmployeeLoading,
                ),
                const SizedBox(height: 16),

                // 6. Card 5: Legalitas & SPJ Agreement Checkbox (Stitch Card 5)
                _buildAgreementCard(isDark, brandColor, textCol, borderCol, cardBg),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // --- 1. BANNER KETENTUAN KASBON ---
  // ==========================================
  Widget _buildPolicyBanner(bool isDark, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? brandColor.withValues(alpha: 0.15)
            : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? brandColor.withValues(alpha: 0.3)
              : const Color(0xFFCCFBF1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? brandColor.withValues(alpha: 0.25)
                  : const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.info,
              color: brandColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketentuan Pengajuan Kasbon',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.inversePrimary : const Color(0xFF115E59),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Permohonan kasbon murni untuk operasional dinas dan wajib dilaporkan (SPJ) sesuai batas waktu pelaporan yang ditentukan.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.inversePrimary.withValues(alpha: 0.85)
                        : const Color(0xFF0F766E),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 2. CARD INFORMASI & NOMINAL KASBON ---
  // ==========================================
  Widget _buildNominalAndTitleCard(
    CreateCashAdvanceState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    final amountVal = _currentAmount;

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
          // Judul Permohonan
          AppTextField(
            label: 'Judul Permohonan / Nama Kegiatan *',
            hintText: 'Contoh: Operasional Kunjungan Klien Jakarta',
            controller: _titleController,
            prefixIcon: LucideIcons.clipboardList,
            onChanged: (_) {
              if (_titleError != null) {
                setState(() => _titleError = null);
              }
            },
          ),
          if (_titleError != null) ...[
            const SizedBox(height: 4),
            Text(
              _titleError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 11.5,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 13, color: subtitleCol),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sebutkan nama kegiatan, lokasi, atau proyek terkait',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Container Nominal Kasbon (Besar, Bisa Diketik Langsung, dengan Quick Chips)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _amountError != null
                    ? AppColors.errorRed
                    : brandColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NOMINAL KASBON',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: subtitleCol,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Baris Input Nominal (Bisa Diketik Langsung)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Rp',
                      style: AppTypography.titleMedium.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.headlineLargeMobile.copyWith(
                          fontWeight: FontWeight.w900,
                          color: brandColor,
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                        ),
                        onChanged: (val) {
                          if (_amountError != null) {
                            setState(() => _amountError = null);
                          }
                          // Format pemisah ribuan saat user mengetik manual
                          final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.isNotEmpty) {
                            final numVal = int.tryParse(clean) ?? 0;
                            final formatted = NumberFormat('#,###', 'id_ID').format(numVal);
                            if (formatted != _amountController.text) {
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          } else {
                            _amountController.value = const TextEditingValue(
                              text: '0',
                              selection: TextSelection.collapsed(offset: 1),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Quick add chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildQuickChip('+ Rp 500rb', () => _addQuickAmount(500000), isDark, brandColor),
                    _buildQuickChip('+ Rp 1jt', () => _addQuickAmount(1000000), isDark, brandColor),
                    _buildQuickChip('+ Rp 2jt', () => _addQuickAmount(2000000), isDark, brandColor),
                    InkWell(
                      onTap: _resetAmount,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          'Reset',
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Box Terbilang Otomatis
                if (amountVal > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: brandColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Terbilang: ${angkaKeTerbilang(amountVal)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: brandColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_amountError != null) ...[
            const SizedBox(height: 4),
            Text(
              _amountError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChip(
    String label,
    VoidCallback onTap,
    bool isDark,
    Color brandColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: brandColor.withValues(alpha: isDark ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: brandColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: brandColor,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- 3. BATAS WAKTU PELAPORAN SPJ ---
  // ==========================================
  Widget _buildSettlementDeadlineCard(
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
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
                child: Row(
                  children: [
                    Icon(LucideIcons.calendarClock, size: 18, color: brandColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Batas Waktu Pelaporan SPJ *',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Estimasi SPJ',
                  style: AppTypography.labelSmall.copyWith(
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _settlementDeadline ?? DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
              );
              if (picked != null) {
                setState(() => _settlementDeadline = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 18, color: brandColor),
                      const SizedBox(width: 10),
                      Text(
                        _settlementDeadline != null
                            ? DateFormat('dd MMMM yyyy').format(_settlementDeadline!)
                            : 'Pilih Tanggal Batas SPJ...',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: subtitleCol),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Batas audit finance untuk penyelesaian nota kuitansi bukti pengeluaran dinas.',
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 4. RINCIAN ESTIMASI BIAYA / KEPERLUAN ---
  // ==========================================
  Widget _buildPurposeCard(
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
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
              Icon(LucideIcons.fileText, size: 18, color: brandColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rincian Estimasi Biaya / Keperluan *',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            maxLines: 4,
            style: AppTypography.bodyMedium.copyWith(color: textCol, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Tuliskan estimasi peruntukan biaya secara ringkas...\nContoh:\n1. Tiket Kereta PP (Rp 600.000)\n2. Penginapan 1 Malam (Rp 500.000)',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: subtitleCol.withValues(alpha: 0.6),
                fontSize: 12.5,
                height: 1.4,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderCol),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _purposeError != null ? AppColors.errorRed : borderCol,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: brandColor, width: 1.5),
              ),
            ),
            onChanged: (_) {
              if (_purposeError != null) {
                setState(() => _purposeError = null);
              }
            },
          ),
          if (_purposeError != null) ...[
            const SizedBox(height: 4),
            Text(
              _purposeError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 11.5,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Berikan rincian singkat alokasi penggunaan dana',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_purposeController.text.length} karakter',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // --- 5. PERSETUJUAN & LEGALITAS SPJ ---
  // ==========================================
  Widget _buildAgreementCard(
    bool isDark,
    Color brandColor,
    Color textCol,
    Color borderCol,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _agreementAccepted = !_agreementAccepted);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreementAccepted,
              activeColor: brandColor,
              onChanged: (val) {
                setState(() => _agreementAccepted = val ?? false);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Saya menyatakan dana ini murni untuk keperluan operasional dinas perusahaan dan bersedia menyerahkan bukti struk/nota sah melalui pelaporan SPJ selambatnya sesuai batas waktu yang ditentukan.',
                  style: AppTypography.bodySmall.copyWith(
                    color: textCol,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Permohonan Kasbon',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Kasbon Dinas: Uang muka yang diberikan perusahaan untuk menunjang aktivitas dinas atau operasional yang mendesak.\n\n'
                  '2. Pencairan: Dana akan ditransfer kasir ke rekening payroll terdaftar setelah disetujui atasan dan finance.\n\n'
                  '3. Batas SPJ: Nota dan kuitansi fisik wajib dilaporkan melalui menu Penyelesaian Kasbon (Settlement) sebelum batas waktu berakhir.',
                  style: AppTypography.bodyMedium.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Saya Mengerti',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
