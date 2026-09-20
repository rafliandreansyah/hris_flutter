import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 4: Approver Profile Card (Pejabat Penyetuju)
/// Sesuai spesifikasi Stitch M3 menggunakan EmployeeInfoRow standar global.
class AttendanceRequestApproverCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel? approver;
  final String? approverNotes;

  const AttendanceRequestApproverCard({
    super.key,
    this.approver,
    this.approverNotes,
  });

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
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final app = approver;
    final hasNotes = approverNotes != null && approverNotes!.trim().isNotEmpty;

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
            'PEJABAT PENYETUJU',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (app == null) ...[
            Text(
              'Belum ada approver yang ditugaskan.',
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
            ),
          ] else ...[
            EmployeeInfoRow(
              name: app.fullName.isNotEmpty ? app.fullName : 'Approver',
              role: app.position?.name ?? '',
              department: app.department?.name ?? '',
              company: app.company?.name,
              employeeId: app.employeeNumber ??
                  (app.id.length > 8 ? app.id.substring(0, 8) : app.id),
              avatarUrl: app.photoUrl,
              initials: app.initials,
              avatarSize: 44,
            ),
          ],
          if (hasNotes) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: brandColor, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.messageSquare, size: 15, color: brandColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      approverNotes!.trim(),
                      style: AppTypography.bodySmall.copyWith(
                        color: textCol,
                        fontStyle: FontStyle.italic,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
