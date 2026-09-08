import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceServerClockCard extends StatelessWidget {
  final DateTime serverTime;
  final String clockTimeString;
  final String timezone;
  final String shiftName;

  const AttendanceServerClockCard({
    super.key,
    required this.serverTime,
    required this.clockTimeString,
    this.timezone = 'Asia/Jakarta',
    this.shiftName = 'Regular Shift (09:00 - 18:00)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final onContainerCol =
        isDark ? AppColors.darkOnPrimaryContainer : AppColors.onPrimaryContainer;
    final chipBg =
        isDark ? AppColors.darkSurfaceContainerHighest : AppColors.surfaceContainerLowest;
    final chipBorder =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final chipText =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    // Format date: "Thursday, Aug 27, 2026"
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(serverTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timezone Header Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.clock,
                size: 16,
                color: onContainerCol,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: chipBorder),
                ),
                child: Text(
                  timezone,
                  style: AppTypography.labelSmall.copyWith(
                    color: chipText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Realtime Server Clock (No 'WIB' suffix per user requirement)
          Text(
            clockTimeString,
            style: AppTypography.headlineLarge.copyWith(
              color: onContainerCol,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Formatted Date
          Text(
            formattedDate,
            style: AppTypography.bodyMedium.copyWith(
              color: onContainerCol.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Teal Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.brandTeal.withValues(alpha: 0.20),
          ),
          const SizedBox(height: 14),

          // Regular Shift Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.briefcase,
                size: 18,
                color: onContainerCol,
              ),
              const SizedBox(width: 8),
              Text(
                shiftName,
                style: AppTypography.labelMedium.copyWith(
                  color: onContainerCol,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
