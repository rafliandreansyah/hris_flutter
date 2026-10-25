import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
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

    return RequestListCardFrame(
      onTap: onTap,
      header: RequestCardHeader(
        name: item.name,
        role: item.role,
        department: item.department,
        avatarUrl: item.avatarUrl,
        initials: item.initials,
        isSelf: item.isSelf,
        trailing: _buildStatusBadge(item.status),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: RequestCardInfoLine(
                icon: LucideIcons.calendar,
                text: item.formattedDate,
                emphasize: true,
              ),
            ),
            if (item.attendanceTypeBadge.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              _buildTypeBadge(item, isDark),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        RequestCardInfoLine(
          icon: LucideIcons.clock,
          text: item.formattedWorkHours,
        ),
        if (item.notes.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          RequestCardNote(text: item.notes),
        ],
      ],
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
          : AppColors.primaryContainer;
      fg = isDark ? const Color(0xFF5EEAD4) : AppColors.primaryHover;
      border = isDark ? AppColors.onPrimaryContainer : AppColors.accentTealLight;
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

  Widget _buildStatusBadge(AttendanceRequestStatus status) =>
      AppStatusIcon(label: status.label, tone: status.tone, size: 30);
}
