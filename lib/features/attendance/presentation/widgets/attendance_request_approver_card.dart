import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/attendance/data/models/attendance_request_api_models.dart';

/// Card Approver ("PEJABAT PENYETUJU") presensi luar — memakai
/// [RequestDetailPersonCard] global. Tersembunyi bila belum ada approver
/// maupun catatan.
class AttendanceRequestApproverCard extends StatelessWidget {
  final AttendanceRequestEmployeeModel? approver;
  final String? approverNotes;
  final bool isRejected;

  const AttendanceRequestApproverCard({
    super.key,
    this.approver,
    this.approverNotes,
    this.isRejected = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = approver;
    final hasNotes = approverNotes != null && approverNotes!.trim().isNotEmpty;
    if (app == null && !hasNotes) return const SizedBox.shrink();

    return RequestDetailPersonCard(
      title: 'Pejabat Penyetuju',
      name: (app?.fullName.isNotEmpty ?? false) ? app!.fullName : 'Approver',
      position: app?.position?.name,
      level: app?.levelName,
      department: app?.department?.name,
      avatarUrl: app?.photoUrl,
      initials: app?.initials,
      notes: approverNotes,
      notesLabel: isRejected ? 'Alasan Penolakan' : 'Catatan Approver',
      isRejected: isRejected,
    );
  }
}
