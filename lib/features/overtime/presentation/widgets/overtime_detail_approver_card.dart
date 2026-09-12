import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Card 3: Assigned Approver Information
/// Sesuai spesifikasi Stitch M3: "Section 3: Approver Card"
class OvertimeDetailApproverCard extends StatelessWidget {
  final OvertimeEmployeeModel approver;

  const OvertimeDetailApproverCard({super.key, required this.approver});

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

    final posName = approver.position?.name ?? '';
    final compName = approver.company?.name ?? '';
    final roleCompText = [
      if (posName.isNotEmpty) posName,
      if (compName.isNotEmpty) compName,
    ].join(', ');

    final contactText = (approver.email != null && approver.email!.isNotEmpty)
        ? approver.email!
        : (approver.phone != null && approver.phone!.isNotEmpty)
            ? approver.phone!
            : '';

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
                imageUrl: resolveFileUrl(approver.photoUrl),
                size: 48,
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
                        fontSize: 15.5,
                      ),
                    ),
                    if (roleCompText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleCompText,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (contactText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contactText,
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
