import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Nada warna chip status. Dipakai bersama oleh semua fitur agar seragam.
enum AppStatusTone {
  success,
  warning,
  error,
  info,
  neutral;

  /// Memetakan teks status umum dari API/enum ke nada warna.
  static AppStatusTone fromStatus(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    const success = [
      'approved', 'disetujui', 'paid', 'dibayar', 'active', 'aktif',
      'completed', 'selesai', 'done', 'accepted', 'success',
    ];
    const warning = [
      'pending', 'requested', 'diajukan', 'draft', 'ongoing', 'berjalan',
      'processing', 'menunggu', 'waiting',
    ];
    const error = [
      'rejected', 'ditolak', 'cancelled', 'canceled', 'dibatalkan',
      'expired', 'failed', 'gagal',
    ];
    const info = ['planned', 'dijadwalkan', 'review', 'info'];
    if (success.contains(s)) return AppStatusTone.success;
    if (warning.contains(s)) return AppStatusTone.warning;
    if (error.contains(s)) return AppStatusTone.error;
    if (info.contains(s)) return AppStatusTone.info;
    return AppStatusTone.neutral;
  }
}

enum AppStatusChipSize { normal, small }

/// Chip status tunggal: selalu full rounded, dengan titik indikator opsional
/// atau ikon. Satu-satunya widget yang boleh dipakai untuk badge status.
class AppStatusChip extends StatelessWidget {
  final String label;
  final AppStatusTone tone;
  final IconData? icon;
  final bool showDot;
  final AppStatusChipSize size;

  const AppStatusChip({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
    this.showDot = true,
    this.size = AppStatusChipSize.normal,
  });

  /// Chip dari teks status API; nada dipetakan otomatis.
  factory AppStatusChip.fromStatus(
    String status, {
    Key? key,
    String? label,
    IconData? icon,
    bool showDot = true,
    AppStatusChipSize size = AppStatusChipSize.normal,
  }) => AppStatusChip(
    key: key,
    label: label ?? status,
    tone: AppStatusTone.fromStatus(status),
    icon: icon,
    showDot: showDot,
    size: size,
  );

  (Color bg, Color fg, Color dot) _colors(bool isDark) {
    switch (tone) {
      case AppStatusTone.success:
        return isDark
            ? (
                AppColors.success.withValues(alpha: 0.18),
                const Color(0xFF6EE7B7),
                AppColors.success,
              )
            : (
                AppColors.successContainer,
                AppColors.onSuccessContainer,
                AppColors.success,
              );
      case AppStatusTone.warning:
        return isDark
            ? (
                AppColors.warning.withValues(alpha: 0.18),
                const Color(0xFFFCD34D),
                AppColors.warning,
              )
            : (
                AppColors.warningContainer,
                AppColors.onWarningContainer,
                AppColors.warning,
              );
      case AppStatusTone.error:
        return isDark
            ? (
                AppColors.errorRed.withValues(alpha: 0.18),
                const Color(0xFFFCA5A5),
                AppColors.errorRed,
              )
            : (
                AppColors.errorContainer,
                AppColors.onErrorContainer,
                AppColors.errorRed,
              );
      case AppStatusTone.info:
        return isDark
            ? (
                AppColors.brandTeal.withValues(alpha: 0.18),
                AppColors.inversePrimary,
                AppColors.brandTeal,
              )
            : (
                AppColors.primaryContainer,
                AppColors.onPrimaryContainer,
                AppColors.brandTeal,
              );
      case AppStatusTone.neutral:
        return isDark
            ? (
                AppColors.darkSurfaceContainerHigh,
                AppColors.darkOnSurfaceVariant,
                AppColors.darkOnSurfaceVariant,
              )
            : (
                AppColors.surfaceContainerHigh,
                AppColors.onSurfaceVariant,
                AppColors.surfaceVariant,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, dot) = _colors(isDark);
    final small = size == AppStatusChipSize.small;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xs,
        vertical: small ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.borderFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 11 : 13, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: fg,
                fontSize: small ? 10 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
