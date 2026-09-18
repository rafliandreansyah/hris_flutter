import 'package:equatable/equatable.dart';

abstract class AttendanceRequestDetailEvent extends Equatable {
  const AttendanceRequestDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event saat halaman detail presensi luar kantor pertama kali dibuka.
class AttendanceRequestDetailStarted extends AttendanceRequestDetailEvent {
  final String id;
  final bool isApprover;

  const AttendanceRequestDetailStarted({
    required this.id,
    this.isApprover = false,
  });

  @override
  List<Object?> get props => [id, isApprover];
}

/// Event pull-to-refresh untuk memuat ulang data detail presensi luar kantor.
class AttendanceRequestDetailRefreshRequested
    extends AttendanceRequestDetailEvent {
  const AttendanceRequestDetailRefreshRequested();
}

/// Event submit approval (Approve / Reject) oleh approver.
class AttendanceRequestDetailApproveSubmitted
    extends AttendanceRequestDetailEvent {
  final bool isApproved;
  final String? approverNotes;

  const AttendanceRequestDetailApproveSubmitted({
    required this.isApproved,
    this.approverNotes,
  });

  @override
  List<Object?> get props => [isApproved, approverNotes];
}

/// Event submit hapus permohonan presensi luar kantor milik sendiri (`DELETE /attendances/requests/{id}`).
class AttendanceRequestDetailDeleteSubmitted
    extends AttendanceRequestDetailEvent {
  const AttendanceRequestDetailDeleteSubmitted();
}
