import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dialog konfirmasi sukses presensi (Clock In / Clock Out) sesuai spesifikasi Stitch M3 Teal Oasis.
///
/// Dialog ini persisten ([barrierDismissible: false] dan [PopScope(canPop: false)]),
/// sehingga tidak dapat ditutup secara tidak sengaja melalui ketukan di luar ataupun gestur back,
/// dan hanya bisa ditutup ketika pengguna menekan tombol OK.
class AttendanceSuccessDialog extends StatelessWidget {
  final AttendanceSuccessInfo successInfo;
  final VoidCallback onOk;

  const AttendanceSuccessDialog({
    super.key,
    required this.successInfo,
    required this.onOk,
  });

  /// Menampilkan [AttendanceSuccessDialog] secara statis dan aman.
  static Future<void> show(
    BuildContext context, {
    required AttendanceSuccessInfo successInfo,
    required VoidCallback onOk,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AttendanceSuccessDialog(
            successInfo: successInfo,
            onOk: onOk,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final cardBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Dialog(
      backgroundColor: surfaceColor,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Success Icon Badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandTeal.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.checkCheck,
                    color: AppColors.brandTeal,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Title & Message
              Text(
                successInfo.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textCol,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                successInfo.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: subtitleCol,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Info Details Card (Tanggal, Waktu, Lokasi Kerja)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    // Tanggal
                    _buildInfoRow(
                      icon: LucideIcons.calendar,
                      label: 'Tanggal',
                      value: successInfo.formattedDate,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: borderCol),
                    ),
                    // Waktu Presensi
                    _buildInfoRow(
                      icon: LucideIcons.clock,
                      label: 'Waktu Presensi',
                      value: successInfo.formattedTime,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                      valueColor: AppColors.brandTeal,
                      isBoldValue: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: borderCol),
                    ),
                    // Lokasi Kerja
                    _buildInfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Lokasi Kerja',
                      value: successInfo.locationName,
                      textCol: textCol,
                      subtitleCol: subtitleCol,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Action Button (OK)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const ValueKey('attendance_success_dialog_ok_button'),
                  onPressed: onOk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textCol,
    required Color subtitleCol,
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: subtitleCol,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: subtitleCol,
            fontSize: 12.5,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ?? textCol,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
