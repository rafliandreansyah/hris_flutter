import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/currency_util.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/payroll/data/models/payroll_slip_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PayrollSlipCard extends StatelessWidget {
  final PayrollSlipModel slip;
  final bool isPrivacyMasked;
  final bool isTeamCard;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const PayrollSlipCard({
    super.key,
    required this.slip,
    this.isPrivacyMasked = true,
    this.isTeamCard = false,
    required this.onTap,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.surfaceContainerLowest;
    final borderColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.5);
    final subtleBg = isDark
        ? AppColors.darkBackgroundSubtle
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    const brandCol = AppColors.brandTeal;

    final isPaid = slip.status.toLowerCase() == 'paid';
    final isApproved = slip.status.toLowerCase() == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Period title & Status pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: brandCol.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.fileSpreadsheet,
                            size: 16,
                            color: brandCol,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          slip.period.label.isNotEmpty
                              ? slip.period.label
                              : 'Slip Gaji',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textCol,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusPill(isPaid, isApproved),
                  ],
                ),

                // 2. If in Team tab, display EmployeeInfoRow with divider
                if (isTeamCard) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 12),
                  EmployeeInfoRow(
                    name: slip.employee.fullName,
                    role: slip.employee.position,
                    department: slip.employee.department,
                    employeeId: slip.employee.employeeNumber,
                    avatarUrl: slip.employee.resolvedPhotoUrl,
                    avatarSize: 36,
                  ),
                ],

                const SizedBox(height: 12),

                // 3. Dedicated Financial Summary Box (Lega & Tidak Sempit)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: subtleBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take Home Pay (Gaji Bersih)',
                        style: TextStyle(
                          color: subtitleCol,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPrivacyMasked
                            ? 'Rp ••••••••••'
                            : formatRupiah(slip.netSalary),
                        style: const TextStyle(
                          color: brandCol,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (slip.grossSalary > 0 ||
                          slip.deductions > 0 ||
                          slip.basicSalary > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (slip.grossSalary > 0) ...[
                              Text(
                                isPrivacyMasked
                                    ? 'Kotor: Rp •••••••'
                                    : 'Kotor: ${formatRupiah(slip.grossSalary)}',
                                style: TextStyle(
                                  color: subtitleCol,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (slip.grossSalary > 0 &&
                                slip.deductions > 0) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  color: subtitleCol,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            if (slip.deductions > 0) ...[
                              Text(
                                isPrivacyMasked
                                    ? 'Potongan: Rp •••••••'
                                    : 'Potongan: -${formatRupiah(slip.deductions)}',
                                style: const TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Footer Bar: Pay Date (left) and Action Buttons (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (slip.period.payDate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendarCheck,
                            size: 13,
                            color: subtitleCol,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Gajian: ${slip.period.payDate}',
                            style: TextStyle(
                              color: subtitleCol,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (onDownload != null) ...[
                          InkWell(
                            onTap: onDownload,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.download,
                                    size: 14,
                                    color: brandCol,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Unduh',
                                    style: TextStyle(
                                      color: brandCol,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Row(
                          children: [
                            Text(
                              'Lihat Detail',
                              style: TextStyle(
                                color: brandCol,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isPaid, bool isApproved) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (isPaid) {
      bg = AppColors.successContainer;
      fg = AppColors.onSuccessContainer;
      label = 'Dibayar';
      icon = LucideIcons.checkCheck;
    } else if (isApproved) {
      bg = AppColors.primaryContainer;
      fg = AppColors.onPrimaryContainer;
      label = 'Disetujui';
      icon = LucideIcons.badgeCheck;
    } else {
      bg = AppColors.surfaceContainer;
      fg = AppColors.onSurfaceVariant;
      label = slip.status.toUpperCase();
      icon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
