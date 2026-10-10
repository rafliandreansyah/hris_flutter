import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Approver ("PEJABAT PENYETUJU") sesuai standar Stitch M3:
/// - Menggunakan EmployeeInfoRow standar global.
/// - Menampilkan catatan/alasan dari approver jika tersedia.
/// - Sesuai dengan spesifikasi LeaveDetailApproverCard & OvertimeDetailApproverCard.
class ExpenseDetailApproverCard extends StatelessWidget {
  final ExpenseEmployeeModel? approver;
  final String? approverNotes;
  final String? rejectionReason;

  const ExpenseDetailApproverCard({
    super.key,
    this.approver,
    this.approverNotes,
    this.rejectionReason,
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

    final isRejected =
        rejectionReason != null && rejectionReason!.trim().isNotEmpty;
    final noteText = (isRejected ? rejectionReason : approverNotes)?.trim();
    final hasNotes = noteText != null && noteText.isNotEmpty;
    final noteColor = isRejected ? const Color(0xFFEF4444) : brandColor;

    final app = approver;
    final empNo = app?.displayEmployeeNumber;

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
          if (app != null) ...[
            EmployeeInfoRow(
              name: app.fullName.isNotEmpty ? app.fullName : 'Approver',
              role: app.position ?? app.jobPosition ?? '',
              department: app.department ?? '',
              company: app.company,
              employeeId: empNo,
              avatarUrl: app.resolvedPhotoUrl,
              initials: app.initials,
              avatarSize: 44,
            ),
          ] else ...[
            Text(
              'Belum ada data profil approver.',
              style: AppTypography.bodySmall.copyWith(color: subtitleCol),
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
                  left: BorderSide(color: noteColor, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isRejected
                        ? LucideIcons.alertTriangle
                        : LucideIcons.messageSquare,
                    size: 15,
                    color: noteColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      noteText,
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
