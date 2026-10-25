import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/asset/data/models/asset_detail_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu Riwayat Serah Terima & Silsilah Kepemilikan (Chain of Custody Timeline)
class AssetHandoverTimelineCard extends StatelessWidget {
  final List<AssetAssignmentItemModel> assignments;

  const AssetHandoverTimelineCard({
    super.key,
    required this.assignments,
  });

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
                LucideIcons.history,
                size: 16,
                color: AppColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                'SILSILAH KEPEMILIKAN (CHAIN OF CUSTODY)',
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

          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada riwayat serah terima untuk unit aset ini.',
                  style: AppTypography.bodySmall.copyWith(
                    color: subtitleCol,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final item = assignments[index];
                final isLast = index == assignments.length - 1;
                return _buildTimelineNode(
                  context,
                  item: item,
                  isLast: isLast,
                  textCol: textCol,
                  subtitleCol: subtitleCol,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required AssetAssignmentItemModel item,
    required bool isLast,
    required Color textCol,
    required Color subtitleCol,
    required bool isDark,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = item.assignedDate != null
        ? dateFormat.format(item.assignedDate!)
        : (item.createdAt != null ? dateFormat.format(item.createdAt!) : '-');

    Color nodeColor;
    Color nodeBg;
    IconData nodeIcon;

    switch (item.status) {
      case 'ACTIVE':
        nodeColor = AppColors.success;
        nodeBg = AppColors.successContainer;
        nodeIcon = LucideIcons.check;
        break;
      case 'PENDING_ACCEPTANCE':
        nodeColor = AppColors.warning;
        nodeBg = AppColors.warningContainer;
        nodeIcon = LucideIcons.clock;
        break;
      case 'RETURNED':
        nodeColor = AppColors.surfaceVariant;
        nodeBg = AppColors.darkOnBackground;
        nodeIcon = LucideIcons.rotateCcw;
        break;
      case 'REJECTED':
        nodeColor = AppColors.errorRed;
        nodeBg = const Color(0xFFFEE2E2);
        nodeIcon = LucideIcons.x;
        break;
      default:
        nodeColor = AppColors.brandTeal;
        nodeBg = AppColors.primaryContainer;
        nodeIcon = LucideIcons.circle;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Indicator Line & Dot
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(nodeIcon, size: 12, color: nodeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.darkOnBackground,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),

          // Content Box
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackgroundSubtle
                      : AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineMuted
                        : AppColors.darkOnBackground,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(item.status),
                        Text(
                          formattedDate,
                          style: AppTypography.labelSmall.copyWith(
                            color: subtitleCol,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.employee?.fullName ?? 'Karyawan',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                        fontSize: 13,
                      ),
                    ),
                    if (item.employee?.employeeNumber != null)
                      Text(
                        'No. Pegawai: ${item.employee!.employeeNumber}',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11,
                        ),
                      ),
                    if (item.transferredFrom?.employee != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.arrowRightLeft,
                            size: 12,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Dialihkan dari: ${item.transferredFrom!.employee!.fullName}',
                              style: AppTypography.bodySmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.checkoutNotes != null &&
                        item.checkoutNotes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Catatan: "${item.checkoutNotes!.trim()}"',
                        style: AppTypography.bodySmall.copyWith(
                          color: textCol,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (item.rejectionReason != null &&
                        item.rejectionReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Alasan Penolakan: "${item.rejectionReason!.trim()}"',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.errorRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'ACTIVE':
        return const AppStatusChip(
          label: 'Sedang Dipegang',
          tone: AppStatusTone.success,
        );
      case 'PENDING_ACCEPTANCE':
        return const AppStatusChip(
          label: 'Menunggu Konfirmasi',
          tone: AppStatusTone.warning,
        );
      case 'RETURNED':
        return const AppStatusChip(
          label: 'Telah Dialihkan / Kembali',
          tone: AppStatusTone.neutral,
        );
      case 'REJECTED':
        return const AppStatusChip(
          label: 'Ditolak',
          tone: AppStatusTone.error,
        );
      default:
        return AppStatusChip(label: status, tone: AppStatusTone.info);
    }
  }
}
