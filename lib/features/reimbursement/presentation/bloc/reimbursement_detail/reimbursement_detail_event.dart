import 'package:equatable/equatable.dart';

abstract class ReimbursementDetailEvent extends Equatable {
  const ReimbursementDetailEvent();

  @override
  List<Object?> get props => [];
}

class ReimbursementDetailFetched extends ReimbursementDetailEvent {
  final String id;
  const ReimbursementDetailFetched(this.id);

  @override
  List<Object?> get props => [id];
}

class ReimbursementDetailApproved extends ReimbursementDetailEvent {
  final bool isApproved;
  final String? approverNotes;
  final String? rejectionReason;

  const ReimbursementDetailApproved({
    required this.isApproved,
    this.approverNotes,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [isApproved, approverNotes, rejectionReason];
}
