import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/notification/data/models/notification_api_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationItemCard extends StatelessWidget {
  final NotificationItemModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationItemCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'attendance_request':
      case 'attendance':
        return LucideIcons.calendarCheck2;
      case 'leave_request':
      case 'leave':
        return LucideIcons.calendarClock;
      case 'overtime_request':
      case 'overtime':
        return LucideIcons.clockAlert;
      case 'activity':
        return LucideIcons.briefcase;
      case 'announcement':
        return LucideIcons.megaphone;
      case 'warning_letter':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'attendance_request':
      case 'attendance':
        return AppColors.brandTeal;
      case 'leave_request':
      case 'leave':
        return const Color(0xFF4F46E5); // Indigo
      case 'overtime_request':
      case 'overtime':
        return const Color(0xFFD97706); // Amber
      case 'activity':
        return const Color(0xFF059669); // Emerald
      case 'announcement':
        return const Color(0xFF7C3AED); // Purple
      case 'warning_letter':
        return AppColors.errorRed;
      default:
        return AppColors.brandTeal;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'attendance_request':
      case 'attendance':
        return 'Presensi';
      case 'leave_request':
      case 'leave':
        return 'Cuti & Izin';
      case 'overtime_request':
      case 'overtime':
        return 'Lembur';
      case 'activity':
        return 'Aktivitas';
      case 'announcement':
        return 'Pengumuman';
      case 'warning_letter':
        return 'Surat Peringatan';
      default:
        return 'Pemberitahuan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(notification.type);
    final iconData = _getTypeIcon(notification.type);
    final typeLabel = _getTypeLabel(notification.type);

    final cardBg = isDark
        ? (notification.isRead
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.darkSurfaceContainer)
        : (notification.isRead
            ? AppColors.surfaceContainerLowest
            : AppColors.brandTeal.withValues(alpha: 0.04));

    final borderCol = isDark
        ? (notification.isRead
            ? AppColors.darkOutlineMuted
            : AppColors.brandTeal.withValues(alpha: 0.3))
        : (notification.isRead
            ? AppColors.outlineMuted
            : AppColors.brandTeal.withValues(alpha: 0.3));

    final titleCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final bodyCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol),
        boxShadow: notification.isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.brandTeal.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          key: ValueKey('notification_item_${notification.id}'),
          onTap: () {
            if (!notification.isRead) {
              onMarkAsRead?.call();
            }
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Ikon Jenis Notifikasi
                CircleAvatar(
                  radius: 20,
                  backgroundColor: typeColor.withValues(alpha: 0.12),
                  child: Icon(
                    iconData,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Konten Notifikasi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Kategori & Waktu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                notification.timeAgoLabel,
                                style: AppTypography.bodySmall.copyWith(
                                  color: bodyCol,
                                  fontSize: 11,
                                ),
                              ),
                              if (!notification.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandTeal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Judul Notifikasi
                      Text(
                        notification.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: titleCol,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Isi Pesan
                      Text(
                        notification.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyCol,
                          height: 1.4,
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
