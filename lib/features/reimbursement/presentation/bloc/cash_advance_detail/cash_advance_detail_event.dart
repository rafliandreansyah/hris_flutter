import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class CashAdvanceDetailEvent extends Equatable {
  const CashAdvanceDetailEvent();

  @override
  List<Object?> get props => [];
}

class CashAdvanceDetailFetched extends CashAdvanceDetailEvent {
  final String id;
  const CashAdvanceDetailFetched(this.id);

  @override
  List<Object?> get props => [id];
}

class CashAdvanceDetailApproved extends CashAdvanceDetailEvent {
  final bool isApproved;
  final double? approvedAmount;
  final String? approverNotes;

  const CashAdvanceDetailApproved({
    required this.isApproved,
    this.approvedAmount,
    this.approverNotes,
  });

  @override
  List<Object?> get props => [isApproved, approvedAmount, approverNotes];
}

class CashAdvanceRefundSubmitted extends CashAdvanceDetailEvent {
  final double amount;
  final String method;
  final String? refundDate;
  final String? notes;
  final XFile? proofFile;

  const CashAdvanceRefundSubmitted({
    required this.amount,
    required this.method,
    this.refundDate,
    this.notes,
    this.proofFile,
  });

  @override
  List<Object?> get props => [amount, method, refundDate, notes, proofFile];
}
