import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceTimelineSection extends StatelessWidget {
  final String? inTime;
  final String? outTime;
  final String? breakOutTime;
  final String? breakInTime;
  final bool isClockedIn;
  final bool isClockedOut;

  const AttendanceTimelineSection({
    super.key,
    this.inTime,
    this.outTime,
    this.breakOutTime,
    this.breakInTime,
    this.isClockedIn = false,
    this.isClockedOut = false,
  });

  static String _formatTimeHHmm(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '--:--') {
      return '--:--';
    }
    final match = RegExp(r'(\d{2}):\d{2}').firstMatch(timeStr);
    if (match != null) return match.group(0)!;
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textPrimary =
        isDark ? AppColors.darkOnSurface : AppColors.onBackground;
    final textSecondary =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.surfaceVariant;
    final iconBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconColor =
        isDark ? AppColors.darkOnPrimaryContainer : AppColors.onPrimaryContainer;

    return Column(
      children: [
        // 1. Clock In Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.logIn,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock In',
                        style: AppTypography.labelMedium.copyWith(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inTime != null && inTime!.isNotEmpty ? _formatTimeHHmm(inTime) : '--:--',
                        style: AppTypography.titleMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                isClockedIn ? 'Recorded' : 'Not started',
                style: AppTypography.labelSmall.copyWith(
                  color: isClockedIn
                      ? AppColors.brandTeal
                      : textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Break Session Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.coffee,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Break Session',
                    style: AppTypography.titleMedium.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 1,
                color: borderColor,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Break Out',
                          style: AppTypography.labelSmall.copyWith(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          breakOutTime != null && breakOutTime!.isNotEmpty
                              ? _formatTimeHHmm(breakOutTime)
                              : '--:--',
                          style: AppTypography.bodyLarge.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Break In',
                          style: AppTypography.labelSmall.copyWith(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          breakInTime != null && breakInTime!.isNotEmpty
                              ? _formatTimeHHmm(breakInTime)
                              : '--:--',
                          style: AppTypography.bodyLarge.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Clock Out Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.logOut,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock Out',
                        style: AppTypography.labelMedium.copyWith(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        outTime != null && outTime!.isNotEmpty ? _formatTimeHHmm(outTime) : '--:--',
                        style: AppTypography.titleMedium.copyWith(
                          color: isClockedOut
                              ? textPrimary
                              : textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                isClockedOut ? 'Recorded' : 'Pending',
                style: AppTypography.labelSmall.copyWith(
                  color: isClockedOut
                      ? AppColors.brandTeal
                      : textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
