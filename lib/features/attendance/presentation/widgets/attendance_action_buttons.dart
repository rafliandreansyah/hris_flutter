import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceActionButtons extends StatefulWidget {
  final bool isClockedIn;
  final bool isClockedOut;
  final bool isOnBreak;
  final bool isLoading;
  final VoidCallback? onClockPressed;
  final void Function(String method)? onClockWithMethodPressed;
  final ValueChanged<String>? onMethodChanged;
  final VoidCallback? onBreakPressed;
  final VoidCallback? onReportIssuePressed;

  /// Apakah user memiliki lokasi kerja yang ditentukan.
  final bool hasWorkLocation;

  /// Waktu break out (untuk menentukan apakah sudah pernah break).
  final String? breakOutTime;

  /// Metode awal (default: 'photo')
  final String initialMethod;

  const AttendanceActionButtons({
    super.key,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.isOnBreak,
    this.isLoading = false,
    this.onClockPressed,
    this.onClockWithMethodPressed,
    this.onMethodChanged,
    this.onBreakPressed,
    this.onReportIssuePressed,
    this.hasWorkLocation = true,
    this.breakOutTime,
    this.initialMethod = 'photo',
  });

  @override
  State<AttendanceActionButtons> createState() =>
      _AttendanceActionButtonsState();
}

class _AttendanceActionButtonsState extends State<AttendanceActionButtons> {
  late String _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  void _selectMethod(String method) {
    if (_selectedMethod == method) return;
    setState(() {
      _selectedMethod = method;
    });
    widget.onMethodChanged?.call(method);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String primaryButtonText;
    final IconData primaryButtonIcon;
    final VoidCallback? primaryAction;

    final isAttendanceCompleted = widget.isClockedIn && widget.isClockedOut;
    final isPhoto = _selectedMethod == 'photo';

    if (!widget.hasWorkLocation) {
      // Poin 4: Tidak punya lokasi kerja — disabled
      primaryButtonText = 'Lokasi Kerja Tidak Tersedia';
      primaryButtonIcon = LucideIcons.mapPinOff;
      primaryAction = null;
    } else if (!widget.isClockedIn) {
      primaryButtonText = isPhoto ? 'Clock In Now' : 'Clock In via Biometrik';
      primaryButtonIcon = isPhoto
          ? LucideIcons.camera
          : LucideIcons.fingerprint;
      primaryAction = widget.isLoading
          ? null
          : () {
              if (widget.onClockWithMethodPressed != null) {
                widget.onClockWithMethodPressed!(_selectedMethod);
              } else {
                widget.onClockPressed?.call();
              }
            };
    } else if (!widget.isClockedOut) {
      primaryButtonText = isPhoto ? 'Clock Out Now' : 'Clock Out via Biometrik';
      primaryButtonIcon = isPhoto
          ? LucideIcons.camera
          : LucideIcons.fingerprint;
      primaryAction = widget.isLoading
          ? null
          : () {
              if (widget.onClockWithMethodPressed != null) {
                widget.onClockWithMethodPressed!(_selectedMethod);
              } else {
                widget.onClockPressed?.call();
              }
            };
    } else {
      primaryButtonText = 'Attendance Completed';
      primaryButtonIcon = LucideIcons.circleCheck;
      primaryAction = null;
    }

    // Poin 6: Conditional break button visibility
    // Tampil ketika: sudah clock in, belum clock out, dan (belum pernah break ATAU sedang break)
    final bool hasBreakStarted =
        widget.breakOutTime != null &&
        widget.breakOutTime!.isNotEmpty &&
        widget.breakOutTime != '--:--';
    final bool showBreakButton =
        widget.isClockedIn &&
        !widget.isClockedOut &&
        (!hasBreakStarted || widget.isOnBreak);

    final String breakButtonText = widget.isOnBreak
        ? 'End Break'
        : 'Start Break';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 0. Selector Metode Presensi (Hanya tampil jika belum selesai presensi hari ini)
        if (widget.hasWorkLocation && !isAttendanceCompleted) ...[
          _buildMethodSelector(isDark),
          const SizedBox(height: AppSpacing.md),
        ],

        // 1. Primary Clock Action Button (Clock In / Clock Out)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.hasWorkLocation
                  ? AppColors.brandTeal
                  : AppColors.surfaceVariant,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              disabledBackgroundColor: widget.hasWorkLocation
                  ? AppColors.brandTeal.withValues(alpha: 0.5)
                  : (isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : const Color(0xFFE2E8F0)),
            ),
            onPressed: primaryAction,
            child: widget.isLoading
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
                          fontSize: widget.hasWorkLocation ? 16 : 14,
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
              onPressed: widget.isLoading ? null : widget.onBreakPressed,
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
      ],
    );
  }

  /// Segmented Button / Toggle untuk memilih metode Foto atau Biometrik
  Widget _buildMethodSelector(bool isDark) {
    final containerBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineMuted
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodTabItem(
              icon: LucideIcons.camera,
              label: 'Foto Selfie',
              isSelected: _selectedMethod == 'photo',
              onTap: widget.isLoading ? null : () => _selectMethod('photo'),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildMethodTabItem(
              icon: LucideIcons.fingerprint,
              label: 'Biometrik',
              isSelected: _selectedMethod == 'biometric',
              onTap: widget.isLoading ? null : () => _selectMethod('biometric'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    final textColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.input),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandTeal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
