import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman Direktori Pegawai Oasish HRIS sesuai Google Stitch.
/// Dibangun dengan Clean Architecture + Flutter BLoC (EmployeeListBloc).
class EmployeeDirectoryScreen extends StatelessWidget {
  final List<EmployeeDirectoryItem>? customEmployees;
  final EmployeeRepository? employeeRepository;
  final EmployeeListBloc? employeeListBloc;

  const EmployeeDirectoryScreen({
    super.key,
    this.customEmployees,
    this.employeeRepository,
    this.employeeListBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (employeeListBloc != null) {
      return BlocProvider<EmployeeListBloc>.value(
        value: employeeListBloc!,
        child: _EmployeeDirectoryView(
          customEmployees: customEmployees,
          employeeRepository: employeeRepository,
        ),
      );
    }

    return BlocProvider<EmployeeListBloc>(
      create: (ctx) => EmployeeListBloc(
        repository: employeeRepository,
        initialCustomEmployees: customEmployees,
      )..add(EmployeeListStarted(customEmployees: customEmployees)),
      child: _EmployeeDirectoryView(
        customEmployees: customEmployees,
        employeeRepository: employeeRepository,
      ),
    );
  }
}

class _EmployeeDirectoryView extends StatefulWidget {
  final List<EmployeeDirectoryItem>? customEmployees;
  final EmployeeRepository? employeeRepository;

  const _EmployeeDirectoryView({
    this.customEmployees,
    this.employeeRepository,
  });

  @override
  State<_EmployeeDirectoryView> createState() => _EmployeeDirectoryViewState();
}

class _EmployeeDirectoryViewState extends State<_EmployeeDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  String _localSearchQuery = '';

