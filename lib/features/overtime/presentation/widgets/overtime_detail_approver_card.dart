import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/activity/data/models/activity_api_models.dart'
    show resolveFileUrl;
import 'package:hris_flutter/features/overtime/data/models/overtime_api_models.dart';

/// Card Approver ("PEJABAT PENYETUJU") lembur — memakai
/// [RequestDetailPersonCard] global beserta catatan approver bila ada.
class OvertimeDetailApproverCard extends StatelessWidget {
  final OvertimeEmployeeModel approver;
  final String? approverNotes;
  final bool isRejected;

  const OvertimeDetailApproverCard({
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
      avatarUrl: resolveFileUrl(approver.photoUrl),
      initials: approver.initials,
      notes: approverNotes,
      notesLabel: isRejected ? 'Alasan Penolakan' : 'Catatan Approver',
      isRejected: isRejected,
    );
  }
}
