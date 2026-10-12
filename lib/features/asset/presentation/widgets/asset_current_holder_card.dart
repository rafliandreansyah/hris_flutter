import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Pemegang Fasilitas Saat Ini atau Status Penyimpanan Gudang
class AssetCurrentHolderCard extends StatelessWidget {
  final AssetDetailData asset;

  const AssetCurrentHolderCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : AppColors.outlineMuted;

    final active = asset.activeAssignment;

    if (active != null && active.employee != null) {
      final employee = active.employee!;
      final dateFormat = DateFormat('dd MMM yyyy');

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.userCheck,
                  size: 16,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  'PEMEGANG FASILITAS SAAT INI',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            EmployeeInfoRow(
              name: employee.fullName,
              employeeId: employee.employeeNumber ?? '-',
              initials: employee.initials,
              avatarSize: 44,
            ),
            if (active.assignedDate != null) ...[
              const SizedBox(height: AppSpacing.sm + 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackgroundSubtle
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: AppColors.brandTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Diserahterimakan sejak: ${dateFormat.format(active.assignedDate!)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11,
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

    // Jika sedang berada di gudang pool
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.warehouse,
                size: 16,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              Text(
                'STATUS PENYIMPANAN GUDANG',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.boxes,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit Tersedia di Pool / Gudang',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.location ?? 'Gudang Inventaris Utama',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtitleCol,
                        fontSize: 12,
                      ),
                    ),
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
