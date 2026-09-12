import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/overtime/data/models/overtime_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 1: Schedule Highlight & Status Overview
/// Sesuai dengan spesifikasi Google Stitch: "Section 1: Schedule Highlight"
class OvertimeDetailOverviewCard extends StatelessWidget {
  final OvertimeDetailData detail;

  const OvertimeDetailOverviewCard({super.key, required this.detail});

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

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Chips: Shift Pill & Status Pill ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Overtime Shift Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clockAlert,
                      size: 15,
                      color: isDark
                          ? AppColors.inversePrimary
                          : AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Overtime Shift',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.inversePrimary
                            : AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill (Pending Approval / Approved / Rejected)
              _buildStatusPill(isDark),
            ],
          ),
          const SizedBox(height: 16),

          // ── Big Date Display ──────────────────────────────────────────
          Text(
            detail.formattedDate,
            style: AppTypography.headlineLargeMobile.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textCol,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // ── Time Range & Duration Badge ───────────────────────────────
          Row(
            children: [
              Text(
                detail.formattedTimeRange,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.durationHoursLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : const Color(0xFF131B2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Employee Notes Box ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMPLOYEE NOTES',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleCol,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (detail.notes != null && detail.notes!.trim().isNotEmpty)
                      ? '"${detail.notes!.trim()}"'
                      : 'Tidak ada catatan dari karyawan.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: (detail.notes != null && detail.notes!.trim().isNotEmpty)
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: textCol,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Approver Notes Box (if available) ─────────────────────────
          if (detail.approverNotes != null &&
              detail.approverNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPROVER NOTES',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtitleCol,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${detail.approverNotes!.trim()}"',
                    style: AppTypography.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: textCol,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Footer: Submitted at & Timezone ───────────────────────────
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderCol)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.history, size: 14, color: subtitleCol),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Submitted at ${detail.formattedCreatedAt}',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12,
                          color: subtitleCol,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.globe, size: 14, color: subtitleCol),
                    const SizedBox(width: 6),
                    Text(
                      'Timezone: ${detail.timezone ?? 'WIB'}',
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 12,
                        color: subtitleCol,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool isDark) {
    if (detail.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 13, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text(
              'Approved',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (detail.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.x, size: 13, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Rejected',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Default: Pending Approval (status 'requested')
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Pending Approval',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
