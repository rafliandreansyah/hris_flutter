import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/schedule/data/models/work_schedule_response_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmployeeWorkScheduleHeaderCard extends StatelessWidget {
  final WorkScheduleEmployee employee;

  const EmployeeWorkScheduleHeaderCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;

    final deptPos = [
      if (employee.positionName?.isNotEmpty == true) employee.positionName!,
      if (employee.departmentName?.isNotEmpty == true) employee.departmentName!,
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.userCheck,
                    size: 14,
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Jadwal Kerja Pegawai',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.inversePrimary
                          : AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (employee.companyName?.isNotEmpty == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.backgroundSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: borderCol, width: 0.8),
                  ),
                  child: Text(
                    employee.companyName!,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Employee Profile Row
          Row(
            children: [
              AppAvatar(
                imageUrl: employee.photoUrl,
                name: employee.fullName,
                size: 46,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (deptPos.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        deptPos,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (employee.employeeNumber?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          employee.employeeNumber!,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.inversePrimary
                                : AppColors.brandTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
