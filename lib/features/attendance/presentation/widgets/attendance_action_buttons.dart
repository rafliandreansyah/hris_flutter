import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceActionButtons extends StatelessWidget {
  final bool isClockedIn;
  final bool isClockedOut;
  final bool isOnBreak;
  final bool isLoading;
  final VoidCallback? onClockPressed;
  final VoidCallback? onBreakPressed;
  final VoidCallback? onReportIssuePressed;

  /// Apakah user memiliki lokasi kerja yang ditentukan.
  final bool hasWorkLocation;

  /// Waktu break out (untuk menentukan apakah sudah pernah break).
  final String? breakOutTime;

  /// Metode presensi yang didapat dari server (e.g. 'photo', 'biometric').
  final String attendanceMethod;

  /// Callback presensi dengan parameter method ('photo' atau 'biometric').
  final ValueChanged<String>? onClockWithMethodPressed;

  const AttendanceActionButtons({
    super.key,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.isOnBreak,
    this.isLoading = false,
    this.onClockPressed,
    this.onClockWithMethodPressed,
    this.onBreakPressed,
    this.onReportIssuePressed,
    this.hasWorkLocation = true,
    this.breakOutTime,
    this.attendanceMethod = 'photo',
  });

  bool get _hasAttendanceMethod => attendanceMethod.trim().isNotEmpty;
  bool get _isBiometric =>
      attendanceMethod.toLowerCase().contains('biometric') ||
      attendanceMethod.toLowerCase().contains('finger');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isAttendanceCompleted = isClockedIn && isClockedOut;
    final isBiometric = _isBiometric;
    final hasMethod = _hasAttendanceMethod;

    final String primaryButtonText;
    final IconData primaryButtonIcon;
    final VoidCallback? primaryAction;

    final bool isActionDisabled = !hasWorkLocation || !hasMethod || isAttendanceCompleted;

    void defaultClockAction() {
      if (onClockWithMethodPressed != null) {
        onClockWithMethodPressed!(attendanceMethod);
      } else if (onClockPressed != null) {
        onClockPressed!();
      }
    }

    if (!hasWorkLocation) {
      primaryButtonText = 'Lokasi Kerja Tidak Tersedia';
      primaryButtonIcon = LucideIcons.mapPinOff;
      primaryAction = null;
    } else if (!hasMethod) {
      primaryButtonText = 'Metode Presensi Tidak Tersedia';
      primaryButtonIcon = LucideIcons.shieldAlert;
      primaryAction = null;
    } else if (!isClockedIn) {
      primaryButtonText = isBiometric ? 'Clock In via Biometrik' : 'Clock In Now';
      primaryButtonIcon = isBiometric
          ? LucideIcons.fingerprint
          : LucideIcons.camera;
      primaryAction = isLoading ? null : defaultClockAction;
    } else if (!isClockedOut) {
      primaryButtonText = isBiometric ? 'Clock Out via Biometrik' : 'Clock Out Now';
      primaryButtonIcon = isBiometric
          ? LucideIcons.fingerprint
          : LucideIcons.camera;
      primaryAction = isLoading ? null : defaultClockAction;
    } else {
      primaryButtonText = 'Attendance Completed';
      primaryButtonIcon = LucideIcons.circleCheck;
      primaryAction = null;
    }

    // Conditional break button visibility
    final bool hasBreakStarted =
        breakOutTime != null &&
        breakOutTime!.isNotEmpty &&
        breakOutTime != '--:--';
    final bool showBreakButton =
        isClockedIn &&
        !isClockedOut &&
        (!hasBreakStarted || isOnBreak);

    final String breakButtonText = isOnBreak
        ? 'End Break'
        : 'Start Break';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 0. Badge Informasi Metode Presensi (Otomatis dari Server, non-toggleable)
        if (hasWorkLocation && !isAttendanceCompleted && hasMethod) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineMuted
                      : AppColors.outlineMuted,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBiometric ? LucideIcons.fingerprint : LucideIcons.camera,
                    size: 14,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBiometric
                        ? 'Metode Presensi: Biometrik'
                        : 'Metode Presensi: Foto Selfie',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.onBackground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 1. Primary Clock Action Button (Clock In / Clock Out)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: !isActionDisabled
                  ? AppColors.brandTeal
                  : AppColors.surfaceVariant,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              disabledBackgroundColor: !isActionDisabled
                  ? AppColors.brandTeal.withValues(alpha: 0.5)
                  : (isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : const Color(0xFFE2E8F0)),
            ),
            onPressed: primaryAction,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(primaryButtonIcon, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        primaryButtonText,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: !isActionDisabled ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // 2. Secondary Break Button (Start Break / End Break) — conditional
        if (showBreakButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.accentTealLight,
                foregroundColor: AppColors.brandTeal,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: isLoading ? null : onBreakPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.coffee,
                    size: 20,
                    color: isDark
                        ? AppColors.inversePrimary
                        : AppColors.brandTeal,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    breakButtonText,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.inversePrimary
                          : AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // 3. Report Location Issue Button
        if (onReportIssuePressed != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onReportIssuePressed,
              icon: const Icon(LucideIcons.messageSquareWarning, size: 16),
              label: const Text(
                'Report Location Issue',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.surfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
