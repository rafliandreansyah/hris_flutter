import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/maps_config.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/features/tracking/data/models/live_tracking_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu detail melayang untuk karyawan yang dipilih di peta pemantauan
class LiveEmployeeBottomCard extends StatelessWidget {
  final LiveEmployeeLocation employee;
  final VoidCallback onClose;
  final VoidCallback onViewRoute;

  const LiveEmployeeBottomCard({
    super.key,
    required this.employee,
    required this.onClose,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final border = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Identitas, dan Tombol Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: employee.photoUrl,
                name: employee.name,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.positionName ?? 'Staff'} • ${employee.departmentName ?? 'Departemen'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (employee.employeeNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          employee.employeeNumber,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(LucideIcons.x, size: 18),
                color: subtitleCol,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Metadata Status: Status Sesi, Online Status, Baterai, Akurasi
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(),
              _buildOnlineBadge(),
              if (employee.batteryLevel != null) _buildBatteryBadge(),
              if (employee.accuracy != null) _buildAccuracyBadge(),
            ],
          ),

          // Info Sesi Aktif (jika ada)
          if (employee.session != null &&
              employee.session!.title != null &&
              employee.session!.title!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHigh
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.briefcase,
                    size: 15,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      employee.session!.title!,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textCol,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol Aksi
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Buka di Maps',
                  variant: AppButtonVariant.outlined,
                  leadingIcon: LucideIcons.externalLink,
                  height: 42,
                  onPressed: () {
                    MapsConfig.openGoogleMaps(
                      latitude: employee.latitude,
                      longitude: employee.longitude,
                      queryLabel: employee.name,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'Lihat Rute',
                  variant: AppButtonVariant.primary,
                  leadingIcon: LucideIcons.route,
                  height: 42,
                  onPressed: onViewRoute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (employee.isGpsOff) {
      return _buildChip(
        label: 'GPS Dimatikan',
        color: AppColors.errorRed,
        icon: LucideIcons.mapPinOff,
      );
    }
    if (employee.status == 'activity') {
      return _buildChip(
        label: 'Dinas Lapangan',
        color: AppColors.brandTeal,
        icon: LucideIcons.briefcase,
      );
    }
    return _buildChip(
      label: 'Presensi Aktif',
      color: const Color(0xFF10B981),
      icon: LucideIcons.fingerprint,
    );
  }

  Widget _buildOnlineBadge() {
    if (employee.isOnline) {
      final text = employee.minutesSinceLastPing <= 1
          ? 'Online (Baru saja)'
          : 'Online (${employee.minutesSinceLastPing}m lalu)';
      return _buildChip(
        label: text,
        color: const Color(0xFF0EA5E9),
        icon: LucideIcons.wifi,
      );
    }
    return _buildChip(
      label: 'Offline (${employee.minutesSinceLastPing}m lalu)',
      color: AppColors.outlineMuted,
      icon: LucideIcons.wifiOff,
    );
  }

  Widget _buildBatteryBadge() {
    final lvl = employee.batteryLevel ?? 100;
    final color = lvl < 20
        ? AppColors.errorRed
        : (lvl < 50 ? Colors.orange : AppColors.brandTeal);
    return _buildChip(
      label: '$lvl%',
      color: color,
      icon: LucideIcons.battery,
    );
  }

  Widget _buildAccuracyBadge() {
    final acc = employee.accuracy?.toStringAsFixed(0) ?? '0';
    return _buildChip(
      label: '±${acc}m',
      color: AppColors.onSurfaceVariant,
      icon: LucideIcons.target,
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
