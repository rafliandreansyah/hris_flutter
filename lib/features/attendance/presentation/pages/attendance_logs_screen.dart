import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_summary_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_team_member_card.dart';
import 'package:hris_flutter/features/employee/domain/repositories/employee_repository.dart';
import 'package:hris_flutter/features/employee/presentation/bloc/employee_list/employee_list_bloc.dart';
import 'package:hris_flutter/features/employee/presentation/widgets/employee_filter_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceLogsScreen extends StatelessWidget {
  final AttendanceRepository? attendanceRepository;
  final EmployeeRepository? employeeRepository;
  final AttendanceLogsBloc? attendanceLogsBloc;
  final EmployeeListBloc? employeeListBloc;
  final String? employeeId;

  const AttendanceLogsScreen({
    super.key,
    this.attendanceRepository,
    this.employeeRepository,
    this.attendanceLogsBloc,
    this.employeeListBloc,
    this.employeeId,
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
                create: (context) => EmployeeListBloc(
                  repository: employeeRepository,
                  attendanceRepository: attendanceRepository,
                  isTeamAttendance: true,
                )..add(const EmployeeListStarted(isTeamAttendance: true)),
              ),
      ],
      child: const _AttendanceLogsView(),
    );
  }
}

class _AttendanceLogsView extends StatefulWidget {
  const _AttendanceLogsView();

  @override
  State<_AttendanceLogsView> createState() => _AttendanceLogsViewState();
}

class _AttendanceLogsViewState extends State<_AttendanceLogsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
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
              'Attendance Logs',
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
              'Track clock-in & clock-out activity',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
              ),
            ),
          ],
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
                  tabs: const [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.user, size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'My Attendance',
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
                          Icon(LucideIcons.users, size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Team Attendance',
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
                  _buildTeamAttendanceTab(),
                ],
              ),
            ),
          ],
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
          AppDialogUtil.showError(
            context,
            title: 'Gagal',
            message: state.errorMessage!,
          );
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
        ? (isDark ? const Color(0xFF003732) : Colors.white)
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
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(brandColor),
        ),
      );
    }

    if (state.status == AttendanceLogsStatus.failure && state.logs.isEmpty) {
      return _buildErrorState(
        message: state.errorMessage ?? 'Gagal memuat riwayat absensi.',
        isNotFound: state.isNotFound,
        onRetry: () => context.read<AttendanceLogsBloc>().add(
          const AttendanceLogsRefreshed(),
        ),
      );
    }

    if (state.logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleMyRefresh,
        color: brandColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 48,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.calendarX,
                      color: brandColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.filterCriteria.hasActiveFilter
                        ? 'Tidak Ada Log Ditemukan'
                        : (state.lastMonth
                            ? 'Belum Ada Riwayat Bulan Lalu'
                            : 'Belum Ada Riwayat Absensi'),
                    style: AppTypography.titleMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.filterCriteria.hasActiveFilter
                        ? 'Tidak ada log absensi yang sesuai dengan kriteria filter yang dipilih.'
                        : (state.lastMonth
                            ? 'Tidak ada riwayat clock-in & clock-out pada periode bulan lalu.'
                            : 'Riwayat clock-in & clock-out Anda akan tampil di sini.'),
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleMyRefresh,
      color: brandColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.logs.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (state.summary == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AttendanceLogsSummaryCard(summary: state.summary!),
            );
          }
          if (index <= state.logs.length) {
            return AttendanceLogCard(log: state.logs[index - 1]);
          }
          if (state.isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                ),
              ),
            );
          }
          if (state.hasMorePages) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: () => context.read<AttendanceLogsBloc>().add(
                  const AttendanceLogsLoadMore(),
                ),
                icon: Icon(LucideIcons.history, size: 18),
                label: const Text('Load Previous Period'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  side: BorderSide(color: brandColor),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceCol,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _teamSearchController,
              style: AppTypography.bodyMedium.copyWith(
                color: textCol,
                fontSize: 14,
              ),
              onChanged: _onTeamSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search team member...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: subtitleCol,
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: subtitleCol,
                ),
                suffixIcon: _teamSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: subtitleCol,
                        ),
                        onPressed: () {
                          _teamSearchController.clear();
                          _onTeamSearchChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<EmployeeListBloc, EmployeeListState>(
            builder: (context, state) {
              if (state.isLoading && state.employees.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                  ),
                );
              }

              if (state.status == EmployeeListStatus.failure &&
                  state.employees.isEmpty) {
                return _buildErrorState(
                  message: state.errorMessage ??
                      (state.isForbidden
                          ? 'Tidak ada hak akses'
                          : 'Gagal memuat data tim absensi.'),
                  isNotFound: false,
                  isForbidden: state.isForbidden,
                  onRetry: () => context.read<EmployeeListBloc>().add(
                    const EmployeeListRefreshed(isTeamAttendance: true),
                  ),
                );
              }

              if (state.employees.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _handleTeamRefresh,
                  color: brandColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.users,
                                color: brandColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak Ada Anggota Tim Ditemukan',
                              style: AppTypography.titleMedium.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Coba ubah kata kunci pencarian atau kriteria filter Anda.',
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                brandColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final employee = state.employees[index];
                    return AttendanceTeamMemberCard(
                      employee: employee,
                      onTap: () =>
                          context.push(Routes.EMPLOYEE_DETAIL, extra: employee),
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
    required VoidCallback onRetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final IconData iconData;
    final Color iconColor;
    final String errorTitle;

    if (isForbidden) {
      iconData = LucideIcons.shieldAlert;
      iconColor = AppColors.errorRed;
      errorTitle = 'Tidak Ada Hak Akses';
    } else if (isNotFound) {
      iconData = LucideIcons.calendarX;
      iconColor = AppColors.warning;
      errorTitle = 'Pemberitahuan Jadwal';
    } else {
      iconData = LucideIcons.alertTriangle;
      iconColor = AppColors.errorRed;
      errorTitle = 'Gagal Memuat Data';
    }

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
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: subtitleCol,
              ),
            ),
            const SizedBox(height: 20),
            if (isNotFound || isForbidden)
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor:
                      isDark ? const Color(0xFF003732) : Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text('Kembali'),
              )
            else
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor:
                      isDark ? const Color(0xFF003732) : Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text('Coba Lagi'),
              ),
          ],
        ),
      ),
    );
  }
}