  // Interaktivitas Search Input: menyembunyikan saat scroll ke atas (reverse),
  // dan tampil lagi saat scroll ke bawah (forward)
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      final state = context.read<EmployeeListBloc>().state;
      if (!state.isLoading &&
          !state.isLoadingMore &&
          state.currentPage < state.totalPages) {
        context.read<EmployeeListBloc>().add(const EmployeeListLoadMore());
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() {
      _localSearchQuery = val;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<EmployeeListBloc>().add(EmployeeListSearchChanged(val));
    });
  }

  List<String> _availableCompanies(List<EmployeeDirectoryItem> employees) {
    final comps = employees
        .map((e) => e.company)
        .whereType<String>()
        .toSet()
        .toList();
    comps.sort();
    return ['Semua Perusahaan', ...comps];
  }

  List<String> _availableDepartments(List<EmployeeDirectoryItem> employees) {
    final depts = employees.map((e) => e.department).toSet().toList();
    depts.sort();
    return ['Semua Departemen', ...depts];
  }

  List<String> _availablePositions(List<EmployeeDirectoryItem> employees) {
    final roles = employees.map((e) => e.role).toSet().toList();
    roles.sort();
    return ['Semua Jabatan', ...roles];
  }

  List<EmployeeDirectoryItem> _getFilteredEmployees({
    required List<EmployeeDirectoryItem> source,
    required EmployeeFilterCriteria filterCriteria,
  }) {
    return source.where((emp) {
      // 1. Filter by search query
      if (_localSearchQuery.trim().isNotEmpty) {
        final q = _localSearchQuery.toLowerCase().trim();
        final matches = emp.name.toLowerCase().contains(q) ||
            emp.role.toLowerCase().contains(q) ||
            emp.department.toLowerCase().contains(q) ||
            emp.email.toLowerCase().contains(q) ||
            emp.id.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // 2. Filter by Company
      if (filterCriteria.company != null &&
          filterCriteria.company != 'Semua Perusahaan') {
        if (emp.company != null &&
            emp.company!.toLowerCase() !=
                filterCriteria.company!.toLowerCase()) {
          return false;
        }
      }

      // 3. Filter by Department
      if (filterCriteria.department != null &&
          filterCriteria.department != 'Semua Departemen') {
        if (emp.department.toLowerCase() !=
            filterCriteria.department!.toLowerCase()) {
          return false;
        }
      }

      // 4. Filter by Position / Role
      if (filterCriteria.position != null &&
          filterCriteria.position != 'Semua Jabatan') {
        if (emp.role.toLowerCase() !=
            filterCriteria.position!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onEmployeeTapped(EmployeeDirectoryItem employee) {
    context.push(Routes.EMPLOYEE_DETAIL, extra: employee);
  }

  Widget _buildActiveFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
    required Color brandColor,
    required Color textCol,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: brandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brandColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              LucideIcons.x,
              size: 13,
              color: brandColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final surfaceCol =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final brandColor =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final state = context.watch<EmployeeListBloc>().state;
    final filteredList = _getFilteredEmployees(
      source: state.employees,
      filterCriteria: state.filterCriteria,
    );

    return Scaffold(
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
              'Employee Directory',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Find colleagues, departments & contact info',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showEmployeeFilterBottomSheet(
                context,
                initialCriteria: state.filterCriteria,
                availableCompanies: _availableCompanies(state.employees),
                availableDepartments: _availableDepartments(state.employees),
                availablePositions: _availablePositions(state.employees),
              );
              if (result != null && context.mounted) {
                context
                    .read<EmployeeListBloc>()
                    .add(EmployeeListFilterApplied(result));
              }
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  color:
                      state.filterCriteria.hasActiveFilter ? brandColor : textCol,
                  size: 20,
                ),
                if (state.filterCriteria.hasActiveFilter)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgCol, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter Direktori',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Dynamic Hide/Show Search Bar on Scroll
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isSearchVisible ? 62 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: bgCol,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isSearchVisible ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceCol,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: (val) {
                        _debounceTimer?.cancel();
                        setState(() {
                          _localSearchQuery = val;
                        });
                        context
                            .read<EmployeeListBloc>()
                            .add(EmployeeListSearchChanged(val));
                      },
                      style: AppTypography.bodyMedium.copyWith(color: textCol),
                      decoration: InputDecoration(
                        hintText:
                            'Search by name, role, department, or email...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: subtitleCol,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: subtitleCol,
                          size: 20,
                        ),
                        suffixIcon: _localSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: subtitleCol,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  context
                                      .read<EmployeeListBloc>()
                                      .add(const EmployeeListSearchChanged(''));
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Content with Scroll Notification Listener
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                       notification.metrics.axis == Axis.vertical) {
                    final delta = notification.scrollDelta ?? 0;

                    // Jika berada di dekat batas atas, selalu tampilkan search bar
                    if (notification.metrics.pixels <= 10) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                    // Saat scroll ke atas (content bergerak ke atas) -> sembunyikan search bar
                    else if (delta > 3) {
                      if (_isSearchVisible) {
                        setState(() => _isSearchVisible = false);
                      }
                    }
                    // Saat scroll ke bawah (content bergerak ke bawah) -> tampilkan search bar
                    else if (delta < -3) {
                      if (!_isSearchVisible) {
                        setState(() => _isSearchVisible = true);
                      }
                    }
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<EmployeeListBloc>()
                        .add(const EmployeeListRefreshed());
                  },
                  color: brandColor,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Active Filter Chips Row
                      if (state.filterCriteria.hasActiveFilter)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (state.filterCriteria.company != null &&
                                      state.filterCriteria.company !=
                                          'Semua Perusahaan')
                                    _buildActiveFilterChip(
                                      label: state.filterCriteria.company!,
                                      icon: LucideIcons.building,
                                      onDeleted: () {
                                        final newCriteria =
                                            state.filterCriteria.copyWith(
                                          company: 'Semua Perusahaan',
                                          companyId: '',
                                        );
                                        context.read<EmployeeListBloc>().add(
                                              EmployeeListFilterApplied(
                                                newCriteria,
                                              ),
                                            );
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  if (state.filterCriteria.department != null &&
                                      state.filterCriteria.department !=
                                          'Semua Departemen')
                                    _buildActiveFilterChip(
                                      label: state.filterCriteria.department!,
                                      icon: LucideIcons.layers,
                                      onDeleted: () {
                                        final newCriteria =
                                            state.filterCriteria.copyWith(
                                          department: 'Semua Departemen',
                                          departmentId: '',
                                        );
                                        context.read<EmployeeListBloc>().add(
                                              EmployeeListFilterApplied(
                                                newCriteria,
                                              ),
                                            );
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  if (state.filterCriteria.position != null &&
                                      state.filterCriteria.position !=
                                          'Semua Jabatan')
                                    _buildActiveFilterChip(
                                      label: state.filterCriteria.position!,
                                      icon: LucideIcons.idCard,
                                      onDeleted: () {
                                        final newCriteria =
                                            state.filterCriteria.copyWith(
                                          position: 'Semua Jabatan',
                                          positionId: '',
                                        );
                                        context.read<EmployeeListBloc>().add(
                                              EmployeeListFilterApplied(
                                                newCriteria,
                                              ),
                                            );
                                      },
                                      brandColor: brandColor,
                                      textCol: textCol,
                                    ),
                                  TextButton(
                                    onPressed: () {
                                      context.read<EmployeeListBloc>().add(
                                            const EmployeeListFilterApplied(
                                              EmployeeFilterCriteria(),
                                            ),
                                          );
                                    },
                                    child: Text(
                                      'Hapus Semua',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: brandColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Loading First Page Indicator
                      if (state.isLoading && state.employees.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(brandColor),
                              ),
                            ),
                          ),
                        )
                      // Employee Cards List or Empty State
                      else if (filteredList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 48,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceContainer
                                          : AppColors.surfaceContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.users,
                                      size: 32,
                                      color: subtitleCol,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _localSearchQuery.isNotEmpty ||
                                            state.filterCriteria.hasActiveFilter
                                        ? 'Pegawai tidak ditemukan'
                                        : 'Belum Ada Data Pegawai',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: textCol,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    state.filterCriteria.hasActiveFilter &&
                                            _localSearchQuery.isNotEmpty
                                        ? 'Tidak ada pegawai yang cocok dengan kata kunci "$_localSearchQuery" dan filter yang aktif.'
                                        : state.filterCriteria.hasActiveFilter
                                            ? 'Tidak ada pegawai yang cocok dengan kriteria filter yang dipilih.'
                                            : 'Tidak ada pegawai yang cocok dengan kata kunci "$_localSearchQuery".',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: subtitleCol,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_localSearchQuery.isNotEmpty ||
                                      state.filterCriteria.hasActiveFilter) ...[
                                    const SizedBox(height: 18),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                        context.read<EmployeeListBloc>().add(
                                              const EmployeeListFilterApplied(
                                                EmployeeFilterCriteria(),
                                              ),
                                            );
                                      },
                                      icon: const Icon(LucideIcons.rotateCcw,
                                          size: 15),
                                      label: const Text('Reset Pencarian'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: brandColor,
                                        side: BorderSide(
                                          color:
                                              brandColor.withValues(alpha: 0.5),
                                        ),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final emp = filteredList[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: EmployeeCard(
                                    employee: emp,
                                    onTap: () => _onEmployeeTapped(emp),
                                  ),
                                );
                              },
                              childCount: filteredList.length,
                            ),
                          ),
                        ),

                      // Infinite Scroll Pagination Indicator
                      if (state.isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      brandColor),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (!state.isLoading &&
                          state.employees.isNotEmpty &&
                          state.currentPage >= state.totalPages)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Semua data pegawai telah ditampilkan',
                                style: AppTypography.labelSmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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
    );
  }
}
