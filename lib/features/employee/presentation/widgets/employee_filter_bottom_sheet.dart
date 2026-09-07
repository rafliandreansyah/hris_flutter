import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/employee/data/models/organization_filter_models.dart';
import 'package:hris_flutter/features/employee/domain/repositories/organization_filter_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kriteria filter untuk daftar direktori pegawai Oasish HRIS.
class EmployeeFilterCriteria {
  final String? companyId;
  final String? company;
  final String? departmentId;
  final String? department;
  final String? positionId;
  final String? position;

  const EmployeeFilterCriteria({
    this.companyId,
    this.company,
    this.departmentId,
    this.department,
    this.positionId,
    this.position,
  });

  bool get hasActiveFilter =>
      (company != null && company != 'Semua Perusahaan') ||
      (companyId != null && companyId!.isNotEmpty) ||
      (department != null && department != 'Semua Departemen') ||
      (departmentId != null && departmentId!.isNotEmpty) ||
      (position != null && position != 'Semua Jabatan') ||
      (positionId != null && positionId!.isNotEmpty);

  int get activeFilterCount {
    int count = 0;
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
    return count;
  }

  EmployeeFilterCriteria copyWith({
    String? companyId,
    String? company,
    String? departmentId,
    String? department,
    String? positionId,
    String? position,
  }) {
    return EmployeeFilterCriteria(
      companyId: companyId ?? this.companyId,
      company: company ?? this.company,
      departmentId: departmentId ?? this.departmentId,
      department: department ?? this.department,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
    );
  }
}

/// Menampilkan Modal Bottom Sheet "Filter Data Pegawai" sesuai spesifikasi Google Stitch
/// dan mengintegrasikan pemuatan data dari OrganizationFilterBloc (caching /companies, /departments, /positions).
Future<EmployeeFilterCriteria?> showEmployeeFilterBottomSheet(
  BuildContext context, {
  required EmployeeFilterCriteria initialCriteria,
  OrganizationFilterRepository? repository,
  OrganizationFilterBloc? organizationFilterBloc,
  List<String>? availableCompanies,
  List<String>? availableDepartments,
  List<String>? availablePositions,
}) {
  return showModalBottomSheet<EmployeeFilterCriteria>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) {
      final sheetWidget = EmployeeFilterBottomSheet(
        initialCriteria: initialCriteria,
        repository: repository,
        organizationFilterBloc: organizationFilterBloc,
        availableCompanies: availableCompanies,
        availableDepartments: availableDepartments,
        availablePositions: availablePositions,
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

class EmployeeFilterBottomSheet extends StatefulWidget {
  final EmployeeFilterCriteria initialCriteria;
  final OrganizationFilterRepository? repository;
  final OrganizationFilterBloc? organizationFilterBloc;
  final List<String>? availableCompanies;
  final List<String>? availableDepartments;
  final List<String>? availablePositions;

  const EmployeeFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    this.repository,
    this.organizationFilterBloc,
    this.availableCompanies,
    this.availableDepartments,
    this.availablePositions,
  });

  @override
  State<EmployeeFilterBottomSheet> createState() =>
      _EmployeeFilterBottomSheetState();
}

class _EmployeeFilterBottomSheetState extends State<EmployeeFilterBottomSheet> {
  String? _selectedCompanyId;
  late String _selectedCompany;

  String? _selectedDepartmentId;
  late String _selectedDepartment;

