import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kriteria filter untuk pengajuan presensi luar kantor.
class AttendanceRequestFilterCriteria extends Equatable {
  final DateTimeRange? dateRange;
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;

  /// Filter status: 'requested' (default), 'approved', 'rejected', 'all'.
  final String status;

  const AttendanceRequestFilterCriteria({
    this.dateRange,
    this.companyId,
    this.company,
    this.departmentId,
    this.department,
    this.positionId,
    this.position,
    this.status = 'requested',
  });

  bool get hasActiveFilter =>
      dateRange != null ||
      (company != null && company != 'Semua Perusahaan') ||
      (companyId != null && companyId!.isNotEmpty) ||
      (department != null && department != 'Semua Departemen') ||
      (departmentId != null && departmentId!.isNotEmpty) ||
      (position != null && position != 'Semua Jabatan') ||
      (positionId != null && positionId!.isNotEmpty) ||
      (status.isNotEmpty && status != 'requested');

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
    if (status.isNotEmpty && status != 'requested') {
      count++;
    }
    return count;
  }

  AttendanceRequestFilterCriteria copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? companyId,
    String? company,
    String? departmentId,
    String? department,
    String? positionId,
    String? position,
    String? status,
  }) {
    return AttendanceRequestFilterCriteria(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
      status: status ?? this.status,
    );
  }

  /// Tanggal mulai format 'yyyy-MM-dd' untuk API.
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Tanggal selesai format 'yyyy-MM-dd' untuk API.
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
        status,
      ];
}

