import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_date_util.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
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

  Widget _buildStatusBadge(ExpenseStatus status) =>
      AppStatusIcon(
        label: status.label,
        tone: status.tone,
        icon: status.icon,
        size: 30,
      );

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
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final parsedStatus = parseExpenseStatus(item.status);
    final createdAt = AppDateUtil.tryParseDateTime(item.createdAt);
    final dateLabel = createdAt != null
        ? AppDateUtil.formatDateShort(createdAt)
        : item.createdAt;

    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeBadge(item.isReimbursement),
              const SizedBox(height: AppSpacing.sm - 2),
              Text(
                item.title,
                style: AppTypography.titleMedium.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!isTeam) ...[
          const SizedBox(width: AppSpacing.sm),
          _buildStatusBadge(parsedStatus),
        ],
      ],
    );

    final amountRow = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.approvedAmount != null
                    ? 'Nominal Disetujui'
                    : 'Nominal Diajukan',
                style: AppTypography.labelSmall.copyWith(
                  color: subtitleCol,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatRupiah(item.approvedAmount ?? item.requestedAmount),
                style: AppTypography.titleMedium.copyWith(
                  color: brandCol,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          item.itemsCount > 0 ? '$dateLabel • ${item.itemsCount} nota' : dateLabel,
          style: AppTypography.labelSmall.copyWith(
            color: subtitleCol,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
      child: RequestListCardFrame(
        onTap: onTap,
        header: isTeam
            ? RequestCardHeader(
                name: item.employee.fullName,
                role: item.employee.jobPosition,
                department: item.employee.department,
                avatarUrl: item.employee.resolvedPhotoUrl,
                trailing: _buildStatusBadge(parsedStatus),
              )
            : titleRow,
        children: [
          if (isTeam) ...[
            titleRow,
            const SizedBox(height: AppSpacing.md - 4),
          ],
          amountRow,
        ],
      ),
    );
  }
}
