import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/core/constants/app_permissions.dart';
import 'package:hris_flutter/core/storage/secure_storage_service.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
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
    final fmt = DateFormat('d MMM yyyy');
    final submittedDateStr =
        item.submittedDate != null ? fmt.format(item.submittedDate!) : '-';
    final effectiveDateStr =
        item.effectiveDate != null ? fmt.format(item.effectiveDate!) : '-';

    final isPending = item.status.toLowerCase() == 'submitted';
    final canReview = isPending &&
        SecureStorageService.instance.hasPermissionInMemory(
          AppPermissions.approvalResignationManager,
        );
    final (statusLabel, statusTone) = _resolveStatus(item.status);

    return RequestListCardFrame(
      // Seluruh kartu dapat diketuk untuk membuka detail.
      onTap: onDetailPressed,
      header: RequestCardHeader(
        name: item.employeeName,
        role: item.positionName,
        department: item.departmentName,
        avatarUrl: item.avatarUrl,
        trailing: AppStatusIcon(label: statusLabel, tone: statusTone, size: 30),
      ),
      children: [
        RequestCardInfoLine(
          icon: LucideIcons.calendarDays,
          text: 'Efektif $effectiveDateStr',
          emphasize: true,
          trailingText: '${item.actualNoticePeriodDays} hari',
        ),
        const SizedBox(height: AppSpacing.sm),
        RequestCardInfoLine(
          icon: LucideIcons.send,
          text: 'Diajukan $submittedDateStr',
        ),
        if (item.isEarlyNotice) ...[
          const SizedBox(height: AppSpacing.sm),
          const RequestCardInfoLine(
            icon: LucideIcons.triangleAlert,
            text: 'Pemberitahuan dini',
          ),
        ],
        if (item.reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          RequestCardNote(text: item.reason),
        ],
        if (canReview) ...[
          const SizedBox(height: AppSpacing.md - 4),
          AppButton(
            text: 'Review 1-on-1',
            leadingIcon: LucideIcons.messageSquareCheck,
            variant: AppButtonVariant.primary,
            height: 40,
            onPressed: onReviewPressed,
          ),
        ],
      ],
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
