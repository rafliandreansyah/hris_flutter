import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Card 2: Requester Employee Profile ("REQUESTER INFORMATION")
/// Sesuai spesifikasi Stitch M3 "Section 2: Requester Profile Card"
class OvertimeDetailEmployeeCard extends StatelessWidget {
  final OvertimeEmployeeModel employee;

  const OvertimeDetailEmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final posName = employee.position?.name ?? '';
    final deptName = employee.department?.name ?? '';
    final roleDeptText = [
      if (posName.isNotEmpty) posName,
      if (deptName.isNotEmpty) deptName,
    ].join(' • ');

    final companyName = employee.company?.name ?? '';
    final empNo = (employee.employeeNumber != null &&
            employee.employeeNumber!.trim().isNotEmpty)
        ? employee.employeeNumber!.trim()
        : (employee.idNumber != null && employee.idNumber!.trim().isNotEmpty)
            ? employee.idNumber!.trim()
            : '';

    final companyEmpText = [
      if (companyName.isNotEmpty) companyName,
      if (empNo.isNotEmpty) empNo,
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REQUESTER INFORMATION',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                name: employee.fullName,
                initials: employee.initials,
                imageUrl: resolveFileUrl(employee.photoUrl),
                size: 50,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 16,
                      ),
                    ),
                    if (roleDeptText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleDeptText,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (companyEmpText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        companyEmpText,
                        style: AppTypography.labelMedium.copyWith(
                          color: textCol,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
