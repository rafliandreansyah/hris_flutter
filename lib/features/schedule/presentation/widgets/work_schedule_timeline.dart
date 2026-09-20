import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

class WorkScheduleTimeline extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChange;

  const WorkScheduleTimeline({
    super.key,
    required this.initialDate,
    required this.onDateChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: EasyDateTimeLine(
        initialDate: initialDate,
        locale: 'id_ID',
        headerProps: EasyHeaderProps(
          monthPickerType: MonthPickerType.switcher,
          dateFormatter: const DateFormatter.fullDateDayAsStrMY(),
          monthStyle: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
          selectedDateStyle: AppTypography.labelMedium.copyWith(
            color: subtitleCol,
            fontWeight: FontWeight.w500,
          ),
        ),
        dayProps: EasyDayProps(
          height: 84,
          width: 60,
          dayStructure: DayStructure.dayStrDayNum,
          activeDayStyle: DayStyle(
            decoration: BoxDecoration(
              color: AppColors.brandTeal,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            dayNumStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            dayStrStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          inactiveDayStyle: DayStyle(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol, width: 1),
            ),
            dayNumStyle: TextStyle(
              color: textCol,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            dayStrStyle: TextStyle(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          todayStyle: DayStyle(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandTeal,
                width: 1.8,
              ),
            ),
            dayNumStyle: TextStyle(
              color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            dayStrStyle: TextStyle(
              color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        onDateChange: onDateChange,
      ),
    );
  }
}
