import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_log_item.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceLogCard extends StatelessWidget {
  final AttendanceLogItem log;
  final VoidCallback? onTap;

  const AttendanceLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final outColor = isDark
        ? AppColors.tertiaryFixedDim
        : AppColors.tertiaryContainer;
    const lateColor = AppColors.errorRed;

    final isClockIn = log.type == AttendanceLogType.clockIn;
    final accentColor = isClockIn ? brandColor : outColor;

    final dateStr = AppDateUtil.formatDateFull(log.dateTime, locale: 'id');
    final time24Str = DateFormat('HH:mm').format(log.dateTime);
    final tzShort = AppDateUtil.timezoneLabel(log.displayTimezone);
    final location = log.locationName?.trim() ?? '';
    final method = log.method?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap ??
              () {
                context.push(Routes.ATTENDANCE_DETAIL, extra: log.id);
              },
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md - 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon tipe absensi
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderInput,
                  ),
                  child: Icon(
                    isClockIn ? LucideIcons.logIn : LucideIcons.logOut,
                    size: 19,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Tipe + jam, chip ketepatan waktu
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: isClockIn ? 'Absen Masuk' : 'Absen Pulang',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: textCol,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  •  $time24Str',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: log.isLate ? lateColor : textCol,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isClockIn) ...[
                            const SizedBox(width: AppSpacing.sm),
                            log.isLate
                                ? _buildBadge(
                                    label: 'Terlambat ${log.lateMinutes} menit',
                                    background: lateColor.withValues(alpha: 0.1),
                                    foreground: lateColor,
                                  )
                                : _buildBadge(
                                    label: 'Tepat Waktu',
                                    background: brandColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    foreground: brandColor,
                                  ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Baris 2: tanggal
                      Text(
                        '$dateStr • $tzShort',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12.5,
                        ),
                      ),
                      // Baris 3: lokasi & metode
                      if (location.isNotEmpty || method.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                LucideIcons.mapPin,
                                size: 13,
                                color: subtitleCol,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs + 2),
                            Expanded(
                              child: Text(
                                [
                                  if (location.isNotEmpty) location,
                                  if (method.isNotEmpty) method,
                                ].join('  •  '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: textCol,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
