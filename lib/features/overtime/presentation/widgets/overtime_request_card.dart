import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/employee_info_row.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu permintaan lembur sesuai Google Stitch (Team Overtime Requests) —
/// header pegawai memakai [EmployeeInfoRow], badge status identik dengan
/// badge pada ActivityCard (ActivityStatusExtension style).
///
/// Presentasi-only: menerima [OvertimeRequestItem] sudah jadi (sumber data
/// dari BLoC) dan meng-emit callback [onViewDetails] saat di-tap —
/// tanpa logika bisnis di dalam widget.
class OvertimeRequestCard extends StatelessWidget {
  final OvertimeRequestItem request;
  final VoidCallback? onViewDetails;

  const OvertimeRequestCard({
    super.key,
    required this.request,
    this.onViewDetails,
  });

  /// Badge status — desainnya identik dengan badge di ActivityCard:
  /// pill (radius 100) berisi dot 6px + label, warna dari
  /// [OvertimeStatusExtension] (same palette as ActivityStatusExtension).
  Widget _buildStatusBadge(OvertimeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
    final cardBg = isDark
        ? AppColors.darkSurfaceContainerLowest
        : AppColors.surfaceContainerLowest;
    final borderCol = isDark
        ? AppColors.darkOutlineMuted
        : AppColors.outlineMuted;
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.onSurfaceVariant;
    final brandColor = isDark ? AppColors.inversePrimary : AppColors.brandTeal;
    final blockBg = isDark
        ? AppColors.darkSurfaceContainerLow
        : const Color(0xFFF8FAFC);
    final mutedTint = isDark
        ? AppColors.darkSurfaceContainerHigh
        : AppColors.accentTealLight;

    final hasSchedule = request.startTime != null || request.endTime != null;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.brandTeal.withValues(alpha: 0.08),
          highlightColor: AppColors.brandTeal.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Employee Header + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (request.isSelf)
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
                            name: request.name,
                            role: request.role,
                            department: request.department,
                            company: request.company.isNotEmpty
                                ? request.company
                                : null,
                            employeeId: request.employeeNumber,
                            avatarUrl: request.avatarUrl,
                            initials: request.initials,
                            avatarSize: 40,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge status — desain identik dengan ActivityCard
                    // (pill + dot 6px + label, warna dari extension).
                    _buildStatusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Overtime Block (Jadwal & Durasi)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blockBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 18, color: textCol),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasSchedule
                                  ? '${request.dateLabel} • ${request.timeRangeLabel}'
                                  : 'Jadwal belum dikonfirmasi',
                              style: AppTypography.bodyMedium.copyWith(
                                color: textCol,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasSchedule)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: mutedTint.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                request.durationLabel,
                                style: AppTypography.labelMedium.copyWith(
                                  color: brandColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (request.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),

                        // 3. Alasan Lembur (italic + garis kiri)
                        Container(
                          padding: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: borderCol, width: 2),
                            ),
                          ),
                          child: Text(
                            '"${request.notes}"',
                            style: AppTypography.bodyMedium.copyWith(
                              color: subtitleCol,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // 4. Footer (Zona Waktu & View Details)
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderCol.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              request.timezone,
                              style: AppTypography.labelSmall.copyWith(
                                color: subtitleCol,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (onViewDetails != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: brandColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
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
              ],
            ),
          ),
        ),
      ),
    );

    // Kartu status terminal (rejected) sedikit diredam, pola dari LeaveRequestCard
    return Opacity(
      opacity: request.status == OvertimeStatus.rejected ? 0.85 : 1.0,
      child: card,
    );
  }
}
