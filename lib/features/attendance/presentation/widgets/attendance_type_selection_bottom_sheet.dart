import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Menampilkan Modal Bottom Sheet "Pilih Metode Presensi Luar"
/// (Google Stitch Screen ID: `b54d937212ed497e80f33efb8670a8e2`).
Future<AttendanceOutsideMethod?> showAttendanceTypeSelectionBottomSheet(
  BuildContext context,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark
      ? AppColors.darkSurfaceContainerLowest
      : AppColors.surfaceContainerLowest;

  return showModalBottomSheet<AttendanceOutsideMethod>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => const AttendanceTypeSelectionBottomSheet(),
  );
}

class AttendanceTypeSelectionBottomSheet extends StatelessWidget {
  const AttendanceTypeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final tealIconBg = isDark
        ? const Color(0xFF003732).withValues(alpha: 0.6)
        : const Color(0xFFF0FDFA);
    final tealBrand =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkOutlineMuted
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Text(
            'Pilih Metode Presensi Luar',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: textCol,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tentukan jenis pengajuan presensi luar kantor sesuai kebutuhan tugas Anda',
            style: AppTypography.bodySmall.copyWith(
              color: subtitleCol,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: Live Attendance (Real-Time)
          _buildOptionCard(
            context: context,
            icon: LucideIcons.mapPin,
            title: 'Live Attendance (Real-Time)',
            description:
                'Catat kehadiran secara langsung di lokasi saat ini menggunakan koordinat GPS real-time.',
            badgeText: 'Instant Check-In / Out',
            badgeBgColor: isDark
                ? const Color(0xFF003732).withValues(alpha: 0.5)
                : const Color(0xFFF0FDFA),
            badgeTextColor: tealBrand,
            tealIconBg: tealIconBg,
            tealBrand: tealBrand,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
            surfaceCol: surfaceCol,
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop(AttendanceOutsideMethod.live);
            },
          ),

          const SizedBox(height: 14),

          // Option 2: Schedule Attendance (Terencana)
          _buildOptionCard(
            context: context,
            icon: LucideIcons.calendarClock,
            title: 'Schedule Attendance (Terencana)',
            description:
                'Ajukan presensi untuk tanggal dan jam tertentu (misal: dinas luar kota atau tugas terjadwal).',
            badgeText: 'Custom Date & Time',
            badgeBgColor: isDark
                ? AppColors.darkSurfaceContainer
                : const Color(0xFFF1F5F9),
            badgeTextColor: isDark
                ? AppColors.darkOnSurfaceVariant
                : const Color(0xFF475569),
            tealIconBg: tealIconBg,
            tealBrand: tealBrand,
            textCol: textCol,
            subtitleCol: subtitleCol,
            borderCol: borderCol,
            surfaceCol: surfaceCol,
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop(AttendanceOutsideMethod.schedule);
            },
          ),

          const SizedBox(height: 24),

          // Bottom Button: Batal
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderCol, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                foregroundColor: subtitleCol,
              ),
              child: Text(
                'Batal',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: subtitleCol,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required Color tealIconBg,
    required Color tealBrand,
    required Color textCol,
    required Color subtitleCol,
    required Color borderCol,
    required Color surfaceCol,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surfaceCol,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bulat kiri
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tealIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: tealBrand,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Teks tengah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textCol,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: subtitleCol,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron kanan
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: subtitleCol.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
