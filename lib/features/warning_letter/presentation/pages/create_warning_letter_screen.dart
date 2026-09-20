import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_document_upload_card.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/warning_letter/domain/repositories/warning_letter_repository.dart';
import 'package:hris_flutter/features/warning_letter/presentation/bloc/create_warning_letter/create_warning_letter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Form Tambah Surat Peringatan (Create Warning Letter Form).
/// Sesuai Google Stitch M3: "Oasish Create Warning Letter Form"
/// (Screen ID: ecee32ead7b04d3b908f2a984d19d368).
class CreateWarningLetterScreen extends StatelessWidget {
  final WarningLetterRepository? warningLetterRepository;
  final EmployeeRepository? employeeRepository;
  final CreateWarningLetterBloc? bloc;

  const CreateWarningLetterScreen({
    super.key,
    this.warningLetterRepository,
    this.employeeRepository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateWarningLetterBloc>.value(
        value: bloc!,
        child: const _CreateWarningLetterScreenView(),
      );
    }

    return BlocProvider<CreateWarningLetterBloc>(
      create: (_) => CreateWarningLetterBloc(
        warningLetterRepository: warningLetterRepository,
        employeeRepository: employeeRepository,
      )..add(const CreateWarningLetterStarted()),
      child: const _CreateWarningLetterScreenView(),
    );
  }
}

class _CreateWarningLetterScreenView extends StatefulWidget {
  const _CreateWarningLetterScreenView();

  @override
  State<_CreateWarningLetterScreenView> createState() =>
      _CreateWarningLetterScreenViewState();
}

