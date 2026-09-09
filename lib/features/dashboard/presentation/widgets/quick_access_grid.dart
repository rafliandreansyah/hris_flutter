import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/features/dashboard/data/models/menu_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QuickAccessItem {
  final String title;
  final String code;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickAccessItem({
    required this.title,
    required this.code,
    required this.icon,
    this.onTap,
  });
}

/// Bento Grid Quick Access untuk Dashboard (Teal Oasis).
/// Menggunakan daftar menu standar proyek, dan menyembunyikan (hide) menu yang
/// tidak terdapat di dalam respon API `/auth/menus`.
class QuickAccessGrid extends StatelessWidget {
  final List<MenuItemModel>? menus;

  const QuickAccessGrid({super.key, this.menus});

  /// Menu Standar Dashboard Oasish HRIS
  /// Kode, nama, dan icon disinkronkan dengan entitas Menu di backend
  static const List<({String code, String title, IconData icon})>
  _defaultMenus = [
    (
      code: 'mobile_activity',
      title: 'Aktivitas',
      icon: LucideIcons.clipboardList,
    ),
    (code: 'mobile_overtime', title: 'Lembur', icon: LucideIcons.clockAlert),
    (code: 'mobile_leave', title: 'Izin & Cuti', icon: LucideIcons.calendarOff),
    (
      code: 'mobile_attendance_request_live',
      title: 'Absen Luar',
      icon: LucideIcons.mapPin,
    ),
    (
      code: 'mobile_attendance',
      title: 'Presensi',
      icon: LucideIcons.fingerprint,
    ),
    (code: 'mobile_employee', title: 'Pegawai', icon: LucideIcons.users),
    (
      code: 'mobile_warning_letter',
      title: 'Surat Peringatan',
      icon: LucideIcons.triangleAlert,
    ),
    (code: 'mobile_payroll', title: 'Slip Gaji', icon: LucideIcons.wallet),
    (
      code: 'mobile_schedule',
      title: 'Jadwal Kerja',
      icon: LucideIcons.calendar,
    ),
  ];

  /// Memeriksa apakah menu tertentu ada di dalam daftar menu API `/auth/menus`
  static bool isMenuAvailable(
    String code,
    String title,
    List<MenuItemModel>? apiMenus,
  ) {
    if (apiMenus == null) return true; // Default aktif jika belum load/offline
    final targetCode = code.toLowerCase().trim();
    final targetTitle = title.toLowerCase().trim();

    // 🌟 Khusus "Absen Luar Kantor":
    // Cek minimal memiliki 1 menu antara `mobile_attendance_request_live` ATAU `mobile_attendance_request_schedule`
    if (targetCode == 'mobile_attendance_request_live' ||
        targetCode == 'mobile_attendance_request_schedule' ||
        targetTitle.contains('absen luar') ||
        targetTitle.contains('luar kantor')) {
      final hasLive = apiMenus.any((m) {
        final c = m.code.toLowerCase().trim();
        final n = m.name.toLowerCase().trim();
        return c == 'mobile_attendance_request_live' ||
            n.contains('absen luar kantor (live)');
      });

      final hasSchedule = apiMenus.any((m) {
        final c = m.code.toLowerCase().trim();
        final n = m.name.toLowerCase().trim();
        return c == 'mobile_attendance_request_schedule' ||
            n.contains('absen luar kantor (schedule)');
      });

      return hasLive || hasSchedule;
    }

    return apiMenus.any((m) {
      final mCode = m.code.toLowerCase().trim();
      final mName = m.name.toLowerCase().trim();

      // 1. Prioritaskan kecocokan persis pada code (case-insensitive)
      if (mCode == targetCode) return true;

      // 2. Kecocokan pada nama menu
      if (mName == targetTitle) return true;
      if (mName.contains(targetTitle) || targetTitle.contains(mName))
        return true;

      // 3. Kecocokan nama umum bahasa Inggris/Indonesia
      if (targetCode == 'mobile_activity' &&
          (mName.contains('aktifitas') || mName.contains('activity'))) {
        return true;
      }
      if (targetCode == 'mobile_overtime' &&
          (mName.contains('lembur') || mName.contains('overtime'))) {
        return true;
      }
      if (targetCode == 'mobile_leave' &&
          (mName.contains('cuti') ||
              mName.contains('izin') ||
              mName.contains('leave'))) {
        return true;
      }
      if (targetCode == 'mobile_attendance' &&
          (mName == 'presensi' ||
              mName == 'attendance' ||
              mName == 'presensi / absensi' ||
              mName == 'absensi')) {
        return true;
      }
      if (targetCode == 'mobile_employee' &&
          (mName.contains('pegawai') ||
              mName.contains('employee') ||
              mName.contains('karyawan'))) {
        return true;
      }
      if (targetCode == 'mobile_warning_letter' &&
          (mName.contains('peringatan') ||
              mName.contains('warning') ||
              mName.contains('sp'))) {
        return true;
      }
      if (targetCode == 'mobile_payroll' &&
          (mName.contains('gaji') ||
              mName.contains('payroll') ||
              mName.contains('slip'))) {
        return true;
      }
      if (targetCode == 'mobile_schedule' &&
          (mName.contains('jadwal') || mName.contains('schedule'))) {
        return true;
      }

      return false;
    });
  }

  static void handleMenuTap(BuildContext context, String code, String title) {
    final c = code.toLowerCase();
    final lower = '$code $title'.toLowerCase();

    if (c == 'mobile_employee') {
      context.push(Routes.EMPLOYEE_DIRECTORY);
    } else if (c == 'mobile_activity') {
      context.push(Routes.ACTIVITY);
    } else if (c == 'mobile_attendance') {
      context.push(Routes.ATTENDANCE_LOGS);
    } else if (c == 'mobile_attendance_request_live' ||
        c == 'mobile_attendance_request_schedule') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menu $title segera hadir')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menu $title segera hadir')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.primaryContainer;
    final iconCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final textCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final sectionTitleCol = isDark
        ? AppColors.darkOnSurface
        : AppColors.onSurface;

    // Filter menu: hanya tampilkan menu yang ada di respon API
    final displayMenus = (menus != null && menus!.isNotEmpty)
        ? _defaultMenus
              .where((item) => isMenuAvailable(item.code, item.title, menus))
              .toList()
        : _defaultMenus;

    if (displayMenus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: AppTypography.titleMedium.copyWith(
            color: sectionTitleCol,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayMenus.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final item = displayMenus[index];

            return Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => handleMenuTap(context, item.code, item.title),
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.brandTeal.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.brandTeal.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 26, color: iconCol),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
