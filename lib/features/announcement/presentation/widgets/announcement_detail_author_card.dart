import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_avatar.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';

/// Kartu "PUBLISHED BY" (Penerbit Pengumuman) sesuai Google Stitch M3.
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
    final titleCol = isDark ? AppColors.darkOnSurface : AppColors.textPrimary;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.textSecondary;
    final captionCol = isDark ? AppColors.darkOutline : AppColors.outline;

    final posAndDept = author.positionAndDeptLabel;
    final compAndEmp = author.companyAndEmpNoLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PUBLISHED BY',
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: author.photoUrl,
                name: author.fullName,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.fullName,
                      style: AppTypography.titleSmall.copyWith(
                        color: titleCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (posAndDept.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        posAndDept,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleCol,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (compAndEmp.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        compAndEmp,
                        style: AppTypography.labelSmall.copyWith(
                          color: captionCol,
                          fontSize: 11.5,
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
        ),
      ],
    );
  }
}
