import 'package:equatable/equatable.dart';

abstract class OvertimeDetailEvent extends Equatable {
  const OvertimeDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman detail lembur pertama kali dibuka.
class OvertimeDetailStarted extends OvertimeDetailEvent {
  final String id;
  final bool isApprover;

  const OvertimeDetailStarted({
    required this.id,
    this.isApprover = false,
  });

  @override
  List<Object?> get props => [id, isApprover];
}

/// Event pull-to-refresh untuk memuat ulang data detail pengajuan lembur.
class OvertimeDetailRefreshRequested extends OvertimeDetailEvent {
  const OvertimeDetailRefreshRequested();
}

/// Event submit approval (Approve / Reject) oleh approver.
class OvertimeDetailApproveSubmitted extends OvertimeDetailEvent {
  final bool isApproved;
  final String? approverNotes;

  const OvertimeDetailApproveSubmitted({
    required this.isApproved,
    this.approverNotes,
  });

  @override
  List<Object?> get props => [isApproved, approverNotes];
}

/// Event submit hapus pengajuan lembur milik sendiri (`DELETE /overtime/{id}`).
class OvertimeDetailDeleteSubmitted extends OvertimeDetailEvent {
  const OvertimeDetailDeleteSubmitted();
}
