import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

/// Card 3: Employee Profile Card (Informasi Pengaju)
/// Sesuai spesifikasi Stitch M3 menggunakan EmployeeInfoRow standar global.
class AttendanceRequestEmployeeCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel employee;

  const AttendanceRequestEmployeeCard({super.key, required this.employee});

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

    final empNumber = employee.employeeNumber ??
        (employee.id.length > 8 ? employee.id.substring(0, 8) : employee.id);

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
            employeeId: empNumber,
            avatarUrl: employee.photoUrl,
            initials: employee.initials,
            avatarSize: 44,
          ),
        ],
      ),
    );
  }
}
