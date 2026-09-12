import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/utils/image_compress_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_document_upload_card.dart';
import 'package:hris_flutter/features/leave/data/models/leave_create_models.dart';
import 'package:hris_flutter/features/leave/domain/repositories/leave_repository.dart';
import 'package:hris_flutter/features/leave/presentation/bloc/create_leave/create_leave_bloc.dart';

/// Halaman Form Pengajuan Cuti / Izin baru (Create Leave Request).
class CreateLeaveScreen extends StatelessWidget {
  final LeaveRepository? repository;
  final CreateLeaveBloc? bloc;

  const CreateLeaveScreen({super.key, this.repository, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<CreateLeaveBloc>.value(
        value: bloc!,
        child: const _CreateLeaveView(),
      );
    }
    return BlocProvider(
      create: (_) => CreateLeaveBloc(repository: repository)
        ..add(const CreateLeaveStarted()),
      child: const _CreateLeaveView(),
    );
  }
}

class _CreateLeaveView extends StatefulWidget {
  const _CreateLeaveView();

  @override
  State<_CreateLeaveView> createState() => _CreateLeaveViewState();
}

class _CreateLeaveViewState extends State<_CreateLeaveView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  int _totalDays = 1;
  LeaveTypeOptionModel? _selectedType;

  XFile? _pickedPhoto;
  ImageCompressResult? _compressResult;
  bool _isCompressingPhoto = false;

  /// Batas maksimal hari pengajuan cuti secara default (30 hari).
  static const int _defaultMaxDays = 30;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Menghitung batas maksimum hari yang berlaku untuk jenis cuti yang dipilih.
  int get _effectiveMaxDays {
    if (_selectedType?.fixedDays != null) {
      return _selectedType!.fixedDays!;
    }
    if (_selectedType?.maxDays != null) {
      final max = _selectedType!.maxDays!;
      return max < _defaultMaxDays ? max : _defaultMaxDays;
    }
    return _defaultMaxDays;
  }

  /// Menghitung estimasi tanggal berakhir cuti (inklusif).
  DateTime get _calculatedEndDate {
    return _startDate.add(Duration(days: _totalDays > 0 ? _totalDays - 1 : 0));
  }

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  String _toApiDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0D9488),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  void _onSelectLeaveType(LeaveTypeOptionModel type) {
    setState(() {
      _selectedType = type;
      if (type.fixedDays != null) {
        _totalDays = type.fixedDays!;
      } else if (type.maxDays != null && _totalDays > type.maxDays!) {
        _totalDays = type.maxDays!;
      }
    });
    context.read<CreateLeaveBloc>().add(CreateLeaveTypeChanged(type));
  }

  void _showLeaveTypeBottomSheet(List<LeaveTypeOptionModel> leaveTypes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendarClock,
                    color: Color(0xFF0D9488),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pilih Jenis Cuti / Izin',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (leaveTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Tidak ada jenis cuti yang tersedia.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: leaveTypes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final type = leaveTypes[index];
                      final isSelected = _selectedType?.id == type.id;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _onSelectLeaveType(type);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          type.name,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF0D9488)
                                                : null,
                                          ),
                                        ),
                                        if (type.code.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type.code,
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: const Color(0xFF0D9488),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (type.requiresFile)
                                          _buildTag(
                                            label: 'Wajib Foto/Dokumen',
                                            bgColor: const Color(0xFFFEF2F2),
                                            textColor: const Color(0xFFDC2626),
                                            icon: LucideIcons.fileText,
                                          ),
                                        if (type.fixedDays != null)
                                          _buildTag(
                                            label: 'Durasi: ${type.fixedDays} Hari',
                                            bgColor: const Color(0xFFEFF6FF),
                                            textColor: const Color(0xFF2563EB),
                                            icon: LucideIcons.lock,
                                          )
                                        else if (type.maxDays != null)
                                          _buildTag(
                                            label: 'Maks. ${type.maxDays} Hari',
                                            bgColor: const Color(0xFFF0FDF4),
                                            textColor: const Color(0xFF16A34A),
                                            icon: LucideIcons.calendarDays,
                                          ),
                                        if (type.isDeducted)
                                          _buildTag(
                                            label: 'Potong Kuota',
                                            bgColor: const Color(0xFFFFFBEB),
                                            textColor: const Color(0xFFD97706),
                                          ),
                                      ],
                                    ),
                                    if (type.description != null &&
                                        type.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        type.description!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  LucideIcons.check,
                                  color: Color(0xFF0D9488),
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
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color bgColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }



  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleSubmit() {
    if (_selectedType == null) {
      _showWarningSnackBar('Silakan pilih jenis cuti/izin terlebih dahulu.');
      return;
    }
    if (_notesController.text.trim().isEmpty) {
      _showWarningSnackBar('Alasan pengajuan cuti/izin wajib diisi.');
      return;
    }
    if (_selectedType!.requiresFile && _pickedPhoto == null) {
      _showWarningSnackBar(
        'Dokumen pendukung (surat dokter/bukti) wajib dilampirkan untuk jenis ${_selectedType!.name}.',
      );
      return;
    }

    context.read<CreateLeaveBloc>().add(
          CreateLeaveSubmitted(
            leaveTypeId: _selectedType!.id,
            startDate: _toApiDate(_startDate),
            totalDays: _totalDays,
            notes: _notesController.text.trim(),
            file: _pickedPhoto,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkSurfaceContainerLow
        : AppColors.backgroundSubtle;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final inputBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;

    return BlocConsumer<CreateLeaveBloc, CreateLeaveState>(
      listener: (context, state) {
        if (state.isSuccess) {
          AppDialogUtil.showSuccess(
            context,
            title: 'Pengajuan Berhasil',
            message: state.successMessage,
            onOk: () {
              Navigator.of(context).pop(true);
            },
          );
        } else if (state.isFailure) {
          AppDialogUtil.showError(
            context,
            title: 'Gagal Mengajukan Cuti',
            message: state.errorMessage,
          );
        }
      },
      builder: (context, state) {
        final leaveTypes = state.leaveTypes;

        return Scaffold(
          backgroundColor: bgCol,
          appBar: AppBar(
            backgroundColor: bgCol.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 1.5,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: textCol, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan Cuti / Izin',
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Formulir permohonan cuti & izin karyawan',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // ── SECTION 1: Jenis Cuti / Izin ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.calendarCheck2,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'JENIS CUTI / IZIN',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          key: const ValueKey('leave_type_selector'),
                          onTap: state.isLoadingTypes
                              ? null
                              : () => _showLeaveTypeBottomSheet(leaveTypes),
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
                                Expanded(
                                  child: _selectedType == null
                                      ? Text(
                                          state.isLoadingTypes
                                              ? 'Memuat jenis cuti...'
                                              : 'Pilih Jenis Cuti / Izin',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedType!.name,
                                              style: AppTypography.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (_selectedType!.requiresFile)
                                                  _buildTag(
                                                    label: 'Wajib Dokumen/Foto',
                                                    bgColor:
                                                        const Color(0xFFFEF2F2),
                                                    textColor:
                                                        const Color(0xFFDC2626),
                                                    icon: LucideIcons.fileText,
                                                  ),
                                                if (_selectedType!.fixedDays !=
                                                    null)
                                                  _buildTag(
                                                    label:
                                                        'Durasi ${_selectedType!.fixedDays} Hari',
                                                    bgColor:
                                                        const Color(0xFFEFF6FF),
                                                    textColor:
                                                        const Color(0xFF2563EB),
                                                    icon: LucideIcons.lock,
                                                  )
                                                else if (_selectedType!
                                                        .maxDays !=
                                                    null)
                                                  _buildTag(
                                                    label:
                                                        'Maks ${_selectedType!.maxDays} Hari',
                                                    bgColor:
                                                        const Color(0xFFF0FDF4),
                                                    textColor:
                                                        const Color(0xFF16A34A),
                                                  ),
                                                if (_selectedType!.isDeducted)
                                                  _buildTag(
                                                    label: 'Potong Kuota',
                                                    bgColor:
                                                        const Color(0xFFFFFBEB),
                                                    textColor:
                                                        const Color(0xFFD97706),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.chevronDown,
                                  color: subtitleCol,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 2: Periode & Durasi Cuti ───────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.calendarDays,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PERIODE & DURASI CUTI',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Tanggal Mulai Picker
                        Text(
                          'Tanggal Mulai',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          key: const ValueKey('start_date_picker'),
                          onTap: _selectStartDate,
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
                                const Icon(
                                  LucideIcons.calendar,
                                  color: Color(0xFF0D9488),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatDate(_startDate),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Ubah',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF0D9488),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Durasi (Total Hari) - Maksimal 30 hari
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jumlah Hari',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textCol,
                                  ),
                                ),
                                Text(
                                  _selectedType?.fixedDays != null
                                      ? 'Terkunci ${_selectedType!.fixedDays} hari'
                                      : 'Pilihan hingga $_effectiveMaxDays hari',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: subtitleCol,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            // Counter Controls
                            Row(
                              children: [
                                IconButton(
                                  key: const ValueKey('decrement_days_btn'),
                                  onPressed: (_selectedType?.fixedDays != null ||
                                          _totalDays <= 1)
                                      ? null
                                      : () {
                                          setState(() => _totalDays--);
                                        },
                                  icon: const Icon(LucideIcons.minusCircle),
                                  color: const Color(0xFF0D9488),
                                  disabledColor: Colors.grey.withValues(alpha: 0.3),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_totalDays Hari',
                                      key: const ValueKey('days_counter_text'),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('increment_days_btn'),
                                  onPressed: (_selectedType?.fixedDays != null ||
                                          _totalDays >= _effectiveMaxDays)
                                      ? null
                                      : () {
                                          setState(() => _totalDays++);
                                        },
                                  icon: const Icon(LucideIcons.plusCircle),
                                  color: const Color(0xFF0D9488),
                                  disabledColor: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Quick Day Selection Chips (1 s/d 30 hari)
                        if (_selectedType?.fixedDays == null) ...[
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [1, 2, 3, 5, 7, 14, 30]
                                  .where((d) => d <= _effectiveMaxDays)
                                  .map((days) {
                                final isSelected = _totalDays == days;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('$days Hari'),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _totalDays = days);
                                      }
                                    },
                                    selectedColor: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.15),
                                    backgroundColor: inputBg,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF0D9488)
                                          : textCol,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF0D9488)
                                            : borderCol,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Banner Estimasi Rentang Cuti
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendarRange,
                                color: Color(0xFF0D9488),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Periode: ${_formatDate(_startDate)} s/d ${_formatDate(_calculatedEndDate)} ($_totalDays hari)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 3: Alasan Pengajuan ───────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.fileEdit,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ALASAN / CATATAN',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('leave_notes_field'),
                          controller: _notesController,
                          maxLines: 4,
                          maxLength: 500,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'Tuliskan alasan atau keterangan lengkap pengajuan cuti/izin Anda...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF0D9488),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppDocumentUploadCard(
                    title: 'DOKUMEN PENDUKUNG',
                    titleIcon: LucideIcons.paperclip,
                    isRequired: _selectedType?.requiresFile == true,
                    requiredTagText: 'Wajib Diunggah',
                    optionalTagText: 'Opsional',
                    uploadPlaceholderTitle: 'Lampirkan Foto Bukti / Surat Dokter',
                    uploadPlaceholderSubtitle:
                        'Kamera atau Galeri (Otomatis dikompresi)',
                    sheetTitle: 'Pilih Sumber Dokumen / Foto',
                    sampleTitle: 'Gunakan Sampel Surat Dokter',
                    sampleSubtitle: 'Simulasi lampiran dokumen pendukung',
                    sampleFileName: 'sample_leave_proof.jpg',
                    file: _pickedPhoto,
                    compressResult: _compressResult,
                    isCompressing: _isCompressingPhoto,
                    uploadBoxKey: const ValueKey('upload_leave_photo_box'),
                    deleteButtonKey: const ValueKey('delete_leave_photo_btn'),
                    onFileWithCompressionChanged: (file, result) {
                      setState(() {
                        _pickedPhoto = file;
                        _compressResult = result;
                        _isCompressingPhoto = false;
                      });
                    },
                    onError: _showWarningSnackBar,
                  ),
                ],
              ),
            ),
          ),

          // ── STICKY BOTTOM BAR: Submit Button ──────────────────────────────
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
            child: AppButton(
              key: const ValueKey('submit_leave_btn'),
              text: 'Kirim Pengajuan Cuti',
              leadingIcon: LucideIcons.send,
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _handleSubmit,
            ),
          ),
        );
      },
    );
  }
}
