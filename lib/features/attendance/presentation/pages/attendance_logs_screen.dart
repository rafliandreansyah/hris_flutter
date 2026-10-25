import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_empty_state.dart';
import 'package:hris_flutter/core/widgets/app_forbidden_state.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_card.dart';
import 'package:hris_flutter/core/widgets/app_search_bar.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';

class AttendanceLogsScreen extends StatelessWidget {
  final AttendanceRepository? attendanceRepository;
  final EmployeeRepository? employeeRepository;
  final AttendanceLogsBloc? attendanceLogsBloc;
  final EmployeeListBloc? employeeListBloc;
  final String? employeeId;
  final bool redirectToDashboardOnBack;

  const AttendanceLogsScreen({
    super.key,
    this.attendanceRepository,
    this.employeeRepository,
    this.attendanceLogsBloc,
    this.employeeListBloc,
    this.employeeId,
    this.redirectToDashboardOnBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        attendanceLogsBloc != null
            ? BlocProvider<AttendanceLogsBloc>.value(
                value: attendanceLogsBloc!,
              )
            : BlocProvider<AttendanceLogsBloc>(
                create: (context) => AttendanceLogsBloc(
                  repository: attendanceRepository,
                  employeeId: employeeId,
                )..add(AttendanceLogsStarted(employeeId: employeeId)),
              ),
        employeeListBloc != null
            ? BlocProvider<EmployeeListBloc>.value(value: employeeListBloc!)
            : BlocProvider<EmployeeListBloc>(
                create: (context) {
                  final bloc = EmployeeListBloc(
                    repository: employeeRepository,
                    attendanceRepository: attendanceRepository,
                    isTeamAttendance: true,
                  );
                  // Data tim hanya dimuat bila berwenang (tab "Tim Saya" disembunyikan bila tidak)
                  if (SecureStorageService.instance.hasAnyPermissionInMemory(
                    AppPermissions.teamAttendanceLogs,
                  )) {
                    bloc.add(const EmployeeListStarted(isTeamAttendance: true));
                  }
                  return bloc;
                },
              ),
      ],
      child: _AttendanceLogsView(
        redirectToDashboardOnBack: redirectToDashboardOnBack,
      ),
    );
  }
}

class _AttendanceLogsView extends StatefulWidget {
  final bool redirectToDashboardOnBack;

  const _AttendanceLogsView({
    this.redirectToDashboardOnBack = false,
  });

  @override
  State<_AttendanceLogsView> createState() => _AttendanceLogsViewState();
}

