import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/resignation/data/models/my_resignation_status_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ResignationCountdownCard extends StatelessWidget {
  final ResignationDetailModel resignation;
  final int daysRemaining;

  const ResignationCountdownCard({
    super.key,
    required this.resignation,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final bgCol = isDark
        ? const Color(0xFF042F2E)
        : const Color(0xFFF0FDFA);
    final borderCol = isDark
        ? const Color(0xFF115E59)
        : const Color(0xFF99F6E4);

    final totalNoticeDays = resignation.actualNoticePeriodDays > 0
        ? resignation.actualNoticePeriodDays
        : resignation.requiredNoticePeriodDays;

    final safeTotal = totalNoticeDays > 0 ? totalNoticeDays : 30;
    final remainingSafe = daysRemaining.clamp(0, safeTotal);
    final dayCurrent = (safeTotal - remainingSafe).clamp(0, safeTotal);
    final progress = safeTotal > 0 ? (dayCurrent / safeTotal) : 0.0;
    final progressPercent = (progress * 100).round();

    final effectiveDateStr = resignation.effectiveDate != null
        ? DateFormat('d MMMM yyyy').format(resignation.effectiveDate!)
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.calendarClock, size: 16, color: brandCol),
                  const SizedBox(width: 8),
                  Text(
                    'Hari Terakhir Bekerja',
                    style: AppTypography.labelMedium.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF134E4A)
                      : const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  resignation.isEarlyNotice
                      ? 'Percepatan Notice'
                      : 'Notice Period: $safeTotal Hari',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF5EEAD4)
                        : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            daysRemaining > 0
                ? '$daysRemaining Hari Kerja Tersisa'
                : 'Hari Terakhir Bekerja',
            style: AppTypography.headlineMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Menuju Tanggal Efektif ($effectiveDateStr)',
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF134E4A)
                  : const Color(0xFFCCFBF1),
              valueColor: AlwaysStoppedAnimation<Color>(brandCol),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Notice Period',
                style: TextStyle(
                  fontSize: 11.5,
                  color: subtitleCol,
                ),
              ),
              Text(
                '$progressPercent% (Hari ke-$dayCurrent dari $safeTotal)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
