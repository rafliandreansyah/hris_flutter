import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pro_dialog/pro_dialog.dart';

/// Dialog konfirmasi sukses presensi (Clock In / Clock Out) berbasis `pro_dialog`
/// sesuai spesifikasi Stitch M3 Teal Oasis.
///
/// Menggunakan animasi icon bounce dari [DialogType.success], custom content
/// untuk rincian data presensi (Tanggal, Waktu, Lokasi), dan tombol aksi terstandarisasi [AppButton].
/// Dialog ini persisten ([barrierDismissible: false] dan [PopScope(canPop: false)]),
/// sehingga tidak dapat ditutup secara tidak sengaja melalui ketukan di luar ataupun gestur back,
/// dan hanya bisa ditutup ketika pengguna menekan tombol OK.
class AttendanceSuccessDialog extends StatelessWidget {
  final AttendanceSuccessInfo successInfo;
  final VoidCallback? onOk;

  const AttendanceSuccessDialog({
    super.key,
    required this.successInfo,
    this.onOk,
  });

  /// Menampilkan [AttendanceSuccessDialog] menggunakan framework `pro_dialog` secara statis dan aman.
  static Future<void> show(
    BuildContext context, {
    required AttendanceSuccessInfo successInfo,
    required VoidCallback onOk,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return showProDialog<void>(
      context,
      type: DialogType.success,
      title: successInfo.title,
      description: successInfo.message,
      icon: LucideIcons.checkCheck,
      iconBackgroundColor: AppColors.brandTeal,
      barrierDismissible: false,
      showCloseButton: false,
      theme: ProDialogTheme(
        backgroundColor: surfaceColor,
        borderRadius: 24.0,
        maxWidth: 400.0,
        iconSize: 34.0,
        iconBackgroundSize: 68.0,
        elevation: 8.0,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        animationStyle: DialogAnimationStyle.bounce,
        iconAnimationStyle: IconAnimationStyle.bounce,
        titleStyle: AppTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: textCol,
          fontSize: 20,
          letterSpacing: -0.4,
        ),
        descriptionStyle: AppTypography.bodyMedium.copyWith(
          color: subtitleCol,
          fontSize: 13.5,
          height: 1.35,
        ),
        contentPadding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      ),
      customContent: PopScope(
        canPop: false,
        child: AttendanceSuccessDialog(
          successInfo: successInfo,
          onOk: onOk,
        ),
      ),
      buttons: [
        DialogButton(
          text: 'OK',
          isPrimary: true,
          onPressed: onOk,
          customWidget: AppButton(
            key: const ValueKey('attendance_success_dialog_ok_button'),
            text: 'OK',
            variant: AppButtonVariant.primary,
            height: 48,
            borderRadius: 14,
            onPressed: onOk,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: borderCol),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tanggal
          _buildInfoTile(
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
          _buildInfoTile(
            icon: LucideIcons.clock,
            label: 'Waktu Presensi',
            value: successInfo.formattedTime,
            textCol: textCol,
            subtitleCol: subtitleCol,
            valueColor: AppColors.brandTeal,
            isBoldValue: true,
            isTime: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: borderCol),
          ),
          // Lokasi Kerja
          _buildInfoTile(
            icon: LucideIcons.mapPin,
            label: 'Lokasi Kerja',
            value: successInfo.locationName,
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
    required Color textCol,
    required Color subtitleCol,
    Color? valueColor,
    bool isBoldValue = false,
    bool isTime = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brandTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.brandTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                softWrap: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: valueColor ?? textCol,
                  fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
                  fontSize: isTime ? 14.5 : 13,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
