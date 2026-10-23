import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tombol aksi presensi yang menempel di bawah layar (sticky bottom bar).
class AttendanceActionButtons extends StatelessWidget {
  final bool isClockedIn;
  final bool isClockedOut;
  final bool isOnBreak;
  final bool isLoading;
  final VoidCallback? onClockPressed;
  final VoidCallback? onBreakPressed;

  /// Apakah user memiliki lokasi kerja yang ditentukan.
  final bool hasWorkLocation;

  /// Metode presensi yang didapat dari server (e.g. 'photo', 'biometric').
  final String attendanceMethod;

  const AttendanceActionButtons({
    super.key,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.isOnBreak,
    this.isLoading = false,
    this.onClockPressed,
    this.onBreakPressed,
    this.hasWorkLocation = true,
    this.attendanceMethod = 'photo',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final method = attendanceMethod.toLowerCase();
    final hasMethod = attendanceMethod.trim().isNotEmpty;
    final isLiveness = method.contains('liveness');
    final isBiometric =
        method.contains('biometric') || method.contains('finger');
    final isCompleted = isClockedIn && isClockedOut;

    final IconData methodIcon = isLiveness
        ? LucideIcons.scanFace
        : isBiometric
        ? LucideIcons.fingerprint
        : LucideIcons.camera;
    final String methodLabel = isLiveness
        ? 'Verifikasi: Liveness AI'
        : isBiometric
        ? 'Verifikasi: Sidik Jari / Face ID'
        : 'Verifikasi: Foto Selfie';

    final String text;
    final IconData icon;
    VoidCallback? onPressed;
    if (!hasWorkLocation) {
      text = 'Lokasi Kerja Belum Diatur';
      icon = LucideIcons.mapPinOff;
    } else if (!hasMethod) {
      text = 'Metode Presensi Belum Diatur';
      icon = LucideIcons.shieldAlert;
    } else if (isCompleted) {
      text = 'Presensi Selesai';
      icon = LucideIcons.circleCheck;
    } else {
      text = isClockedIn ? 'Absen Pulang' : 'Absen Masuk';
      icon = methodIcon;
      onPressed = isLoading ? null : onClockPressed;
    }

    final showBreak = isClockedIn && !isClockedOut;
    final showHint = !showBreak && (onPressed != null || isLoading);
    final subtle = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHint) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(methodIcon, size: 14, color: subtle),
              const SizedBox(width: AppSpacing.xs),
              Text(
                methodLabel,
                style: AppTypography.labelSmall.copyWith(color: subtle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton(
          key: const ValueKey('attendance_clock_button'),
          text: text,
          leadingIcon: icon,
          height: 56,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
        if (showBreak) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('attendance_break_button'),
            text: isOnBreak ? 'Selesai Istirahat' : 'Mulai Istirahat',
            leadingIcon: LucideIcons.coffee,
            variant: AppButtonVariant.outlined,
            height: 48,
            onPressed: isLoading ? null : onBreakPressed,
          ),
        ],
      ],
    );
  }
}
