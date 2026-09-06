import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/activity/data/models/activity_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Feed Log Aktivitas Karyawan sesuai Google Stitch Material 3
class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.brandTeal.withValues(alpha: 0.08),
          highlightColor: AppColors.brandTeal.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Employee Header Row (Avatar, Name, Role • Department)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppAvatar(
                      imageUrl: activity.avatarUrl,
                      name: activity.userName,
                      size: 40,
                      fontSize: 14,
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.userName,
                            style: AppTypography.titleSmall.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${activity.userRole} • ${activity.department}',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleCol,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Task Title & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: activity.status.backgroundColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: activity.status.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activity.status.label,
                            style: TextStyle(
                              color: activity.status.textColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 3. Activity Notes / Description
                Text(
                  activity.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: subtitleCol,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Footer Metadata (Location & Time)
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: borderCol.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 13.5,
                        color: subtitleCol,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.clock,
                        size: 13.5,
                        color: subtitleCol,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        activity.time,
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
