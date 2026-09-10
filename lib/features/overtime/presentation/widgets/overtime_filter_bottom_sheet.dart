import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kriteria filter untuk daftar permintaan lembur (Overtime Requests).
///
/// Pola mengikuti [LeaveFilterCriteria]: field id + nama untuk display,
/// dengan helper `hasActiveFilter` / `activeFilterCount`. Equatable agar
/// perbandingan state BLoC akurat di unit test.
class OvertimeFilterCriteria extends Equatable {
  final DateTimeRange? dateRange;
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;

  /// Filter status pengajuan: null/'all' = semua, 'requested',
  /// 'approved', 'rejected'.
  final String? statusApprove;

  const OvertimeFilterCriteria({
    this.dateRange,
    this.companyId,
    this.company,
    this.departmentId,
    this.department,
    this.positionId,
    this.position,
    this.statusApprove,
  });

  bool get hasActiveFilter =>
      dateRange != null ||
      (company != null && company != 'Semua Perusahaan') ||
      (companyId != null && companyId!.isNotEmpty) ||
      (department != null && department != 'Semua Departemen') ||
      (departmentId != null && departmentId!.isNotEmpty) ||
      (position != null && position != 'Semua Jabatan') ||
      (positionId != null && positionId!.isNotEmpty) ||
      (statusApprove != null &&
          statusApprove!.isNotEmpty &&
          statusApprove != 'all');

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    if ((company != null && company != 'Semua Perusahaan') ||
        (companyId != null && companyId!.isNotEmpty)) {
      count++;
    }
    if ((department != null && department != 'Semua Departemen') ||
        (departmentId != null && departmentId!.isNotEmpty)) {
      count++;
    }
    if ((position != null && position != 'Semua Jabatan') ||
        (positionId != null && positionId!.isNotEmpty)) {
      count++;
    }
    if (statusApprove != null &&
        statusApprove!.isNotEmpty &&
        statusApprove != 'all') {
      count++;
    }
    return count;
  }

  OvertimeFilterCriteria copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? companyId,
    String? company,
    String? departmentId,
    String? department,
    String? positionId,
    String? position,
    String? statusApprove,
  }) {
    return OvertimeFilterCriteria(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
      statusApprove: statusApprove ?? this.statusApprove,
    );
  }

  /// Tanggal mulai terformat 'yyyy-MM-dd' untuk query parameter API.
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Tanggal selesai terformat 'yyyy-MM-dd' untuk query parameter API.
  String? get endDateParam {
    final end = dateRange?.end;
    if (end == null) return null;
    return '${end.year.toString().padLeft(4, '0')}-'
        '${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        dateRange,
        companyId,
        company,
        departmentId,
        department,
        positionId,
        position,
        statusApprove,
      ];
}

/// Menampilkan Modal Bottom Sheet "Filter Permintaan Lembur".
/// Master data organisasi (/companies, /departments, /positions) dimuat via
/// [OrganizationFilterBloc] dengan in-memory caching (rule AGENTS.md #3).
Future<OvertimeFilterCriteria?> showOvertimeFilterBottomSheet(
  BuildContext context, {
  required OvertimeFilterCriteria initialCriteria,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
}) {
  return showModalBottomSheet<OvertimeFilterCriteria>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) {
      final sheetWidget = OvertimeFilterBottomSheet(
        initialCriteria: initialCriteria,
      );

      if (organizationFilterBloc != null) {
        return BlocProvider<OrganizationFilterBloc>.value(
          value: organizationFilterBloc,
          child: sheetWidget,
        );
      }

      return BlocProvider<OrganizationFilterBloc>(
        create: (ctx) => OrganizationFilterBloc(
          repository: repository,
        )..add(const OrganizationFilterStarted()),
        child: sheetWidget,
      );
    },
  );
}

class OvertimeFilterBottomSheet extends StatefulWidget {
  final OvertimeFilterCriteria initialCriteria;

