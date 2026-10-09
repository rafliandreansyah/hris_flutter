import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/filter/filter_field_selector.dart';
import 'package:hris_flutter/core/widgets/filter/filter_option_selector_modal.dart';
import 'package:hris_flutter/core/widgets/filter/filter_status_segmented_row.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/organization_filter/organization_filter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _monthNames = [
  'Semua Bulan',
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

class PayrollFilterBottomSheet extends StatefulWidget {
  final int? initialYear;
  final int? initialMonth;
  final String? initialStatus;
  final String? initialCompanyId;
  final String? initialDepartmentId;
  final bool isTeamTab;
  final void Function({
    int? year,
    int? month,
    String? status,
    String? companyId,
    String? departmentId,
  }) onApply;

  const PayrollFilterBottomSheet({
    super.key,
    this.initialYear,
    this.initialMonth,
    this.initialStatus,
    this.initialCompanyId,
    this.initialDepartmentId,
    this.isTeamTab = false,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialYear,
    int? initialMonth,
    String? initialStatus,
    String? initialCompanyId,
    String? initialDepartmentId,
    bool isTeamTab = false,
    required void Function({
      int? year,
      int? month,
      String? status,
      String? companyId,
      String? departmentId,
    }) onApply,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        final sheetWidget = PayrollFilterBottomSheet(
          initialYear: initialYear,
          initialMonth: initialMonth,
          initialStatus: initialStatus,
          initialCompanyId: initialCompanyId,
          initialDepartmentId: initialDepartmentId,
          isTeamTab: isTeamTab,
          onApply: onApply,
        );

        if (isTeamTab) {
          OrganizationFilterBloc? resolvedOrgBloc;
          try {
            resolvedOrgBloc = context.read<OrganizationFilterBloc>();
          } catch (_) {}

          if (resolvedOrgBloc != null) {
            return BlocProvider<OrganizationFilterBloc>.value(
              value: resolvedOrgBloc..add(const OrganizationFilterStarted()),
              child: sheetWidget,
            );
          }

          return BlocProvider<OrganizationFilterBloc>(
            create: (c) => OrganizationFilterBloc()
              ..add(const OrganizationFilterStarted()),
            child: sheetWidget,
          );
        }

        return sheetWidget;
      },
    );
  }

  @override
  State<PayrollFilterBottomSheet> createState() =>
      _PayrollFilterBottomSheetState();
}

