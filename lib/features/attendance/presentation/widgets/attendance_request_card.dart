import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card item pengajuan presensi luar kantor
/// (Google Stitch Screen ID: `2175015883474c6db43079587a17dccb`).
class AttendanceRequestCard extends StatelessWidget {
  final AttendanceRequestItem item;
  final VoidCallback? onTap;

  const AttendanceRequestCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final textCol = isDark ? AppColors.darkOnSurface : const Color(0xFF0F172A);
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : const Color(0xFF64748B);
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : const Color(0xFFE2E8F0);
    final innerBoxBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : const Color(0xFFF8FAFC);
    final brandColor = isDark
        ? AppColors.inversePrimary
        : const Color(0xFF0D9488);

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
              // ── Header: Info Pegawai (via EmployeeInfoRow) + Badge Status ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.isSelf)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 13,
                                  color: brandColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Your request',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: brandColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        EmployeeInfoRow(
                          name: item.name,
                          role: item.role,
                          department: item.department,
                          company: item.company.isNotEmpty ? item.company : null,
                          employeeId: item.employeeNumber,
                          avatarUrl: item.avatarUrl,
                          initials: item.initials,
                          avatarSize: 42,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  _buildStatusBadge(status),
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
                    // Baris 1: Tanggal & Badge Tipe
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
                        if (item.attendanceTypeBadge.isNotEmpty)
                          _buildTypeBadge(item, isDark),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Baris 2: Jam Kerja / Jam Presensi
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 15, color: subtitleCol),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(AttendanceRequestItem item, bool isDark) {
    Color bg;
    Color fg;
    Color border;

    if (item.isInOut) {
      bg = isDark
          ? const Color(0xFF312E81).withValues(alpha: 0.35)
          : const Color(0xFFEEF2FF);
      fg = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
      border = isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE);
    } else if (item.isOut) {
      bg = isDark
          ? const Color(0xFF7C2D12).withValues(alpha: 0.35)
          : const Color(0xFFFFF7ED);
      fg = isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C);
      border = isDark ? const Color(0xFF9A3412) : const Color(0xFFFED7AA);
    } else {
      bg = isDark
          ? const Color(0xFF134E4A).withValues(alpha: 0.35)
          : const Color(0xFFF0FDFA);
      fg = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
      border = isDark ? const Color(0xFF115E59) : const Color(0xFFCCFBF1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        item.attendanceTypeBadge,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceRequestStatus status) {
    return Container(
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
    );
  }
}
