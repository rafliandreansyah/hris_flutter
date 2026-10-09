import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PayrollAttendanceRecapCard extends StatelessWidget {
  final PayrollAttendanceRecapModel attendance;

  const PayrollAttendanceRecapCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.userCheck,
                  size: 16,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rekapitulasi Kehadiran',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Hari Kerja',
                  value: '${attendance.workingDays}',
                  icon: LucideIcons.calendarDays,
                  iconColor: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Hadir',
                  value: '${attendance.presentDays}',
                  icon: LucideIcons.checkCircle2,
                  iconColor: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Absen',
                  value: '${attendance.absentDays}',
                  icon: LucideIcons.alertCircle,
                  iconColor: AppColors.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Terlambat',
                  value: '${attendance.lateMinutes} mnt',
                  icon: LucideIcons.timer,
                  iconColor: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  label: 'Lembur',
                  value: '${attendance.overtimeHours.toStringAsFixed(1)} jam',
                  icon: LucideIcons.clockAlert,
                  iconColor: AppColors.brandTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerHigh
            : AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
