import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';

/// Menampilkan Material 3 DateRangePicker dengan tema Stitch M3 "Teal Oasis".
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String saveText = 'Pilih',
  String helpText = 'PILIH RENTANG TANGGAL',
  String fieldStartLabelText = 'Tanggal Mulai',
  String fieldEndLabelText = 'Tanggal Selesai',
}) async {
  final now = DateTime.now();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
  final onPrimaryCol = isDark ? const Color(0xFF003732) : Colors.white;
  final surfaceCol = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;
  final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
  final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

  return showDateRangePicker(
    context: context,
    firstDate: firstDate ?? DateTime(now.year - 2),
    lastDate: lastDate ?? DateTime(now.year + 1),
    initialDateRange: initialDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
    saveText: saveText,
    helpText: helpText,
    fieldStartLabelText: fieldStartLabelText,
    fieldEndLabelText: fieldEndLabelText,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: primaryCol,
                  onPrimary: onPrimaryCol,
                  surface: surfaceCol,
                  onSurface: textCol,
                  surfaceContainerHighest: AppColors.darkSurfaceContainerHigh,
                  onSurfaceVariant: AppColors.darkOnSurfaceVariant,
                  outline: borderCol,
                )
              : ColorScheme.light(
                  primary: primaryCol,
                  onPrimary: onPrimaryCol,
                  surface: surfaceCol,
                  onSurface: textCol,
                  surfaceContainerHighest: const Color(0xFFE2E8F0),
                  onSurfaceVariant: const Color(0xFF64748B),
                  outline: borderCol,
                ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: primaryCol,
            headerForegroundColor: onPrimaryCol,
            backgroundColor: surfaceCol,
            rangePickerHeaderBackgroundColor: primaryCol,
            rangePickerHeaderForegroundColor: onPrimaryCol,
            rangePickerSurfaceTintColor: Colors.transparent,
            rangeSelectionBackgroundColor: primaryCol.withValues(alpha: 0.15),
            todayBorder: BorderSide(color: primaryCol, width: 1.5),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return onPrimaryCol;
              }
              return primaryCol;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return primaryCol;
              }
              return null;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return onPrimaryCol;
              }
              return textCol;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
