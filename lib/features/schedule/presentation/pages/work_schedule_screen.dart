import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:hris_flutter/features/schedule/domain/repositories/work_schedule_repository.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_bloc.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_event.dart';
import 'package:hris_flutter/features/schedule/presentation/bloc/work_schedule/work_schedule_state.dart';
import 'package:hris_flutter/features/schedule/presentation/widgets/employee_work_schedule_header_card.dart';
import 'package:hris_flutter/features/schedule/presentation/widgets/selected_schedule_card.dart';
import 'package:hris_flutter/features/schedule/presentation/widgets/upcoming_schedule_card.dart';
import 'package:hris_flutter/features/schedule/presentation/widgets/work_schedule_shimmer.dart';
import 'package:hris_flutter/features/schedule/presentation/widgets/work_schedule_timeline.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkScheduleScreen extends StatelessWidget {
  final String? employeeId;
  final WorkScheduleEmployee? employeePreview;
  final WorkScheduleRepository? repository;
  final WorkScheduleBloc? bloc;

  const WorkScheduleScreen({
    super.key,
    this.employeeId,
    this.employeePreview,
    this.repository,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<WorkScheduleBloc>.value(
        value: bloc!,
        child: _WorkScheduleView(
          employeeId: employeeId,
          employeePreview: employeePreview,
        ),
      );
    }

    return BlocProvider<WorkScheduleBloc>(
      create: (context) => WorkScheduleBloc(repository: repository)
        ..add(WorkScheduleFetchRequested(employeeId: employeeId)),
      child: _WorkScheduleView(
        employeeId: employeeId,
        employeePreview: employeePreview,
      ),
    );
  }
}

class _WorkScheduleView extends StatelessWidget {
  final String? employeeId;
  final WorkScheduleEmployee? employeePreview;

  const _WorkScheduleView({
    this.employeeId,
    this.employeePreview,
  });

  bool get _isViewingOtherEmployee =>
      employeeId != null && employeeId!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol =
        isDark ? AppColors.darkBackground : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    final screenTitle =
        _isViewingOtherEmployee ? 'Jadwal Kerja Pegawai' : 'Jadwal Kerja Saya';

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: surfaceColor,
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
        title: Text(
          screenTitle,
          style: AppTypography.titleMedium.copyWith(
            color: textCol,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Jadwal',
            icon: Icon(
              LucideIcons.refreshCw,
              size: 19,
              color: textCol,
            ),
            onPressed: () {
              context
                  .read<WorkScheduleBloc>()
                  .add(const WorkScheduleRefreshRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<WorkScheduleBloc, WorkScheduleState>(
        listener: (context, state) {
          if (state.status == WorkScheduleStatus.failure &&
              state.errorMessage != null &&
              state.data != null) {
            AppDialogUtil.showError(
              context,
              message: state.errorMessage!,
              onRetry: () => context.read<WorkScheduleBloc>().add(
                    WorkScheduleFetchRequested(employeeId: employeeId),
                  ),
            );
          }
        },
        builder: (context, state) {
          // 1. Loading Shimmer
          if (state.status == WorkScheduleStatus.loading &&
              state.data == null) {
            return WorkScheduleShimmer(
              showEmployeeHeader: _isViewingOtherEmployee,
            );
          }

          // 2. Full-page Error State
          if (state.status == WorkScheduleStatus.failure &&
              state.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        size: 36,
                        color: AppColors.errorRed,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Gagal Memuat Jadwal',
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.errorMessage ??
                          'Terjadi kesalahan saat memuat data jadwal kerja.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      text: 'Coba Lagi',
                      leadingIcon: LucideIcons.rotateCcw,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        context.read<WorkScheduleBloc>().add(
                              WorkScheduleFetchRequested(
                                employeeId: employeeId,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Normal / Success State
          final displayEmployee = state.data?.employee ?? employeePreview;
          final upcomingList = state.upcomingSchedules;

          return RefreshIndicator(
            color: AppColors.brandTeal,
            onRefresh: () async {
              context
                  .read<WorkScheduleBloc>()
                  .add(const WorkScheduleRefreshRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Identitas Pegawai jika sedang melihat jadwal rekan kerja
                  if (_isViewingOtherEmployee && displayEmployee != null) ...[
                    EmployeeWorkScheduleHeaderCard(employee: displayEmployee),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Timeline Tanggal Horizontal (EasyDateTimeLine)
                  WorkScheduleTimeline(
                    initialDate: state.selectedDate,
                    onDateChange: (date) {
                      context
                          .read<WorkScheduleBloc>()
                          .add(WorkScheduleDateSelected(date));
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Item Pertama: Jadwal Tanggal Terpilih (Hero Card)
                  SelectedScheduleCard(
                    selectedDate: state.selectedDate,
                    schedule: state.selectedSchedule,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Bagian Jadwal Mendatang (Upcoming Schedules)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jadwal Berikutnya',
                        style: AppTypography.titleSmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (upcomingList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.backgroundSubtle,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutlineMuted
                                  : AppColors.outlineMuted,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${upcomingList.length} Hari Terjadwal',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (upcomingList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineMuted
                              : AppColors.outlineMuted,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Tidak ada jadwal kerja mendatang setelah tanggal ini.',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingList.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final upcomingItem = upcomingList[index];
                        return UpcomingScheduleCard(
                          item: upcomingItem,
                          onTap: () {
                            if (upcomingItem.parsedDate != null) {
                              context.read<WorkScheduleBloc>().add(
                                    WorkScheduleDateSelected(
                                      upcomingItem.parsedDate!,
                                    ),
                                  );
                            }
                          },
                        );
                      },
                    ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