  const OvertimeFilterBottomSheet({super.key, required this.initialCriteria});

  @override
  State<OvertimeFilterBottomSheet> createState() =>
      _OvertimeFilterBottomSheetState();
}

class _OvertimeFilterBottomSheetState extends State<OvertimeFilterBottomSheet> {
  DateTimeRange? _selectedDateRange;

  String? _selectedCompanyId;
  late String _selectedCompany;

  String? _selectedDepartmentId;
  late String _selectedDepartment;

  String? _selectedPositionId;
  late String _selectedPosition;

  /// null/'all' = Semua Status, 'requested', 'approved', 'rejected'.
  late String _selectedStatusApprove;

  @override
  void initState() {
    super.initState();

    _selectedDateRange = widget.initialCriteria.dateRange;

    _selectedCompanyId = widget.initialCriteria.companyId;
    _selectedCompany = widget.initialCriteria.company ?? 'Semua Perusahaan';
    _selectedStatusApprove = widget.initialCriteria.statusApprove ?? 'all';

    if (_isCompanySelected) {
      _selectedDepartmentId = widget.initialCriteria.departmentId;
      _selectedDepartment =
          widget.initialCriteria.department ?? 'Semua Departemen';

      _selectedPositionId = widget.initialCriteria.positionId;
      _selectedPosition = widget.initialCriteria.position ?? 'Semua Jabatan';
    } else {
      _selectedDepartmentId = null;
      _selectedDepartment = 'Semua Departemen';
      _selectedPositionId = null;
      _selectedPosition = 'Semua Jabatan';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<OrganizationFilterBloc>();
        bloc.add(const OrganizationFilterStarted());
        if (_isCompanySelected && _selectedCompanyId != null) {
          bloc.add(
            OrganizationFilterCompanySelected(companyId: _selectedCompanyId),
          );
        }
      }
    });
  }

  bool get _isCompanySelected =>
      _selectedCompany != 'Semua Perusahaan' &&
      _selectedCompany.trim().isNotEmpty;

  void _resetFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedCompanyId = null;
      _selectedCompany = 'Semua Perusahaan';
      _selectedDepartmentId = null;
      _selectedDepartment = 'Semua Departemen';
      _selectedPositionId = null;
      _selectedPosition = 'Semua Jabatan';
      _selectedStatusApprove = 'all';
    });
    context.read<OrganizationFilterBloc>().add(
          const OrganizationFilterCompanySelected(companyId: null),
        );
  }

  void _applyFilters() {
    final result = OvertimeFilterCriteria(
      dateRange: _selectedDateRange,
      companyId: _selectedCompanyId,
      company:
          _selectedCompany == 'Semua Perusahaan' ? null : _selectedCompany,
      departmentId: _selectedDepartmentId,
      department: _selectedDepartment == 'Semua Departemen'
          ? null
          : _selectedDepartment,
      positionId: _selectedPositionId,
      position:
          _selectedPosition == 'Semua Jabatan' ? null : _selectedPosition,
      statusApprove:
          _selectedStatusApprove == 'all' ? null : _selectedStatusApprove,
    );
    Navigator.of(context).pop(result);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String get _dateRangeDisplay {
    if (_selectedDateRange == null) {
      return 'Semua Rentang Waktu';
    }
    return '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final onPrimaryCol = isDark ? const Color(0xFF003732) : Colors.white;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      saveText: 'Pilih',
      helpText: 'PILIH RENTANG TANGGAL',
      fieldStartLabelText: 'Tanggal Mulai',
      fieldEndLabelText: 'Tanggal Selesai',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: primaryCol,
                    onPrimary: onPrimaryCol,
                    surface: surfaceCol,
                    onSurface: textCol,
                    surfaceContainerHighest:
                        AppColors.darkSurfaceContainerHigh,
                    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
                    outline: borderCol,
                  )
                : ColorScheme.light(
                    primary: primaryCol,
                    onPrimary: onPrimaryCol,
                    surface: surfaceCol,
                    onSurface: textCol,
                    surfaceContainerHighest: const Color(0xFFE2E8F0),
                    onSurfaceVariant: const Color(0xFF64748B),
                    outline: borderCol,
                  ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: primaryCol,
              headerForegroundColor: onPrimaryCol,
              backgroundColor: surfaceCol,
              rangePickerHeaderBackgroundColor: primaryCol,
              rangePickerHeaderForegroundColor: onPrimaryCol,
              rangePickerSurfaceTintColor: Colors.transparent,
              rangeSelectionBackgroundColor:
                  primaryCol.withValues(alpha: 0.15),
              todayBorder: BorderSide(color: primaryCol, width: 1.5),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return onPrimaryCol;
                }
                return primaryCol;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryCol;
                }
                return null;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return onPrimaryCol;
                }
                return textCol;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _showOptionSelector({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.surfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    String searchQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredOptions = options.where((opt) {
              if (searchQuery.trim().isEmpty) return true;
              return opt
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase().trim());
            }).toList();

            return Material(
              color: surfaceColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(bottomSheetContext).size.height * 0.7,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkOutlineMuted
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (options.length > 5) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackgroundSubtle
                                    : AppColors.backgroundSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkOutlineMuted
                                      : AppColors.outlineMuted,
                                ),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setModalState(() {
                                    searchQuery = val;
                                  });
                                },
                                style: AppTypography.bodyMedium.copyWith(
                                  color: textCol,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari pilihan...',
                                  hintStyle: AppTypography.bodySmall.copyWith(
                                    color: subtitleCol,
                                  ),
                                  prefixIcon: Icon(
                                    LucideIcons.search,
                                    size: 16,
                                    color: subtitleCol,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const Divider(height: 1),
                        Flexible(
                          child: filteredOptions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'Pilihan tidak ditemukan',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: subtitleCol,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredOptions.length,
                                  itemBuilder: (context, index) {
                                    final opt = filteredOptions[index];
                                    final isSelected = opt == selectedValue;
                                    return ListTile(
                                      onTap: () {
                                        onSelected(opt);
                                        Navigator.of(bottomSheetContext).pop();
                                      },
                                      title: Text(
                                        opt,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: isSelected
                                              ? brandColor
                                              : textCol,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              LucideIcons.check,
                                              color: brandColor,
                                              size: 18,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color fieldBg,
    required Color borderCol,
    required Color textCol,
    required Color labelCol,
    required Color brandColor,
    String? helperText,
    bool isLoading = false,
    bool isEnabled = true,
    VoidCallback? onClear,
  }) {
    final effectiveFieldBg =
        isEnabled ? fieldBg : fieldBg.withValues(alpha: 0.4);
    final effectiveBorderCol =
        isEnabled ? borderCol : borderCol.withValues(alpha: 0.4);
    final effectiveTextCol =
        isEnabled ? textCol : labelCol.withValues(alpha: 0.5);
    final effectiveIconCol =
        isEnabled ? brandColor : labelCol.withValues(alpha: 0.4);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: effectiveTextCol,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: isEnabled && !isLoading ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: effectiveFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: effectiveBorderCol, width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: effectiveIconCol),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: effectiveTextCol,
                        fontWeight:
                            isEnabled ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: brandColor,
                      ),
                    ),
                  ] else if (!isEnabled) ...[
                    Icon(
                      LucideIcons.lock,
                      size: 16,
                      color: labelCol.withValues(alpha: 0.45),
                    ),
                  ] else if (onClear != null) ...[
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child:
                            Icon(LucideIcons.x, size: 16, color: labelCol),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronDown, size: 16, color: labelCol),
                  ],
                ],
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (!isEnabled) ...[
                  Icon(
                    LucideIcons.info,
                    size: 12,
                    color: labelCol.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    helperText,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelCol.withValues(alpha: isEnabled ? 1.0 : 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required String selectedValue,
    required Color brandColor,
    required Color labelCol,
    required Color borderCol,
    required Color fieldBg,
    required bool isDark,
    required VoidCallback onSelected,
  }) {
    final isSelected = value.toLowerCase() == selectedValue.toLowerCase();
    final chipBg = isSelected
        ? (isDark
            ? brandColor.withValues(alpha: 0.18)
            : const Color(0xFFF0FDFA))
        : fieldBg;
    final chipBorder = isSelected ? brandColor : borderCol;
    final chipTextCol =
        isSelected ? (isDark ? brandColor : const Color(0xFF0D9488)) : labelCol;

    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: chipTextCol,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final fieldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;

    final orgState = context.watch<OrganizationFilterBloc>().state;
    final companiesList = [
      'Semua Perusahaan',
      ...orgState.companies.map((c) => c.name),
    ];
    final departmentsList = _isCompanySelected
        ? ['Semua Departemen', ...orgState.departments.map((d) => d.name)]
        : ['Semua Departemen'];
    final positionsList = _isCompanySelected
        ? ['Semua Jabatan', ...orgState.positions.map((p) => p.name)]
        : ['Semua Jabatan'];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOutlineMuted
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),

              // 2. Scrollable Content Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Permintaan Lembur',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Saring permintaan lembur berdasarkan rentang tanggal, perusahaan, divisi, jabatan, dan status',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: labelCol,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: Icon(
                              LucideIcons.rotateCcw,
                              size: 15,
                              color: brandColor,
                            ),
                            label: Text(
                              'Reset Filter',
                              style: AppTypography.labelMedium.copyWith(
                                color: brandColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Field 1: Rentang Tanggal (Date Range)
                      _buildFilterField(
                        label: 'Rentang Tanggal (Date Range)',
                        value: _dateRangeDisplay,
                        icon: LucideIcons.calendar,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        helperText:
                            'Pilih rentang tanggal mulai hingga selesai',
                        onTap: _pickDateRange,
                        onClear: _selectedDateRange != null
                            ? () => setState(() => _selectedDateRange = null)
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Perusahaan (Company)
                      _buildFilterField(
                        label: 'Perusahaan (Company)',
                        value: _selectedCompany,
                        icon: LucideIcons.building,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        isLoading: orgState.isLoadingCompanies,
                        onTap: () {
                          _showOptionSelector(
                            title: 'Pilih Perusahaan',
                            options: companiesList,
                            selectedValue: _selectedCompany,
                            onSelected: (val) {
                              setState(() {
                                _selectedCompany = val;
                                if (val == 'Semua Perusahaan') {
                                  _selectedCompanyId = null;
                                  _selectedDepartmentId = null;
                                  _selectedDepartment = 'Semua Departemen';
                                  _selectedPositionId = null;
                                  _selectedPosition = 'Semua Jabatan';
                                } else {
                                  final found = orgState.companies
                                      .where((c) => c.name == val);
                                  _selectedCompanyId = found.isNotEmpty
                                      ? found.first.id
                                      : null;

                                  _selectedDepartmentId = null;
                                  _selectedDepartment = 'Semua Departemen';
                                  _selectedPositionId = null;
                                  _selectedPosition = 'Semua Jabatan';
                                }
                              });
                              context.read<OrganizationFilterBloc>().add(
                                    OrganizationFilterCompanySelected(
                                      companyId: _selectedCompanyId,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Departemen (Division)
                      _buildFilterField(
                        label: 'Departemen (Division)',
                        value: _selectedDepartment,
                        icon: LucideIcons.briefcase,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        isLoading: orgState.isLoadingDepartments,
                        isEnabled: _isCompanySelected,
                        helperText: _isCompanySelected
                            ? 'Filter berdasarkan divisi organisasi kerja'
                            : 'Pilih perusahaan terlebih dahulu',
                        onTap: () {
                          _showOptionSelector(
                            title: 'Pilih Departemen',
                            options: departmentsList,
                            selectedValue: _selectedDepartment,
                            onSelected: (val) {
                              setState(() {
                                _selectedDepartment = val;
                                if (val == 'Semua Departemen') {
                                  _selectedDepartmentId = null;
                                } else {
                                  final found = orgState.departments
                                      .where((d) => d.name == val);
                                  _selectedDepartmentId = found.isNotEmpty
                                      ? found.first.id
                                      : null;
                                }
                                _selectedPositionId = null;
                                _selectedPosition = 'Semua Jabatan';
                              });
                              context.read<OrganizationFilterBloc>().add(
                                    OrganizationFilterDepartmentSelected(
                                      companyId: _selectedCompanyId,
                                      departmentId: _selectedDepartmentId,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Jabatan (Position)
                      _buildFilterField(
                        label: 'Jabatan (Position)',
                        value: _selectedPosition,
                        icon: LucideIcons.userCheck,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        isLoading: orgState.isLoadingPositions,
                        isEnabled: _isCompanySelected,
                        helperText: _isCompanySelected
                            ? 'Filter permintaan lembur berdasarkan jabatan atau peran pegawai'
                            : 'Pilih perusahaan terlebih dahulu',
                        onTap: () {
                          _showOptionSelector(
                            title: 'Pilih Jabatan',
                            options: positionsList,
                            selectedValue: _selectedPosition,
                            onSelected: (val) {
                              setState(() {
                                _selectedPosition = val;
                                if (val == 'Semua Jabatan') {
                                  _selectedPositionId = null;
                                } else {
                                  final found = orgState.positions
                                      .where((p) => p.name == val);
                                  _selectedPositionId = found.isNotEmpty
                                      ? found.first.id
                                      : null;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field 5: Status Pengajuan Lembur (status)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Pengajuan',
                            style: AppTypography.labelMedium.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusChip(
                                label: 'Semua',
                                value: 'all',
                                selectedValue: _selectedStatusApprove,
                                brandColor: brandColor,
                                labelCol: labelCol,
                                borderCol: borderCol,
                                fieldBg: fieldBg,
                                isDark: isDark,
                                onSelected: () {
                                  setState(
                                      () => _selectedStatusApprove = 'all');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                label: 'Requested',
                                value: 'requested',
                                selectedValue: _selectedStatusApprove,
                                brandColor: brandColor,
                                labelCol: labelCol,
                                borderCol: borderCol,
                                fieldBg: fieldBg,
                                isDark: isDark,
                                onSelected: () {
                                  setState(() =>
                                      _selectedStatusApprove = 'requested');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                label: 'Approved',
                                value: 'approved',
                                selectedValue: _selectedStatusApprove,
                                brandColor: brandColor,
                                labelCol: labelCol,
                                borderCol: borderCol,
                                fieldBg: fieldBg,
                                isDark: isDark,
                                onSelected: () {
                                  setState(() =>
                                      _selectedStatusApprove = 'approved');
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(
                                label: 'Rejected',
                                value: 'rejected',
                                selectedValue: _selectedStatusApprove,
                                brandColor: brandColor,
                                labelCol: labelCol,
                                borderCol: borderCol,
                                fieldBg: fieldBg,
                                isDark: isDark,
                                onSelected: () {
                                  setState(() =>
                                      _selectedStatusApprove = 'rejected');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Default memuat semua status permintaan lembur',
                            style: AppTypography.labelSmall.copyWith(
                              color: labelCol,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Footer Action Buttons (StadiumBorder, 52dp)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: borderCol),
                                  shape: const StadiumBorder(),
                                  foregroundColor: labelCol,
                                ),
                                child: Text(
                                  'Batal',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: labelCol,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _applyFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandColor,
                                  foregroundColor: isDark
                                      ? const Color(0xFF003732)
                                      : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.filter,
                                      size: 18,
                                      color: isDark
                                          ? const Color(0xFF003732)
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Terapkan Filter',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: isDark
                                              ? const Color(0xFF003732)
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
