import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
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
    final lateColor = AppColors.errorRed;

    final isClockIn = log.type == AttendanceLogType.clockIn;
    final accentColor = !isClockIn
        ? outColor
        : (log.isLate ? lateColor : brandColor);
    final timeColor = log.isLate ? lateColor : textCol;

    final dateStr = DateFormat('EEEE, dd MMM yyyy', 'en_US').format(
      log.dateTime,
    );
    final timeStr =
        '${DateFormat('hh:mm a', 'en_US').format(log.dateTime)} '
        '${log.timezoneAbbreviation}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                context.push(Routes.ATTENDANCE_DETAIL, extra: log.id);
              },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: AppTypography.labelSmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: AppTypography.titleMedium.copyWith(
                                  color: timeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBadge(
                              label: isClockIn ? 'Clock In' : 'Clock Out',
                              background: (isClockIn
                                      ? brandColor
                                      : outColor)
                                  .withValues(alpha: 0.1),
                              foreground: isClockIn ? brandColor : outColor,
                            ),
                            if (isClockIn) ...[
                              const SizedBox(height: 4),
                              if (log.isLate)
                                _buildBadge(
                                  label: 'Late by ${log.lateMinutes} mins',
                                  background: lateColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  foreground: lateColor,
                                  icon: LucideIcons.triangleAlert,
                                )
                              else
                                _buildBadge(
                                  label: 'On Time',
                                  background: isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.surfaceContainerHigh,
                                  foreground: textCol,
                                  icon: LucideIcons.circleCheck,
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: borderCol.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isClockIn
                              ? LucideIcons.logIn
                              : LucideIcons.logOut,
                          size: 18,
                          color: isClockIn ? brandColor : subtitleCol,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                label: 'Location',
                                value: log.locationName ?? '-',
                                subtitleCol: subtitleCol,
                                textCol: textCol,
                              ),
                              const SizedBox(height: 2),
                              _buildDetailRow(
                                label: 'Method',
                                value: log.method ?? '-',
                                subtitleCol: subtitleCol,
                                textCol: textCol,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color subtitleCol,
    required Color textCol,
  }) {
    return RichText(
      maxLines: 2,
      text: TextSpan(
        text: '$label: ',
        style: AppTypography.labelSmall.copyWith(
          color: subtitleCol,
          fontSize: 11.5,
        ),
        children: [
          TextSpan(
            text: value,
            style: AppTypography.labelSmall.copyWith(
              color: textCol,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
