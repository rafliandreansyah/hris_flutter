import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_text_field.dart';
import 'package:hris_flutter/features/reimbursement/domain/repositories/reimbursement_repository.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_bloc.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_event.dart';
import 'package:hris_flutter/features/reimbursement/presentation/bloc/create_reimbursement/create_reimbursement_state.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/beneficiary_account_card.dart';
import 'package:hris_flutter/features/reimbursement/presentation/widgets/cash_advance_picker_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman form pengajuan reimbursement baru.
///
/// Mengikuti spesifikasi desain Google Stitch Project 17152850901645837896
/// Screen ID: 269678ef6a274fadb9aa494d9a32cd4e ("Oasish Ajukan Reimbursement Screen").
class CreateReimbursementScreen extends StatelessWidget {
  final ReimbursementRepository? repository;
  final String? initialCashAdvanceId;

  const CreateReimbursementScreen({
    super.key,
    this.repository,
    this.initialCashAdvanceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateReimbursementBloc>(
      create: (context) {
        final bloc = CreateReimbursementBloc(
          repository: repository ?? context.read<ReimbursementRepository>(),
        )..add(const CreateReimbursementStarted());

        if (initialCashAdvanceId != null && initialCashAdvanceId!.isNotEmpty) {
          bloc.add(
            const CreateReimbursementTypeChanged('cash_advance_settlement'),
          );
          bloc.add(
            CreateReimbursementCashAdvanceSelected(initialCashAdvanceId),
          );
        }
        return bloc;
      },
      child: const _CreateReimbursementView(),
    );
  }
}

class _CreateReimbursementView extends StatefulWidget {
  const _CreateReimbursementView();

  @override
  State<_CreateReimbursementView> createState() =>
      _CreateReimbursementViewState();
}

class _ItemFormData {
  String? categoryId;
  DateTime expenseDate = DateTime.now();
  final merchantController = TextEditingController();
  final descController = TextEditingController();
  final amountController = TextEditingController();
  XFile? receiptFile;
  int? fileSizeBytes;

  void dispose() {
    merchantController.dispose();
    descController.dispose();
    amountController.dispose();
  }

  Map<String, dynamic> toMap() {
    final rawAmt = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amt = double.tryParse(rawAmt) ?? 0.0;
    return {
      'categoryId': categoryId,
      'expenseDate': DateFormat('yyyy-MM-dd').format(expenseDate),
      'merchant': merchantController.text.trim(),
      'description': descController.text.trim(),
      'requestedAmount': amt,
      'currency': 'IDR',
    };
  }
}

class _CreateReimbursementViewState extends State<_CreateReimbursementView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final List<_ItemFormData> _itemsData = [];
  final ImagePicker _imagePicker = ImagePicker();

  String? _titleError;
  String? _itemsError;

