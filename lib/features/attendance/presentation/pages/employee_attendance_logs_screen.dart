import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_logs/attendance_logs_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_log_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_filter_bottom_sheet.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_logs_summary_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/employee_attendance_header_card.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Halaman riwayat absensi untuk pegawai tertentu yang dipilih dari Team Attendance.
class EmployeeAttendanceLogsScreen extends StatelessWidget {
  final EmployeeDirectoryItem employee;
  final AttendanceRepository? attendanceRepository;
  final AttendanceLogsBloc? attendanceLogsBloc;

  const EmployeeAttendanceLogsScreen({
    super.key,
    required this.employee,
    this.attendanceRepository,
    this.attendanceLogsBloc,
  });

  String get _targetEmployeeId => employee.rawId ?? employee.id;

  @override
  Widget build(BuildContext context) {
    if (attendanceLogsBloc != null) {
      return BlocProvider<AttendanceLogsBloc>.value(
        value: attendanceLogsBloc!,
        child: _EmployeeAttendanceLogsView(employee: employee),
      );
    }

    return BlocProvider<AttendanceLogsBloc>(
      create: (context) => AttendanceLogsBloc(
        repository: attendanceRepository,
        employeeId: _targetEmployeeId,
      )..add(AttendanceLogsStarted(employeeId: _targetEmployeeId)),
      child: _EmployeeAttendanceLogsView(employee: employee),
    );
  }
}

class _EmployeeAttendanceLogsView extends StatefulWidget {
  final EmployeeDirectoryItem employee;

  const _EmployeeAttendanceLogsView({
    required this.employee,
  });

  @override
  State<_EmployeeAttendanceLogsView> createState() =>
      _EmployeeAttendanceLogsViewState();
}

class _EmployeeAttendanceLogsViewState
    extends State<_EmployeeAttendanceLogsView> {
  String get _targetEmployeeId =>
      widget.employee.rawId ?? widget.employee.id;

  Future<void> _handleRefresh() async {
    context.read<AttendanceLogsBloc>().add(
          AttendanceLogsRefreshed(employeeId: _targetEmployeeId),
        );
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _openFilterBottomSheet() async {
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
              'Absensi Pegawai',
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
              widget.employee.name,
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          BlocBuilder<AttendanceLogsBloc, AttendanceLogsState>(
            builder: (context, state) {
              final hasActiveFilter = state.filterCriteria.hasActiveFilter;
              return IconButton(
                key: const ValueKey('employee_attendance_filter_button'),
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
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<AttendanceLogsBloc, AttendanceLogsState>(
          listener: (context, state) {
            if (state.status == AttendanceLogsStatus.failure &&
                state.logs.isNotEmpty &&
                state.errorMessage != null) {
              final l10n = AppLocalizations.of(context);
              if (state.isNotFound && state.lastMonth) {
                AppDialogUtil.showError(
                  context,
                  title: l10n?.noPayrollPeriodTitle ??
                      'Periode Penggajian Belum Ada',
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
                // Header Card Pegawai
                EmployeeAttendanceHeaderCard(employee: widget.employee),

                // Month Selector
                _buildMonthSelector(
                  lastMonth: state.lastMonth,
                  isDark: isDark,
                  brandColor: brandColor,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                ),

                // Attendance Logs Body
                Expanded(
                  child: _buildAttendanceBody(
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
        ),
      ),
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
            key: const ValueKey('employee_attendance_month_chip_current'),
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
            key: const ValueKey('employee_attendance_month_chip_last'),
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

  Widget _buildAttendanceBody({
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
              AttendanceLogsRefreshed(employeeId: _targetEmployeeId),
            ),
      );
    }

    if (state.logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
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
                            ? 'Tidak ada riwayat clock-in & clock-out pada periode bulan lalu untuk ${widget.employee.name}.'
                            : 'Riwayat clock-in & clock-out ${widget.employee.name} akan tampil di sini.'),
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
      onRefresh: _handleRefresh,
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

  Widget _buildErrorState({
    required String message,
    required bool isNotFound,
    bool isForbidden = false,
    bool isLastMonth = false,
    VoidCallback? onSwitchToCurrentMonth,
    required VoidCallback onRetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final l10n = AppLocalizations.of(context);

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
              ElevatedButton(
                key: const ValueKey(
                  'employee_attendance_view_current_month_button',
                ),
                onPressed: onSwitchToCurrentMonth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor:
                      isDark ? const Color(0xFF003732) : Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  l10n?.viewCurrentMonth ?? 'Lihat Bulan Ini',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const ValueKey('employee_attendance_back_button'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ] else if (isNotFound || isForbidden)
              ElevatedButton(
                key: const ValueKey('employee_attendance_back_button'),
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
                key: const ValueKey('employee_attendance_retry_button'),
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
