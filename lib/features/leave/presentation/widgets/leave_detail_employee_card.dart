import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

/// Card Requester Profile ("EMPLOYEE INFORMATION") sesuai desain Stitch:
/// - Avatar inisial / foto profil
/// - Nama lengkap karyawan
/// - Posisi/Jabatan • Departemen
/// - Email • Nama Perusahaan
class LeaveDetailEmployeeCard extends StatelessWidget {
  final LeaveEmployeeDetailModel employee;

  const LeaveDetailEmployeeCard({super.key, required this.employee});

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
    final emailText = employee.email.isNotEmpty ? employee.email : '';
    final emailCompanyText = [
      if (emailText.isNotEmpty) emailText,
      if (companyName.isNotEmpty) companyName,
    ].join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMPLOYEE INFORMATION',
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
                imageUrl: employee.resolvedAvatarUrl,
                size: 46,
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
                        fontSize: 15.5,
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
                    if (emailCompanyText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        emailCompanyText,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol.withValues(alpha: 0.85),
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
