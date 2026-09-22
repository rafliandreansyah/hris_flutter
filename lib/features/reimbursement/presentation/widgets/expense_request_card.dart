import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';
import 'package:hris_flutter/features/reimbursement/presentation/models/expense_item_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExpenseRequestCard extends StatelessWidget {
  final ExpenseFeedItemModel item;
  final bool isTeam;
  final VoidCallback? onTap;

  const ExpenseRequestCard({
    super.key,
    required this.item,
    bool isTeam = false,
    bool? isTeamTab,
    this.onTap,
  }) : isTeam = isTeamTab ?? isTeam;

  Widget _buildStatusBadge(ExpenseStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(bool isReimbursement) {
    final bgColor = isReimbursement
        ? const Color(0xFFEFF6FF) // Blue 50
        : const Color(0xFFFAF5FF); // Purple 50
    final textColor = isReimbursement
        ? const Color(0xFF1D4ED8) // Blue 700
        : const Color(0xFF7E22CE); // Purple 700
    final icon = isReimbursement
        ? LucideIcons.receipt
        : LucideIcons.handCoins;
    final label = isReimbursement ? 'Reimbursement' : 'Kasbon';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtleBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final parsedStatus = parseExpenseStatus(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Employee info (jika tab Team) atau Header Baris Pengajuan
                if (isTeam) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: EmployeeInfoRow(
                          name: item.employee.fullName,
                          role: item.employee.jobPosition ??
                              item.employee.department ??
                              '-',
                          avatarUrl: item.employee.resolvedPhotoUrl,
                          avatarSize: 34,
                        ),
                      ),
                      _buildStatusBadge(parsedStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 12),
                ],

                // Baris Badge Tipe & No Referensi
                Row(
                  children: [
                    _buildTypeBadge(item.isReimbursement),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.referenceNumber,
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isTeam) _buildStatusBadge(parsedStatus),
                  ],
                ),
                const SizedBox(height: 10),

                // Judul Pengeluaran
                Text(
                  item.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textCol,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleCol,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Card Nominal & Waktu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: subtleBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.approvedAmount != null
                                  ? 'Nominal Disetujui'
                                  : 'Nominal Diajukan',
                              style: TextStyle(
                                color: subtitleCol,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRupiah(
                                item.approvedAmount ?? item.requestedAmount,
                              ),
                              style: TextStyle(
                                color: brandCol,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.itemsCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.receipt,
                                size: 12,
                                color: subtitleCol,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.itemsCount} nota',
                                style: TextStyle(
                                  color: subtitleCol,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer: Tanggal & Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 13,
                          color: subtitleCol,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppDateUtil.tryParseDateTime(item.createdAt) != null
                              ? AppDateUtil.formatDateShort(
                                  AppDateUtil.tryParseDateTime(item.createdAt)!,
                                )
                              : item.createdAt,
                          style: TextStyle(
                            color: subtitleCol,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Detail',
                          style: TextStyle(
                            color: brandCol,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: brandCol,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
