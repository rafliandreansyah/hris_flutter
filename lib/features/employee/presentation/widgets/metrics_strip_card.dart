import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Ringkasan Metrik (Overtime & Pengajuan Cuti)
class MetricsStripCard extends StatelessWidget {
  final String overtimeFormatted;
  final int overtimeTotalMinutes;
  final int leaveRequestCount;
  final String leaveRequestStatus;

  const MetricsStripCard({
    super.key,
    this.overtimeFormatted = '4 Jam 0 Menit',
    this.overtimeTotalMinutes = 240,
    this.leaveRequestCount = 3,
    this.leaveRequestStatus = 'Menunggu Approval',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final iconCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Row(
      children: [
        // 1. Overtime Metric
        Expanded(
          child: Container(
            height: 104,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.timer, size: 16, color: iconCol),
                    const SizedBox(width: 6),
                    Text(
                      'TOTAL OVERTIME',
                      style: AppTypography.labelSmall.copyWith(
                        color: iconCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overtimeFormatted,
                      style: AppTypography.titleSmall.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$overtimeTotalMinutes Total Menit',
                      style: AppTypography.labelSmall.copyWith(
                        color: labelCol,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Leave Request Metric
        Expanded(
          child: Container(
            height: 104,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendarClock, size: 16, color: iconCol),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'PENGAJUAN CUTI',
                        style: AppTypography.labelSmall.copyWith(
                          color: iconCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$leaveRequestCount Pengajuan',
                      style: AppTypography.titleSmall.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      leaveRequestStatus,
                      style: AppTypography.labelSmall.copyWith(
                        color: labelCol,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
