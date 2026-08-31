import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';

/// Kartu Informasi Atasan Langsung (Direct Reporting Manager)
class ManagerInfoCard extends StatelessWidget {
  final String name;
  final String role;
  final String department;
  final String company;
  final String employeeId;
  final String initials;

  const ManagerInfoCard({
    super.key,
    this.name = 'Alex Rivera',
    this.role = 'Senior Engineering Manager',
    this.department = 'Engineering',
    this.company = 'PT Oasish Tech Nusantara',
    this.employeeId = 'EMP-2022-005',
    this.initials = 'AR',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.surfaceContainerLowest;
    final borderCol = isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final labelCol = isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final avatarBg = isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIRECT REPORTING MANAGER',
          style: AppTypography.labelSmall.copyWith(
            color: labelCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.inversePrimary : AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleSmall.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$role • $department',
                      style: AppTypography.bodySmall.copyWith(
                        color: labelCol,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$company • $employeeId',
                      style: AppTypography.labelSmall.copyWith(
                        color: labelCol.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
