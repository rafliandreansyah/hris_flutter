import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/attendance_status_resolver.dart';
import 'package:hris_flutter/features/attendance/presentation/widgets/status_banner_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Status satu baris di panel bawah: menjawab "bisa absen sekarang? kalau tidak,
/// kenapa dan harus apa?" tanpa checklist panjang.
class AttendanceStatusStrip extends StatelessWidget {
  final AttendanceLoaded state;
  final bool isBusy;
  final VoidCallback? onAction;

  const AttendanceStatusStrip({
    super.key,
    required this.state,
    this.isBusy = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = AttendanceStatusResolver.resolve(state);
    final Color accent = switch (spec.tone) {
      StatusTone.success => AppColors.success,
      StatusTone.info => AppColors.brandTeal,
      StatusTone.warning => AppColors.warning,
      StatusTone.error => AppColors.errorRed,
    };
    final onBg = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final onBgVariant = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      key: const ValueKey('attendance_status_strip'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(spec.icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
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
                const SizedBox(height: 2),
                Text(
                  spec.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: onBgVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (spec.actionText != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              key: const ValueKey('attendance_status_strip_action'),
              onPressed: isBusy ? null : onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accent,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.refreshCw, size: 16),
                        const SizedBox(height: 2),
                        Text(
                          spec.actionText!,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
