import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Card 2: Requester Employee Profile ("INFORMASI PENGAJU")
/// Sesuai spesifikasi Stitch M3 menggunakan EmployeeInfoRow standar global.
class OvertimeDetailEmployeeCard extends StatelessWidget {
  final OvertimeEmployeeModel employee;

  const OvertimeDetailEmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final empNo = (employee.employeeNumber != null &&
            employee.employeeNumber!.trim().isNotEmpty)
        ? employee.employeeNumber!.trim()
        : (employee.idNumber != null && employee.idNumber!.trim().isNotEmpty)
            ? employee.idNumber!.trim()
            : employee.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMASI PENGAJU',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          EmployeeInfoRow(
            name: employee.fullName,
            role: employee.position?.name ?? '',
            department: employee.department?.name ?? '',
            company: employee.company?.name,
            employeeId: empNo,
            avatarUrl: resolveFileUrl(employee.photoUrl),
            initials: employee.initials,
            avatarSize: 44,
          ),
        ],
      ),
    );
  }
}
