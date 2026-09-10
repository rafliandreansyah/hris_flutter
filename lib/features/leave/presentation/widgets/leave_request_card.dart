import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card permintaan cuti/izin pada halaman "Team Requests".
///
/// Presentasi-only: menerima [LeaveRequestItem] sudah jadi (sumber data
/// dari BLoC) dan meng-emit callback [onViewDetails] saat di-tap —
/// tanpa logika bisnis di dalam widget.
///
/// Hierarchy (selaras desain Stitch "Oasish Team Leave Requests"):
///  1. Baris identitas pegawai via [EmployeeInfoRow] + badge status.
///  2. Blok detail: Leave Type / Duration, rentang tanggal, catatan.
///  3. Footer: meta timezone + aksi "View Details".
class LeaveRequestCard extends StatelessWidget {
  final LeaveRequestItem item;
  final VoidCallback? onViewDetails;

  const LeaveRequestCard({super.key, required this.item, this.onViewDetails});

  /// Badge status — desainnya identik dengan badge di [ActivityCard]:
  /// pill (radius 100) berisi dot 6px + label, warna dari
  /// [LeaveStatusExtension] (same palette as ActivityStatusExtension).
  Widget _buildStatusBadge(LeaveStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3.5,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(100),
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
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.textColor,
              fontSize: 10.5,
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
    final surfaceCol = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final subtleCol = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.backgroundSubtle;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceCol,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Identitas pegawai + badge status ──────────────────────
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
                    // Widget global identitas pegawai — konsisten dengan
                    // ActivityCard (avatar, nama, role • dept, badge ID/company).
                    EmployeeInfoRow(
                      name: item.name,
                      role: item.role,
                      department: item.department,
                      company: item.company.isNotEmpty ? item.company : null,
                      employeeId: item.employeeNumber,
                      avatarUrl: item.avatarUrl,
                      initials: item.initials,
                      avatarSize: 44,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Badge status — desain identik dengan badge di ActivityCard
              // (pill + dot 6px + label, warna dari extension).
              _buildStatusBadge(item.status),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. Blok detail: type / duration / dates / note ───────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: subtleCol,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _detailColumn('Leave Type', item.leaveType, textCol, subtitleCol)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _detailColumn(
                        'Duration',
                        item.durationLabel,
                        textCol,
                        subtitleCol,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 1,
                  decoration: BoxDecoration(
                    color: borderCol,
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.calendarDays, size: 17, color: brandColor),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        item.dateRangeLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textCol,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Catatan / alasan — dipagari left border seperti desain.
                _NoteBlock(
                  text: item.note,
                  color: subtitleCol,
                  brandColor: brandColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 3. Footer: meta timezone + aksi View Details ────────────
          Row(
            children: [
              Icon(LucideIcons.clock, size: 13, color: subtitleCol),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Submitted with Timezone: ${item.timezone}',
                  style: AppTypography.labelSmall.copyWith(
                    color: subtitleCol,
                    fontSize: 11,
                  ),
                ),
              ),
              if (onViewDetails != null)
                GestureDetector(
                  onTap: onViewDetails,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: AppTypography.labelMedium.copyWith(
                          color: brandColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, size: 18, color: brandColor),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    // Card "Approved" pada desain sedikit meredup (opacity-75).
    return Opacity(
      opacity: item.status == LeaveStatus.approved ? 0.85 : 1.0,
      child: card,
    );
  }

  // ── Helper: kolom label+nilai kecil ──────────────────────────────────
  Widget _detailColumn(
    String label,
    String value,
    Color textCol,
    Color subtitleCol, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: subtitleCol,
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: textCol,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Catatan alasan (italic + left border teal) — potongan kecil terpisah
/// agar [LeaveRequestCard] tetap terbaca.
class _NoteBlock extends StatelessWidget {
  final String text;
  final Color color;
  final Color brandColor;

  const _NoteBlock({
    required this.text,
    required this.color,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: brandColor, width: 2),
        ),
      ),
      child: Text(
        '“$text”',
        style: AppTypography.bodyMedium.copyWith(
          color: color,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