/// Menampilkan Modal Bottom Sheet Filter Pengajuan Presensi Luar Kantor.
Future<AttendanceRequestFilterCriteria?> showAttendanceRequestFilterBottomSheet(
  BuildContext context, {
  required AttendanceRequestFilterCriteria initialCriteria,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<AttendanceRequestFilterCriteria>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) {
      final sheetWidget = AttendanceRequestFilterBottomSheet(
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

class AttendanceRequestFilterBottomSheet extends StatefulWidget {
  final AttendanceRequestFilterCriteria initialCriteria;

  const AttendanceRequestFilterBottomSheet({
    super.key,
    required this.initialCriteria,
  });

  @override
  State<AttendanceRequestFilterBottomSheet> createState() =>
      _AttendanceRequestFilterBottomSheetState();
}

class _AttendanceRequestFilterBottomSheetState
    extends State<AttendanceRequestFilterBottomSheet> {
  DateTimeRange? _selectedDateRange;
  String? _selectedCompanyId;
  String _selectedCompany = 'Semua Perusahaan';
  String? _selectedDepartmentId;
  String _selectedDepartment = 'Semua Departemen';
  String? _selectedPositionId;
  String _selectedPosition = 'Semua Jabatan';
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialCriteria.dateRange;
    _selectedCompanyId = widget.initialCriteria.companyId;
    _selectedCompany = widget.initialCriteria.company ?? 'Semua Perusahaan';
    _selectedStatus = widget.initialCriteria.status.isNotEmpty
        ? widget.initialCriteria.status
        : 'requested';

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
      _selectedStatus = 'requested';
    });
    context.read<OrganizationFilterBloc>().add(
          const OrganizationFilterCompanySelected(companyId: null),
        );
  }

  void _applyFilters() {
    final result = AttendanceRequestFilterCriteria(
      dateRange: _selectedDateRange,
      companyId: _selectedCompanyId,
      company: _selectedCompany == 'Semua Perusahaan' ? null : _selectedCompany,
      departmentId: _selectedDepartmentId,
      department: _selectedDepartment == 'Semua Departemen'
          ? null
          : _selectedDepartment,
      positionId: _selectedPositionId,
      position: _selectedPosition == 'Semua Jabatan' ? null : _selectedPosition,
      status: _selectedStatus,
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
                    surfaceContainerHighest: AppColors.darkSurfaceContainerHigh,
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
              rangeSelectionBackgroundColor: primaryCol.withValues(alpha: 0.15),
              todayBorder: BorderSide(color: primaryCol, width: 1.5),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return onPrimaryCol;
                }
                return primaryCol;
              }),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header Modal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryCol.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 18,
                      color: primaryCol,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filter Pengajuan Presensi',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: Icon(
                      LucideIcons.rotateCcw,
                      size: 14,
                      color: primaryCol,
                    ),
                    label: Text(
                      'Reset Filter',
                      style: AppTypography.bodySmall.copyWith(
                        color: primaryCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Konten Scrollable Form Filter ─────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Rentang Tanggal (Date Range)
                    Text(
                      'Rentang Tanggal Presensi',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceCol,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedDateRange != null
                                ? primaryCol
                                : borderCol,
                            width: _selectedDateRange != null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendarRange,
                              size: 18,
                              color: _selectedDateRange != null
                                  ? primaryCol
                                  : subtitleCol,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dateRangeDisplay,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: _selectedDateRange != null
                                      ? textCol
                                      : subtitleCol,
                                  fontWeight: _selectedDateRange != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (_selectedDateRange != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedDateRange = null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: subtitleCol,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                LucideIcons.chevronDown,
                                size: 16,
                                color: subtitleCol,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. Status Pengajuan
                    Text(
                      'Status Pengajuan',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(
                          label: 'Menunggu',
                          value: 'requested',
                          primaryCol: primaryCol,
                          borderCol: borderCol,
                          textCol: textCol,
                          isDark: isDark,
                        ),
                        _buildStatusChip(
                          label: 'Disetujui',
                          value: 'approved',
                          primaryCol: primaryCol,
                          borderCol: borderCol,
                          textCol: textCol,
                          isDark: isDark,
                        ),
                        _buildStatusChip(
                          label: 'Ditolak',
                          value: 'rejected',
                          primaryCol: primaryCol,
                          borderCol: borderCol,
                          textCol: textCol,
                          isDark: isDark,
                        ),
                        _buildStatusChip(
                          label: 'Semua Status',
                          value: 'all',
                          primaryCol: primaryCol,
                          borderCol: borderCol,
                          textCol: textCol,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. Organisasi (Perusahaan, Departemen, Jabatan)
                    BlocBuilder<OrganizationFilterBloc, OrganizationFilterState>(
                      builder: (context, orgState) {
                        final companies = orgState.companies;
                        final departments = orgState.departments;
                        final positions = orgState.positions;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Perusahaan
                            Text(
                              'Perusahaan',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textCol,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdownContainer(
                              borderCol: borderCol,
                              surfaceCol: surfaceCol,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCompany,
                                  isExpanded: true,
                                  icon: Icon(
                                    LucideIcons.chevronDown,
                                    size: 16,
                                    color: subtitleCol,
                                  ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: textCol,
                                    fontSize: 13.5,
                                  ),
                                  dropdownColor: surfaceCol,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: 'Semua Perusahaan',
                                      child: Text('Semua Perusahaan'),
                                    ),
                                    ...companies.map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.name,
                                        child: Text(c.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _selectedCompany = val;
                                      if (val == 'Semua Perusahaan') {
                                        _selectedCompanyId = null;
                                        _selectedDepartment =
                                            'Semua Departemen';
                                        _selectedDepartmentId = null;
                                        _selectedPosition = 'Semua Jabatan';
                                        _selectedPositionId = null;
                                      } else {
                                        final found = companies.firstWhere(
                                          (c) => c.name == val,
                                        );
                                        _selectedCompanyId = found.id;
                                        _selectedDepartment =
                                            'Semua Departemen';
                                        _selectedDepartmentId = null;
                                        _selectedPosition = 'Semua Jabatan';
                                        _selectedPositionId = null;
                                      }
                                    });
                                    context.read<OrganizationFilterBloc>().add(
                                          OrganizationFilterCompanySelected(
                                            companyId: _selectedCompanyId,
                                          ),
                                        );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Departemen
                            Text(
                              'Departemen',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _isCompanySelected
                                    ? textCol
                                    : subtitleCol.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdownContainer(
                              borderCol: borderCol,
                              surfaceCol: surfaceCol,
                              enabled: _isCompanySelected,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedDepartment,
                                  isExpanded: true,
                                  icon: Icon(
                                    LucideIcons.chevronDown,
                                    size: 16,
                                    color: subtitleCol,
                                  ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _isCompanySelected
                                        ? textCol
                                        : subtitleCol.withValues(alpha: 0.6),
                                    fontSize: 13.5,
                                  ),
                                  dropdownColor: surfaceCol,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: 'Semua Departemen',
                                      child: Text('Semua Departemen'),
                                    ),
                                    if (_isCompanySelected)
                                      ...departments.map(
                                        (d) => DropdownMenuItem<String>(
                                          value: d.name,
                                          child: Text(d.name),
                                        ),
                                      ),
                                  ],
                                  onChanged: _isCompanySelected
                                      ? (val) {
                                          if (val == null) return;
                                          setState(() {
                                            _selectedDepartment = val;
                                            if (val == 'Semua Departemen') {
                                              _selectedDepartmentId = null;
                                            } else {
                                              final found =
                                                  departments.firstWhere(
                                                (d) => d.name == val,
                                              );
                                              _selectedDepartmentId = found.id;
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Jabatan
                            Text(
                              'Jabatan',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _isCompanySelected
                                    ? textCol
                                    : subtitleCol.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdownContainer(
                              borderCol: borderCol,
                              surfaceCol: surfaceCol,
                              enabled: _isCompanySelected,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPosition,
                                  isExpanded: true,
                                  icon: Icon(
                                    LucideIcons.chevronDown,
                                    size: 16,
                                    color: subtitleCol,
                                  ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _isCompanySelected
                                        ? textCol
                                        : subtitleCol.withValues(alpha: 0.6),
                                    fontSize: 13.5,
                                  ),
                                  dropdownColor: surfaceCol,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: 'Semua Jabatan',
                                      child: Text('Semua Jabatan'),
                                    ),
                                    if (_isCompanySelected)
                                      ...positions.map(
                                        (p) => DropdownMenuItem<String>(
                                          value: p.name,
                                          child: Text(p.name),
                                        ),
                                      ),
                                  ],
                                  onChanged: _isCompanySelected
                                      ? (val) {
                                          if (val == null) return;
                                          setState(() {
                                            _selectedPosition = val;
                                            if (val == 'Semua Jabatan') {
                                              _selectedPositionId = null;
                                            } else {
                                              final found =
                                                  positions.firstWhere(
                                                (p) => p.name == val,
                                              );
                                              _selectedPositionId = found.id;
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer Action Buttons ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderCol),
                          shape: const StadiumBorder(),
                          foregroundColor: textCol,
                        ),
                        child: Text(
                          'Batal',
                          style: AppTypography.bodyMedium.copyWith(
                            color: subtitleCol,
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCol,
                          foregroundColor:
                              isDark ? const Color(0xFF003732) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                style: AppTypography.bodyMedium.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required Color primaryCol,
    required Color borderCol,
    required Color textCol,
    required bool isDark,
  }) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
      labelStyle: AppTypography.bodySmall.copyWith(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (isDark ? const Color(0xFF003732) : Colors.white)
            : textCol,
        fontSize: 12.5,
      ),
      selectedColor: primaryCol,
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainer
          : const Color(0xFFF8FAFC),
      side: BorderSide(
        color: isSelected ? primaryCol : borderCol,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDropdownContainer({
    required Widget child,
    required Color borderCol,
    required Color surfaceCol,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? surfaceCol : surfaceCol.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? borderCol : borderCol.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
