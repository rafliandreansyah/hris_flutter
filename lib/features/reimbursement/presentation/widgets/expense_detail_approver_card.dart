import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/reimbursement/data/models/expenses_feed_model.dart';

/// Card Approver ("PEJABAT PENYETUJU") reimbursement/kasbon — memakai
/// [RequestDetailPersonCard] global. Menampilkan alasan penolakan (merah)
/// atau catatan approver bila ada.
class ExpenseDetailApproverCard extends StatelessWidget {
  final ExpenseEmployeeModel? approver;
  final String? approverNotes;
  final String? rejectionReason;

  const ExpenseDetailApproverCard({
    super.key,
    this.approver,
    this.approverNotes,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected =
        rejectionReason != null && rejectionReason!.trim().isNotEmpty;
    final noteText = (isRejected ? rejectionReason : approverNotes)?.trim();
    final app = approver;

    return RequestDetailPersonCard(
      title: 'Pejabat Penyetuju',
      name: (app?.fullName.isNotEmpty ?? false)
          ? app!.fullName
          : 'Belum ada data profil approver',
      position: app?.position,
      level: app?.levelName,
      department: app?.department,
      avatarUrl: app?.resolvedPhotoUrl,
      initials: app?.initials,
      notes: noteText,
      notesLabel: isRejected ? 'Alasan Penolakan' : 'Catatan Approver',
      isRejected: isRejected,
    );
  }
}