class _AttendanceLogsViewState extends State<_AttendanceLogsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  /// Tab tim disembunyikan bila user tidak berwenang (tanpa memuat data tim).
  late final bool _canViewTeam = SecureStorageService.instance
      .hasAnyPermissionInMemory(AppPermissions.teamAttendanceLogs);
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _canViewTeam ? 2 : 1, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    _teamScrollController.addListener(_onTeamScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _teamSearchController.dispose();
    _teamScrollController.removeListener(_onTeamScroll);
    _teamScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _onTeamScroll() {
    if (_teamScrollController.hasClients &&
        _teamScrollController.position.pixels >=
            _teamScrollController.position.maxScrollExtent - 250) {
      final state = context.read<EmployeeListBloc>().state;
      if (!state.isLoading &&
          !state.isLoadingMore &&
          state.currentPage < state.totalPages) {
        context.read<EmployeeListBloc>().add(const EmployeeListLoadMore());
      }
    }
  }

  void _handleBack() {
    if (widget.redirectToDashboardOnBack) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.DASHBOARD);
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.DASHBOARD);
      }
    }
  }

  void _onTeamSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<EmployeeListBloc>().add(EmployeeListSearchChanged(val));
    });
  }

  Future<void> _openFilterBottomSheet() async {
    if (_tabController.index == 0) {
      final bloc = context.read<AttendanceLogsBloc>();
      final result = await showAttendanceLogsFilterBottomSheet(
        context,
        initialCriteria: bloc.state.filterCriteria.copyWith(
          lastMonth: bloc.state.lastMonth,
        ),
      );
      if (result != null && mounted) {
        if (result.lastMonth != bloc.state.lastMonth) {
          bloc.add(AttendanceLogsMonthToggled(result.lastMonth));
        }
        bloc.add(AttendanceLogsFilterApplied(result));
      }
    } else {
      final bloc = context.read<EmployeeListBloc>();
      final result = await showEmployeeFilterBottomSheet(
        context,
        initialCriteria: bloc.state.filterCriteria,
      );
      if (result != null && mounted) {
        bloc.add(EmployeeListFilterApplied(result));
      }
    }
  }

  Future<void> _handleMyRefresh() async {
    context.read<AttendanceLogsBloc>().add(const AttendanceLogsRefreshed());
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _handleTeamRefresh() async {
    context
        .read<EmployeeListBloc>()
        .add(const EmployeeListRefreshed(isTeamAttendance: true));
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final logsState = context.watch<AttendanceLogsBloc>().state;
    final teamState = context.watch<EmployeeListBloc>().state;
    final hasActiveFilter = _tabController.index == 0
        ? logsState.filterCriteria.hasActiveFilter
        : teamState.filterCriteria.hasActiveFilter;

    return PopScope(
      canPop: !widget.redirectToDashboardOnBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
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
            onPressed: _handleBack,
          ),
          title: Text(
              AppLocalizations.of(context)?.titleAttendanceLogs ?? 'Riwayat Presensi',
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
        actions: [
          IconButton(
            key: const ValueKey('attendance_logs_filter_button'),
            onPressed: _openFilterBottomSheet,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  color: hasActiveFilter ? brandColor : textCol,
                  size: 20,
                ),
                if (hasActiveFilter)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_canViewTeam)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    setState(() {});
                  },
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerLowest
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.06,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: brandColor,
                  unselectedLabelColor: subtitleCol,
                  labelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  splashBorderRadius: BorderRadius.circular(12),
                  tabs: [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.user, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.tabSelf ?? 'Saya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.users, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n?.tabMyTeam ?? 'Tim Saya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyAttendanceTab(),
                  if (_canViewTeam)
                  _buildTeamAttendanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildMyAttendanceTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return BlocConsumer<AttendanceLogsBloc, AttendanceLogsState>(
      listener: (context, state) {
        if (state.status == AttendanceLogsStatus.failure &&
            state.logs.isNotEmpty &&
            state.errorMessage != null) {
          final l10n = AppLocalizations.of(context);
          if (state.isNotFound && state.lastMonth) {
            AppDialogUtil.showError(
              context,
              title:
                  l10n?.noPayrollPeriodTitle ?? 'Periode Penggajian Belum Ada',
              message: state.errorMessage!,
              retryText: l10n?.viewCurrentMonth ?? 'Lihat Bulan Ini',
              onRetry: () => context
                  .read<AttendanceLogsBloc>()
                  .add(const AttendanceLogsMonthToggled(false)),
            );
          } else {
            AppDialogUtil.showError(
              context,
              title: 'Gagal',
              message: state.errorMessage!,
            );
          }
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildMonthSelector(
              lastMonth: state.lastMonth,
              isDark: isDark,
              brandColor: brandColor,
              textCol: textCol,
              subtitleCol: subtitleCol,
            ),
            Expanded(
              child: _buildMyAttendanceBody(
                state: state,
                isDark: isDark,
                brandColor: brandColor,
                textCol: textCol,
                subtitleCol: subtitleCol,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector({
    required bool lastMonth,
    required bool isDark,
    required Color brandColor,
    required Color textCol,
    required Color subtitleCol,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _buildMonthChip(
            key: const ValueKey('attendance_logs_month_chip_current'),
            label: 'Bulan Ini',
            isSelected: !lastMonth,
            onTap: () {
              if (lastMonth) {
                context
                    .read<AttendanceLogsBloc>()
                    .add(const AttendanceLogsMonthToggled(false));
              }
            },
            brandColor: brandColor,
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
          ),
          const SizedBox(width: 8),
          _buildMonthChip(
            key: const ValueKey('attendance_logs_month_chip_last'),
            label: 'Bulan Lalu',
            isSelected: lastMonth,
            onTap: () {
              if (!lastMonth) {
                context
                    .read<AttendanceLogsBloc>()
                    .add(const AttendanceLogsMonthToggled(true));
              }
            },
            brandColor: brandColor,
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChip({
    Key? key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color brandColor,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
  }) {
    final bg = isSelected
        ? brandColor
        : (isDark
            ? AppColors.darkSurfaceContainer
            : const Color(0xFFF1F5F9));
    final fg = isSelected
        ? (isDark ? AppColors.darkOnPrimary : Colors.white)
        : subtitleCol;

    return Material(
      key: key,
      color: bg,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyAttendanceBody({
    required AttendanceLogsState state,
    required bool isDark,
    required Color brandColor,
    required Color textCol,
    required Color subtitleCol,
  }) {
    if (state.status == AttendanceLogsStatus.loading && state.logs.isEmpty) {
      return Center(
        child: AppLoadingIndicator(color: brandColor),
      );
    }

    if (state.status == AttendanceLogsStatus.failure && state.logs.isEmpty) {
      return _buildErrorState(
        message: state.errorMessage ??
            (state.isForbidden
                ? 'Tidak ada hak akses'
                : 'Gagal memuat riwayat absensi.'),
        isNotFound: state.isNotFound,
        isForbidden: state.isForbidden,
        isLastMonth: state.lastMonth,
        onSwitchToCurrentMonth: () => context.read<AttendanceLogsBloc>().add(
              const AttendanceLogsMonthToggled(false),
            ),
        onRetry: () => context.read<AttendanceLogsBloc>().add(
              const AttendanceLogsRefreshed(),
            ),
      );
    }

    if (state.logs.isEmpty) {
      final isFiltered = state.filterCriteria.hasActiveFilter;
      return RefreshIndicator(
        onRefresh: _handleMyRefresh,
        color: brandColor,
        child: AppEmptyState(
          icon: LucideIcons.history,
          title: isFiltered
              ? 'Tidak Ada Log Ditemukan'
              : (state.lastMonth
                  ? 'Belum Ada Riwayat Bulan Lalu'
                  : 'Belum Ada Riwayat Absensi'),
          message: isFiltered
              ? 'Tidak ada log absensi yang sesuai dengan kriteria filter yang dipilih.'
              : (state.lastMonth
                  ? 'Tidak ada riwayat clock-in & clock-out pada periode bulan lalu.'
                  : 'Riwayat clock-in & clock-out Anda akan tampil di sini.'),
          onResetFilter: isFiltered
              ? () => context.read<AttendanceLogsBloc>().add(
                    const AttendanceLogsFilterApplied(
                      AttendanceLogFilterCriteria(),
                    ),
                  )
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleMyRefresh,
      color: brandColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.logs.length + 1,
        itemBuilder: (context, index) {
          if (index < state.logs.length) {
            return AttendanceLogCard(log: state.logs[index]);
          }
          if (state.isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: AppLoadingIndicator.small(color: brandColor),
              ),
            );
          }
          if (state.hasMorePages) {
            return Center(
              child: AppButton(
                text: 'Muat Periode Sebelumnya',
                leadingIcon: LucideIcons.history,
                variant: AppButtonVariant.outlined,
                width: null,
                height: 44,
                onPressed: () => context.read<AttendanceLogsBloc>().add(
                  const AttendanceLogsLoadMore(),
                ),
              ),
            );
          }
          return const SizedBox(height: 8);
        },
      ),
    );
  }

  Widget _buildTeamAttendanceTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Column(
      children: [
        AppSearchBar(
          controller: _teamSearchController,
          hintText: 'Cari anggota tim...',
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          onChanged: _onTeamSearchChanged,
          onClear: () {
            _onTeamSearchChanged('');
            setState(() {});
          },
        ),
        Expanded(
          child: BlocBuilder<EmployeeListBloc, EmployeeListState>(
            builder: (context, state) {
              if (state.isLoading && state.employees.isEmpty) {
                return Center(
                  child: AppLoadingIndicator(color: brandColor),
                );
              }

              if (state.status == EmployeeListStatus.failure &&
                  state.employees.isEmpty) {
                return _buildErrorState(
                  message: state.errorMessage ??
                      (state.isForbidden
                          ? 'Tidak ada hak akses'
                          : 'Gagal memuat data tim absensi.'),
                  isNotFound: state.isNotFound,
                  isForbidden: state.isForbidden,
                  onBackToSelf: () => _tabController.animateTo(0),
                  onRetry: () => context.read<EmployeeListBloc>().add(
                    const EmployeeListRefreshed(isTeamAttendance: true),
                  ),
                );
              }

              if (state.employees.isEmpty) {
                final isFiltered = state.filterCriteria.hasActiveFilter ||
                    _teamSearchController.text.trim().isNotEmpty;
                return RefreshIndicator(
                  onRefresh: _handleTeamRefresh,
                  color: brandColor,
                  child: AppEmptyState(
                    icon: LucideIcons.usersRound,
                    title: 'Tidak Ada Anggota Tim Ditemukan',
                    message: 'Coba ubah kata kunci pencarian atau kriteria filter Anda.',
                    onResetFilter: isFiltered
                        ? () {
                            _teamSearchController.clear();
                            context.read<EmployeeListBloc>().add(
                                  const EmployeeListFilterApplied(
                                    EmployeeFilterCriteria(),
                                  ),
                                );
                          }
                        : null,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _handleTeamRefresh,
                color: brandColor,
                child: ListView.separated(
                  controller: _teamScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: state.employees.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= state.employees.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: AppLoadingIndicator.small(color: brandColor,),
                        ),
                      );
                    }
                    final employee = state.employees[index];
                    return EmployeeCard(
                      employee: employee,
                      actionLabel: 'Lihat Absensi',
                      onTap: () => context.push(
                        Routes.EMPLOYEE_ATTENDANCE_LOGS,
                        extra: employee,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState({
    required String message,
    required bool isNotFound,
    bool isForbidden = false,
    bool isLastMonth = false,
    VoidCallback? onSwitchToCurrentMonth,
    required VoidCallback onRetry,
    VoidCallback? onBackToSelf,
  }) {
    if (isForbidden) {
      // Standar global 403 (sama dengan halaman Aktivitas)
      return AppForbiddenState(
        message: message,
        onRetry: onRetry,
        actionText: onBackToSelf != null ? 'Log Saya' : null,
        onAction: onBackToSelf,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);

    final IconData iconData;
    final Color iconColor;
    final String errorTitle;

    if (isNotFound) {
      iconData = LucideIcons.calendarX;
      iconColor = AppColors.warning;
      if (isLastMonth) {
        errorTitle =
            l10n?.noPayrollPeriodTitle ?? 'Periode Penggajian Belum Ada';
      } else {
        errorTitle = 'Pemberitahuan Jadwal';
      }
    } else {
      iconData = LucideIcons.alertTriangle;
      iconColor = AppColors.errorRed;
      errorTitle = 'Gagal Memuat Data';
    }

    final displayMessage = (isNotFound && isLastMonth && message.isEmpty)
        ? (l10n?.noPayrollPeriodLastMonthDesc ??
            'Belum ada data periode penggajian untuk bulan lalu.')
        : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: subtitleCol,
              ),
            ),
            const SizedBox(height: 20),
            if (isNotFound && isLastMonth && onSwitchToCurrentMonth != null) ...[
              AppButton(
                key: const ValueKey('attendance_logs_view_current_month_button'),
                text: l10n?.viewCurrentMonth ?? 'Lihat Bulan Ini',
                width: null,
                onPressed: onSwitchToCurrentMonth,
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const ValueKey('attendance_logs_back_button'),
                text: 'Kembali',
                variant: AppButtonVariant.ghost,
                width: null,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ] else if (isNotFound)
              AppButton(
                key: const ValueKey('attendance_logs_back_button'),
                text: 'Kembali',
                width: null,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            else
              AppButton(
                key: const ValueKey('attendance_logs_retry_button'),
                text: 'Coba Lagi',
                leadingIcon: LucideIcons.rotateCcw,
                width: null,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
