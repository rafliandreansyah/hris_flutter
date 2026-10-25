import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
import 'package:hris_flutter/features/leave/presentation/models/leave_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Card permintaan cuti/izin pada daftar pengajuan.
///
/// Presentasi-only: menerima [LeaveRequestItem] sudah jadi (sumber data
/// dari BLoC) dan meng-emit callback [onViewDetails] saat di-tap.
///
/// Sengaja ringkas — hanya identitas inti pegawai, jenis cuti, durasi,
/// rentang tanggal, dan catatan singkat. Detail lengkap ada di halaman detail.
class LeaveRequestCard extends StatelessWidget {
  final LeaveRequestItem item;
  final VoidCallback? onViewDetails;

  const LeaveRequestCard({super.key, required this.item, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return RequestListCardFrame(
      onTap: onViewDetails,
      dimmed: item.status == LeaveStatus.approved,
      header: RequestCardHeader(
        name: item.name,
        role: item.role,
        department: item.department,
        avatarUrl: item.avatarUrl,
        initials: item.initials,
        isSelf: item.isSelf,
        trailing: AppStatusIcon(
          label: item.status.label,
          tone: item.status.tone,
          size: 30,
        ),
      ),
      children: [
        RequestCardInfoLine(
          icon: LucideIcons.calendarClock,
          text: item.leaveType,
          trailingText: item.durationLabel,
          emphasize: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        RequestCardInfoLine(
          icon: LucideIcons.calendarDays,
          text: item.dateRangeLabel,
        ),
        if (item.notes.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          RequestCardNote(text: item.notes),
        ],
      ],
    );
  }
}
