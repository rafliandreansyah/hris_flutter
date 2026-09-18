import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card 1: Overview & Status Card
/// Sesuai spesifikasi Google Stitch Screen ID: `c0c581134c61461a8585cf77a66f1dd7`.
class AttendanceRequestOverviewCard extends StatelessWidget {
  final AttendanceRequestDetailData detail;

  const AttendanceRequestOverviewCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF64748B);
    final borderCol =
        isDark ? AppColors.darkOutlineMuted : const Color(0xFFE2E8F0);
    final innerBoxBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : const Color(0xFFF8FAFC);

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris 1: Kategori Presensi & Status Badge ───────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryContainer.withValues(alpha: 0.15)
                      : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Presensi Luar Kantor',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.inversePrimary
                        : const Color(0xFF115E59),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildStatusPill(isDark),
            ],
          ),
          const SizedBox(height: 14),

          // ── Tanggal Utama ──────────────────────────────────────────
          Text(
            detail.formattedDate,
            style: AppTypography.titleMedium.copyWith(
              color: textCol,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),

          // ── Method & Type Chips ─────────────────────────────────────
          Row(
            children: [
              _buildIconChip(
                icon: detail.isPhotoMethod
                    ? LucideIcons.camera
                    : LucideIcons.smartphone,
                label: detail.method.toUpperCase(),
                subtitleCol: subtitleCol,
              ),
              const SizedBox(width: 14),
              _buildIconChip(
                icon: detail.isIn ? LucideIcons.logIn : LucideIcons.logOut,
                label: detail.attendanceTypeBadge,
                subtitleCol: subtitleCol,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Grid Jam Masuk & Pulang ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: innerBoxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderCol.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masuk',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail.formattedInTime,
                        style: AppTypography.titleMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: borderCol.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pulang',
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleCol,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail.formattedOutTime,
                        style: AppTypography.titleMedium.copyWith(
                          color: detail.attendanceOutTime != null
                              ? textCol
                              : subtitleCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Alasan / Keperluan ─────────────────────────────────────
          Text(
            'ALASAN / KEPERLUAN',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (detail.reason != null && detail.reason!.trim().isNotEmpty)
                ? detail.reason!.trim()
                : '-',
            style: AppTypography.bodyMedium.copyWith(
              color: textCol,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),

          // ── Catatan Approver (jika ada) ────────────────────────────
          if (detail.approverNote != null &&
              detail.approverNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'CATATAN APPROVER',
              style: AppTypography.labelSmall.copyWith(
                color: subtitleCol,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.approverNote!.trim(),
              style: AppTypography.bodyMedium.copyWith(
                color: detail.isRejected ? const Color(0xFFEF4444) : textCol,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: borderCol.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),

          // ── Footer: Diajukan & Zona Waktu ──────────────────────────
          Text(
            detail.formattedSubmittedInfo,
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required String label,
    required Color subtitleCol,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: subtitleCol),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: subtitleCol,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool isDark) {
    Color bg;
    Color fg;
    String text;

    if (detail.isApproved) {
      bg = isDark
          ? const Color(0xFF0F766E).withValues(alpha: 0.25)
          : const Color(0xFFCCFBF1);
      fg = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      text = 'Disetujui';
    } else if (detail.isRejected) {
      bg = isDark
          ? const Color(0xFF991B1B).withValues(alpha: 0.25)
          : const Color(0xFFFEE2E2);
      fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
      text = 'Ditolak';
    } else {
      bg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.25)
          : const Color(0xFFFEF3C7);
      fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
      text = 'Menunggu Persetujuan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
