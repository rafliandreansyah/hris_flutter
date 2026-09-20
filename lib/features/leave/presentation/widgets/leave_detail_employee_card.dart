import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

/// Card Requester Profile ("INFORMASI PENGAJU") sesuai desain Stitch:
/// - Menggunakan EmployeeInfoRow standar global
/// - Avatar foto/inisial
/// - Nama lengkap
/// - Posisi • Departemen
/// - Badge ID Pegawai & Badge Perusahaan
class LeaveDetailEmployeeCard extends StatelessWidget {
  final LeaveEmployeeDetailModel employee;

  const LeaveDetailEmployeeCard({super.key, required this.employee});

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
            employeeId:
                employee.employeeNumber ?? employee.idNumber ?? employee.id,
            avatarUrl: employee.resolvedAvatarUrl,
            initials: employee.initials,
            avatarSize: 44,
          ),
        ],
      ),
    );
  }
}