class _PayrollFilterBottomSheetState extends State<PayrollFilterBottomSheet> {
  late int _selectedYear;
  int? _selectedMonth;
  String _selectedStatus = 'all';
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  String? _selectedDepartmentId;
  String? _selectedDepartmentName;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    _selectedMonth = widget.initialMonth;
    _selectedStatus = widget.initialStatus ?? 'all';
    _selectedCompanyId = widget.initialCompanyId;
    _selectedDepartmentId = widget.initialDepartmentId;
  }

  void _resetFilter() {
    setState(() {
      _selectedYear = DateTime.now().year;
      _selectedMonth = null;
      _selectedStatus = 'all';
      _selectedCompanyId = null;
      _selectedCompanyName = null;
      _selectedDepartmentId = null;
      _selectedDepartmentName = null;
    });
  }

  void _pickYear() {
    final currentYear = DateTime.now().year;
    final yearsList = List.generate(6, (i) => '${currentYear - i}');

    showFilterOptionSelector(
      context,
      title: 'Pilih Tahun',
      options: yearsList,
      selectedValue: '$_selectedYear',
      onSelected: (selected) {
        final parsed = int.tryParse(selected);
        if (parsed != null) {
          setState(() {
            _selectedYear = parsed;
          });
        }
      },
    );
  }

  void _pickMonth() {
    final currentLabel = _selectedMonth != null &&
            _selectedMonth! >= 1 &&
            _selectedMonth! <= 12
        ? _monthNames[_selectedMonth!]
        : 'Semua Bulan';

    showFilterOptionSelector(
      context,
      title: 'Pilih Bulan',
      options: _monthNames,
      selectedValue: currentLabel,
      onSelected: (selected) {
        final idx = _monthNames.indexOf(selected);
        setState(() {
          _selectedMonth = idx <= 0 ? null : idx;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _selectedMonth != null &&
            _selectedMonth! >= 1 &&
            _selectedMonth! <= 12
        ? _monthNames[_selectedMonth!]
        : 'Semua Bulan';

    final statusOptions = [
      const FilterStatusOption(label: 'Semua', value: 'all'),
      const FilterStatusOption(label: 'Dibayar', value: 'paid'),
      const FilterStatusOption(label: 'Disetujui', value: 'approved'),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 18,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filter Slip Gaji',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilter,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandTeal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Atur Ulang',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outlineVariant,
            ),

            // ── Scrollable Body Fields ───────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Tahun
                    FilterFieldSelector(
                      label: 'Tahun',
                      value: '$_selectedYear',
                      icon: LucideIcons.calendar,
                      helperText: 'Pilih tahun periode penerbitan slip gaji',
                      onTap: _pickYear,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Bulan
                    FilterFieldSelector(
                      label: 'Bulan',
                      value: monthLabel,
                      icon: LucideIcons.calendarDays,
                      helperText: 'Filter berdasarkan bulan periode penggajian',
                      onTap: _pickMonth,
                      onClear: _selectedMonth != null
                          ? () => setState(() => _selectedMonth = null)
                          : null,
                    ),
                    const SizedBox(height: 18),

                    // Field 3: Status Pembayaran
                    FilterStatusSegmentedRow(
                      title: 'Status Pembayaran',
                      options: statusOptions,
                      selectedValue: _selectedStatus,
                      helperText: 'Filter berdasarkan status proses slip gaji',
                      onSelected: (val) {
                        setState(() => _selectedStatus = val);
                      },
                    ),

                    // Field 4 & 5: Organisasi (Hanya untuk Tab Tim / Semua Pegawai)
                    if (widget.isTeamTab) ...[
                      const SizedBox(height: 18),
                      BlocBuilder<OrganizationFilterBloc,
                          OrganizationFilterState>(
                        builder: (context, orgState) {
                          final companies = orgState.companies;
                          final departments = orgState.departments;

                          final hasCompany = _selectedCompanyId != null &&
                              _selectedCompanyId!.isNotEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FilterFieldSelector(
                                label: 'Perusahaan (Company)',
                                value: _selectedCompanyName ??
                                    'Semua Perusahaan',
                                icon: LucideIcons.building2,
                                isLoading: orgState.isLoadingCompanies,
                                onTap: () {
                                  final compOptions = [
                                    'Semua Perusahaan',
                                    ...companies.map((c) => c.name),
                                  ];
                                  showFilterOptionSelector(
                                    context,
                                    title: 'Pilih Perusahaan',
                                    options: compOptions,
                                    selectedValue: _selectedCompanyName ??
                                        'Semua Perusahaan',
                                    onSelected: (val) {
                                      if (val == 'Semua Perusahaan') {
                                        setState(() {
                                          _selectedCompanyId = null;
                                          _selectedCompanyName = null;
                                          _selectedDepartmentId = null;
                                          _selectedDepartmentName = null;
                                        });
                                        context
                                            .read<OrganizationFilterBloc>()
                                            .add(
                                              const OrganizationFilterCompanySelected(),
                                            );
                                      } else {
                                        final comp = companies.firstWhere(
                                          (c) => c.name == val,
                                        );
                                        setState(() {
                                          _selectedCompanyId = comp.id;
                                          _selectedCompanyName = comp.name;
                                          _selectedDepartmentId = null;
                                          _selectedDepartmentName = null;
                                        });
                                        context
                                            .read<OrganizationFilterBloc>()
                                            .add(
                                              OrganizationFilterCompanySelected(
                                                companyId: comp.id,
                                              ),
                                            );
                                      }
                                    },
                                  );
                                },
                                onClear: _selectedCompanyId != null
                                    ? () => setState(() {
                                          _selectedCompanyId = null;
                                          _selectedCompanyName = null;
                                          _selectedDepartmentId = null;
                                          _selectedDepartmentName = null;
                                        })
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              FilterFieldSelector(
                                label: 'Departemen (Division)',
                                value: _selectedDepartmentName ??
                                    'Semua Departemen',
                                icon: hasCompany
                                    ? LucideIcons.briefcase
                                    : LucideIcons.lock,
                                isEnabled: hasCompany,
                                helperText: hasCompany
                                    ? 'Filter berdasarkan departemen kerja'
                                    : 'Pilih perusahaan terlebih dahulu',
                                isLoading: orgState.isLoadingDepartments,
                                onTap: hasCompany
                                    ? () {
                                        final deptOptions = [
                                          'Semua Departemen',
                                          ...departments.map((d) => d.name),
                                        ];
                                        showFilterOptionSelector(
                                          context,
                                          title: 'Pilih Departemen',
                                          options: deptOptions,
                                          selectedValue:
                                              _selectedDepartmentName ??
                                                  'Semua Departemen',
                                          onSelected: (val) {
                                            if (val == 'Semua Departemen') {
                                              setState(() {
                                                _selectedDepartmentId = null;
                                                _selectedDepartmentName = null;
                                              });
                                            } else {
                                              final dept =
                                                  departments.firstWhere(
                                                (d) => d.name == val,
                                              );
                                              setState(() {
                                                _selectedDepartmentId = dept.id;
                                                _selectedDepartmentName =
                                                    dept.name;
                                              });
                                            }
                                          },
                                        );
                                      }
                                    : null,
                                onClear: _selectedDepartmentId != null
                                    ? () => setState(() {
                                          _selectedDepartmentId = null;
                                          _selectedDepartmentName = null;
                                        })
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
                      onPressed: () {
                        widget.onApply(
                          year: _selectedYear,
                          month: _selectedMonth,
                          status: _selectedStatus == 'all'
                              ? null
                              : _selectedStatus,
                          companyId: _selectedCompanyId,
                          departmentId: _selectedDepartmentId,
                        );
                        Navigator.of(context).pop();
                      },
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
