import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Card Preview Saldo Cuti Dashboard
class LeaveBalancePreviewCard extends StatelessWidget {
  final int annualLeaveRemaining;
  final int annualLeaveTotal;
  final int sickLeaveRemaining;
  final int sickLeaveTotal;
  final VoidCallback? onRequestTimeOff;

  const LeaveBalancePreviewCard({
    super.key,
    this.annualLeaveRemaining = 12,
    this.annualLeaveTotal = 14,
    this.sickLeaveRemaining = 10,
    this.sickLeaveTotal = 14,
    this.onRequestTimeOff,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final progressBg = isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh;

    final annualProgress = (annualLeaveRemaining / annualLeaveTotal).clamp(0.0, 1.0);
    final sickProgress = (sickLeaveRemaining / sickLeaveTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leave Balance',
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onRequestTimeOff ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Form Request Time Off segera dibuka')),
                      );
                    },
                child: Text(
                  'Request Time Off',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 Columns Progress
          Row(
            children: [
              // Annual Leave
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Annual',
                          style: AppTypography.bodySmall.copyWith(
                            color: labelCol,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$annualLeaveRemaining Days',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 7,
                        width: double.infinity,
                        color: progressBg,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: annualProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Sick Leave
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sick',
                          style: AppTypography.bodySmall.copyWith(
                            color: labelCol,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$sickLeaveRemaining Days',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 7,
                        width: double.infinity,
                        color: progressBg,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: sickProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
