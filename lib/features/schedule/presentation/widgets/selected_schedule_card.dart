import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedScheduleCard extends StatelessWidget {
  final DateTime selectedDate;
  final WorkScheduleItem? schedule;

  const SelectedScheduleCard({
    super.key,
    required this.selectedDate,
    this.schedule,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    // 1. Kondisi Tidak Ada Jadwal Tercatat
    if (schedule == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(textCol),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.calendarOff,
                    size: 20,
                    color: isDark
                        ? AppColors.inversePrimary
                        : AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tidak ada informasi jadwal kerja untuk tanggal ini.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: subtitleCol,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Kondisi Hari Libur (Day Off)
    if (schedule!.isDayOff) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildDateHeader(textCol)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.coffee,
                        size: 13,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hari Libur',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.moon,
                    size: 22,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Libur / Off Schedule',
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schedule!.dayOffNotes?.isNotEmpty == true
                            ? schedule!.dayOffNotes!
                            : 'Tidak ada jam operasional kerja terjadwal.',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
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

    // 3. Kondisi Hari Kerja dengan Shift
    final shift = schedule!.shift;
    final startTime = shift?.startTime != null
        ? AppDateUtil.formatTimeHHmm(shift!.startTime)
        : '08:00';
    final endTime = shift?.endTime != null
        ? AppDateUtil.formatTimeHHmm(shift!.endTime)
        : '17:00';
    final breakStart = shift?.breakStart != null
        ? AppDateUtil.formatTimeHHmm(shift!.breakStart)
        : null;
    final breakEnd = shift?.breakEnd != null
        ? AppDateUtil.formatTimeHHmm(shift!.breakEnd)
        : null;
    final shiftName =
        shift?.name ??
        (shift?.isNightShift == true ? 'Shift Malam' : 'Shift Reguler');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkPrimaryContainer
              : AppColors.brandTeal.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tanggal & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Expanded(child: _buildDateHeader(textCol))],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Nama Shift
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                shiftName,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.inversePrimary
                      : AppColors.brandTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.brandTeal.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Jadwal Aktif',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.inversePrimary
                            : AppColors.brandTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Jam Kerja Besar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.clock,
                size: 24,
                color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime WIB',
                style: AppTypography.headlineLargeMobile.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Detail Istirahat jika tersedia
          if (breakStart != null && breakEnd != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.coffee, size: 16, color: subtitleCol),
                  const SizedBox(width: 8),
                  Text(
                    'Istirahat: $breakStart - $breakEnd WIB',
                    style: AppTypography.bodySmall.copyWith(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Tag Chips (Fleksibel, Istirahat Fleksibel, Shift Malam)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (shift?.isFlexibleTime == true)
                _buildChip(
                  label: 'Jam Fleksibel',
                  icon: LucideIcons.clock,
                  isDark: isDark,
                ),
              if (shift?.isFlexibleBreak == true)
                _buildChip(
                  label: 'Istirahat Fleksibel',
                  icon: LucideIcons.coffee,
                  isDark: isDark,
                ),
              if (shift?.isNightShift == true)
                _buildChip(
                  label: 'Shift Malam',
                  icon: LucideIcons.moon,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(Color textCol) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            _formatDate(selectedDate),
            style: AppTypography.titleSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (_isToday) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandTeal,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Hari Ini',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
