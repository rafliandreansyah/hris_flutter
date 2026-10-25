import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_status_chip.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu ringkasan detail pengajuan cuti/izin:
/// - Header: jenis cuti + ikon status
/// - Daftar berlabel: tanggal mulai, tanggal selesai, durasi
/// - Bagian alasan
class LeaveDetailOverviewCard extends StatelessWidget {
  final LeaveRequestDetailData detail;

  const LeaveDetailOverviewCard({super.key, required this.detail});

  Widget _buildStatusIcon() {
    if (detail.isApproved) {
      return const AppStatusIcon(label: 'Disetujui', tone: AppStatusTone.success);
    }
    if (detail.isRejected) {
      return const AppStatusIcon(label: 'Ditolak', tone: AppStatusTone.error);
    }
    return const AppStatusIcon(
      label: 'Menunggu Persetujuan',
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
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final leaveTypeName =
        detail.leaveType.name.isNotEmpty ? detail.leaveType.name : 'Cuti / Izin';
    final hasNotes = detail.notes != null && detail.notes!.trim().isNotEmpty;

    final rows = <(IconData, String, String)>[
      (LucideIcons.calendarDays, 'Tanggal Mulai', detail.formattedStartDate),
      (LucideIcons.calendarCheck, 'Tanggal Selesai', detail.formattedEndDate),
      (LucideIcons.hourglass, 'Durasi', detail.durationLabel),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: jenis cuti + status ───────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderInput,
                ),
                child: Icon(LucideIcons.calendarClock, size: 20, color: brandColor),
              ),
              const SizedBox(width: AppSpacing.md - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Cuti / Izin',
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      leaveTypeName,
                      style: AppTypography.titleMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildStatusIcon(),
            ],
          ),
          const SizedBox(height: AppSpacing.md - 2),
          Divider(color: borderCol, height: 1, thickness: 1),

          // ── Daftar tanggal & durasi ───────────────────────────────────
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Icon(r.$1, size: 18, color: subtitleCol),
                  const SizedBox(width: AppSpacing.md - 4),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: AppTypography.bodyMedium.copyWith(
                        color: subtitleCol,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      r.$3,
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Divider(color: borderCol, height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.md - 2),

          // ── Alasan ────────────────────────────────────────────────────
          Text(
            'ALASAN',
            style: AppTypography.labelSmall.copyWith(
              color: subtitleCol,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            hasNotes
                ? detail.notes!.trim()
                : 'Tidak ada alasan yang dilampirkan.',
            style: AppTypography.bodyMedium.copyWith(
              color: hasNotes ? textCol : subtitleCol,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
