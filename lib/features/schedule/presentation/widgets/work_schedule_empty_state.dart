import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget Empty State berstandar Stitch M3 "Teal Oasis" untuk jadwal kerja yang belum tersedia.
class WorkScheduleEmptyState extends StatelessWidget {
  final bool isViewingOtherEmployee;
  final VoidCallback? onBack;
  final VoidCallback? onSelectOtherEmployee;
  final VoidCallback? onRefresh;

  const WorkScheduleEmptyState({
    super.key,
    this.isViewingOtherEmployee = false,
    this.onBack,
    this.onSelectOtherEmployee,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final accentTeal =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final infoBg =
        isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLow;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final descriptionText = isViewingOtherEmployee
        ? 'Pegawai ini belum memiliki jadwal shift kerja aktif yang ditugaskan oleh pihak manajemen atau HR.'
        : 'Anda belum memiliki jadwal kerja aktif yang ditugaskan. Silakan hubungi atasan atau tim HR untuk pengaturan shift kerja Anda.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon Badge dengan Glow Halus Teal Oasis
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentTeal.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.calendarClock,
                      size: 28,
                      color: accentTeal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Heading Title
            Text(
              'Belum Ada Jadwal Kerja',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: textCol,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // 3. Contextual Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                descriptionText,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: subtitleCol,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Info Card / Guidance Banner
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: infoBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderCol, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.info,
                        size: 16,
                        color: accentTeal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Jadwal kerja dapat diatur oleh Admin melalui menu Work Schedule di Dashboard Web HRIS.',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 5. Action Buttons (Zero Retry Loop)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  if (isViewingOtherEmployee) ...[
                    AppButton(
                      text: 'Pilih Pegawai Lain',
                      leadingIcon: LucideIcons.users,
                      variant: AppButtonVariant.primary,
                      height: 48,
                      onPressed: onSelectOtherEmployee ??
                          () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      text: 'Kembali',
                      leadingIcon: LucideIcons.arrowLeft,
                      variant: AppButtonVariant.outlined,
                      height: 48,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                    ),
                  ] else ...[
                    AppButton(
                      text: 'Kembali ke Beranda',
                      leadingIcon: LucideIcons.arrowLeft,
                      variant: AppButtonVariant.primary,
                      height: 48,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                    ),
                  ],
                  if (onRefresh != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: Icon(
                        LucideIcons.refreshCw,
                        size: 14,
                        color: accentTeal,
                      ),
                      label: Text(
                        'Segarkan Data',
                        style: AppTypography.labelSmall.copyWith(
                          color: accentTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
