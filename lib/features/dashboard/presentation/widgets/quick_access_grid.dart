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

  /// 8 Menu Standar Dashboard Oasish HRIS
  static const List<({String code, String title, IconData icon})>
      _defaultMenus = [
    (code: 'activity', title: 'Activity', icon: LucideIcons.chartLine),
    (code: 'employee', title: 'Employee', icon: LucideIcons.idCard),
    (code: 'overtime', title: 'Overtime', icon: LucideIcons.timer),
    (code: 'leave', title: 'Leave', icon: LucideIcons.calendarOff),
    (code: 'payroll', title: 'Payroll', icon: LucideIcons.wallet),
    (code: 'schedule', title: 'Schedule', icon: LucideIcons.calendar),
    (code: 'attendance', title: 'Attendance', icon: LucideIcons.fingerprint),
    (code: 'helpdesk', title: 'Helpdesk', icon: LucideIcons.headset),
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

    return apiMenus.any((m) {
      final mCode = m.code.toLowerCase().trim();
      final mName = m.name.toLowerCase().trim();
      return mCode == targetCode ||
          mName == targetTitle ||
          mCode.contains(targetCode) ||
          targetCode.contains(mCode) ||
          mName.contains(targetTitle) ||
          targetTitle.contains(mName);
    });
  }

  static void handleMenuTap(
    BuildContext context,
    String code,
    String title,
  ) {
    final lower = '$code $title'.toLowerCase();
    if (lower.contains('emp') ||
        lower.contains('pegawai') ||
        lower.contains('karyawan')) {
      context.push(Routes.EMPLOYEE_DIRECTORY);
    } else if (lower.contains('act') ||
        lower.contains('aktivitas') ||
        lower.contains('activity')) {
      context.push(Routes.ACTIVITY);
    } else if (lower.contains('att') ||
        lower.contains('absen') ||
        lower.contains('presensi') ||
        lower.contains('attendance')) {
      context.push(Routes.ATTENDANCE_LOGS);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu $title segera hadir')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconCol =
        isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final textCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final sectionTitleCol =
        isDark ? AppColors.darkOnSurface : AppColors.onSurface;

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
                onTap: () => handleMenuTap(
                  context,
                  item.code,
                  item.title,
                ),
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
                      Icon(
                        item.icon,
                        size: 26,
                        color: iconCol,
                      ),
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
