import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bar ringkasan metrik pemantauan live tracking (Total, Presensi, Dinas, Online, GPS Mati)
class LiveTrackingSummaryBar extends StatelessWidget {
  final LiveTrackingSummary summary;
  final VoidCallback? onRefresh;

  const LiveTrackingSummaryBar({
    super.key,
    required this.summary,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            context,
            label: 'Total',
            count: summary.totalTracked,
            color: AppColors.primary,
            icon: LucideIcons.users,
          ),
          _buildDivider(isDark),
          _buildItem(
            context,
            label: 'Presensi',
            count: summary.attendanceCount,
            color: const Color(0xFF10B981), // Emerald Green
            icon: LucideIcons.fingerprint,
          ),
          _buildDivider(isDark),
          _buildItem(
            context,
            label: 'Dinas',
            count: summary.activityCount,
            color: AppColors.brandTeal,
            icon: LucideIcons.briefcase,
          ),
          _buildDivider(isDark),
          _buildItem(
            context,
            label: 'Online',
            count: summary.onlineCount,
            color: const Color(0xFF0EA5E9), // Sky Blue
            icon: LucideIcons.wifi,
          ),
          if (summary.gpsOffCount > 0) ...[
            _buildDivider(isDark),
            _buildItem(
              context,
              label: 'GPS Mati',
              count: summary.gpsOffCount,
              color: AppColors.errorRed,
              icon: LucideIcons.mapPinOff,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted,
    );
  }
}
