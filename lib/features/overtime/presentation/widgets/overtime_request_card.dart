import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/app_status_icon.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/core/widgets/request_card_header.dart';
import 'package:hris_flutter/features/overtime/presentation/models/overtime_request_item.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kartu ringkas permintaan lembur pada daftar pengajuan.
///
/// Presentasi-only: menerima [OvertimeRequestItem] sudah jadi (sumber data
/// dari BLoC) dan meng-emit callback [onViewDetails] saat di-tap.
/// Hanya menampilkan identitas inti, jadwal + durasi, dan alasan singkat.
class OvertimeRequestCard extends StatelessWidget {
  final OvertimeRequestItem request;
  final VoidCallback? onViewDetails;

  const OvertimeRequestCard({
    super.key,
    required this.request,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedule = request.startTime != null || request.endTime != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
      child: RequestListCardFrame(
        onTap: onViewDetails,
        dimmed: request.status == OvertimeStatus.rejected,
        header: RequestCardHeader(
          name: request.name,
          role: request.role,
          department: request.department,
          avatarUrl: request.avatarUrl,
          initials: request.initials,
          isSelf: request.isSelf,
          trailing: AppStatusIcon(
            label: request.status.label,
            tone: request.status.tone,
            size: 30,
          ),
        ),
        children: [
          RequestCardInfoLine(
            icon: LucideIcons.calendarDays,
            text: request.dateLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          RequestCardInfoLine(
            icon: LucideIcons.clock,
            text: hasSchedule
                ? request.timeRangeLabel
                : 'Jadwal belum dikonfirmasi',
            trailingText: hasSchedule ? request.durationLabel : null,
            emphasize: true,
          ),
          if (request.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            RequestCardNote(text: request.notes),
          ],
        ],
      ),
    );
  }
}
