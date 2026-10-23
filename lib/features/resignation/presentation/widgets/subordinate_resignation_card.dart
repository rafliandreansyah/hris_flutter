import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/resignation/data/models/subordinate_resignation_model.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SubordinateResignationCard extends StatelessWidget {
  final SubordinateResignationItemModel item;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onDetailPressed;

  const SubordinateResignationCard({
    super.key,
    required this.item,
    this.onReviewPressed,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandCol = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final effectiveDateStr = item.effectiveDate != null
        ? DateFormat('d MMM yyyy').format(item.effectiveDate!)
        : '-';

    final submittedDateStr = item.submittedDate != null
        ? DateFormat('d MMM yyyy').format(item.submittedDate!)
        : '-';

    final isPending = item.status.toLowerCase() == 'submitted';

    final (statusLabel, statusTone) = _resolveStatus(item.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Employee Info Row Standard (AGENTS.md Rule 14)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EmployeeInfoRow(
                  name: item.employeeName,
                  role: item.positionName,
                  department: item.departmentName,
                  employeeId: item.employeeNik,
                  avatarUrl: item.avatarUrl,
                  avatarSize: 42,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusChip(label: statusLabel, tone: statusTone),
            ],
          ),
          const SizedBox(height: 14),

          // Divider
          Divider(color: borderCol.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),

          // Dates & Notice Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tgl Pengajuan',
                      style: TextStyle(fontSize: 11, color: subtitleCol),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      submittedDateStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Efektif',
                      style: TextStyle(fontSize: 11, color: subtitleCol),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      effectiveDateStr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: brandCol,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.isEarlyNotice
                      ? (isDark
                          ? const Color(0xFF78350F)
                          : AppColors.warningContainer)
                      : (isDark
                          ? const Color(0xFF134E4A)
                          : AppColors.accentTealLight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isEarlyNotice
                      ? 'Early Notice (${item.actualNoticePeriodDays} Hari)'
                      : '${item.actualNoticePeriodDays} Hari (Normal)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.isEarlyNotice
                        ? (isDark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97706))
                        : (isDark
                            ? const Color(0xFF5EEAD4)
                            : AppColors.primaryHover),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason Notes
          if (item.reason.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleCol,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Handover To
          if (item.handoverToName != null &&
              item.handoverToName!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.arrowLeftRight,
                  size: 13,
                  color: subtitleCol,
                ),
                const SizedBox(width: 6),
                Text(
                  'Handover ke: ',
                  style: TextStyle(fontSize: 11.5, color: subtitleCol),
                ),
                Expanded(
                  child: Text(
                    item.handoverToName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textCol,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons
          Row(
            children: [
              if (isPending &&
                  SecureStorageService.instance.hasPermissionInMemory(
                      AppPermissions.approvalResignationManager)) ...[
                Expanded(
                  child: AppButton(
                    text: 'Review 1-on-1',
                    leadingIcon: LucideIcons.messageSquareCheck,
                    variant: AppButtonVariant.primary,
                    height: 40,
                    onPressed: onReviewPressed,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppButton(
                  text: 'Lihat Detail',
                  leadingIcon: LucideIcons.eye,
                  variant: AppButtonVariant.outlined,
                  height: 40,
                  onPressed: onDetailPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, AppStatusTone) _resolveStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return ('Menunggu 1-on-1', AppStatusTone.warning);
      case 'manager_approved':
        return ('Disetujui Manajer', AppStatusTone.info);
      case 'hr_approved':
      case 'in_clearance':
        return ('Clearance Offboarding', AppStatusTone.info);
      case 'settled':
        return ('Selesai & Paklaring', AppStatusTone.success);
      case 'rejected':
        return ('Ditolak', AppStatusTone.error);
      default:
        return (status, AppStatusTone.neutral);
    }
  }
}
