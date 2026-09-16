import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card item pengajuan presensi luar kantor
/// (Google Stitch Screen ID: `2175015883474c6db43079587a17dccb`).
class AttendanceRequestCard extends StatelessWidget {
  final AttendanceRequestItem item;
  final VoidCallback? onTap;

  const AttendanceRequestCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
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
    final brandColor =
        isDark ? AppColors.inversePrimary : const Color(0xFF0D9488);

    final status = item.status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceCol,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar + Info Pegawai + Badge Status ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(isDark, brandColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.titleMedium.copyWith(
                            color: textCol,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.role.isNotEmpty
                              ? item.role
                              : (item.department.isNotEmpty
                                  ? item.department
                                  : 'Pegawai'),
                          style: AppTypography.labelMedium.copyWith(
                            color: subtitleCol,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(width: 6),
                        Text(
                          status.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: status.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Kotak Informasi Presensi (Inner Box) ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: innerBoxBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderCol.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris 1: Tanggal
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 15,
                          color: subtitleCol,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.formattedDate,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textCol,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Baris 2: Jam Kerja
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 15,
                          color: subtitleCol,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.formattedWorkHours,
                            style: AppTypography.bodySmall.copyWith(
                              color: subtitleCol,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Baris 3: Catatan / Alasan (jika ada)
                    if (item.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 23),
                        child: Text(
                          '"${item.notes.trim()}"',
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleCol,
                            fontStyle: FontStyle.italic,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Footer: Waktu Pengajuan & Action Link ────────────────
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedSubmittedAt,
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleCol,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tinjau Pengajuan',
                          style: AppTypography.bodySmall.copyWith(
                            color: brandColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: brandColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, Color brandColor) {
    if (item.avatarUrl != null && item.avatarUrl!.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          item.avatarUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatar(isDark, brandColor),
        ),
      );
    }
    return _buildFallbackAvatar(isDark, brandColor);
  }

  Widget _buildFallbackAvatar(bool isDark, Color brandColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkPrimaryContainer
            : const Color(0xFFF0FDFA),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkOutlineMuted : const Color(0xFFCCFBF1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          item.initials,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: brandColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
