import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/filter/app_date_range_picker.dart';
import 'package:hris_flutter/core/widgets/filter/app_request_filter_bottom_sheet.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_option_selector_modal.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pilihan status untuk filter transaksi klaim & kasbon.
class ExpenseFilterStatusOption {
  final String label;
  final String value;

  const ExpenseFilterStatusOption({
    required this.label,
    required this.value,
  });

  static const List<ExpenseFilterStatusOption> options = [
    ExpenseFilterStatusOption(label: 'Semua Status', value: 'all'),
    ExpenseFilterStatusOption(label: 'Diajukan', value: 'requested'),
    ExpenseFilterStatusOption(label: 'Disetujui', value: 'approved'),
    ExpenseFilterStatusOption(label: 'Dicairkan', value: 'disbursed'),
    ExpenseFilterStatusOption(label: 'Ditolak', value: 'rejected'),
  ];
}

/// Menampilkan Modal Bottom Sheet Filter terpadu untuk pengeluaran (Reimbursement & Kasbon).
Future<AppRequestFilterData?> showExpensesFilterBottomSheet(
  BuildContext context, {
  required String title,
  required AppRequestFilterData initialData,
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
      final sheetWidget = ExpensesFilterBottomSheet(
        title: title,
        initialData: initialData,
      );

      OrganizationFilterBloc? resolvedOrgBloc = organizationFilterBloc;
      if (resolvedOrgBloc == null) {
        try {
          resolvedOrgBloc = context.read<OrganizationFilterBloc>();
        } catch (_) {}
      }

      if (resolvedOrgBloc != null) {
        return BlocProvider<OrganizationFilterBloc>.value(
          value: resolvedOrgBloc..add(const OrganizationFilterStarted()),
          child: sheetWidget,
        );
      }

      return BlocProvider<OrganizationFilterBloc>(
        create: (ctx) => OrganizationFilterBloc(
          repository: ctx.read<OrganizationFilterRepository>(),
        )..add(const OrganizationFilterStarted()),
        child: sheetWidget,
      );
    },
  );
}

/// Widget Bottom Sheet Filter Pengeluaran (Reimbursement & Kasbon) dengan Wrap Chips.
class ExpensesFilterBottomSheet extends StatefulWidget {
  final String title;
  final AppRequestFilterData initialData;

  const ExpensesFilterBottomSheet({
    super.key,
    required this.title,
    required this.initialData,
  });

  @override
  State<ExpensesFilterBottomSheet> createState() =>
      _ExpensesFilterBottomSheetState();
}

class _ExpensesFilterBottomSheetState extends State<ExpensesFilterBottomSheet> {
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
        : 'all';

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
      _selectedStatus = 'all';
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
            // Header Modal
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

            // Scrollable Filters
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Field 1: Rentang Tanggal
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

                    // Field 2: Status Pengajuan (Wrap Chips)
                    _buildStatusWrapSection(isDark, brandColor, textCol),
                    const SizedBox(height: 18),

                    // Field 3: Perusahaan
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

                    // Field 4: Departemen
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

                    // Field 5: Jabatan
                    FilterFieldSelector(
                      label: 'Jabatan (Position)',
                      value: _selectedPosition,
                      icon: LucideIcons.userCheck,
                      isLoading: orgState.isLoadingPositions,
                      isEnabled: _isCompanySelected,
                      helperText: _isCompanySelected
                          ? 'Filter pengajuan berdasarkan jabatan pegawai'
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

            // Footer Buttons
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

  Widget _buildStatusWrapSection(
    bool isDark,
    Color brandColor,
    Color textCol,
  ) {
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final fieldBg =
        isDark ? AppColors.darkBackgroundSubtle : AppColors.backgroundSubtle;
    final labelCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Column(
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseFilterStatusOption.options.map((opt) {
            final isSelected =
                opt.value.toLowerCase() == _selectedStatus.toLowerCase();
            final chipBg = isSelected
                ? (isDark
                    ? brandColor.withValues(alpha: 0.18)
                    : const Color(0xFFF0FDFA))
                : fieldBg;
            final chipBorder = isSelected ? brandColor : borderCol;
            final chipTextCol = isSelected
                ? (isDark ? brandColor : const Color(0xFF0D9488))
                : labelCol;

            return InkWell(
              onTap: () => setState(() => _selectedStatus = opt.value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: chipBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: chipTextCol,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
