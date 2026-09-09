import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
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
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final badgeBg = isDark
        ? AppColors.darkSurfaceContainerHigh
        : const Color(0xFFF1F5F9);

    final displayId = (employee.employeeNumber != null &&
            employee.employeeNumber!.isNotEmpty)
        ? employee.employeeNumber!
        : employee.id;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                imageUrl: employee.avatarUrl,
                name: employee.name,
                initials: employee.initials,
                size: 52,
                backgroundColor: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.accentTealLight,
                textColor: isDark
                    ? AppColors.darkOnPrimaryContainer
                    : AppColors.primary,
                fontSize: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.role} • ${employee.department}',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.idCard,
                                size: 12,
                                color: subtitleCol,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayId,
                                style: AppTypography.labelSmall.copyWith(
                                  color: textCol,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (employee.company != null &&
                            employee.company!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                employee.company!,
                                style: AppTypography.labelSmall.copyWith(
                                  color: subtitleCol,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