class _CreateWarningLetterScreenViewState
    extends State<_CreateWarningLetterScreenView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _sanctionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _sanctionController.dispose();
    super.dispose();
  }

  void _showEmployeePicker(CreateWarningLetterState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final bloc = context.read<CreateWarningLetterBloc>();
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = state.employees.where((emp) {
            if (query.isEmpty) return true;
            return emp.name.toLowerCase().contains(query) ||
                emp.role.toLowerCase().contains(query) ||
                emp.department.toLowerCase().contains(query) ||
                (emp.employeeNumber?.toLowerCase().contains(query) ?? false);
          }).toList();

          return SafeArea(
            child: Container(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Pilih Pegawai Penerima SP',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 20,
                            color: subtitleCol,
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setSheetState(() {}),
                      onTapOutside: (event) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, jabatan, atau divisi...',
                        hintStyle: TextStyle(
                          color: subtitleCol,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          size: 18,
                          color: subtitleCol,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineMuted
                                : AppColors.outlineMuted,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkOutlineMuted
                                : AppColors.outlineMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // List Pegawai
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                query.isEmpty
                                    ? 'Tidak ada data pegawai.'
                                    : 'Tidak ada pegawai dengan kata kunci "$query".',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleCol),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (_, index) {
                              final emp = filtered[index];
                              final isSelected =
                                  state.selectedEmployee?.id == emp.id;

                              return ListTile(
                                leading: AppAvatar(
                                  imageUrl: emp.avatarUrl,
                                  name: emp.name,
                                  initials: emp.initials,
                                  size: 40,
                                ),
                                title: Text(
                                  emp.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.brandTeal
                                        : textCol,
                                  ),
                                ),
                                subtitle: Text(
                                  '${emp.role} • ${emp.department}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        LucideIcons.check,
                                        color: AppColors.brandTeal,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  bloc.add(
                                    CreateWarningLetterEmployeeSelected(emp),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTypePicker(CreateWarningLetterState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final bloc = context.read<CreateWarningLetterBloc>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Tipe Surat Peringatan',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.warningLetterTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Memuat data tipe surat peringatan...',
                        style: TextStyle(color: subtitleCol),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.warningLetterTypes.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final type = state.warningLetterTypes[index];
                        final isSelected = state.selectedType?.id == type.id;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            bloc.add(CreateWarningLetterTypeSelected(type));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brandColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'SP ${type.level}',
                                    style: TextStyle(
                                      color: brandColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.name,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? brandColor
                                              : textCol,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Masa berlaku: ${type.validityPeriodMonths} Bulan',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: subtitleCol,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    LucideIcons.check,
                                    color: brandColor,
                                    size: 20,
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
          ),
        );
      },
    );
  }

  Future<void> _pickIssuedDate(CreateWarningLetterState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.issuedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      context.read<CreateWarningLetterBloc>().add(
            CreateWarningLetterIssuedDateChanged(picked),
          );
    }
  }

  void _showGuidanceDialog() {
    AppDialogUtil.showWarning(
      context,
      title: 'Panduan Surat Peringatan',
      message:
          '1. SP 1 (Teguran Pertama): Pelanggaran disiplin ringan atau keterlambatan berulang.\n\n'
          '2. SP 2 (Teguran Kedua): Pelanggaran berulang dalam masa aktif SP 1 atau pelanggaran SOP sedang.\n\n'
          '3. SP 3 (Peringatan Terakhir): Pelanggaran berat atau berulang selama masa aktif SP 2 sebelum proses pemutusan hubungan kerja.',
      cancelText: 'Mengerti',
    );
  }

  void _submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<CreateWarningLetterBloc>().add(
          const CreateWarningLetterSubmitted(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackground
        : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final brandColor =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);
    final inputBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.surfaceContainerLow;

    return BlocListener<CreateWarningLetterBloc, CreateWarningLetterState>(
      listener: (context, state) {
        if (state.status == CreateWarningLetterStatus.success) {
          final refNo = state.createdResponse?.data?.referenceNumber ?? '-';
          AppDialogUtil.showSuccess(
            context,
            title: 'Surat Peringatan Diterbitkan',
            message:
                'Surat peringatan untuk ${state.selectedEmployee?.name ?? 'Pegawai'} berhasil diterbitkan dengan nomor referensi $refNo.',
            buttonText: 'Selesai',
            onOk: () {
              context.pop(true);
            },
          );
        } else if (state.status == CreateWarningLetterStatus.failure &&
            state.errorMessage != null) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Menerbitkan SP',
            message: state.errorMessage!,
            closeText: 'Tutup',
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgCol,
        appBar: AppBar(
          backgroundColor: bgCol.withValues(alpha: 0.95),
          elevation: 0,
          scrolledUnderElevation: 1.5,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Surat Peringatan',
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Penerbitan sanksi disiplin & kepatuhan pegawai',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(LucideIcons.helpCircle, color: textCol, size: 20),
              onPressed: _showGuidanceDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<CreateWarningLetterBloc, CreateWarningLetterState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  children: [
                    // ── 1. Card Pemilihan Pegawai ───────────────────────
                    _buildEmployeeCard(
                      state: state,
                      cardBg: cardBg,
                      borderCol: borderCol,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      brandColor: brandColor,
                    ),

                    const SizedBox(height: 16),

                    // ── 2. Card Surat Peringatan Terakhir ───────────────
                    if (state.selectedEmployee != null) ...[
                      _buildLastWarningLetterCard(
                        state: state,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 3. Section: Tipe Surat & Tanggal Penerbitan ─────
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
                          Text(
                            'TIPE SURAT & TANGGAL PENERBITAN',
                            style: AppTypography.labelSmall.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tipe Peringatan Field
                          _buildFieldLabel('Tipe Peringatan', isRequired: true),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showTypePicker(state),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.scale,
                                    size: 18,
                                    color: brandColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      state.selectedType != null
                                          ? '${state.selectedType!.name} (SP ${state.selectedType!.level})'
                                          : 'Pilih Tipe Surat Peringatan',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: state.selectedType != null
                                            ? textCol
                                            : subtitleCol,
                                        fontWeight: state.selectedType != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 18,
                                    color: subtitleCol,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tanggal Diterbitkan Field
                          _buildFieldLabel('Tanggal Diterbitkan', isRequired: true),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickIssuedDate(state),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 18,
                                    color: brandColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      state.formattedIssuedDateDisplay,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: textCol,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 18,
                                    color: subtitleCol,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Banner Otomatis Kedaluwarsa
                          if (state.selectedType != null &&
                              state.selectedType!.validityPeriodMonths > 0) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF042F2E)
                                    : const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF115E59)
                                      : const Color(0xFFCCFBF1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.info,
                                    color: brandColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Otomatis Kedaluwarsa pada: ${state.formattedCalculatedExpiredDate} (${state.selectedType!.validityPeriodMonths} Bulan Masa Berlaku)',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark
                                            ? const Color(0xFF5EEAD4)
                                            : const Color(0xFF0F766E),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 4. Section: Detail Pelanggaran & Bukti ───────────
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
                          Text(
                            'DETAIL PELANGGARAN & BUKTI',
                            style: AppTypography.labelSmall.copyWith(
                              color: brandColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Alasan Pelanggaran
                          _buildFieldLabel('Alasan Pelanggaran', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _reasonController,
                            maxLines: 4,
                            maxLength: 500,
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            onChanged: (val) {
                              context.read<CreateWarningLetterBloc>().add(
                                    CreateWarningLetterReasonChanged(val),
                                  );
                            },
                            style: AppTypography.bodyMedium.copyWith(color: textCol),
                            decoration: InputDecoration(
                              hintText: 'Tuliskan detail pelanggaran di sini...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: subtitleCol.withValues(alpha: 0.7),
                                fontSize: 13.5,
                              ),
                              filled: true,
                              fillColor: inputBg,
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
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Sanksi Tindakan Disiplin (Opsional)
                          _buildFieldLabel('Sanksi / Tindakan Disiplin (Opsional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sanctionController,
                            maxLines: 2,
                            maxLength: 200,
                            onTapOutside: (event) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            onChanged: (val) {
                              context.read<CreateWarningLetterBloc>().add(
                                    CreateWarningLetterSanctionChanged(val),
                                  );
                            },
                            style: AppTypography.bodyMedium.copyWith(color: textCol),
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: Penundaan kenaikan gaji, skorsing 3 hari kerja, dsb...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: subtitleCol.withValues(alpha: 0.7),
                                fontSize: 13.5,
                              ),
                              filled: true,
                              fillColor: inputBg,
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
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Unggah Dokumen Bukti
                          AppDocumentUploadCard(
                            title: 'DOKUMEN PENDUKUNG / BUKTI',
                            titleIcon: LucideIcons.paperclip,
                            isRequired: false,
                            optionalTagText: 'Opsional',
                            uploadPlaceholderTitle:
                                'Ketuk untuk Unggah Dokumen PDF atau Foto Bukti',
                            uploadPlaceholderSubtitle:
                                'Kamera atau Galeri (Foto bukti pelanggaran)',
                            sheetTitle: 'Pilih Sumber Bukti Pelanggaran',
                            file: state.attachmentFile,
                            compressResult: state.compressResult,
                            onFileWithCompressionChanged: (file, result) {
                              context.read<CreateWarningLetterBloc>().add(
                                    CreateWarningLetterFileChanged(
                                      file: file,
                                      compressResult: result,
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── 5. Bottom Action Button Bar ─────────────────────────────────
        bottomNavigationBar:
            BlocBuilder<CreateWarningLetterBloc, CreateWarningLetterState>(
          builder: (context, state) {
            final isSubmitting =
                state.status == CreateWarningLetterStatus.submitting;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: AppButton(
                    text: 'Terbitkan Surat Peringatan',
                    leadingIcon: LucideIcons.send,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submitForm,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildEmployeeCard({
    required CreateWarningLetterState state,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required Color brandColor,
  }) {
    final employee = state.selectedEmployee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: employee == null
          ? InkWell(
              onTap: () => _showEmployeePicker(state),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.userPlus,
                        color: brandColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pilih Pegawai',
                                style: AppTypography.titleSmall.copyWith(
                                  color: textCol,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketuk untuk memilih pegawai yang akan diberikan SP',
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleCol,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: subtitleCol,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                AppAvatar(
                  imageUrl: employee.avatarUrl,
                  name: employee.name,
                  initials: employee.initials,
                  size: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${employee.role} • ${employee.department}',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showEmployeePicker(state),
                  style: TextButton.styleFrom(
                    foregroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Ganti',
                    style: AppTypography.bodyMedium.copyWith(
                      color: brandColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLastWarningLetterCard({
    required CreateWarningLetterState state,
    required bool isDark,
  }) {
    if (state.isLoadingLastLetter) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainerLowest
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkOutlineMuted
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Memeriksa riwayat surat peringatan terakhir...',
              style: TextStyle(fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    final last = state.lastWarningLetter;

    // Jika pegawai memiliki SP terakhir
    if (last != null) {
      final bg = isDark ? const Color(0xFF3B0D0C) : const Color(0xFFFEF2F2);
      final border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
      final primaryText =
          isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
      final badgeBg =
          isDark ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card SP Terakhir
            Row(
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Surat Peringatan Terakhir',
                    style: AppTypography.titleSmall.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    last.levelBadgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF450A0A)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    last.isActive ? '• Aktif' : '• Tidak Aktif',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              '${last.warningLetterType.name} (${last.levelBadgeLabel})',
              style: AppTypography.bodyMedium.copyWith(
                color: primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ref: ${last.referenceNumber}',
              style: AppTypography.bodySmall.copyWith(
                color: primaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Masa Berlaku: ${last.formattedPeriod}',
              style: AppTypography.bodySmall.copyWith(
                color: primaryText,
                fontSize: 12,
              ),
            ),
            if (last.sanction != null && last.sanction!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Sanksi: ${last.sanction}',
                style: AppTypography.bodySmall.copyWith(
                  color: primaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Jika pegawai belum pernah menerima SP sebelumnya
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            color: Color(0xFF16A34A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum Ada Riwayat Surat Peringatan',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF166534),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pegawai ini belum pernah menerima surat peringatan sebelumnya.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFF166534),
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
}
