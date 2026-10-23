import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum StatusTone { success, info, warning, error }

enum StatusStepState { done, pending, failed }

class StatusStep {
  final String label;
  final StatusStepState status;
  const StatusStep(this.label, this.status);
}

class StatusBannerSpec {
  final StatusTone tone;
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final List<StatusStep> steps;

  const StatusBannerSpec({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.steps = const [],
  });
}

/// Kartu status + checklist langkah yang dipakai banner presensi (reguler & live).
class StatusBannerCard extends StatelessWidget {
  final StatusBannerSpec spec;

  /// Tombol aksi menampilkan loading dan nonaktif saat true.
  final bool isBusy;
  final VoidCallback? onAction;

  const StatusBannerCard({
    super.key,
    required this.spec,
    this.isBusy = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color accent = switch (spec.tone) {
      StatusTone.success => AppColors.success,
      StatusTone.info => AppColors.brandTeal,
      StatusTone.warning => AppColors.warning,
      StatusTone.error => AppColors.errorRed,
    };
    final Color bg = switch (spec.tone) {
      StatusTone.success => AppColors.successContainer,
      StatusTone.info => AppColors.primaryContainer,
      StatusTone.warning => AppColors.warningContainer,
      StatusTone.error => AppColors.errorContainer,
    };
    final onBg = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onBgVariant = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      key: const ValueKey('attendance_status_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerHighest
            : bg.withValues(alpha: 0.55),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onBg,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      spec.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: onBgVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (spec.steps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final step in spec.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      switch (step.status) {
                        StatusStepState.done => LucideIcons.circleCheck,
                        StatusStepState.failed => LucideIcons.circleX,
                        StatusStepState.pending => LucideIcons.circleDashed,
                      },
                      size: 16,
                      color: switch (step.status) {
                        StatusStepState.done => AppColors.success,
                        StatusStepState.failed => AppColors.errorRed,
                        StatusStepState.pending => onBgVariant,
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        step.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: onBg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (spec.actionText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const ValueKey('attendance_status_banner_action'),
              text: spec.actionText!,
              variant: AppButtonVariant.outlined,
              leadingIcon: LucideIcons.refreshCw,
              height: 44,
              isLoading: isBusy,
              onPressed: isBusy ? null : onAction,
            ),
          ],
        ],
      ),
    );
  }
}
