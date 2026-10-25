import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_detail/attendance_detail_bloc.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_detail_hero_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_map_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_proof_card.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_request_info_card.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final String attendanceId;
  final AttendanceDetailBloc? bloc;

  const AttendanceDetailScreen({
    super.key,
    required this.attendanceId,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<AttendanceDetailBloc>.value(
        value: bloc!,
        child: _AttendanceDetailView(attendanceId: attendanceId),
      );
    }

    return BlocProvider<AttendanceDetailBloc>(
      create: (context) =>
          AttendanceDetailBloc()..add(AttendanceDetailStarted(attendanceId)),
      child: _AttendanceDetailView(attendanceId: attendanceId),
    );
  }
}

class _AttendanceDetailView extends StatelessWidget {
  final String attendanceId;

  const _AttendanceDetailView({required this.attendanceId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark ? AppColors.darkBackground : AppColors.background;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurfaceContainerLowest
            : Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n?.attendanceDetailTitle ?? 'Detail Presensi',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: textCol,
            fontSize: 16,
          ),
        ),
      ),
      body: BlocBuilder<AttendanceDetailBloc, AttendanceDetailState>(
        builder: (context, state) {
          // 1. Loading State
          if (state.status == AttendanceDetailStatus.loading ||
              state.status == AttendanceDetailStatus.initial) {
            return const Center(child: AppLoadingIndicator());
          }

          // 2. Error States
          if (state.status == AttendanceDetailStatus.failure) {
            return _buildErrorView(
              context: context,
              state: state,
              isDark: isDark,
              textCol: textCol,
              subtitleCol: subtitleCol,
              l10n: l10n,
            );
          }

          // 3. Success State
          final detail = state.detail;
          if (detail == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            color: AppColors.brandTeal,
            onRefresh: () async {
              context.read<AttendanceDetailBloc>().add(
                AttendanceDetailRefreshed(attendanceId),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Hero Verification Card
                  AttendanceDetailHeroCard(detail: detail),

                  const SizedBox(height: 16),

                  // Section 2: Interactive GPS Map Card
                  AttendanceMapCard(detail: detail),

                  // Section 3: Outside Attendance Card (Conditional)
                  if (detail.hasAttendanceRequest) ...[
                    const SizedBox(height: 16),
                    AttendanceRequestInfoCard(detail: detail),
                  ],

                  const SizedBox(height: 16),

                  // Section 4: Employee Profile Card
                  _buildEmployeeProfileCard(detail: detail, l10n: l10n),

                  const SizedBox(height: 16),

                  // Section 5: Shift & Attendance Method Bento Grid
                  _buildShiftMethodBento(
                    detail: detail,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    subtitleCol: subtitleCol,
                    l10n: l10n,
                  ),

                  // Section 6: Proof Attachment Photo Card (Conditional)
                  if (detail.isPhotoMethod) ...[
                    const SizedBox(height: 16),
                    AttendanceProofCard(detail: detail),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeProfileCard({
    required AttendanceDetailModel detail,
    required AppLocalizations? l10n,
  }) {
    final emp = detail.employee;
    final level = emp?.level?.trim() ?? '';
    return RequestDetailPersonCard(
      title: l10n?.employeeInfo ?? 'Informasi Karyawan',
      name: emp?.fullName.isNotEmpty == true ? emp!.fullName : 'Nama Pegawai',
      position: [
        if (emp?.position?.trim().isNotEmpty ?? false) emp!.position!.trim(),
        if (level.isNotEmpty) level,
      ].join(' • '),
      department: emp?.department,
      company: emp?.company,
      avatarUrl: emp?.photoUrl,
    );
  }

  Widget _buildShiftMethodBento({
    required AttendanceDetailModel detail,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required AppLocalizations? l10n,
  }) {
    final shiftName = detail.shift?.name ?? 'Regular Shift';
    final shiftTime = detail.shift?.timeRange ?? '-';
    final String method;
    if (detail.attendanceMethod.toLowerCase() == 'liveness') {
      method = 'Liveness AI';
    } else if (detail.attendanceMethod.isNotEmpty) {
      method = detail.attendanceMethod;
    } else {
      method = 'Biometric Check-In';
    }

    // Disusun vertikal dalam satu kartu agar lega dan teks tidak terpotong.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: LucideIcons.calendarClock,
            label: l10n?.shiftSchedule ?? 'Jadwal Shift',
            value: shiftName,
            caption: shiftTime,
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
          ),
          Divider(height: 1, thickness: 1, color: borderCol),
          _buildInfoTile(
            icon: LucideIcons.shieldCheck,
            label: l10n?.attendanceMethod ?? 'Metode Presensi',
            value: method,
            caption: 'Presensi Terverifikasi',
            isDark: isDark,
            textCol: textCol,
            subtitleCol: subtitleCol,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required String caption,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
  }) {
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderInput,
            ),
            child: Icon(icon, size: 18, color: brandColor),
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textCol,
                  ),
                ),
                if (caption.isNotEmpty && caption != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: subtitleCol,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView({
    required BuildContext context,
    required AttendanceDetailState state,
    required bool isDark,
    required Color textCol,
    required Color subtitleCol,
    required AppLocalizations? l10n,
  }) {
    final isNotFound = state.isNotFound;
    final isForbidden = state.isForbidden;

    final title = isNotFound
        ? (l10n?.attendanceDetailNotFound ?? 'Data presensi tidak ditemukan')
        : (isForbidden
              ? (l10n?.attendanceDetailNoAccess ?? 'Tidak ada hak akses')
              : (l10n?.error ?? 'Terjadi Kesalahan'));

    final message = state.errorMessage ?? title;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isNotFound
                    ? Colors.grey.withValues(alpha: 0.15)
                    : (isForbidden
                          ? Colors.orange.withValues(alpha: 0.15)
                          : AppColors.errorContainer),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isNotFound
                      ? LucideIcons.searchX
                      : (isForbidden
                            ? LucideIcons.shieldAlert
                            : LucideIcons.alertTriangle),
                  size: 30,
                  color: isNotFound
                      ? Colors.grey
                      : (isForbidden ? Colors.orange : AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons based on AGENTS.md:
            // 404 & 403: Only "Kembali" button, no retry!
            // 500 / other: "Coba Lagi" + "Kembali"
            if (!isNotFound && !isForbidden) ...[
              AppButton(
                text: l10n?.retry ?? 'Coba Lagi',
                leadingIcon: LucideIcons.refreshCw,
                width: 180,
                height: 44,
                onPressed: () {
                  context.read<AttendanceDetailBloc>().add(
                    AttendanceDetailRefreshed(attendanceId),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            AppButton(
              text: l10n?.back ?? 'Kembali',
              variant: AppButtonVariant.outlined,
              width: 180,
              height: 44,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
