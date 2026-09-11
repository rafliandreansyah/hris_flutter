import 'package:flutter/material.dart';
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
    Color bg;
    Color text;
    Color dot;
    String label;

    if (detail.isApproved) {
      bg = const Color(0xFFDCFCE7); // Green 100
      text = const Color(0xFF166534); // Green 800
      dot = const Color(0xFF16A34A); // Green 600
      label = 'Approved';
    } else if (detail.isRejected) {
      bg = const Color(0xFFFEE2E2); // Red 100
      text = const Color(0xFF991B1B); // Red 800
      dot = const Color(0xFFEF4444); // Red 500
      label = 'Rejected';
    } else {
      bg = const Color(0xFFFEF3C7); // Amber 100
      text = const Color(0xFFD97706); // Amber 600
      dot = const Color(0xFFD97706);
      label = 'Pending Approval';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
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
                      : const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  leaveTypeName,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF6DF5E1)
                        : const Color(0xFF0F766E),
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
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              detail.durationLabel,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
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
