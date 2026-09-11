import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Approver ("ASSIGNED APPROVER") sesuai desain Stitch:
/// - Hanya dirender jika approver != null (sembunyi otomatis jika null).
/// - Avatar, Nama Approver, Posisi (Departemen)
/// - Menampilkan catatan/alasan dari approver jika tersedia.
class LeaveDetailApproverCard extends StatelessWidget {
  final LeaveApproverDetailModel approver;
  final String? approverNotes;

  const LeaveDetailApproverCard({
    super.key,
    required this.approver,
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

    final posName = approver.position?.name ?? '';
    final deptName = approver.department?.name ?? '';
    String roleDeptText = '';
    if (posName.isNotEmpty && deptName.isNotEmpty) {
      roleDeptText = '$posName ($deptName)';
    } else if (posName.isNotEmpty) {
      roleDeptText = posName;
    } else if (deptName.isNotEmpty) {
      roleDeptText = deptName;
    }

    final hasNotes = approverNotes != null && approverNotes!.trim().isNotEmpty;

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
            'ASSIGNED APPROVER',
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
                name: approver.fullName,
                initials: approver.initials,
                imageUrl: approver.resolvedAvatarUrl,
                size: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approver.fullName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 15,
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
                  ],
                ),
              ),
            ],
          ),
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
