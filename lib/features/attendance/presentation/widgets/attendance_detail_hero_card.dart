import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceDetailHeroCard extends StatelessWidget {
  final AttendanceDetailModel detail;

  const AttendanceDetailHeroCard({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    final isClockIn = detail.isClockIn;
    final typeText = isClockIn
        ? (l10n?.clockIn ?? 'Clock In')
        : (l10n?.clockOut ?? 'Clock Out');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Badges Row: Type Badge + Punctuality Badge + (Optional Outside Attendance Badge)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type Badge (Clock In / Clock Out)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isClockIn
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : AppColors.primaryContainer)
                      : (isDark
                          ? AppColors.warning.withValues(alpha: 0.25)
                          : AppColors.warningContainer),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClockIn ? LucideIcons.logIn : LucideIcons.logOut,
                      size: 13,
                      color: isClockIn
                          ? (isDark ? AppColors.inversePrimary : AppColors.primary)
                          : (isDark ? AppColors.warning : AppColors.onWarningContainer),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      typeText,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isClockIn
                            ? (isDark ? AppColors.inversePrimary : AppColors.primary)
                            : (isDark ? AppColors.warning : AppColors.onWarningContainer),
                      ),
                    ),
                  ],
                ),
              ),

              // Punctuality Badge (On Time / Late by X mins)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: detail.isLate
                      ? (isDark
                          ? AppColors.errorRed.withValues(alpha: 0.2)
                          : AppColors.errorContainer)
                      : (isDark
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.successContainer),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      detail.isLate ? LucideIcons.clockAlert : LucideIcons.checkCircle2,
                      size: 13,
                      color: detail.isLate
                          ? (isDark ? const Color(0xFFFCA5A5) : AppColors.onErrorContainer)
                          : (isDark ? const Color(0xFF86EFAC) : AppColors.onSuccessContainer),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      detail.isLate
                          ? (l10n?.lateByMinutes(detail.lateInMinutes) ??
                              'Late by ${detail.lateInMinutes} mins')
                          : (l10n?.onTime ?? 'On Time'),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: detail.isLate
                            ? (isDark ? const Color(0xFFFCA5A5) : AppColors.onErrorContainer)
                            : (isDark ? const Color(0xFF86EFAC) : AppColors.onSuccessContainer),
                      ),
                    ),
                  ],
                ),
              ),

              // Outside Attendance Chip (If requested via outside attendance)
              if (detail.hasAttendanceRequest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B280E)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF92400E).withValues(alpha: 0.5)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.briefcase,
                        size: 13,
                        color: isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF92400E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n?.outsideAttendanceTitle ?? 'Outside Attendance',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Large 24-Hour Time & Timezone Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                detail.formattedTime24,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: textCol,
                ),
              ),
              if (detail.timezone != null && detail.timezone!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    detail.timezone!,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: subtitleCol,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // 3. Biometric & Geofence Verification Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.brandTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: isDark ? AppColors.inversePrimary : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.verifiedIdentityNotice ??
                        'Identitas terverifikasi dengan biometrik dan geofence GPS',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.inversePrimary
                          : AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
