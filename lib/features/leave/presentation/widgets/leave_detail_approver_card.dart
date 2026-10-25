import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/leave/data/models/leave_request_detail_model.dart';

/// Card Approver ("PEJABAT PENYETUJU") — memakai [RequestDetailPersonCard]
/// global, lengkap dengan callout catatan/alasan approver bila ada.
class LeaveDetailApproverCard extends StatelessWidget {
  final LeaveApproverDetailModel approver;
  final String? approverNotes;
  final bool isRejected;

  const LeaveDetailApproverCard({
    super.key,
    required this.approver,
    this.approverNotes,
    this.isRejected = false,
  });

  @override
  Widget build(BuildContext context) {
    return RequestDetailPersonCard(
      title: 'Pejabat Penyetuju',
      name: approver.fullName,
      position: approver.position?.name,
      level: approver.levelName,
      department: approver.department?.name,
      avatarUrl: approver.resolvedAvatarUrl,
      initials: approver.initials,
      notes: approverNotes,
      notesLabel: isRejected ? 'Alasan Penolakan' : 'Catatan Approver',
      isRejected: isRejected,
    );
  }
}
