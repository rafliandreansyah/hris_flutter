import 'package:equatable/equatable.dart';

abstract class LeaveDetailEvent extends Equatable {
  const LeaveDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman detail cuti pertama kali dibuka.
class LeaveDetailStarted extends LeaveDetailEvent {
  final String id;
  final bool isApprover;

  const LeaveDetailStarted({
    required this.id,
    this.isApprover = false,
  });

  @override
  List<Object?> get props => [id, isApprover];
}

/// Event pull-to-refresh untuk memuat ulang data detail pengajuan cuti.
class LeaveDetailRefreshRequested extends LeaveDetailEvent {
  const LeaveDetailRefreshRequested();
}

/// Event submit approval (Approve / Reject) oleh approver.
class LeaveDetailApproveSubmitted extends LeaveDetailEvent {
  final bool isApproved;
  final String? approverNotes;

  const LeaveDetailApproveSubmitted({
    required this.isApproved,
    this.approverNotes,
  });

  @override
  List<Object?> get props => [isApproved, approverNotes];
}

/// Event submit hapus pengajuan cuti milik sendiri (`DELETE /leave-request/{id}`).
class LeaveDetailDeleteSubmitted extends LeaveDetailEvent {
  const LeaveDetailDeleteSubmitted();
}
