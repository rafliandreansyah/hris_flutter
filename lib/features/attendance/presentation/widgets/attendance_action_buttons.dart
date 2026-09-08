import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
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

  const AttendanceActionButtons({
    super.key,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.isOnBreak,
    this.isLoading = false,
    this.onClockPressed,
    this.onBreakPressed,
    this.onReportIssuePressed,
    this.hasWorkLocation = true,
    this.breakOutTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String primaryButtonText;
    final IconData primaryButtonIcon;
    final VoidCallback? primaryAction;

    if (!hasWorkLocation) {
      // Poin 4: Tidak punya lokasi kerja — disabled
      primaryButtonText = 'Lokasi Kerja Tidak Tersedia';
      primaryButtonIcon = LucideIcons.mapPinOff;
      primaryAction = null;
    } else if (!isClockedIn) {
      primaryButtonText = 'Clock In Now';
      primaryButtonIcon = LucideIcons.fingerprint;
      primaryAction = isLoading ? null : onClockPressed;
    } else if (!isClockedOut) {
      primaryButtonText = 'Clock Out Now';
      primaryButtonIcon = LucideIcons.logOut;
      primaryAction = isLoading ? null : onClockPressed;
    } else {
      primaryButtonText = 'Attendance Completed';
      primaryButtonIcon = LucideIcons.circleCheck;
      primaryAction = null;
    }

    // Poin 6: Conditional break button visibility
    // Tampil ketika: sudah clock in, belum clock out, dan (belum pernah break ATAU sedang break)
    final bool hasBreakStarted = breakOutTime != null &&
        breakOutTime!.isNotEmpty &&
        breakOutTime != '--:--';
    final bool showBreakButton = isClockedIn &&
        !isClockedOut &&
        (!hasBreakStarted || isOnBreak);

    final String breakButtonText = isOnBreak ? 'End Break' : 'Start Break';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Primary Clock Action Button (Clock In / Clock Out)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasWorkLocation
                  ? AppColors.brandTeal
                  : AppColors.surfaceVariant,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              disabledBackgroundColor: hasWorkLocation
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
                          fontSize: hasWorkLocation ? 16 : 14,
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
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    breakButtonText,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),

        // 3. Report Location Issue Link
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: const StadiumBorder(),
          ),
          onPressed: onReportIssuePressed,
          child: Text(
            'Report Location Issue',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