  String? _selectedPositionId;
  late String _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.initialCriteria.companyId;
    _selectedCompany = widget.initialCriteria.company ?? 'Semua Perusahaan';

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
          bloc.add(OrganizationFilterCompanySelected(companyId: _selectedCompanyId));
        }
      }
    });
  }

  bool get _isCompanySelected =>
      _selectedCompany != 'Semua Perusahaan' &&
      _selectedCompany.trim().isNotEmpty;

  List<String> _getCompaniesList(List<CompanyItem> companies) {
    if (companies.isNotEmpty) {
      return ['Semua Perusahaan', ...companies.map((c) => c.name)];
    }
    final fallback = [
      'Semua Perusahaan',
      ...?widget.availableCompanies?.where((c) => c != 'Semua Perusahaan'),
    ];
    if (fallback.length == 1) {
      fallback.addAll([
        'PT Oasish Group',
        'PT Oasish Nusantara',
        'PT Muratech Teknologi',
      ]);
    }
    return fallback;
  }

  List<String> _getDepartmentsList(List<DepartmentItem> departments) {
    if (!_isCompanySelected) {
      return ['Semua Departemen'];
    }
    if (departments.isNotEmpty) {
      return ['Semua Departemen', ...departments.map((d) => d.name)];
    }
    final fallback = [
      'Semua Departemen',
      ...?widget.availableDepartments?.where((d) => d != 'Semua Departemen'),
    ];
    if (fallback.length == 1) {
      fallback.addAll([
        'Engineering',
        'Operations',
        'Human Resources',
        'Finance',
        'Marketing',
        'Product',
      ]);
    }
    return fallback;
  }

  List<String> _getPositionsList(List<PositionItem> positions) {
    if (!_isCompanySelected) {
      return ['Semua Jabatan'];
    }
    if (positions.isNotEmpty) {
      return ['Semua Jabatan', ...positions.map((p) => p.name)];
    }
    final fallback = [
      'Semua Jabatan',
      ...?widget.availablePositions?.where((p) => p != 'Semua Jabatan'),
    ];
    if (fallback.length == 1) {
      fallback.addAll([
        'Senior Frontend Engineer',
        'Site Operations Supervisor',
        'Head of People & Culture',
        'Senior Engineering Manager',
        'Finance & Tax Specialist',
      ]);
    }
    return fallback;
  }

  void _resetFilters() {
    setState(() {
      _selectedCompanyId = null;
      _selectedCompany = 'Semua Perusahaan';
      _selectedDepartmentId = null;
      _selectedDepartment = 'Semua Departemen';
      _selectedPositionId = null;
      _selectedPosition = 'Semua Jabatan';
    });
    context.read<OrganizationFilterBloc>().add(
      const OrganizationFilterCompanySelected(companyId: null),
    );
  }

  void _applyFilters() {
    final criteria = EmployeeFilterCriteria(
      companyId: _selectedCompanyId,
      company: _selectedCompany,
      departmentId: _selectedDepartmentId,
      department: _selectedDepartment,
      positionId: _selectedPositionId,
      position: _selectedPosition,
    );
    Navigator.of(context).pop(criteria);
  }

  Future<void> _showOptionSelector({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
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
              return opt.toLowerCase().contains(
                searchQuery.toLowerCase().trim(),
              );
            }).toList();

            return Material(
              color: surfaceCol,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                                  : AppColors.outlineMuted,
                              borderRadius: BorderRadius.circular(2),
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

                        // Search box for filtering long lists
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
                                    final option = filteredOptions[index];
                                    final isSelected = option == selectedValue;
                                    return ListTile(
                                      onTap: () {
                                        onSelected(option);
                                        Navigator.of(bottomSheetContext).pop();
                                      },
                                      title: Text(
                                        option,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final fieldBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;

    final orgState = context.watch<OrganizationFilterBloc>().state;
    final companiesList = _getCompaniesList(orgState.companies);
    final departmentsList = _getDepartmentsList(orgState.departments);
    final positionsList = _getPositionsList(orgState.positions);

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
              // 1. Drag Handle Bar (M3 Standard: 40x4dp, centered)
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
                      // Header Row: Title & Reset Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Data Pegawai',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: textCol,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Saring daftar pegawai berdasarkan perusahaan, departemen, dan jabatan',
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

                      // Field 1: Perusahaan (Company)
                      _buildFilterField(
                        label: 'Perusahaan (Company)',
                        subLabel: 'Semua Entitas',
                        value: _selectedCompany,
                        icon: LucideIcons.building,
                        isLoading: orgState.isLoadingCompanies,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        helperText:
                            'Mencakup PT Oasish Group & Seluruh Unit Usaha',
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
                                  final match = orgState.companies
                                      .where((c) => c.name == val)
                                      .firstOrNull;
                                  _selectedCompanyId = match?.id;

                                  // Reset cascading filters
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

                      // Field 2: Departemen (Department)
                      _buildFilterField(
                        label: 'Departemen (Department)',
                        subLabel: 'Divisi Kerja',
                        value: _selectedDepartment,
                        icon: LucideIcons.layers,
                        isLoading: orgState.isLoadingDepartments,
                        isEnabled: _isCompanySelected,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        helperText: _isCompanySelected
                            ? 'Filter berdasarkan unit divisi kerja'
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
                                  final match = orgState.departments
                                      .where((d) => d.name == val)
                                      .firstOrNull;
                                  _selectedDepartmentId = match?.id;
                                }

                                // Reset dependent position
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

                      // Field 3: Jabatan (Position)
                      _buildFilterField(
                        label: 'Jabatan (Position)',
                        subLabel: 'Tingkat Peran',
                        value: _selectedPosition,
                        icon: LucideIcons.idCard,
                        isLoading: orgState.isLoadingPositions,
                        isEnabled: _isCompanySelected,
                        fieldBg: fieldBg,
                        borderCol: borderCol,
                        textCol: textCol,
                        labelCol: labelCol,
                        brandColor: brandColor,
                        helperText: _isCompanySelected
                            ? 'Filter berdasarkan tingkat jabatan peran'
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
                                  final match = orgState.positions
                                      .where((p) => p.name == val)
                                      .firstOrNull;
                                  _selectedPositionId = match?.id;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Footer Action Buttons (M3 StadiumBorder 52dp height)
                      Row(
                        children: [
                          // Outlined Button: Batal
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

                          // Filled Button: Terapkan Filter
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

  Widget _buildFilterField({
    required String label,
    required String subLabel,
    required String value,
    required IconData icon,
    bool isLoading = false,
    bool isEnabled = true,
    required Color fieldBg,
    required Color borderCol,
    required Color textCol,
    required Color labelCol,
    required Color brandColor,
    String? helperText,
    required VoidCallback onTap,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: effectiveTextCol,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: labelCol.withValues(alpha: isEnabled ? 0.8 : 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: isEnabled && !isLoading ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: effectiveFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: effectiveBorderCol),
              ),
              child: Row(
                children: [
                  Icon(icon, color: effectiveIconCol, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: effectiveTextCol,
                        fontWeight:
                            isEnabled ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: brandColor,
                      ),
                    )
                  else if (!isEnabled)
                    Icon(
                      LucideIcons.lock,
                      color: labelCol.withValues(alpha: 0.45),
                      size: 16,
                    )
                  else
                    Icon(LucideIcons.chevronDown, color: labelCol, size: 18),
                ],
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  isEnabled ? LucideIcons.badgeCheck : LucideIcons.info,
                  color:
                      isEnabled ? brandColor : labelCol.withValues(alpha: 0.5),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    helperText,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelCol.withValues(alpha: isEnabled ? 0.8 : 0.6),
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
}
