import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/filter/app_date_range_picker.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_option_selector_modal.dart';
import 'package:hris_flutter/core/widgets/filter/filter_status_segmented_row.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Model data kriteria filter seragam untuk seluruh modul pengajuan (Presensi, Cuti, Lembur).
class AppRequestFilterData extends Equatable {
  final DateTimeRange? dateRange;
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;
  final String status;

  const AppRequestFilterData({
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

  AppRequestFilterData copyWith({
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
    return AppRequestFilterData(
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

  /// Tanggal mulai format 'yyyy-MM-dd' untuk query param API.
  String? get startDateParam {
    final start = dateRange?.start;
    if (start == null) return null;
    return '${start.year.toString().padLeft(4, '0')}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
  }

  /// Tanggal selesai format 'yyyy-MM-dd' untuk query param API.
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

/// Menampilkan Modal Bottom Sheet Filter terpadu untuk pengajuan presensi, cuti, atau lembur.
Future<AppRequestFilterData?> showAppRequestFilterBottomSheet(
  BuildContext context, {
  required String title,
  required AppRequestFilterData initialData,
  List<FilterStatusOption>? statusOptions,
  String? statusHelperText,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<AppRequestFilterData>(
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
      final sheetWidget = AppRequestFilterBottomSheet(
        title: title,
        initialData: initialData,
        statusOptions: statusOptions ?? FilterStatusOption.defaultRequestStatusOptions,
        statusHelperText: statusHelperText ?? 'Default memuat status pengajuan diminta (requested)',
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

/// Widget Bottom Sheet Filter terpadu untuk modul pengajuan (Stitch M3 "Teal Oasis").
class AppRequestFilterBottomSheet extends StatefulWidget {
  final String title;
  final AppRequestFilterData initialData;
  final List<FilterStatusOption> statusOptions;
  final String statusHelperText;

  const AppRequestFilterBottomSheet({
    super.key,
    required this.title,
    required this.initialData,
    this.statusOptions = FilterStatusOption.defaultRequestStatusOptions,
    this.statusHelperText = 'Default memuat status pengajuan diminta (requested)',
  });

  @override
  State<AppRequestFilterBottomSheet> createState() =>
      _AppRequestFilterBottomSheetState();
}

class _AppRequestFilterBottomSheetState
    extends State<AppRequestFilterBottomSheet> {
  DateTimeRange? _selectedDateRange;
  String? _selectedCompanyId;
  late String _selectedCompany;
  String? _selectedDepartmentId;
  late String _selectedDepartment;
  String? _selectedPositionId;
  late String _selectedPosition;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialData.dateRange;
    _selectedCompanyId = widget.initialData.companyId;
    _selectedCompany = widget.initialData.company ?? 'Semua Perusahaan';
    _selectedStatus = widget.initialData.status.isNotEmpty
        ? widget.initialData.status
        : 'requested';

    if (_isCompanySelected) {
      _selectedDepartmentId = widget.initialData.departmentId;
      _selectedDepartment =
          widget.initialData.department ?? 'Semua Departemen';
      _selectedPositionId = widget.initialData.positionId;
      _selectedPosition = widget.initialData.position ?? 'Semua Jabatan';
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
    final result = AppRequestFilterData(
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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
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
    final picked = await showAppDateRangePicker(
      context,
      initialDateRange: _selectedDateRange,
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
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      color: brandColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 18,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: Icon(
                      LucideIcons.rotateCcw,
                      size: 14,
                      color: brandColor,
                    ),
                    label: Text(
                      'Reset Filter',
                      style: AppTypography.bodySmall.copyWith(
                        color: brandColor,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Field 1: Rentang Tanggal (Date Range)
                    FilterFieldSelector(
                      label: 'Rentang Tanggal (Date Range)',
                      value: _dateRangeDisplay,
                      icon: LucideIcons.calendar,
                      helperText: 'Pilih rentang tanggal mulai hingga selesai',
                      onTap: _pickDateRange,
                      onClear: _selectedDateRange != null
                          ? () => setState(() => _selectedDateRange = null)
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // Field 2: Status Pengajuan (Segmented chips row)
                    FilterStatusSegmentedRow(
                      title: 'Status Pengajuan',
                      options: widget.statusOptions,
                      selectedValue: _selectedStatus,
                      helperText: widget.statusHelperText,
                      onSelected: (val) {
                        setState(() => _selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Field 3: Perusahaan (Company)
                    FilterFieldSelector(
                      label: 'Perusahaan (Company)',
                      value: _selectedCompany,
                      icon: LucideIcons.building,
                      isLoading: orgState.isLoadingCompanies,
                      onTap: () {
                        showFilterOptionSelector(
                          context,
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

                    // Field 4: Departemen (Division)
                    FilterFieldSelector(
                      label: 'Departemen (Division)',
                      value: _selectedDepartment,
                      icon: LucideIcons.briefcase,
                      isLoading: orgState.isLoadingDepartments,
                      isEnabled: _isCompanySelected,
                      helperText: _isCompanySelected
                          ? 'Filter berdasarkan divisi organisasi kerja'
                          : 'Pilih perusahaan terlebih dahulu',
                      onTap: () {
                        showFilterOptionSelector(
                          context,
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

                    // Field 5: Jabatan (Position)
                    FilterFieldSelector(
                      label: 'Jabatan (Position)',
                      value: _selectedPosition,
                      icon: LucideIcons.userCheck,
                      isLoading: orgState.isLoadingPositions,
                      isEnabled: _isCompanySelected,
                      helperText: _isCompanySelected
                          ? 'Filter pengajuan berdasarkan jabatan atau peran pegawai'
                          : 'Pilih perusahaan terlebih dahulu',
                      onTap: () {
                        showFilterOptionSelector(
                          context,
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
                  ],
                ),
              ),
            ),

            // ── Footer Action Buttons (50dp height) ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Batal',
                      variant: AppButtonVariant.outlined,
                      height: 50,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Terapkan Filter',
                      leadingIcon: LucideIcons.filter,
                      variant: AppButtonVariant.primary,
                      height: 50,
                      onPressed: _applyFilters,
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
}
