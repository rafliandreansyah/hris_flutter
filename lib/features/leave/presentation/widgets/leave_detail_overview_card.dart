import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card Status Banner & Overview sesuai desain Google Stitch:
/// - Badge jenis cuti (mint/teal light)
/// - Badge status cuti (Pending / Approved / Rejected)
/// - Ikon kalender + Rentang tanggal (misal: "28 Agustus 2026")
/// - Badge durasi hari kerja (misal: "1 Work Day(s)")
/// - Pembatas & Bagian "REASON"
class LeaveDetailOverviewCard extends StatelessWidget {
  final LeaveRequestDetailData detail;

  const LeaveDetailOverviewCard({super.key, required this.detail});

  Widget _buildStatusBadge(BuildContext context) {
    if (detail.isApproved) {
      return const AppStatusChip(label: 'Approved', tone: AppStatusTone.success);
    }
    if (detail.isRejected) {
      return const AppStatusChip(label: 'Rejected', tone: AppStatusTone.error);
    }
    return const AppStatusChip(
      label: 'Pending Approval',
      tone: AppStatusTone.warning,
    );
  }

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

    final leaveTypeName = detail.leaveType.name.isNotEmpty
        ? detail.leaveType.name
        : 'Leave Request';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
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
          // ── Row 1: Leave Type Pill & Status Badge ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF004D44)
                      : AppColors.accentTealLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  leaveTypeName,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.secondaryContainer
                        : AppColors.primaryHover,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),

          const SizedBox(height: 16),

          // ── Row 2: Calendar icon + Formatted Date ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendarDays,
                color: subtitleCol,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail.formattedDateRange,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 3: Work days count badge ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceBright
                  : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              detail.durationLabel,
              style: TextStyle(
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.darkSurfaceContainerHigh,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Divider ───────────────────────────────────────────────────
          Divider(color: borderCol, height: 1, thickness: 1),

          const SizedBox(height: 14),

          // ── Reason Section ────────────────────────────────────────────
          Text(
            'REASON',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (detail.notes != null && detail.notes!.trim().isNotEmpty)
                ? detail.notes!.trim()
                : 'Tidak ada catatan alasan yang dilampirkan.',
            style: AppTypography.bodyMedium.copyWith(
              color: (detail.notes != null && detail.notes!.trim().isNotEmpty)
                  ? textCol
                  : subtitleCol,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
