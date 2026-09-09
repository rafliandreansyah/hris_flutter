import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_detail_model.dart';
import 'package:hris_flutter/l10n/generated/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttendanceRequestInfoCard extends StatelessWidget {
  final AttendanceDetailModel detail;

  const AttendanceRequestInfoCard({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    // Hide if no attendance request ID
    if (!detail.hasAttendanceRequest) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF1E212B)
        : const Color(0xFFFFFBEB); // Soft Amber Tint
    final borderCol = isDark
        ? const Color(0xFF92400E).withValues(alpha: 0.4)
        : const Color(0xFFFDE68A);
    final textCol = isDark ? AppColors.darkOnSurface : AppColors.onSurface;
    final subtitleCol = isDark
        ? AppColors.darkOnSurfaceVariant
        : const Color(0xFF92400E);

    final requestId = detail.attendanceRequestId!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: File Icon + Title + Chip
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.4)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.fileText,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.outsideAttendanceTitle ?? 'Kehadiran Luar Kantor',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.outsideAttendanceDesc ??
                          'Absen dari pengajuan Outside Attendance / Kehadiran luar kantor',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: subtitleCol,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFFDE68A)),
          const SizedBox(height: 10),

          // Request Reference ID Row with Copy action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.hash,
                    size: 14,
                    color: subtitleCol,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n?.requestReference ?? "Referensi Pengajuan"}:',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtitleCol,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: requestId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ID Pengajuan disalin: $requestId'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineMuted
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          requestId,
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.copy,
                        size: 11,
                        color: subtitleCol,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
