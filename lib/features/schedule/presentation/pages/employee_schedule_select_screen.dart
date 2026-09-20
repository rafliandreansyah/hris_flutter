import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmployeeScheduleSelectScreen extends StatelessWidget {
  final EmployeeRepository? repository;

  const EmployeeScheduleSelectScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmployeeListBloc>(
      create: (context) => EmployeeListBloc(repository: repository)
        ..add(const EmployeeListStarted()),
      child: const _EmployeeScheduleSelectView(),
    );
  }
}

class _EmployeeScheduleSelectView extends StatefulWidget {
  const _EmployeeScheduleSelectView();

  @override
  State<_EmployeeScheduleSelectView> createState() =>
      _EmployeeScheduleSelectViewState();
}

class _EmployeeScheduleSelectViewState
    extends State<_EmployeeScheduleSelectView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<EmployeeListBloc>().state;
      if (!state.isLoading &&
          !state.isLoadingMore &&
          state.currentPage < state.totalPages) {
        context.read<EmployeeListBloc>().add(const EmployeeListLoadMore());
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    context.read<EmployeeListBloc>().add(EmployeeListSearchChanged(query));
  }

  void _selectEmployee(EmployeeDirectoryItem emp) {
    FocusManager.instance.primaryFocus?.unfocus();

    final preview = WorkScheduleEmployee(
      id: emp.id,
      firstName: emp.firstName ?? emp.name,
      lastName: emp.lastName,
      email: emp.email,
      phone: emp.phone,
      photoUrl: emp.avatarUrl,
      employeeNumber: emp.employeeNumber,
      idNumber: emp.idNumber,
      companyName: emp.company,
      departmentName: emp.department,
      positionName: emp.role,
    );

    context.push(
      '${Routes.WORK_SCHEDULE}?employeeId=${emp.id}',
      extra: preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final surfaceCol = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: surfaceCol,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 20,
            color: textCol,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Pegawai',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Pilih pegawai untuk melihat jadwal kerja',
              style: AppTypography.bodySmall.copyWith(
                color: subtitleCol,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Box Container
          Container(
            color: surfaceCol,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: _onSearchChanged,
                style: AppTypography.bodyMedium.copyWith(color: textCol),
                decoration: InputDecoration(
                  hintText: 'Cari nama, jabatan, atau departemen...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: subtitleCol,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: subtitleCol,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
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

          // Employee List Content
          Expanded(
            child: BlocBuilder<EmployeeListBloc, EmployeeListState>(
              builder: (context, state) {
                if (state.isLoading && state.employees.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandTeal,
                    ),
                  );
                }

                if (state.errorMessage != null && state.employees.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            size: 36,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            state.errorMessage ?? 'Gagal memuat pegawai',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () {
                              context
                                  .read<EmployeeListBloc>()
                                  .add(const EmployeeListStarted());
                            },
                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final employees = state.employees;
                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 40,
                          color: subtitleCol,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Pegawai tidak ditemukan',
                          style: AppTypography.titleSmall.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.brandTeal,
                  onRefresh: () async {
                    context
                        .read<EmployeeListBloc>()
                        .add(const EmployeeListRefreshed());
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.marginMobile),
                    itemCount: employees.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == employees.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.brandTeal,
                              ),
                            ),
                          ),
                        );
                      }

                      final employee = employees[index];
                      return EmployeeCard(
                        employee: employee,
                        onTap: () => _selectEmployee(employee),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
