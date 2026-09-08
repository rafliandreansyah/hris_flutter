import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_api_models.dart';

class AttendanceLogsSummaryCard extends StatelessWidget {
  final AttendanceLogSummary summary;

  const AttendanceLogsSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final lateValueCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final totalInBg = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.accentTealLight;
    final lateInBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainer;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;

    final presentPercent = summary.presentPercentage % 1 == 0
        ? summary.presentPercentage.toStringAsFixed(0)
        : summary.presentPercentage.toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            label: 'TOTAL IN',
            value: '${summary.totalInDays} Days',
            caption: '$presentPercent% Present',
            background: totalInBg,
            borderColor: brandColor.withValues(alpha: 0.2),
            labelColor: subtitleCol,
            valueColor: brandColor,
            captionColor: brandColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            label: 'LATE IN',
            value: '${summary.lateMinutes} Mins',
            caption: '${summary.lateCount} Late records',
            background: lateInBg,
            borderColor: borderCol,
            labelColor: subtitleCol,
            valueColor: lateValueCol,
            captionColor: subtitleCol,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String caption,
    required Color background,
    required Color borderColor,
    required Color labelColor,
    required Color valueColor,
    required Color captionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: labelColor,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTypography.labelSmall.copyWith(
              color: captionColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