  @override
  void initState() {
    super.initState();
    // Inisialisasi 1 item nota pertama
    _addNewItem();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final item in _itemsData) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    final item = _ItemFormData();
    item.amountController.addListener(_onAmountChanged);
    setState(() {
      _itemsData.add(item);
    });
  }

  void _removeItem(int index) {
    if (_itemsData.length <= 1) return;
    final removed = _itemsData.removeAt(index);
    removed.amountController.removeListener(_onAmountChanged);
    removed.dispose();
    setState(() {});
  }

  void _onAmountChanged() {
    setState(() {});
  }

  double get _calculatedTotal {
    double total = 0.0;
    for (final item in _itemsData) {
      final rawAmt = item.amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      total += double.tryParse(rawAmt) ?? 0.0;
    }
    return total;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickReceiptImage(int index, ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;

      final length = await picked.length();
      setState(() {
        _itemsData[index].receiptFile = picked;
        _itemsData[index].fileSizeBytes = length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showImageSourceSheet(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Bukti Struk / Nota',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: AppColors.brandTeal,
                  ),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Foto fisik struk secara langsung'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceiptImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: AppColors.brandTeal,
                  ),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text(
                  'Ambil file foto atau screenshot dari ponsel',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceiptImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _previewImageDialog(XFile file) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.file(
                File(file.path),
                fit: BoxFit.contain,
                height: 380,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: AppButton(
                text: 'Tutup Preview',
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    setState(() {
      _titleError = null;
      _itemsError = null;
    });

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul keperluan klaim wajib diisi');
      return;
    }

    // Validasi data items
    for (int i = 0; i < _itemsData.length; i++) {
      final item = _itemsData[i];
      final rawAmt = item.amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final amt = double.tryParse(rawAmt) ?? 0.0;

      if (item.categoryId == null || item.categoryId!.isEmpty) {
        setState(
          () =>
              _itemsError = 'Kategori biaya pada Nota #${i + 1} belum dipilih',
        );
        return;
      }
      if (amt <= 0) {
        setState(
          () => _itemsError = 'Nominal pada Nota #${i + 1} harus lebih dari 0',
        );
        return;
      }
    }

    final bloc = context.read<CreateReimbursementBloc>();
    final state = bloc.state;

    // Kumpulkan files dari item nota
    final List<XFile> files = [];
    for (final item in _itemsData) {
      if (item.receiptFile != null) {
        files.add(item.receiptFile!);
      }
    }

    // Sinkronkan items ke state BLoC
    for (final item in _itemsData) {
      bloc.add(CreateReimbursementItemAdded(item.toMap()));
    }

    bloc.add(
      CreateReimbursementSubmitted(
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        bankName: state.employeeDetail?.bankName,
        bankAccountNumber: state.employeeDetail?.bankNumber,
        bankAccountHolder: state.employeeDetail?.bankAccount,
        files: files.isNotEmpty ? files : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF8FAFC);
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : const Color(0xFF64748B);
    final brandColor = isDark
        ? AppColors.inversePrimary
        : const Color(0xFF0D9488);
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajukan Reimbursement',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Formulir Klaim & Penggantian Biaya',
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
            tooltip: 'Bantuan Klaim',
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
              BlocBuilder<CreateReimbursementBloc, CreateReimbursementState>(
                builder: (context, state) {
                  return AppButton(
                    text: 'Kirim Pengajuan Reimbursement',
                    leadingIcon: LucideIcons.send,
                    isLoading: state.isSubmitting,
                    height: 50,
                    onPressed: state.isSubmitting ? null : _submit,
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.archive, size: 13, color: subtitleCol),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Pastikan fisik nota/struk disimpan untuk keperluan audit berkala',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<CreateReimbursementBloc, CreateReimbursementState>(
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
                  'Pengajuan berhasil dibuat dengan nomor ${state.createdClaimNumber ?? ''}',
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
                // 1. Jenis Pengajuan Klaim (Stitch Section 1)
                _buildClaimTypeSection(
                  state,
                  isDark,
                  brandColor,
                  textCol,
                  subtitleCol,
                  borderCol,
                  cardBg,
                ),
                const SizedBox(height: 16),

                // 2. Informasi Dasar Pengajuan (Stitch Section 2)
                _buildBasicInfoSection(
                  state,
                  isDark,
                  brandColor,
                  textCol,
                  subtitleCol,
                  borderCol,
                  cardBg,
                ),
                const SizedBox(height: 16),

                // 3. Daftar Nota & Struk Biaya (Stitch Section 3)
                _buildExpenseItemsSection(
                  state,
                  isDark,
                  brandColor,
                  textCol,
                  subtitleCol,
                  borderCol,
                  cardBg,
                ),
                const SizedBox(height: 16),

                // 4. Rekening Tujuan Pencairan (Stitch Section 4)
                BeneficiaryAccountCard(
                  bankName: state.employeeDetail?.bankName,
                  bankNumber: state.employeeDetail?.bankNumber,
                  bankAccount: state.employeeDetail?.bankAccount,
                  employeePosition: state.employeeDetail?.position?.name,
                  isLoading: state.isEmployeeLoading,
                ),
                const SizedBox(height: 16),

                // 5. Ringkasan Perhitungan & Selisih Kasbon (Stitch Section 5)
                _buildCalculationSummarySection(
                  state,
                  isDark,
                  brandColor,
                  textCol,
                  subtitleCol,
                  borderCol,
                  cardBg,
                ),
                const SizedBox(height: 16),

                // 6. Policy & Audit Callout
                _buildPolicyCallout(isDark, subtitleCol),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // --- SECTION 1: JENIS PENGAJUAN KLAIM ---
  // ==========================================
  Widget _buildClaimTypeSection(
    CreateReimbursementState state,
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
              Row(
                children: [
                  Icon(LucideIcons.layoutGrid, size: 16, color: brandColor),
                  const SizedBox(width: 8),
                  Text(
                    'JENIS PENGAJUAN KLAIM',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: subtitleCol,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Wajib Dipilih',
                  style: AppTypography.labelSmall.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Opsi 1: Reimbursement Mandiri (Out-of-Pocket)
          _buildTypeOptionTile(
            title: 'Reimbursement Mandiri (Out-of-pocket)',
            subtitle:
                'Penggantian biaya pribadi untuk keperluan operasional atau dinas kantor',
            isSelected: state.type == 'out_of_pocket',
            badgeText: null,
            onTap: () {
              context.read<CreateReimbursementBloc>().add(
                const CreateReimbursementTypeChanged('out_of_pocket'),
              );
            },
            isDark: isDark,
            brandColor: brandColor,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
          ),
          const SizedBox(height: 10),

          // Opsi 2: Pelaporan Kasbon (Settlement)
          _buildTypeOptionTile(
            title: 'Pelaporan Kasbon (Settlement)',
            subtitle:
                'Penyelesaian uang muka kasbon yang telah dicairkan sebelumnya',
            isSelected: state.type == 'cash_advance_settlement',
            badgeText: state.cashAdvanceNumber != null
                ? 'Kasbon Terpilih'
                : 'Pilih Kasbon',
            onTap: () {
              context.read<CreateReimbursementBloc>().add(
                const CreateReimbursementTypeChanged('cash_advance_settlement'),
              );
            },
            isDark: isDark,
            brandColor: brandColor,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
          ),

          // Jika tipe settlement, sediakan picker / detail kasbon terpilih
          if (state.type == 'cash_advance_settlement') ...[
            const SizedBox(height: 12),
            _buildCashAdvancePickerCard(
              state,
              isDark,
              brandColor,
              textCol,
              subtitleCol,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    String? badgeText,
    required VoidCallback onTap,
    required bool isDark,
    required Color brandColor,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandColor : borderCol,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? brandColor : borderCol,
                    width: isSelected ? 5 : 2,
                  ),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? textCol
                                : textCol.withValues(alpha: 0.8),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.circleCheck,
                          size: 16,
                          color: brandColor,
                        )
                      else if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashAdvancePickerCard(
    CreateReimbursementState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
  ) {
    final hasSelected =
        state.cashAdvanceId != null && state.cashAdvanceId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.banknote, size: 16, color: brandColor),
                  const SizedBox(width: 6),
                  Text(
                    hasSelected
                        ? 'Kasbon yang Diselesaikan'
                        : 'Kasbon Belum Dipilih',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  final picked = await CashAdvancePickerSheet.show(
                    context,
                    selectedCashAdvanceId: state.cashAdvanceId,
                  );
                  if (picked != null && mounted) {
                    context.read<CreateReimbursementBloc>().add(
                      CreateReimbursementCashAdvanceObjectSelected(picked),
                    );
                  }
                },
                child: Text(
                  hasSelected ? 'Ganti Kasbon' : 'Pilih Kasbon',
                  style: AppTypography.labelSmall.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (hasSelected) ...[
            const SizedBox(height: 8),
            Text(
              '${state.cashAdvanceNumber ?? ''} • ${state.cashAdvanceTitle ?? ''}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: textCol,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Nominal Kasbon Dicairkan: ${formatRupiah(state.cashAdvanceNominal ?? 0)}',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Tekan "Pilih Kasbon" di atas untuk menautkan kasbon yang sudah cair.',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // --- SECTION 2: INFORMASI DASAR PENGAJUAN ---
  // ==========================================
  Widget _buildBasicInfoSection(
    CreateReimbursementState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    final deptName = state.employeeDetail?.department?.name ?? 'Operasional';
    final posName = state.employeeDetail?.position?.name ?? 'Karyawan';

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
              Text(
                'Informasi Dasar Pengajuan',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Judul Pengajuan
          AppTextField(
            label: 'Judul Pengajuan / Keperluan *',
            hintText: 'Contoh: Tiket Pesawat Dinas Yogyakarta',
            controller: _titleController,
            prefixIcon: LucideIcons.filePenLine,
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
                Icon(LucideIcons.info, size: 12, color: subtitleCol),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Jelaskan tujuan pengeluaran dinas secara singkat dan jelas',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Departemen / Alokasi Proyek (Read-only context)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Departemen / Alokasi Proyek',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.idCard,
                            size: 18,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$deptName • $posName',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textCol,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Terkunci',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deskripsi Tambahan (Opsional)
          AppTextField(
            label: 'Deskripsi / Catatan Tambahan (Opsional)',
            hintText: 'Keterangan pendukung pengajuan bila diperlukan...',
            controller: _descController,
            maxLines: 2,
            prefixIcon: LucideIcons.alignLeft,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- SECTION 3: DAFTAR NOTA & STRUK BIAYA ---
  // ==========================================
  Widget _buildExpenseItemsSection(
    CreateReimbursementState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.receipt, size: 20, color: brandColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Daftar Nota & Struk Biaya',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${_itemsData.length} Nota Ditambahkan',
                  style: AppTypography.labelSmall.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_itemsError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              _itemsError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // List item cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _itemsData.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildItemCard(
              index,
              _itemsData[index],
              state,
              isDark,
              brandColor,
              textCol,
              subtitleCol,
              borderCol,
              cardBg,
            );
          },
        ),
        const SizedBox(height: 12),

        // Tombol Tambah Nota
        InkWell(
          onTap: _addNewItem,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: isDark ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: brandColor.withValues(alpha: 0.4),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.circlePlus, size: 18, color: brandColor),
                const SizedBox(width: 8),
                Text(
                  'Tambah Nota Biaya Lain',
                  style: AppTypography.labelMedium.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    int index,
    _ItemFormData item,
    CreateReimbursementState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Item (Nomor Nota + Tombol Hapus)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Item Nota #${index + 1}',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: _itemsData.length <= 1
                      ? subtitleCol.withValues(alpha: 0.3)
                      : AppColors.errorRed,
                ),
                onPressed: _itemsData.length <= 1
                    ? null
                    : () => _removeItem(index),
                tooltip: 'Hapus Nota',
              ),
            ],
          ),

          const Divider(height: 16),

          // Kategori Biaya
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KATEGORI BIAYA *',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: subtitleCol,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: item.categoryId,
                    isExpanded: true,
                    hint: Text(
                      'Pilih Kategori...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: subtitleCol,
                      ),
                    ),
                    icon: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: subtitleCol,
                    ),
                    items: state.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(
                          cat.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textCol,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => item.categoryId = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2 Kolom: Tanggal Transaksi & Nama Merchant
          Row(
            children: [
              // Tanggal Transaksi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANGGAL NOTA *',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: subtitleCol,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: item.expenseDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null) {
                          setState(() => item.expenseDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(item.expenseDate),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textCol,
                                fontSize: 12.5,
                              ),
                            ),
                            Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: brandColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Nama Merchant
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NAMA MERCHANT',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: subtitleCol,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 46,
                      child: TextField(
                        controller: item.merchantController,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Grab',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: subtitleCol.withValues(alpha: 0.6),
                            fontSize: 12.5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderCol),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderCol),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: brandColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nominal Biaya Sesuai Struk
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOMINAL BIAYA SESUAI STRUK *',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: subtitleCol,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: item.amountController,
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.badgePercent,
                hintText: '0',
                onChanged: (val) {
                  // Format pemisah ribuan otomatis
                  final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.isNotEmpty) {
                    final numVal = int.tryParse(clean) ?? 0;
                    final formatted = NumberFormat(
                      '#,###',
                      'id_ID',
                    ).format(numVal);
                    if (formatted != item.amountController.text) {
                      item.amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Keterangan / Deskripsi Nota
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KETERANGAN / KEPERLUAN NOTA',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: subtitleCol,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: item.descController,
                hintText: 'Contoh: Biaya makan lembur tim deployment',
                prefixIcon: LucideIcons.notepadText,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Foto Bukti Fisik Struk per Item (Stitch Design, TANPA badge terverifikasi)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOTO BUKTI FISIK STRUK',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: subtitleCol,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (item.receiptFile == null) ...[
                // Card Dashed Kosong
                InkWell(
                  onTap: () => _showImageSourceSheet(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderCol,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, size: 18, color: brandColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tap untuk Upload Struk / Nota (Kamera / Galeri)',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Card Terisi (Stitch Emerald Style, tanpa badge terverifikasi)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF059669)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF065F46)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF059669)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.receipt,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF047857),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.receiptFile!.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textCol,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatFileSize(item.fileSizeBytes ?? 0),
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              LucideIcons.eye,
                              size: 18,
                              color: textCol,
                            ),
                            tooltip: 'Lihat Foto Struk',
                            onPressed: () =>
                                _previewImageDialog(item.receiptFile!),
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.refreshCw,
                              size: 18,
                              color: textCol,
                            ),
                            tooltip: 'Ganti File',
                            onPressed: () => _showImageSourceSheet(index),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppColors.errorRed,
                            ),
                            tooltip: 'Hapus File',
                            onPressed: () {
                              setState(() {
                                item.receiptFile = null;
                                item.fileSizeBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- SECTION 5: RINGKASAN PERHITUNGAN ---
  // ==========================================
  Widget _buildCalculationSummarySection(
    CreateReimbursementState state,
    bool isDark,
    Color brandColor,
    Color textCol,
    Color subtitleCol,
    Color borderCol,
    Color cardBg,
  ) {
    final subtotal = _calculatedTotal;
    final isSettlement = state.type == 'cash_advance_settlement';
    final advanceNominal = state.cashAdvanceNominal ?? 0.0;
    final diff = subtotal - advanceNominal;

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
                  'Subtotal Biaya (${_itemsData.length} item nota)',
                  style: AppTypography.bodyMedium.copyWith(color: subtitleCol),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRupiah(subtotal),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          if (isSettlement && advanceNominal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Nominal Kasbon Dicairkan',
                    style: AppTypography.bodyMedium.copyWith(
                      color: subtitleCol,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatRupiah(advanceNominal),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: subtitleCol,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    diff == 0
                        ? 'Status Selisih (Impas)'
                        : (diff > 0
                              ? 'Kekurangan Bayar (Ditransfer Kantor)'
                              : 'Sisa Kasbon (Harus Dikembalikan)'),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: diff == 0
                          ? subtitleCol
                          : (diff > 0 ? brandColor : const Color(0xFFD97706)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatRupiah(diff.abs()),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: diff == 0
                        ? subtitleCol
                        : (diff > 0 ? brandColor : const Color(0xFFD97706)),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pengajuan Reimbursement',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    Text(
                      'Nominal bersih yang ditagihkan',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRupiah(subtotal),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: brandColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- SECTION 6: POLICY CALLOUT ---
  // ==========================================
  Widget _buildPolicyCallout(bool isDark, Color subtitleCol) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, size: 16, color: subtitleCol),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Klaim akan melalui proses verifikasi dan audit oleh atasan langsung dan tim Finance HRIS.',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
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
                  'Panduan Pengajuan Reimbursement',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Out-of-Pocket: Gunakan tipe ini untuk klaim biaya operasional yang Anda bayar menggunakan dana pribadi.\n\n'
                  '2. Settlement Kasbon: Gunakan tipe ini untuk melaporkan nota pertanggungjawaban atas kasbon dinas yang telah dicairkan sebelumnya.\n\n'
                  '3. Struk Fisik: Foto kuitansi/struk wajib terlihat jelas (tulisan, tanggal, nominal, dan nama merchant).\n\n'
                  '4. Rekening: Pencairan akan dilakukan otomatis ke rekening payroll yang terdaftar di sistem HR.',
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
