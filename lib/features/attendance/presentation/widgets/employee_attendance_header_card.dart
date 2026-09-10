import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/employee/data/models/employee_directory_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu profil pegawai yang ditampilkan di bagian atas halaman riwayat absensi pegawai.
class EmployeeAttendanceHeaderCard extends StatelessWidget {
  final EmployeeDirectoryItem employee;

  const EmployeeAttendanceHeaderCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeInfoRow(employee: employee),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          InkWell(
            key: const ValueKey('view_employee_profile_btn'),
            onTap: () {
              context.push(Routes.EMPLOYEE_DETAIL, extra: employee);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 15,
                        color: brandColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lihat Profil Pegawai',
                        style: AppTypography.labelMedium.copyWith(
                          color: brandColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: brandColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
