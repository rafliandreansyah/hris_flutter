import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QuickAccessItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickAccessItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}

/// Bento Grid Quick Access untuk Dashboard (Teal Oasis)
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkPrimaryContainer : AppColors.primaryContainer;
    final iconCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;

    final items = [
      QuickAccessItem(
        title: 'Activity',
        icon: LucideIcons.chartLine,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Activity segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Employee',
        icon: LucideIcons.idCard,
        onTap: () {
          context.push(Routes.EMPLOYEE_DETAIL);
        },
      ),
      QuickAccessItem(
        title: 'Overtime',
        icon: LucideIcons.timer,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Overtime segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Leave',
        icon: LucideIcons.calendarOff,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Leave segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Payroll',
        icon: LucideIcons.wallet,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Payroll segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Schedule',
        icon: LucideIcons.calendar,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Schedule segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Attendance',
        icon: LucideIcons.fingerprint,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Attendance segera hadir')),
          );
        },
      ),
      QuickAccessItem(
        title: 'Helpdesk',
        icon: LucideIcons.headset,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu Helpdesk segera hadir')),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: AppTypography.titleMedium.copyWith(
            color: textCol,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: AppColors.brandTeal.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
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
