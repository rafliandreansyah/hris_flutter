import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';

/// Kartu "PENERBIT PENGUMUMAN" (Penerbit Pengumuman) sesuai Google Stitch M3.
class AnnouncementDetailAuthorCard extends StatelessWidget {
  final AnnouncementAuthor author;

  const AnnouncementDetailAuthorCard({
    super.key,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENERBIT PENGUMUMAN (PUBLISHED BY)',
          style: AppTypography.labelSmall.copyWith(
            color: subtitleCol,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: EmployeeInfoRow(
            name: author.fullName,
            role: author.position?.name ?? '',
            department: author.department?.name ?? '',
            company: author.company?.name,
            employeeId: author.employeeNumber ?? author.idNumber ?? author.id,
            avatarUrl: author.photoUrl,
            initials: author.initials,
            avatarSize: 44,
          ),
        ),
      ],
    );
  }
}
