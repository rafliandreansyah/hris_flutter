import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
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
        title: BlocBuilder<AttendanceDetailBloc, AttendanceDetailState>(
          builder: (context, state) {
            final dateText = state.detail?.formattedDate;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.attendanceDetailTitle ?? 'Detail Presensi',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textCol,
                    fontSize: 16,
                  ),
                ),
                if (dateText != null)
                  Text(
                    dateText,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontSize: 11,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<AttendanceDetailBloc, AttendanceDetailState>(
        builder: (context, state) {
          // 1. Loading State
          if (state.status == AttendanceDetailStatus.loading ||
              state.status == AttendanceDetailStatus.initial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.loading ?? 'Memproses...',
                    style: AppTypography.bodySmall.copyWith(color: subtitleCol),
                  ),
                ],
              ),
            );
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
                  _buildEmployeeProfileCard(
                    detail: detail,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderCol: borderCol,
                    textCol: textCol,
                    subtitleCol: subtitleCol,
                    l10n: l10n,
                  ),

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

                  const SizedBox(height: 24),

                  // Section 7: Bottom Action Button (Ajukan Koreksi Absensi)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Formulir koreksi absensi belum tersedia',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(
                        LucideIcons.fileEdit,
                        size: 18,
                        color: AppColors.brandTeal,
                      ),
                      label: Text(
                        l10n?.requestAttendanceCorrection ??
                            'Ajukan Koreksi Absensi',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandTeal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.brandTeal,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

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
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color subtitleCol,
    required AppLocalizations? l10n,
  }) {
    final emp = detail.employee;
    final fullName = emp?.fullName.isNotEmpty == true
        ? emp!.fullName
        : 'Nama Pegawai';

    final position = emp?.position ?? '-';
    final level = emp?.level != null && emp!.level!.isNotEmpty
        ? ' • ${emp.level}'
        : '';
    final dept = emp?.department ?? '-';
    final company = emp?.company ?? '-';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.employeeInfo ?? 'Informasi Karyawan',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppAvatar(
                imageUrl: emp?.photoUrl,
                name: fullName,
                size: 52,
                showBorder: true,
                borderColor: borderCol,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$position$level',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dept,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10.5,
                              color: subtitleCol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            company,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10.5,
                              color: subtitleCol,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final method = detail.attendanceMethod.isNotEmpty
        ? detail.attendanceMethod
        : 'Biometric Check-In';

    return Row(
      children: [
        // 1. Shift Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarClock,
                      size: 15,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n?.shiftSchedule ?? 'Jadwal Shift',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shiftName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  shiftTime,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: subtitleCol,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Attendance Method Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 15,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n?.attendanceMethod ?? 'Metode Presensi',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  method,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified Attendance',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: subtitleCol,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              SizedBox(
                width: 180,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<AttendanceDetailBloc>().add(
                      AttendanceDetailRefreshed(attendanceId),
                    );
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(l10n?.retry ?? 'Coba Lagi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: 180,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n?.back ?? 'Kembali'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
