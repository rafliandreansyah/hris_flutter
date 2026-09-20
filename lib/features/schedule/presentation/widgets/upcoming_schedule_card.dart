import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UpcomingScheduleCard extends StatelessWidget {
  final WorkScheduleItem item;
  final VoidCallback? onTap;

  const UpcomingScheduleCard({
    super.key,
    required this.item,
    this.onTap,
  });

  String _formatDayName(DateTime dt) {
    const days = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];
    return days[dt.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final date = item.parsedDate ?? DateTime.now();
    final dayName = _formatDayName(date);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: item.isDayOff
                  ? AppColors.errorRed.withValues(alpha: 0.25)
                  : borderCol,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Kolom Tanggal (Badge Kiri)
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: item.isDayOff
                      ? AppColors.errorRed.withValues(alpha: 0.08)
                      : (isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.backgroundSubtle),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: item.isDayOff
                        ? AppColors.errorRed.withValues(alpha: 0.2)
                        : borderCol,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: item.isDayOff
                            ? AppColors.errorRed
                            : subtitleCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: AppTypography.titleMedium.copyWith(
                        color: item.isDayOff ? AppColors.errorRed : textCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Konten Detail Jadwal
              Expanded(
                child: item.isDayOff
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Text(
                                  'Hari Libur',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.dayOffNotes?.isNotEmpty == true
                                ? item.dayOffNotes!
                                : 'Off Schedule / Libur',
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleCol,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.shift?.name ??
                                    (item.shift?.isNightShift == true
                                        ? 'Shift Malam'
                                        : 'Shift Pagi'),
                                style: AppTypography.labelMedium.copyWith(
                                  color: isDark
                                      ? AppColors.inversePrimary
                                      : AppColors.brandTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.shift?.isNightShift == true) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  LucideIcons.moon,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.inversePrimary
                                      : AppColors.brandTeal,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: subtitleCol,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppDateUtil.formatTimeHHmm(item.shift?.startTime ?? "08:00")} - ${AppDateUtil.formatTimeHHmm(item.shift?.endTime ?? "17:00")} WIB',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: textCol,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (item.shift?.breakStart != null &&
                              item.shift?.breakEnd != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Istirahat: ${AppDateUtil.formatTimeHHmm(item.shift!.breakStart)} - ${AppDateUtil.formatTimeHHmm(item.shift!.breakEnd)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),

              // Panah Aksi
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: subtitleCol.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
